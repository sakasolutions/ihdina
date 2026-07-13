import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ihdina/guide/purification/content/wudu_guide_content.dart';
import 'package:ihdina/guide/purification/content/wudu_step_contents.dart';
import 'package:ihdina/guide/purification/religious_content_copy.dart';
import 'package:ihdina/guide/purification/purification_guide_navigation.dart';
import 'package:ihdina/guide/purification/religious_content_meta.dart';
import 'package:ihdina/screens/purification_step_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpWithOverview(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      MaterialApp(
        home: home,
      ),
    );
  }

  testWidgets('shows step 1 title, introduction and check items',
      (tester) async {
    await pumpWithOverview(
      tester,
      PurificationStepScreen(content: WuduStepContents.preparation),
    );

    expect(find.text('Vor dem Wudu'), findsOneWidget);
    expect(find.text('Schritt 1 von 13'), findsOneWidget);
    expect(find.textContaining('Bevor du beginnst'), findsOneWidget);
    expect(find.text('Reines Wasser'), findsOneWidget);
    expect(find.text('Medizinische Abdeckungen'), findsOneWidget);
    expect(find.text('Besondere Fälle'), findsOneWidget);
    expect(
      find.text(ReligiousContentCopy.guideAttributionNotice),
      findsOneWidget,
    );
    expect(
      find.text(WuduGuideContent.primaryActionBeginWudu),
      findsOneWidget,
    );
  });

  testWidgets('step 1 primary action opens step 2', (tester) async {
    await pumpWithOverview(
      tester,
      PurificationStepScreen(content: WuduStepContents.preparation),
    );

    await tester.tap(find.text(WuduGuideContent.primaryActionBeginWudu));
    await tester.pumpAndSettle();

    expect(find.text('Absicht fassen'), findsOneWidget);
    expect(find.text('Schritt 2 von 13'), findsOneWidget);
  });

  testWidgets('step 12 navigates to step 13 completion', (tester) async {
    await pumpWithOverview(
      tester,
      PurificationStepScreen(content: WuduStepContents.duaAfter),
    );

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(find.text('Gebetswaschung abgeschlossen'), findsOneWidget);
    expect(find.text(WuduGuideContent.completionPrimaryAction), findsOneWidget);
    expect(
        find.text(WuduGuideContent.completionSecondaryAction), findsOneWidget);
  });

  testWidgets('back navigation returns to previous step', (tester) async {
    await pumpWithOverview(
      tester,
      PurificationStepScreen(content: WuduStepContents.preparation),
    );

    await tester.tap(find.text(WuduGuideContent.primaryActionBeginWudu));
    await tester.pumpAndSettle();
    expect(find.text('Absicht fassen'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Vor dem Wudu'), findsOneWidget);
    expect(find.text('Absicht fassen'), findsNothing);
  });

  testWidgets('completion returns to overview', (tester) async {
    const overviewKey = Key('wudu-overview-marker');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(
                          name: kWuduOverviewRouteName,
                        ),
                        builder: (_) => const Scaffold(
                          key: overviewKey,
                          body: SizedBox.shrink(),
                        ),
                      ),
                    );
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => PurificationStepScreen(
                          content: WuduStepContents.summary,
                        ),
                      ),
                    );
                  },
                  child: const Text('Setup stack'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Setup stack'));
    await tester.pumpAndSettle();

    expect(find.text('Gebetswaschung abgeschlossen'), findsOneWidget);

    await tester.tap(find.text(WuduGuideContent.completionPrimaryAction));
    await tester.pumpAndSettle();

    expect(find.byKey(overviewKey), findsOneWidget);
    expect(find.text('Gebetswaschung abgeschlossen'), findsNothing);
  });

  testWidgets('sources sheet opens from link', (tester) async {
    await pumpWithOverview(
      tester,
      PurificationStepScreen(content: WuduStepContents.intention),
    );

    await tester.tap(find.text(WuduGuideContent.sourcesLinkLabel));
    await tester.pumpAndSettle();

    expect(find.textContaining('Diyanet'), findsWidgets);
    expect(find.textContaining('Nūr al-Īḍāḥ'), findsWidgets);
    expect(
      find.text(ReligiousContentCopy.sourceSheetReviewPendingFootnote),
      findsNothing,
    );
  });

  testWidgets('why sheet opens on step 1', (tester) async {
    await pumpWithOverview(
      tester,
      PurificationStepScreen(content: WuduStepContents.preparation),
    );

    await tester.tap(find.text(WuduGuideContent.step1WhyImportantTitle));
    await tester.pumpAndSettle();

    expect(find.textContaining('Diyanet'), findsWidgets);
    expect(find.textContaining('Nūr al-Īḍāḥ'), findsWidgets);
  });
}
