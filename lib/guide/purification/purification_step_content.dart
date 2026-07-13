import 'purification_check_item.dart';
import 'purification_live_presentation.dart';
import 'religious_content_copy.dart';
import 'religious_content_meta.dart';
import 'religious_liturgical_text.dart';
import 'religious_source_reference.dart';

/// Zentraler Inhalt eines interaktiven Reinigungsschritts (Single Source of Truth).
class PurificationStepContent {
  const PurificationStepContent({
    required this.id,
    required this.guideId,
    required this.stepNumber,
    required this.totalSteps,
    required this.title,
    required this.introduction,
    required this.items,
    required this.sources,
    required this.reviewStatus,
    required this.sourceStatus,
    required this.releaseStatus,
    required this.contentVersion,
    this.category = PurificationStepCategory.prerequisite,
    this.guideAppBarTitle = 'Gebetswaschung',
    this.whyImportantTitle,
    this.whyImportantBody,
    this.primaryActionLabel = 'Weiter',
    this.detailBody,
    this.memoryAid,
    this.hint,
    this.isCompletionStep = false,
    this.secondaryActionLabel,
    this.pendingReviewNoticeOverride,
    this.sourceSheetReviewFootnoteOverride,
    this.livePresentation,
    this.liturgicalTexts = const [],
  });

  final String id;
  final String guideId;
  final int stepNumber;
  final int totalSteps;
  final String title;
  final String introduction;
  final List<PurificationCheckItem> items;
  final List<ReligiousSourceReference> sources;
  final ReligiousReviewStatus reviewStatus;
  final ReligiousSourceStatus sourceStatus;
  final ReligiousReleaseStatus releaseStatus;
  final String contentVersion;
  final PurificationStepCategory category;
  final String guideAppBarTitle;
  final String? whyImportantTitle;
  final String? whyImportantBody;
  final String primaryActionLabel;
  final String? detailBody;
  final String? memoryAid;
  final String? hint;
  final bool isCompletionStep;
  final String? secondaryActionLabel;

  /// Optionaler Schritt-spezifischer Prüfhinweis; sonst [ReligiousContentCopy.pendingReviewNotice].
  final String? pendingReviewNoticeOverride;

  /// Optionaler Fußnote-Text im Quellen-Sheet; sonst Standard aus [ReligiousContentCopy].
  final String? sourceSheetReviewFootnoteOverride;

  /// Kompakte Live-Begleiter-Ansicht; `null` = noch nicht im Live-Modus.
  final PurificationLivePresentation? livePresentation;

  /// Arabische Formeln mit Umschrift und Bedeutung (Basmala, Duʿāʾ, …).
  final List<ReligiousLiturgicalText> liturgicalTexts;

  String get progressLabel => 'Schritt $stepNumber von $totalSteps';

  bool get supportsLiveGuide => livePresentation != null;

  static final RegExp _internalHintPattern = RegExp(
    r'Primärprüfung|Hadith-Wortlaut|fachlicher Prüfung',
    caseSensitive: false,
  );

  /// Nutzer-sichtbarer Hinweis (ohne interne Prüf-/Debug-Formulierungen).
  String? get userVisibleHint {
    final value = hint;
    if (value == null || _internalHintPattern.hasMatch(value)) {
      return null;
    }
    return value;
  }

  bool get showPendingReviewNotice =>
      reviewStatus == ReligiousReviewStatus.pendingScholarReview;

  /// Positive Quellen-Einordnung für die Nutzeroberfläche.
  String? get userVisibleAttributionNotice => showPendingReviewNotice
      ? ReligiousContentCopy.guideAttributionNotice
      : null;

  String? get pendingReviewNoticeText => showPendingReviewNotice
      ? (pendingReviewNoticeOverride ??
          ReligiousContentCopy.pendingReviewNotice)
      : null;

  String? get sourceSheetReviewFootnote => showPendingReviewNotice
      ? (sourceSheetReviewFootnoteOverride ??
          ReligiousContentCopy.sourceSheetReviewPendingFootnote)
      : null;

  String? get categoryLabel => switch (category) {
        PurificationStepCategory.prerequisite =>
          ReligiousContentCopy.categoryPrerequisite,
        PurificationStepCategory.fard => ReligiousContentCopy.categoryFard,
        PurificationStepCategory.sunnah => ReligiousContentCopy.categorySunnah,
        PurificationStepCategory.adab => ReligiousContentCopy.categoryAdab,
        PurificationStepCategory.completion => null,
        PurificationStepCategory.specialCase =>
          ReligiousContentCopy.categorySpecialCase,
      };

  /// Kopie für Tests oder spätere fachliche Freigabe (Status/Text-Austausch).
  PurificationStepContent copyWith({
    ReligiousReviewStatus? reviewStatus,
    ReligiousReleaseStatus? releaseStatus,
    String? contentVersion,
    String? pendingReviewNoticeOverride,
    String? sourceSheetReviewFootnoteOverride,
    PurificationLivePresentation? livePresentation,
    List<ReligiousLiturgicalText>? liturgicalTexts,
  }) {
    return PurificationStepContent(
      id: id,
      guideId: guideId,
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      title: title,
      introduction: introduction,
      items: items,
      sources: sources,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      sourceStatus: sourceStatus,
      releaseStatus: releaseStatus ?? this.releaseStatus,
      contentVersion: contentVersion ?? this.contentVersion,
      category: category,
      guideAppBarTitle: guideAppBarTitle,
      whyImportantTitle: whyImportantTitle,
      whyImportantBody: whyImportantBody,
      primaryActionLabel: primaryActionLabel,
      detailBody: detailBody,
      memoryAid: memoryAid,
      hint: hint,
      isCompletionStep: isCompletionStep,
      secondaryActionLabel: secondaryActionLabel,
      pendingReviewNoticeOverride:
          pendingReviewNoticeOverride ?? this.pendingReviewNoticeOverride,
      sourceSheetReviewFootnoteOverride: sourceSheetReviewFootnoteOverride ??
          this.sourceSheetReviewFootnoteOverride,
      livePresentation: livePresentation ?? this.livePresentation,
      liturgicalTexts: liturgicalTexts ?? this.liturgicalTexts,
    );
  }
}
