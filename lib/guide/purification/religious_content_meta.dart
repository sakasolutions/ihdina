/// Fachliche Prüflage eines religiösen Inhalts.
enum ReligiousReviewStatus {
  pendingScholarReview,
  approved,
  rejected,
}

/// Quellenlage (technische Vorbereitung, keine Endfreigabe).
enum ReligiousSourceStatus {
  sourcePrepared,
  doubleConfirmed,
  unclear,
}

/// Veröffentlichungsstatus in der App.
enum ReligiousReleaseStatus {
  developmentOnly,
  approvedForRelease,
}

/// Klassifikation eines Lernschritts (Anzeige-Badge, optional).
enum PurificationStepCategory {
  prerequisite,
  fard,
  sunnah,
  adab,
  completion,
  specialCase,
}

/// Route-Name der Wudu-Übersicht (Navigation zurück aus dem Schrittguide).
const String kWuduOverviewRouteName = '/wudu/overview';

/// Aktuelle Content-Version aller Tahara-Entwürfe.
const String kTaharaContentVersion = 'tahara-draft-1';
