import {
  createEmptyExplanationReview,
  type CurrentExplanationEvalVerse,
  type CurrentExplanationReviewFields,
} from "./currentExplanationEvalSet.js";

export type CurrentExplanationVerseReport = {
  verseKey: string;
  surahName: string;
  ayahNumber: number;
  textDe: string;
  rassoulSourcePresent: boolean;
  rassoulTextLength: number;
  bedeutung: string;
  kontext: string;
  heute: string;
  model: string | null;
  promptTokens: number | null;
  completionTokens: number | null;
  totalTokens: number | null;
  latencyMs: number | null;
  status: "ok" | "error";
  errorReason: string | null;
  review: CurrentExplanationReviewFields;
};

export type CurrentExplanationEvalReport = {
  generatedAt: string;
  tool: "explain:evaluate";
  modelOverride: string | null;
  verseCount: number;
  okCount: number;
  errorCount: number;
  verses: CurrentExplanationVerseReport[];
};

export function buildVerseReportBase(
  verse: CurrentExplanationEvalVerse,
  meta: {
    textDe: string;
    rassoulSourcePresent: boolean;
    rassoulTextLength: number;
  }
): Pick<
  CurrentExplanationVerseReport,
  | "verseKey"
  | "surahName"
  | "ayahNumber"
  | "textDe"
  | "rassoulSourcePresent"
  | "rassoulTextLength"
  | "review"
> {
  return {
    verseKey: verse.verseKey,
    surahName: verse.surahName,
    ayahNumber: verse.ayahNumber,
    textDe: meta.textDe,
    rassoulSourcePresent: meta.rassoulSourcePresent,
    rassoulTextLength: meta.rassoulTextLength,
    review: createEmptyExplanationReview(),
  };
}

export function buildEvalReport(params: {
  modelOverride: string | null;
  verses: CurrentExplanationVerseReport[];
}): CurrentExplanationEvalReport {
  const okCount = params.verses.filter((v) => v.status === "ok").length;
  return {
    generatedAt: new Date().toISOString(),
    tool: "explain:evaluate",
    modelOverride: params.modelOverride,
    verseCount: params.verses.length,
    okCount,
    errorCount: params.verses.length - okCount,
    verses: params.verses,
  };
}

export function reportContainsFullTafsirDump(
  report: CurrentExplanationEvalReport
): boolean {
  const json = JSON.stringify(report);
  // Berichtsstruktur speichert bewusst keinen Tafsir-Volltext.
  if (/"tafsir"\s*:/.test(json)) return true;
  if (/"rassoulText"\s*:/.test(json)) return true;
  if (/"trustedContext"\s*:/.test(json)) return true;
  return false;
}

export function buildMarkdownReport(
  report: CurrentExplanationEvalReport
): string {
  const lines: string[] = [
    "# Qualitätsprüfung: aktuelle Verserklärung",
    "",
    `Erzeugt: ${report.generatedAt}`,
    `Verse: ${report.verseCount} (ok: ${report.okCount}, Fehler: ${report.errorCount})`,
    report.modelOverride
      ? `Modell-Override: ${report.modelOverride}`
      : "Modell-Override: keiner",
    "",
    "Hinweis: Rassoul-Volltexte sind nicht enthalten. Menschliche Prüfung anhand der Rubrik.",
    "",
  ];

  for (const verse of report.verses) {
    lines.push(`## Sure ${verse.surahName}, Vers ${verse.ayahNumber}`);
    lines.push("");
    lines.push(`Verse-Key: ${verse.verseKey}`);
    lines.push(
      `Rassoul-Quelle: ${verse.rassoulSourcePresent ? "ja" : "nein"} (Länge: ${verse.rassoulTextLength})`
    );
    lines.push(`Status: ${verse.status}`);
    if (verse.errorReason) {
      lines.push(`Fehlergrund: ${verse.errorReason}`);
    }
    lines.push(`Modell: ${verse.model ?? "—"}`);
    lines.push(
      `Tokens: prompt=${verse.promptTokens ?? "—"}, completion=${verse.completionTokens ?? "—"}, total=${verse.totalTokens ?? "—"}`
    );
    lines.push(`Latenz: ${verse.latencyMs ?? "—"} ms`);
    lines.push("");
    lines.push("### Vers");
    lines.push("");
    lines.push(verse.textDe || "—");
    lines.push("");
    lines.push("### Bedeutung");
    lines.push("");
    lines.push(verse.bedeutung || "—");
    lines.push("");
    lines.push("### Kontext");
    lines.push("");
    lines.push(verse.kontext || "—");
    lines.push("");
    lines.push("### Heute");
    lines.push("");
    lines.push(verse.heute || "—");
    lines.push("");
    lines.push("### Prüfung");
    lines.push("");
    lines.push("Bedeutung quellentreu: ☐");
    lines.push("Kontext belegt: ☐");
    lines.push("Heute gläubig und lebendig: ☐");
    lines.push("Heute hilfreich: ☐");
    lines.push("Unbelegtes persönliches Versprechen: ☐");
    lines.push("Versteckte Rechts-/Fatwa-Aussage: ☐");
    lines.push("Notizen:");
    lines.push("");
    lines.push("---");
    lines.push("");
  }

  return lines.join("\n");
}
