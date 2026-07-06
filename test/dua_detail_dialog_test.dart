import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/data/dua/dua_entry.dart';
import 'package:ihdina/data/dua/dua_repository.dart';
import 'package:ihdina/widgets/dua_detail_dialog.dart';
import 'package:ihdina/widgets/dua_reader_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DuaEntry entry193;
  late DuaEntry entry120;

  setUpAll(() async {
    DuaRepository.resetCacheForTest();
    final data = await DuaRepository.instance.load();
    entry193 = data.byId[193]!;
    entry120 = data.byId[120]!;
  });

  testWidgets('öffnet DuaReaderTile im Dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDuaDetailDialog(
                context,
                entry: entry193,
                listIndex: 1,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(DuaReaderTile), findsOneWidget);
    expect(find.textContaining('أَعُوذُ'), findsOneWidget);
    expect(find.textContaining('verfluchten Schaytan'), findsOneWidget);
  });

  testWidgets('lange Dua im Dialog scrollbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDuaDetailDialog(
                context,
                entry: entry120,
                listIndex: 2,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.textContaining('O Allah, ich bin Dein Diener'), findsOneWidget);
    expect(find.byTooltip('Schließen'), findsOneWidget);
  });
}
