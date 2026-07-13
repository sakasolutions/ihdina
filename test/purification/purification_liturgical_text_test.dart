import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ihdina/guide/purification/content/wudu_guide_content.dart';
import 'package:ihdina/guide/purification/content/wudu_liturgical_texts.dart';
import 'package:ihdina/guide/purification/content/wudu_live_guide_config.dart';
import 'package:ihdina/guide/purification/content/wudu_step_contents.dart';
import 'package:ihdina/guide/purification/religious_liturgical_text.dart';
import 'package:ihdina/guide/purification/widgets/purification_liturgical_text_block.dart';
import 'package:ihdina/screens/purification_live_guide_screen.dart';
import 'package:ihdina/screens/purification_step_screen.dart';

/// Langer Testtext — simuliert spätere Duʿāʾ ohne Produktionsinhalte zu ändern.
const ReligiousLiturgicalText kLongLiturgicalFixture = ReligiousLiturgicalText(
  label: 'Langtext-Fixture',
  arabicText:
      'أَعُوذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيمِ بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ',
  transliteration: 'Aʿūdhu billāhi mina-sch-schayṭāni-r-radschīm. '
      'Bismillāhi-r-raḥmāni-r-raḥīm — vollständige Umschrift ohne Kürzung.',
  translation: 'Ich suche Zuflucht bei Allah vor dem verstoßenen Satan. '
      'Im Namen Allahs, des Allerbarmers, des Barmherzigen — vollständige Bedeutung.',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() {
    WuduLiveGuideConfig.disabledStepIdsOverride = null;
  });

  group('WuduLiturgicalTexts — zentrale Inhalte', () {
    test('Basmala ist vollständig hinterlegt', () {
      const text = WuduLiturgicalTexts.basmala;
      expect(text.label, 'Basmala');
      expect(text.arabicText, contains('الرَّحْمَٰنِ الرَّحِيمِ'));
      expect(text.transliteration, 'Bismillāhi r-raḥmāni r-raḥīm.');
      expect(
        text.translation,
        'Im Namen Allahs, des Allerbarmers, des Barmherzigen.',
      );
    });
  });

  group('Schritt 3 — Basmala', () {
    final step = WuduStepContents.basmala;

    test('Titel ist Basmala', () {
      expect(step.title, 'Basmala');
    });

    test('enthält genau einen liturgischen Text', () {
      expect(step.liturgicalTexts, hasLength(1));
      expect(step.liturgicalTexts.single, WuduLiturgicalTexts.basmala);
    });

    test('Check-Item verknüpft vollständige Basmala', () {
      expect(step.items, hasLength(1));
      expect(step.items.single.liturgicalText, WuduLiturgicalTexts.basmala);
      expect(step.items.single.title, 'Basmala');
    });

    test('Handlungstexte ohne Eûzü', () {
      expect(step.introduction, 'Beginne den Wudu mit der Basmala.');
      expect(step.memoryAid, contains('Mit der Basmala beginnen'));
      expect(step.introduction, isNot(contains('Eûzü')));
      expect(step.detailBody, isNot(contains('Eûzü')));
      expect(step.livePresentation!.actionText, isNot(contains('Eûzü')));
    });
  });

  group('PurificationLiturgicalTextBlock — Darstellung', () {
    testWidgets('zeigt Label, Arabisch, Lautschrift und Bedeutung',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PurificationLiturgicalTextBlock(
              text: WuduLiturgicalTexts.basmala,
            ),
          ),
        ),
      );

      expect(find.text('Basmala'), findsOneWidget);
      expect(
        find.textContaining('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'),
        findsOneWidget,
      );
      expect(find.text('Bismillāhi r-raḥmāni r-raḥīm.'), findsOneWidget);
      expect(
        find.text('Im Namen Allahs, des Allerbarmers, des Barmherzigen.'),
        findsOneWidget,
      );
    });

    testWidgets('Arabisch wird mit RTL gerendert', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PurificationLiturgicalTextBlock(
              text: WuduLiturgicalTexts.basmala,
            ),
          ),
        ),
      );

      final directionality = tester.widget<Directionality>(
        find.descendant(
          of: find.byType(PurificationLiturgicalTextBlock),
          matching: find.byType(Directionality),
        ),
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('langer arabischer Text wird vollständig gerendert',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PurificationLiturgicalTextBlock(
                text: kLongLiturgicalFixture,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('الرَّحِيمِ'), findsOneWidget);
      expect(find.textContaining('…'), findsNothing);
    });

    testWidgets('kein TextOverflow.ellipsis im Liturgical-Text-Widget',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PurificationLiturgicalTextBlock(
              text: kLongLiturgicalFixture,
            ),
          ),
        ),
      );

      final texts = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(PurificationLiturgicalTextBlock),
          matching: find.byType(Text),
        ),
      );
      for (final textWidget in texts) {
        expect(textWidget.overflow, isNot(TextOverflow.ellipsis));
        expect(textWidget.maxLines, isNull);
      }
    });

    testWidgets('große Textskalierung verursacht keinen RenderFlex-Overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.4),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: PurificationLiturgicalTextList(
                  texts: WuduStepContents.basmala.liturgicalTexts,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Live-Guide — Schritt 3', () {
    testWidgets('zeigt vollständige Basmala ohne Eûzü', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: PurificationLiveGuideScreen(initialStepNumber: 3),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Basmala'), findsWidgets);
      expect(find.text('Eûzü'), findsNothing);
      expect(
        find.textContaining('الرَّحْمَٰنِ الرَّحِيمِ'),
        findsOneWidget,
      );
      expect(find.text('Bismillāhi r-raḥmāni r-raḥīm.'), findsOneWidget);
      expect(
        find.textContaining('Allerbarmers, des Barmherzigen'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Beginne den Wudu mit der Basmala.'),
        findsWidgets,
      );
    });

    testWidgets('Navigation 2 → 3 → 4 bleibt unverändert', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: PurificationLiveGuideScreen(initialStepNumber: 2),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Absicht fassen'), findsOneWidget);

      await tester.tap(find.text(WuduGuideContent.livePrimaryContinue));
      await tester.pumpAndSettle();
      expect(find.text('Basmala'), findsWidgets);

      await tester.tap(find.text(WuduGuideContent.livePrimaryContinue));
      await tester.pumpAndSettle();
      expect(find.text('Hände waschen'), findsOneWidget);
    });
  });

  group('Detailansicht — Schritt 3', () {
    testWidgets('zeigt vollständige Basmala ohne Eûzü', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PurificationStepScreen(content: WuduStepContents.basmala),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Basmala'), findsWidgets);
      expect(find.text('Eûzü'), findsNothing);
      expect(
        find.textContaining('الرَّحْمَٰنِ الرَّحِيمِ'),
        findsOneWidget,
      );
      expect(find.text('Bismillāhi r-raḥmāni r-raḥīm.'), findsOneWidget);
      expect(find.textContaining('Zufluchtsformel'), findsNothing);
    });
  });

  group('Duʿā nach dem Wudu — Sequenz', () {
    test('bleibt außerhalb Debug deaktiviert', () {
      WuduLiveGuideConfig.disabledStepIdsOverride = {'wudu_dua_after'};
      expect(WuduLiveGuideConfig.isStepNumberEnabled(12), isFalse);
    });

    test('hat noch keine liturgicalTexts bis zur Freigabe', () {
      expect(WuduStepContents.duaAfter.liturgicalTexts, isEmpty);
    });
  });
}
