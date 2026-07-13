import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/guide/purification/content/wudu_step_contents.dart';
import 'package:ihdina/guide/purification/religious_content_copy.dart';
import 'package:ihdina/guide/purification/religious_content_meta.dart';

void main() {
  group('WuduStepContents.preparation', () {
    final content = WuduStepContents.preparation;

    test('metadata marks draft and pending scholar review', () {
      expect(content.reviewStatus, ReligiousReviewStatus.pendingScholarReview);
      expect(content.sourceStatus, ReligiousSourceStatus.sourcePrepared);
      expect(content.releaseStatus, ReligiousReleaseStatus.developmentOnly);
      expect(content.contentVersion, kTaharaContentVersion);
    });

    test('step numbering matches guide overview', () {
      expect(content.stepNumber, 1);
      expect(content.totalSteps, 13);
      expect(content.progressLabel, 'Schritt 1 von 13');
    });

    test('introduction matches review document wording', () {
      expect(
        content.introduction,
        contains('Bevor du beginnst'),
      );
      expect(content.introduction, contains('Wasser'));
    });

    test('has three check items including medical detail sheet', () {
      expect(content.items, hasLength(3));
      expect(content.items[2].title, 'Medizinische Abdeckungen');
      expect(content.items[2].hasDetailSheet, isTrue);
    });

    test('sources reference documented Diyanet and Nūr pages', () {
      expect(content.sources, hasLength(2));
      expect(content.sources[0].bookPage, '101');
      expect(content.sources[1].bookPage, '47');
      expect(content.sources[1].pdfPage, '40');
    });

    test('pending review notice comes from central copy', () {
      expect(content.showPendingReviewNotice, isTrue);
      expect(
        content.pendingReviewNoticeText,
        ReligiousContentCopy.pendingReviewNotice,
      );
    });
  });
}
