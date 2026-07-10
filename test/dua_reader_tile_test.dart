import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/data/dua/dua_entry.dart';
import 'package:ihdina/data/dua/dua_repository.dart';
import 'package:ihdina/data/dua/dua_type.dart';
import 'package:ihdina/widgets/dua_reader_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DuaEntry entry193;
  late DuaEntry entry120;
  late DuaEntry entry188;

  setUpAll(() async {
    DuaRepository.resetCacheForTest();
    final data = await DuaRepository.instance.load();
    entry193 = data.byId[193]!;
    entry120 = data.byId[120]!;
    entry188 = data.byId[188]!;
  });

  Future<void> pumpTile(WidgetTester tester, DuaEntry entry, {int index = 1}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DuaReaderTile(entry: entry, listIndex: index),
        ),
      ),
    );
  }

  testWidgets('id 193: Card zeigt Arabisch, Deutsch, Hinweise-Button', (tester) async {
    await pumpTile(tester, entry193);

    expect(find.textContaining('أَعُوذُ'), findsOneWidget);
    expect(find.textContaining('verfluchten Schaytan'), findsOneWidget);
    expect(find.text('Hinweise'), findsOneWidget);
    expect(find.textContaining('Al-Bukhari'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
  });

  testWidgets('Lesezeichen-Button wenn onBookmarkTap gesetzt', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DuaReaderTile(
            entry: entry193,
            listIndex: 1,
            isBookmarked: true,
            onBookmarkTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bookmark_rounded));
    expect(tapped, isTrue);
  });

  testWidgets('id 120: langer Text in Card, scrollbar in ListView', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [DuaReaderTile(entry: entry120, listIndex: 1)],
          ),
        ),
      ),
    );

    expect(find.textContaining('O Allah, ich bin Dein Diener'), findsOneWidget);
    expect(find.textContaining('Schwinden meines Kummers'), findsOneWidget);
  });

  testWidgets('id 188: Hinweise-Dialog mit Anleitung-Text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [DuaReaderTile(entry: entry188, listIndex: 1)],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Hinweise'));
    await tester.pumpAndSettle();

    expect(find.text('Hinweise'), findsWidgets);
    expect(find.textContaining('überliefert und werden traditionell auf Arabisch'),
        findsOneWidget);
    expect(find.textContaining('Anleitung mit eingebettetem Sprechtext'),
        findsOneWidget);
    expect(entry188.type, DuaType.anleitung);
  });
}
