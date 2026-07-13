import '../purification_live_presentation.dart';
import '../purification_step_content.dart';
import '../purification_check_item.dart';
import '../religious_content_meta.dart';
import '../religious_source_reference.dart';
import 'wudu_guide_content.dart';
import 'wudu_liturgical_texts.dart';

/// Guide-Kennungen für spätere Tayammum/Ghusl-Erweiterung.
abstract final class PurificationGuideIds {
  static const wudu = 'wudu';
}

/// Zentrale Wudu-Schritt-Inhalte (Entwurf — Fachprüfung ausstehend).
abstract final class WuduStepContents {
  WuduStepContents._();

  static const int totalSteps = 13;

  static const _metaReview = ReligiousReviewStatus.pendingScholarReview;
  static const _metaSource = ReligiousSourceStatus.sourcePrepared;
  static const _metaRelease = ReligiousReleaseStatus.developmentOnly;
  static const _metaVersion = kTaharaContentVersion;

  /// Schritt 1 — Voraussetzungen (`docs/wudu_steps/01_voraussetzungen.md`).
  static const PurificationStepContent preparation = PurificationStepContent(
    id: 'wudu_preparation',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 1,
    totalSteps: totalSteps,
    title: 'Vor dem Wudu',
    introduction:
        'Bevor du beginnst, achte darauf, dass das Wasser die zu waschenden Stellen wirklich erreichen kann.',
    category: PurificationStepCategory.prerequisite,
    items: [
      PurificationCheckItem(
        title: 'Reines Wasser',
        body:
            'Verwende sauberes Wasser, das für die rituelle Reinigung im hanafitischen Lernpfad geeignet ist.',
      ),
      PurificationCheckItem(
        title: 'Wasser erreicht die Haut',
        body:
            'Entferne feste Schichten wie Nagellack, Wachs oder Kleber, damit das Wasser die Haut erreichen kann. Bewege enge Ringe so, dass Wasser darunter gelangt.',
      ),
      PurificationCheckItem(
        title: 'Medizinische Abdeckungen',
        body:
            'Medizinisch notwendige Pflaster, Verbände oder Schutzschichten nicht eigenständig entfernen.',
        detailActionLabel: 'Besondere Fälle',
        detailSheetTitle: 'Besondere Fälle',
        detailSheetBody:
            'Bei Wunden, Verbänden, Gips oder anderen medizinischen Einschränkungen gelten besondere Regeln. '
            'Entferne medizinische Auflagen nicht ohne ärztliche Anweisung. '
            'Bei Unsicherheit frage eine qualifizierte hanafitische Fachperson — und bei gesundheitlichen Fragen medizinisches Fachpersonal.',
      ),
    ],
    guideAppBarTitle: WuduGuideContent.guideAppBarTitle,
    whyImportantTitle: WuduGuideContent.step1WhyImportantTitle,
    whyImportantBody: WuduGuideContent.step1WhyImportantBody,
    livePresentation: PurificationLivePresentation(
      actionText:
          'Achte darauf, dass sauberes Wasser die zu waschenden Stellen erreichen kann.',
      attentionText:
          'Feste Schichten entfernen. Medizinische Abdeckungen nicht eigenständig lösen.',
      primaryActionLabel: WuduGuideContent.livePrimaryReady,
      sectionLabel: WuduGuideContent.sectionPreparation,
      visualCategory: PurificationLiveVisualCategory.preparation,
      visualDisplay: PurificationLiveVisualDisplay.compact,
      visualSemanticLabel: 'Vorbereitung für die Gebetswaschung',
    ),
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'V. Abdest (Anschluss an Farzları)',
        bookPage: '101',
        pdfPage: '101',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Conditions That Validate Wudu',
        bookPage: '47',
        pdfPage: '40',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
    primaryActionLabel: WuduGuideContent.primaryActionBeginWudu,
  );

  /// Schritt 2 — Absicht (`docs/wudu_steps/02_absicht.md`).
  static const PurificationStepContent intention = PurificationStepContent(
    id: 'wudu_intention',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 2,
    totalSteps: totalSteps,
    title: 'Absicht fassen',
    introduction: 'Mach dir bewusst, warum du Wudu machst.',
    category: PurificationStepCategory.sunnah,
    detailBody:
        'Bevor du beginnst, fasse in deinem Herzen die Absicht, Wudu zu machen. '
        'Du musst dafür keinen bestimmten Satz sprechen. Entscheidend ist die bewusste Absicht im Herzen. '
        'Im hanafitischen Lernpfad ist die Absicht eine Sunnah. Sie zusätzlich mit Worten auszusprechen, ist empfohlen.',
    memoryAid:
        'Die Absicht entsteht im Herzen. Worte können sie begleiten, sind aber nicht erforderlich.',
    items: [
      PurificationCheckItem(
        title: 'Absicht im Herzen',
        body:
            'Fasse innerlich die Absicht, Wudu zu machen — ohne vorgeschriebene Formel.',
      ),
      PurificationCheckItem(
        title: 'Worte optional',
        body:
            'Das Aussprechen der Absicht ist empfohlen, aber keine Voraussetzung für den hanafitischen Lernpfad.',
      ),
    ],
    whyImportantTitle: WuduGuideContent.sourcesLinkLabel,
    whyImportantBody: WuduGuideContent.sourcesIntroBody,
    livePresentation: PurificationLivePresentation(
      actionText: 'Fasse in deinem Herzen die Absicht, Wudu zu machen.',
      attentionText: 'Du musst keinen bestimmten Satz sprechen.',
      sectionLabel: WuduGuideContent.sectionPreparation,
      visualCategory: PurificationLiveVisualCategory.intention,
      visualDisplay: PurificationLiveVisualDisplay.minimal,
      visualSemanticLabel: 'Absicht für die Gebetswaschung',
    ),
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'Abdestin Sünnetleri, Punkt 3',
        bookPage: '102',
        pdfPage: '102',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Intention in Wudu',
        bookPage: '51',
        pdfPage: '44',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
  );

  /// Schritt 3 — Basmala (`docs/wudu_steps/03_basmala.md`).
  static const PurificationStepContent basmala = PurificationStepContent(
    id: 'wudu_basmala',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 3,
    totalSteps: totalSteps,
    title: 'Basmala',
    introduction: 'Beginne den Wudu mit der Basmala.',
    category: PurificationStepCategory.sunnah,
    detailBody:
        'Beginne den Wudu mit der Basmala. Im hanafitischen Lernpfad gehört dies zur Sunnah. '
        'Falls du es vergisst, bleibt der Wudu im hanafitischen Lernpfad dennoch wirksam, '
        'wenn alle Pflichtteile erfüllt sind.',
    memoryAid:
        'Mit der Basmala beginnen — vergessen allein macht den Wudu nicht ungültig.',
    items: [
      PurificationCheckItem(
        title: 'Basmala',
        liturgicalText: WuduLiturgicalTexts.basmala,
        body: 'Beginne die Waschung bewusst mit dem Namen Allahs.',
      ),
    ],
    whyImportantTitle: WuduGuideContent.sourcesLinkLabel,
    whyImportantBody: WuduGuideContent.sourcesIntroBody,
    livePresentation: PurificationLivePresentation(
      actionText: 'Beginne den Wudu mit der Basmala.',
      attentionText:
          'Im hanafitischen Lernpfad Sunnah — vergessen allein macht den Wudu nicht ungültig.',
      sectionLabel: WuduGuideContent.sectionPreparation,
      visualCategory: PurificationLiveVisualCategory.basmala,
      visualDisplay: PurificationLiveVisualDisplay.minimal,
      visualSemanticLabel: 'Basmala zu Beginn der Waschung',
    ),
    liturgicalTexts: [WuduLiturgicalTexts.basmala],
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'Abdestin Sünnetleri, Punkt 2',
        bookPage: '102',
        pdfPage: '102',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Sunnah of Wudu',
        bookPage: '49',
        pdfPage: '42',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
  );

  /// Schritt 4 — Hände waschen (`docs/wudu_steps/04_haende_waschen.md`).
  static const PurificationStepContent washHands = PurificationStepContent(
    id: 'wudu_wash_hands',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 4,
    totalSteps: totalSteps,
    title: 'Hände waschen',
    introduction: 'Wasche beide Hände gründlich bis zu den Handgelenken.',
    category: PurificationStepCategory.sunnah,
    detailBody:
        'Wasche zuerst beide Hände bis einschließlich der Handgelenke. Achte darauf, dass das Wasser auch zwischen die Finger gelangt. '
        'Im vollständigen hanafitischen Ablauf werden die Hände dreimal gewaschen. Dieser Schritt gehört zur Sunnah des Wudu.',
    memoryAid:
        'Hände zuerst — bis zu den Handgelenken und zwischen die Finger.',
    livePresentation: PurificationLivePresentation(
      actionText: 'Wasche beide Hände gründlich bis zu den Handgelenken.',
      attentionText: 'Achte auch auf die Fingerzwischenräume.',
      sectionLabel: WuduGuideContent.sectionWashing,
      visualCategory: PurificationLiveVisualCategory.hands,
      visualDisplay: PurificationLiveVisualDisplay.full,
      visualSemanticLabel: 'Hände waschen',
    ),
    items: [
      PurificationCheckItem(
        title: 'Beide Hände',
        body:
            'Wasche rechte und linke Hand bis einschließlich der Handgelenke.',
      ),
      PurificationCheckItem(
        title: 'Zwischenräume',
        body: 'Stelle sicher, dass Wasser zwischen alle Finger gelangt.',
      ),
    ],
    whyImportantTitle: WuduGuideContent.sourcesLinkLabel,
    whyImportantBody: WuduGuideContent.sourcesIntroBody,
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'Abdestin Sünnetleri, Punkt 1',
        bookPage: '102',
        pdfPage: '102',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Sunnah of Wudu',
        bookPage: '49',
        pdfPage: '42',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
  );

  /// Schritt 5 — Mund ausspülen (`docs/wudu_steps/05_mund_ausspuelen.md`).
  static const PurificationStepContent rinseMouth = PurificationStepContent(
    id: 'wudu_rinse_mouth',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 5,
    totalSteps: totalSteps,
    title: 'Mund ausspülen',
    introduction: 'Nimm Wasser in den Mund und spüle ihn gründlich aus.',
    category: PurificationStepCategory.sunnah,
    detailBody:
        'Nimm mit der rechten Hand Wasser in den Mund, bewege es darin und spucke es wieder aus. Wiederhole dies dreimal. '
        'Das Ausspülen des Mundes gehört im hanafitischen Wudu zur Sunnah. '
        'Wenn du fastest, spüle vorsichtig und ziehe das Wasser nicht weit in Richtung Hals.',
    memoryAid: 'Dreimal ausspülen — beim Fasten besonders vorsichtig.',
    items: [
      PurificationCheckItem(
        title: 'Rechte Hand',
        body: 'Nimm Wasser mit der rechten Hand in den Mund.',
      ),
      PurificationCheckItem(
        title: 'Gründlich ausspülen',
        body:
            'Bewege das Wasser im Mund und spucke es aus — dreimal im vollständigen Ablauf.',
      ),
    ],
    hint:
        'Beim Fasten: nicht übertreiben, damit kein Wasser in den Rachen gelangt.',
    livePresentation: PurificationLivePresentation(
      actionText: 'Nimm Wasser in den Mund und spüle ihn gründlich aus.',
      attentionText:
          'Beim Fasten vorsichtig spülen, damit kein Wasser in den Rachen gelangt.',
      sectionLabel: WuduGuideContent.sectionWashing,
      visualCategory: PurificationLiveVisualCategory.mouth,
      visualDisplay: PurificationLiveVisualDisplay.full,
      visualSemanticLabel: 'Mund ausspülen',
    ),
    whyImportantTitle: WuduGuideContent.sourcesLinkLabel,
    whyImportantBody: WuduGuideContent.sourcesIntroBody,
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'Abdestin Sünnetleri, Punkt 5',
        bookPage: '102',
        pdfPage: '102',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Sunnah of Wudu',
        bookPage: '50',
        pdfPage: '43',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
  );

  /// Schritt 6 — Nase reinigen (`docs/wudu_steps/06_nase_reinigen.md`).
  static const PurificationStepContent cleanNose = PurificationStepContent(
    id: 'wudu_clean_nose',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 6,
    totalSteps: totalSteps,
    title: 'Nase reinigen',
    introduction: 'Ziehe Wasser in die Nase und reinige sie.',
    category: PurificationStepCategory.sunnah,
    detailBody:
        'Nimm mit der rechten Hand Wasser auf, ziehe es in die Nase und reinige die Nase anschließend mit der linken Hand. '
        'Wiederhole dies dreimal. Die Nasenreinigung gehört im hanafitischen Wudu zur Sunnah. '
        'Wenn du fastest, ziehe das Wasser nicht tief ein, damit es nicht in den Rachen gelangt.',
    memoryAid: 'Rechte Hand zum Einziehen, linke Hand zum Reinigen — dreimal.',
    items: [
      PurificationCheckItem(
        title: 'Wasser einziehen',
        body: 'Nimm Wasser mit der rechten Hand auf und ziehe es in die Nase.',
      ),
      PurificationCheckItem(
        title: 'Nase reinigen',
        body:
            'Reinige die Nase mit der linken Hand und wiederhole den Vorgang dreimal.',
      ),
    ],
    hint: 'Beim Fasten: Wasser nicht tief einziehen.',
    livePresentation: PurificationLivePresentation(
      actionText:
          'Ziehe Wasser in die Nase und reinige sie mit der linken Hand.',
      attentionText: 'Beim Fasten das Wasser nicht tief einziehen.',
      sectionLabel: WuduGuideContent.sectionWashing,
      visualCategory: PurificationLiveVisualCategory.nose,
      visualDisplay: PurificationLiveVisualDisplay.full,
      visualSemanticLabel: 'Nase reinigen',
    ),
    whyImportantTitle: WuduGuideContent.sourcesLinkLabel,
    whyImportantBody: WuduGuideContent.sourcesIntroBody,
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'Abdestin Sünnetleri, Punkte 6–7',
        bookPage: '102',
        pdfPage: '102',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Sunnah of Wudu',
        bookPage: '50',
        pdfPage: '43',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
  );

  /// Schritt 7 — Gesicht waschen (`docs/wudu_steps/07_gesicht_waschen.md`).
  static const PurificationStepContent washFace = PurificationStepContent(
    id: 'wudu_wash_face',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 7,
    totalSteps: totalSteps,
    title: 'Gesicht waschen',
    introduction: 'Wasche dein gesamtes Gesicht vollständig mit Wasser.',
    category: PurificationStepCategory.fard,
    detailBody:
        'Wasche dein Gesicht vom Haaransatz bis unter das Kinn und seitlich von einem Ohrläppchen zum anderen. '
        'Achte darauf, dass auch die Bereiche an den Augenwinkeln erreicht werden. Das Innere der Augen muss nicht gewaschen werden. '
        'Das vollständige Waschen des Gesichts ist Fard. Einmaliges Waschen erfüllt die Pflicht; '
        'im vollständigen hanafitischen Ablauf wird das Gesicht dreimal gewaschen.',
    memoryAid:
        'Haaransatz bis Kinn, Ohrläppchen zu Ohrläppchen — nichts trocken lassen.',
    livePresentation: PurificationLivePresentation(
      actionText: 'Wasche dein gesamtes Gesicht vollständig mit Wasser.',
      attentionText:
          'Vom Haaransatz bis unter das Kinn, Ohrläppchen zu Ohrläppchen.',
      sectionLabel: WuduGuideContent.sectionWashing,
      visualCategory: PurificationLiveVisualCategory.face,
      visualDisplay: PurificationLiveVisualDisplay.full,
      visualSemanticLabel: 'Gesicht waschen',
    ),
    items: [
      PurificationCheckItem(
        title: 'Grenzen des Gesichts',
        body:
            'Vom Haaransatz bis unter das Kinn, seitlich von Ohrläppchen zu Ohrläppchen.',
      ),
      PurificationCheckItem(
        title: 'Augenwinkel',
        body:
            'Erreiche auch die Bereiche an den Augenwinkeln — nicht das Innere der Augen.',
      ),
    ],
    whyImportantTitle: WuduGuideContent.sourcesLinkLabel,
    whyImportantBody: WuduGuideContent.sourcesIntroBody,
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'Abdestin Farzları, Punkt 1',
        bookPage: '98',
        pdfPage: '98',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Fard of Wudu',
        bookPage: '45',
        pdfPage: '38',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
  );

  /// Schritt 8 — Arme waschen (`docs/wudu_steps/08_arme_waschen.md`).
  static const PurificationStepContent washArms = PurificationStepContent(
    id: 'wudu_wash_arms',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 8,
    totalSteps: totalSteps,
    title: 'Arme waschen',
    introduction:
        'Wasche beide Arme vollständig bis einschließlich der Ellenbogen.',
    category: PurificationStepCategory.fard,
    detailBody:
        'Wasche zuerst den rechten und danach den linken Arm – jeweils von den Fingern bis einschließlich der Ellenbogen. '
        'Achte darauf, dass das Wasser alle Seiten der Arme und auch die Ellenbogen vollständig erreicht. '
        'Das Waschen beider Arme einschließlich der Ellenbogen ist Fard. Einmaliges vollständiges Waschen erfüllt die Pflicht; '
        'im vollständigen hanafitischen Ablauf werden die Arme dreimal gewaschen.',
    memoryAid:
        'Rechts, dann links — Fingerspitzen bis Ellenbogen, alle Seiten.',
    livePresentation: PurificationLivePresentation(
      actionText:
          'Wasche beide Arme vollständig bis einschließlich der Ellenbogen.',
      attentionText:
          'Zuerst rechts, dann links — alle Seiten der Arme erreichen.',
      sectionLabel: WuduGuideContent.sectionWashing,
      visualCategory: PurificationLiveVisualCategory.arms,
      visualDisplay: PurificationLiveVisualDisplay.full,
      visualSemanticLabel: 'Arme waschen',
    ),
    items: [
      PurificationCheckItem(
        title: 'Rechter Arm zuerst',
        body:
            'Wasche den rechten Arm von den Fingern bis einschließlich des Ellenbogens.',
      ),
      PurificationCheckItem(
        title: 'Linker Arm danach',
        body:
            'Wasche den linken Arm vollständig — alle Seiten und die Ellenbogen müssen nass sein.',
      ),
    ],
    whyImportantTitle: WuduGuideContent.sourcesLinkLabel,
    whyImportantBody: WuduGuideContent.sourcesIntroBody,
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'Abdestin Farzları, Punkt 2',
        bookPage: '98',
        pdfPage: '98',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Fard of Wudu',
        bookPage: '45',
        pdfPage: '38',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
  );

  /// Schritt 9 — Kopf streichen (`docs/wudu_steps/09_kopf_streichen.md`).
  static const PurificationStepContent wipeHead = PurificationStepContent(
    id: 'wudu_wipe_head',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 9,
    totalSteps: totalSteps,
    title: 'Kopf streichen',
    introduction: 'Streiche einmal mit nassen Händen über deinen Kopf.',
    category: PurificationStepCategory.fard,
    detailBody:
        'Befeuchte deine Hände und streiche einmal über deinen Kopf. Mindestens ein Viertel des Kopfes muss dabei erreicht werden. '
        'Das Bestreichen von mindestens einem Viertel des Kopfes ist Fard. '
        'In der vollständigen hanafitischen Ausführung wird der gesamte Kopf einmal bestrichen.',
    memoryAid:
        'Mindestens ein Viertel des Kopfes — im vollständigen Ablauf der ganze Kopf.',
    livePresentation: PurificationLivePresentation(
      actionText: 'Streiche einmal mit nassen Händen über deinen Kopf.',
      attentionText:
          'Mindestens ein Viertel des Kopfes muss dabei erreicht werden.',
      sectionLabel: WuduGuideContent.sectionWashing,
      visualCategory: PurificationLiveVisualCategory.head,
      visualDisplay: PurificationLiveVisualDisplay.full,
      visualSemanticLabel: 'Kopf streichen',
    ),
    items: [
      PurificationCheckItem(
        title: 'Hände befeuchten',
        body:
            'Nimm frisches Wasser auf die Hände, bevor du den Kopf streichst.',
      ),
      PurificationCheckItem(
        title: 'Kopf erreichen',
        body:
            'Streiche einmal über den Kopf — mindestens ein Viertel, im vollständigen Ablauf den ganzen Kopf.',
      ),
    ],
    whyImportantTitle: WuduGuideContent.sourcesLinkLabel,
    whyImportantBody: WuduGuideContent.sourcesIntroBody,
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'Abdestin Farzları, Punkt 3',
        bookPage: '98',
        pdfPage: '98',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Fard of Wudu',
        bookPage: '46',
        pdfPage: '39',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
  );

  /// Schritt 10 — Ohren streichen (`docs/wudu_steps/10_ohren_streichen.md`).
  static const PurificationStepContent wipeEars = PurificationStepContent(
    id: 'wudu_wipe_ears',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 10,
    totalSteps: totalSteps,
    title: 'Ohren streichen',
    introduction:
        'Streiche einmal über die Innen- und Außenseite deiner Ohren.',
    category: PurificationStepCategory.sunnah,
    detailBody:
        'Streiche mit den Zeigefingern über die Innenseite der Ohren und mit den Daumen über die Außenseite. '
        'Verwende dafür die Feuchtigkeit, die nach dem Kopfstreichen noch an deinen Händen ist. '
        'Sind deine Hände bereits trocken, befeuchte sie erneut. Das Streichen der Ohren gehört im hanafitischen Wudu zur Sunnah.',
    memoryAid:
        'Zeigefinger innen, Daumen außen — Feuchtigkeit vom Kopfstreichen nutzen.',
    livePresentation: PurificationLivePresentation(
      actionText:
          'Streiche einmal über die Innen- und Außenseite deiner Ohren.',
      attentionText:
          'Zeigefinger innen, Daumen außen — Feuchtigkeit vom Kopfstreichen.',
      sectionLabel: WuduGuideContent.sectionWashing,
      visualCategory: PurificationLiveVisualCategory.ears,
      visualDisplay: PurificationLiveVisualDisplay.full,
      visualSemanticLabel: 'Ohren streichen',
    ),
    items: [
      PurificationCheckItem(
        title: 'Innenseite',
        body: 'Streiche mit den Zeigefingern über die Innenseite der Ohren.',
      ),
      PurificationCheckItem(
        title: 'Außenseite',
        body: 'Streiche mit den Daumen über die Außenseite der Ohren.',
      ),
    ],
    whyImportantTitle: WuduGuideContent.sourcesLinkLabel,
    whyImportantBody: WuduGuideContent.sourcesIntroBody,
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'Abdestin Sünnetleri, Punkt 15',
        bookPage: '103',
        pdfPage: '103',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Sunnah of Wudu',
        bookPage: '51',
        pdfPage: '44',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
  );

  /// Schritt 11 — Füße waschen (`docs/wudu_steps/11_fuesse_waschen.md`).
  static const PurificationStepContent washFeet = PurificationStepContent(
    id: 'wudu_wash_feet',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 11,
    totalSteps: totalSteps,
    title: 'Füße waschen',
    introduction:
        'Wasche beide Füße vollständig bis einschließlich der Knöchel.',
    category: PurificationStepCategory.fard,
    detailBody:
        'Wasche zuerst den rechten und danach den linken Fuß – jeweils vollständig bis einschließlich der Knöchel. '
        'Achte besonders auf die Fersen, Fußsohlen und die Zwischenräume der Zehen, damit keine Stelle trocken bleibt. '
        'Das Waschen beider Füße einschließlich der Knöchel ist Fard. Einmaliges vollständiges Waschen erfüllt die Pflicht; '
        'im vollständigen hanafitischen Ablauf werden die Füße dreimal gewaschen.',
    memoryAid:
        'Rechts, dann links — Fersen, Sohlen und Zehenzwischenräume nicht vergessen.',
    livePresentation: PurificationLivePresentation(
      actionText:
          'Wasche beide Füße vollständig bis einschließlich der Knöchel.',
      attentionText: 'Fersen, Sohlen und Zehenzwischenräume nicht auslassen.',
      sectionLabel: WuduGuideContent.sectionWashing,
      visualCategory: PurificationLiveVisualCategory.feet,
      visualDisplay: PurificationLiveVisualDisplay.full,
      visualSemanticLabel: 'Füße waschen',
    ),
    items: [
      PurificationCheckItem(
        title: 'Rechter Fuß zuerst',
        body:
            'Wasche den rechten Fuß vollständig bis einschließlich der Knöchel.',
      ),
      PurificationCheckItem(
        title: 'Linker Fuß danach',
        body:
            'Wasche den linken Fuß — besonders Fersen, Sohlen und Zehenzwischenräume.',
      ),
    ],
    whyImportantTitle: WuduGuideContent.sourcesLinkLabel,
    whyImportantBody: WuduGuideContent.sourcesIntroBody,
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'Abdestin Farzları, Punkt 4',
        bookPage: '99',
        pdfPage: '99',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Fard of Wudu',
        bookPage: '45',
        pdfPage: '38',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
  );

  /// Schritt 12 — Dua nach dem Wudu (`docs/wudu_steps/12_dua_nach_wudu.md`).
  static const PurificationStepContent duaAfter = PurificationStepContent(
    id: 'wudu_dua_after',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 12,
    totalSteps: totalSteps,
    title: 'Dua nach dem Wudu',
    introduction:
        'Sprich nach dem Wudu die Schahāda und eine überlieferte Dua.',
    category: PurificationStepCategory.adab,
    detailBody:
        'Nach dem vollständigen Wudu kannst du die Schahāda sprechen und Allah darum bitten, '
        'dich zu den Reumütigen und zu den sich Reinigenden gehören zu lassen. '
        'Diese Worte gehören zur empfohlenen Ausführung nach dem Wudu. '
        'Sie sind keine Voraussetzung für die äußere Waschung selbst.',
    memoryAid:
        'Wudu beendet — Schahāda sprechen und Allah um Reue und Reinigung bitten.',
    items: [
      PurificationCheckItem(
        title: 'Schahāda',
        body:
            'أَشْهَدُ أَنْ لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ\n\n'
            'Ich bezeuge, dass es keine anbetungswürdige Gottheit außer Allah gibt, allein und ohne Teilhaber. '
            'Und ich bezeuge, dass Muhammad Sein Diener und Gesandter ist.',
      ),
      PurificationCheckItem(
        title: 'Dua',
        body:
            'اللَّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ وَاجْعَلْنِي مِنَ الْمُتَطَهِّرِينَ\n\n'
            'O Allah, lass mich zu den Reumütigen und zu den sich Reinigenden gehören.',
      ),
    ],
    hint:
        'Hadith-Wortlaut und Referenzen sind noch in Primärprüfung. Es werden keine Hadithnummern angezeigt. '
        'Audioausgabe ist für eine spätere Version vorgesehen.',
    livePresentation: PurificationLivePresentation(
      actionText:
          'Sprich nach dem Wudu die Schahāda und eine überlieferte Dua.',
      attentionText:
          'Empfohlene Ausführung — keine Voraussetzung für die Waschung.',
      sectionLabel: WuduGuideContent.sectionCompletion,
      visualCategory: PurificationLiveVisualCategory.completion,
      visualDisplay: PurificationLiveVisualDisplay.compact,
      visualSemanticLabel: 'Dua nach dem Wudu',
    ),
    whyImportantTitle: WuduGuideContent.sourcesLinkLabel,
    whyImportantBody: WuduGuideContent.sourcesIntroBody,
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'Abdestin Adabı / Abdest Duaları',
        bookPage: '104–107',
        pdfPage: '104–107',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Adab after Wudu',
        note: 'Genaue Buchseite vor Veröffentlichung ergänzen',
      ),
      ReligiousSourceReference(
        work: 'Hadith-Primärquellen',
        section: 'Schahāda und Dua nach Wudu',
        note: 'Referenz und Wortlaut in Prüfung — keine Nummern in der App',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
  );

  /// Schritt 13 — Abschluss (`docs/wudu_steps/13_zusammenfassung.md`, neutral formuliert).
  static const PurificationStepContent summary = PurificationStepContent(
    id: 'wudu_summary',
    guideId: PurificationGuideIds.wudu,
    stepNumber: 13,
    totalSteps: totalSteps,
    title: 'Gebetswaschung abgeschlossen',
    introduction: 'Du hast alle Schritte des Wudu-Begleiters durchlaufen.',
    category: PurificationStepCategory.completion,
    livePresentation: PurificationLivePresentation(
      actionText: 'Du hast alle Schritte des Wudu-Begleiters durchlaufen.',
      sectionLabel: WuduGuideContent.sectionCompletion,
      visualCategory: PurificationLiveVisualCategory.completion,
      visualDisplay: PurificationLiveVisualDisplay.compact,
      visualSemanticLabel: 'Gebetswaschung abgeschlossen',
      primaryActionLabel: WuduGuideContent.completionPrimaryAction,
    ),
    items: [],
    whyImportantTitle: WuduGuideContent.sourcesLinkLabel,
    whyImportantBody: WuduGuideContent.sourcesIntroBody,
    sources: [
      ReligiousSourceReference(
        work: 'Diyanet, İslam İlmihali',
        section: 'V. Abdest (Gesamtüberblick)',
        bookPage: '96–114',
        pdfPage: '96–114',
      ),
      ReligiousSourceReference(
        work: 'Nūr al-Īḍāḥ, Book I – Purification',
        section: 'Wudu overview',
        bookPage: '45–54',
        pdfPage: '38–47',
      ),
    ],
    reviewStatus: _metaReview,
    sourceStatus: _metaSource,
    releaseStatus: _metaRelease,
    contentVersion: _metaVersion,
    isCompletionStep: true,
    primaryActionLabel: WuduGuideContent.completionPrimaryAction,
    secondaryActionLabel: WuduGuideContent.completionSecondaryAction,
  );

  static const List<PurificationStepContent> allSteps = [
    preparation,
    intention,
    basmala,
    washHands,
    rinseMouth,
    cleanNose,
    washFace,
    washArms,
    wipeHead,
    wipeEars,
    washFeet,
    duaAfter,
    summary,
  ];

  static PurificationStepContent? byStepNumber(int stepNumber) {
    if (stepNumber < 1 || stepNumber > allSteps.length) {
      return null;
    }
    return allSteps[stepNumber - 1];
  }
}
