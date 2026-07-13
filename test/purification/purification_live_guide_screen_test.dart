import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ihdina/guide/purification/content/wudu_guide_content.dart';
import 'package:ihdina/guide/purification/religious_content_copy.dart';
import 'package:ihdina/guide/purification/widgets/purification_overlay_sheet.dart';
import 'package:ihdina/guide/purification/purification_guide_navigation.dart';
import 'package:ihdina/screens/purification_live_guide_screen.dart';
import 'package:ihdina/screens/purification_step_screen.dart';
import 'package:ihdina/screens/wudu_overview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpLiveGuide(WidgetTester tester, {int step = 1}) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: PurificationLiveGuideScreen(initialStepNumber: step),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('PurificationLiveGuideScreen — vollständiger Guide 1–13', () {
    testWidgets('Schritt 1 zeigt Titel, Hauptanweisung und Hinweis',
        (tester) async {
      await pumpLiveGuide(tester);

      expect(find.text('Vor dem Wudu'), findsOneWidget);
      expect(
        find.textContaining('sauberes Wasser die zu waschenden Stellen'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Feste Schichten entfernen'),
        findsOneWidget,
      );
    });

    testWidgets('Liturgical-Schritt ist vertikal scrollbar', (tester) async {
      await pumpLiveGuide(tester, step: 3);
      expect(find.byType(Scrollable), findsWidgets);
    });

    testWidgets('Mehr dazu öffnet Detailinhalt mit Quellen', (tester) async {
      await pumpLiveGuide(tester);

      await tester.tap(find.text(WuduGuideContent.liveMoreLabel));
      await tester.pumpAndSettle();

      expect(find.text('Reines Wasser'), findsOneWidget);
      await tester.ensureVisible(
        find.text(WuduGuideContent.step1WhyImportantTitle),
      );
      await tester.tap(find.text(WuduGuideContent.step1WhyImportantTitle));
      await tester.pumpAndSettle();

      expect(find.textContaining('Diyanet'), findsWidgets);
    });

    testWidgets('Ich bin bereit führt zu Schritt 2', (tester) async {
      await pumpLiveGuide(tester);

      await tester.tap(find.text(WuduGuideContent.livePrimaryReady));
      await tester.pumpAndSettle();

      expect(find.text('Absicht fassen'), findsOneWidget);
    });

    testWidgets('Navigation 1 bis 13 funktioniert', (tester) async {
      await pumpLiveGuide(tester);

      const stepTitles = [
        'Vor dem Wudu',
        'Absicht fassen',
        'Basmala',
        'Hände waschen',
        'Mund ausspülen',
        'Nase reinigen',
        'Gesicht waschen',
        'Arme waschen',
        'Kopf streichen',
        'Ohren streichen',
        'Füße waschen',
        'Dua nach dem Wudu',
        'Gebetswaschung abgeschlossen',
      ];

      expect(find.text(stepTitles.first), findsOneWidget);

      await tester.tap(find.text(WuduGuideContent.livePrimaryReady));
      await tester.pumpAndSettle();

      for (var i = 1; i < stepTitles.length; i++) {
        final title = stepTitles[i];
        // Schritt 3: Titel und liturgisches Label heißen beide „Basmala“.
        if (title == 'Basmala') {
          expect(find.text(title), findsWidgets);
        } else {
          expect(find.text(title), findsOneWidget);
        }
        if (i < stepTitles.length - 1) {
          await tester.tap(find.text(WuduGuideContent.livePrimaryContinue));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Zurück-Navigation funktioniert', (tester) async {
      await pumpLiveGuide(tester, step: 4);

      await tester.tap(find.text(WuduGuideContent.liveBackLabel));
      await tester.pumpAndSettle();
      expect(find.text('Basmala'), findsWidgets);

      await tester.tap(find.text(WuduGuideContent.liveBackLabel));
      await tester.pumpAndSettle();
      expect(find.text('Absicht fassen'), findsOneWidget);

      await tester.tap(find.text(WuduGuideContent.liveBackLabel));
      await tester.pumpAndSettle();
      expect(find.text('Vor dem Wudu'), findsOneWidget);
      expect(find.text(WuduGuideContent.liveBackLabel), findsNothing);
    });

    testWidgets('Schritt 13 zeigt neutralen Abschluss', (tester) async {
      await pumpLiveGuide(tester, step: 13);

      expect(find.text('Gebetswaschung abgeschlossen'), findsOneWidget);
      expect(
        find.textContaining('alle Schritte des Wudu-Begleiters'),
        findsOneWidget,
      );
      expect(
          find.text(WuduGuideContent.completionPrimaryAction), findsOneWidget);
      expect(
        find.text(WuduGuideContent.completionSecondaryAction),
        findsOneWidget,
      );
      expect(find.textContaining('Dein Wudu ist gültig'), findsNothing);
    });

    testWidgets('Mehr dazu bei Schritt 7 öffnet Detailinhalt', (tester) async {
      await pumpLiveGuide(tester, step: 7);

      await tester.tap(find.text(WuduGuideContent.liveMoreLabel));
      await tester.pumpAndSettle();

      expect(find.text('Grenzen des Gesichts'), findsOneWidget);
      expect(find.byType(PurificationOverlayCard), findsOneWidget);
    });

    testWidgets('Schließen beendet den Live-Modus', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => PurificationGuideNavigation.openWuduLiveGuide(
                  context,
                  stepNumber: 1,
                ),
                child: const Text('Open live'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open live'));
      await tester.pumpAndSettle();
      expect(find.text('Vor dem Wudu'), findsOneWidget);

      await tester.tap(find.byTooltip(WuduGuideContent.liveCloseTooltip));
      await tester.pumpAndSettle();

      expect(find.text('Vor dem Wudu'), findsNothing);
    });

    testWidgets('kein Gültigkeits- oder Freigabetext', (tester) async {
      await pumpLiveGuide(tester);
      expect(find.textContaining('Dein Wudu ist gültig'), findsNothing);
      expect(find.textContaining('fachlich freigegeben'), findsNothing);
    });

    testWidgets('Mehr dazu nutzt blickdichtes Overlay mit Scroll und Schließen',
        (tester) async {
      await pumpLiveGuide(tester);

      await tester.tap(find.text(WuduGuideContent.liveMoreLabel));
      await tester.pumpAndSettle();

      expect(find.byType(PurificationOverlayCard), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);

      final overlayClose = find.descendant(
        of: find.byType(PurificationOverlayCard),
        matching: find.byTooltip(ReligiousContentCopy.sourceSheetCloseLabel),
      );
      expect(overlayClose, findsOneWidget);

      await tester.tap(overlayClose);
      await tester.pumpAndSettle();

      expect(find.byType(PurificationOverlayCard), findsNothing);
      expect(find.text('Vor dem Wudu'), findsOneWidget);
    });

    testWidgets('Warum ist das wichtig nutzt denselben Overlay-Stil',
        (tester) async {
      await pumpLiveGuide(tester);

      await tester.tap(find.text(WuduGuideContent.liveMoreLabel));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.text(WuduGuideContent.step1WhyImportantTitle),
      );
      await tester.tap(find.text(WuduGuideContent.step1WhyImportantTitle));
      await tester.pumpAndSettle();

      expect(find.byType(PurificationOverlayCard), findsNWidgets(2));
      expect(
        find.text(WuduGuideContent.step1WhyImportantTitle),
        findsWidgets,
      );

      final closeButtons = find.byTooltip(
        ReligiousContentCopy.sourceSheetCloseLabel,
      );
      await tester.tap(closeButtons.last);
      await tester.pumpAndSettle();

      expect(find.byType(PurificationOverlayCard), findsOneWidget);
    });
  });

  group('WuduOverviewScreen — Live vs. Detail', () {
    testWidgets('Guide starten öffnet Live-Begleiter', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: WuduOverviewScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(WuduGuideContent.overviewStartButtonLabel));
      await tester.pumpAndSettle();

      expect(find.byType(PurificationLiveGuideScreen), findsOneWidget);
      expect(find.text('Vor dem Wudu'), findsOneWidget);
    });

    testWidgets('Schrittliste öffnet weiterhin Detail-Screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: WuduOverviewScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Absicht'));
      await tester.pumpAndSettle();

      expect(find.byType(PurificationStepScreen), findsOneWidget);
      expect(find.byType(PurificationLiveGuideScreen), findsNothing);
    });
  });
}
