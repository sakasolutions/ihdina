export type QuestionMode =
  | "normalVerse"
  | "context"
  | "wordOrImage"
  | "fiqhOrPersonalCase"
  | "safety"
  | "medicalOrMentalHealth"
  | "aqidaOrControversy"
  | "sourceOrHadith"
  | "tafsirOrSource"
  | "adversarialOrProvocation";

export type QuestionRoute = {
  /**
   * Der wichtigste Modus nach Sicherheits-Priorität.
   * Später bestimmt er die primäre Antwortstrategie.
   */
  primaryMode: QuestionMode;

  /**
   * Mehrere Modi sind möglich:
   * „Darf ich mit Diabetes fasten?“
   * → medicalOrMentalHealth + fiqhOrPersonalCase
   */
  matchedModes: QuestionMode[];

  /**
   * Nur für Logging, Tests und spätere Debug-Auswertung.
   * Keine Nutzerdatenbank, keine Speicherung in diesem Service.
   */
  matchedSignals: string[];
};

type QuestionRule = {
  mode: Exclude<QuestionMode, "normalVerse">;
  signal: string;
  patterns: readonly RegExp[];
};

/**
 * Reihenfolge ist bewusst sicherheitsorientiert.
 *
 * Ein Satz wie „Darf ich meinen Mann schlagen?“ darf niemals zuerst
 * als Fiqh- oder Quellenfrage behandelt werden, sondern als Safety-Fall.
 */
const MODE_PRIORITY: readonly QuestionMode[] = [
  "safety",
  "medicalOrMentalHealth",
  "fiqhOrPersonalCase",
  "adversarialOrProvocation",
  "sourceOrHadith",
  "tafsirOrSource",
  "aqidaOrControversy",
  "context",
  "wordOrImage",
  "normalVerse",
];

const QUESTION_RULES: readonly QuestionRule[] = [
  {
    mode: "safety",
    signal: "safety",
    patterns: [
      /\b(gewalt|schlag(?:en|e|t|st)?|schläg(?:t|st)|geschlagen|prügel(?:n|t|st)?|hauen|verletz(?:en|t|e|st)?|misshandel(?:n|t)?|bedroh(?:en|t)?|droh(?:en|t)?|erpress(?:en|t)?|zwing(?:en|t)?|kontrollier(?:en|t)?|missbrauch|vergewaltig(?:en|t)?)\b/i,
      /\b(selbstmord|suizid|selbstverletz(?:en|ung)?|mich umbring(?:en)?|will nicht mehr leben|jemanden töt(?:en|en)|umbring(?:en)?)\b/i,
      /\b(angst vor meinem mann|angst vor meiner frau|angst vor meinem partner|ich bin nicht sicher|ich fühle mich nicht sicher)\b/i,
    ],
  },
  {
    mode: "medicalOrMentalHealth",
    signal: "medical_or_mental_health",
    patterns: [
      /\b(depression|depressiv|panik|panikattacke|angststörung|burnout|trauma|therapie|psycholog(?:e|in|isch)?|psychiatr(?:ie|isch)?|medikament(?:e)?|arzt|ärztin)\b/i,
      /\b(diabetes|schwanger|schwangerschaft|krankheit|chronisch krank|erschöpf(?:t|ung)|psychisch|mentale gesundheit)\b/i,
    ],
  },
  {
    mode: "fiqhOrPersonalCase",
    signal: "fiqh_or_personal_case",
    patterns: [
      /\b(halal|haram|erlaubt|verboten|pflicht|verpflichtet|fatwa)\b/i,
      /\b(darf ich|ist es erlaubt|ist das erlaubt|ist das verboten)\b/i,
      /\b(wudu|wudū|waschung|tayammum|gebet verpasst|salah verpasst|salat verpasst|fasten|ramadan|zakat|riba|zinsen|kredit|erbe|scheidung|talaq|heirat|ehevertrag)\b/i,
    ],
  },
  {
    mode: "adversarialOrProvocation",
    signal: "adversarial_or_provocation",
    patterns: [
      /\b(wie zerstöre ich|wie zerlege ich|wie mache ich .* lächerlich|wie demütige ich|wie gewinne ich die debatte|wie kann ich .* widerlegen)\b/i,
      /\b(schlagfertige argumente gegen|munition gegen|beleidige|hetze gegen|hass gegen)\b/i,
      /\b(wie zwinge ich .* zum islam|wie überrede ich .* zu konvertieren|wie bekehre ich .* gegen seinen willen)\b/i,
    ],
  },
  {
    mode: "sourceOrHadith",
    signal: "source_or_hadith",
    patterns: [
      /\b(hadith|hadīs|sunnah|überlieferung|sahih|hasan|authentisch)\b/i,
      /\b(ibn kathir|ibn ka(?:t|ṭ)hir|gelehrte|imam|zitat)\b/i,
    ],
  },
  {
    mode: "tafsirOrSource",
    signal: "tafsir_or_source",
    patterns: [
      /\b(tafsir|tafsīr|koran(?:kommentar| kommentar)|kommentar zum vers)\b/i,
      /\b(quelle|quellen|beleg|belege|woher stammt|woher kommt die erklärung)\b/i,
      /\b(rassoul|ibn rassoul|angebunden(?:e|er|en)? tafsir)\b/i,
    ],
  },
  {
    mode: "aqidaOrControversy",
    signal: "aqida_or_controversy",
    patterns: [
      /\b(allah sehen|paradies|hölle|jenseits|trinität|jesus|isa|göttlich|gottheit)\b/i,
      /\b(vorbestimmung|qadar|schicksal|freier wille|warum hat allah|existiert allah)\b/i,
      /\b(kritik am islam|widerspruch|unterdrück(?:t|ung)|diskriminier(?:t|ung)|frauenrechte)\b/i,
    ],
  },
  {
    mode: "context",
    signal: "context",
    patterns: [
      /\b(kontext|zusammenhang|davor|danach|vorherige verse|nächste verse|passage)\b/i,
      /\b(an wen richtet sich|zu wem spricht|warum wurde .* offenbart|offenbarungsanlass|asbab|asbāb)\b/i,
    ],
  },
  {
    mode: "wordOrImage",
    signal: "word_or_image",
    patterns: [
      /\b(schlüsselbegriff|schlüsselbegriffe|wort bedeutet|begriff bedeutet|arabische wort|arabisch bedeutet)\b/i,
      /\b(gleichnis|bildsprache|metapher|sprachlich|formulierung|warum steht dort)\b/i,
    ],
  },
];

function normalizeQuestion(rawQuestion: string): string {
  return rawQuestion.replace(/\s+/g, " ").trim();
}

function ruleMatches(rule: QuestionRule, question: string): boolean {
  return rule.patterns.some((pattern) => pattern.test(question));
}

/**
 * Klassifiziert nur die Art der Frage.
 *
 * Der Router erzeugt bewusst noch keine religiöse oder persönliche Antwort.
 * Die Antwortregeln, Prompts und der sichere Verskontext werden erst im
 * nächsten Schritt an die jeweiligen Modi gekoppelt.
 */
export function routeQuestion(rawQuestion: string): QuestionRoute {
  const question = normalizeQuestion(rawQuestion);

  if (!question) {
    return {
      primaryMode: "normalVerse",
      matchedModes: ["normalVerse"],
      matchedSignals: [],
    };
  }

  const matchedModeSet = new Set<QuestionMode>();
  const matchedSignals: string[] = [];

  for (const rule of QUESTION_RULES) {
    if (!ruleMatches(rule, question)) continue;

    matchedModeSet.add(rule.mode);
    matchedSignals.push(rule.signal);
  }

  const matchedModes = MODE_PRIORITY.filter((mode) => matchedModeSet.has(mode));

  if (matchedModes.length === 0) {
    return {
      primaryMode: "normalVerse",
      matchedModes: ["normalVerse"],
      matchedSignals: [],
    };
  }

  return {
    primaryMode: matchedModes[0]!,
    matchedModes,
    matchedSignals,
  };
}
