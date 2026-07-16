/**
 * LOCAL CLI ONLY — Qualitätsprüfung der aktuellen produktiven Verserklärung.
 *
 * Nutzt dieselbe Context-/Tafsir-/Policy-/OpenAI-Logik wie die API,
 * ohne Nutzer-, Limit-, Analytics- oder Datenbank-Schreibpfade.
 */

import { access, constants, mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import {
  CURRENT_EXPLANATION_EVAL_VERSES,
  parseExplainSections,
  resolveEvalVersesFromOnly,
  type CurrentExplanationEvalVerse,
} from "./currentExplanationEvalSet.js";
import {
  buildEvalReport,
  buildMarkdownReport,
  buildVerseReportBase,
  type CurrentExplanationEvalReport,
  type CurrentExplanationVerseReport,
} from "./currentExplanationEvalReport.js";

export type EvaluateCurrentExplanationsCliArgs = {
  json: boolean;
  output: string | null;
  markdown: string | null;
  overwrite: boolean;
  only: string | null;
  model: string | null;
};

export type ParseCliArgsResult =
  | { ok: true; value: EvaluateCurrentExplanationsCliArgs }
  | { ok: false; message: string };

export function parseEvaluateCurrentExplanationsArgs(
  argv: readonly string[]
): ParseCliArgsResult {
  let json = false;
  let output: string | null = null;
  let markdown: string | null = null;
  let overwrite = false;
  let only: string | null = null;
  let model: string | null = null;

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    if (arg === "--json") {
      json = true;
      continue;
    }

    if (arg === "--overwrite") {
      overwrite = true;
      continue;
    }

    if (arg === "--output") {
      const value = argv[index + 1];
      if (value === undefined || value.startsWith("--")) {
        return {
          ok: false,
          message: "--output benötigt einen Dateipfad.",
        };
      }
      output = value;
      index += 1;
      continue;
    }

    if (arg === "--markdown") {
      const value = argv[index + 1];
      if (value === undefined || value.startsWith("--")) {
        return {
          ok: false,
          message: "--markdown benötigt einen Dateipfad.",
        };
      }
      markdown = value;
      index += 1;
      continue;
    }

    if (arg === "--only") {
      const value = argv[index + 1];
      if (value === undefined || value.startsWith("--")) {
        return {
          ok: false,
          message: "--only benötigt Verse-Keys (z. B. 2:255,4:34).",
        };
      }
      only = value;
      index += 1;
      continue;
    }

    if (arg === "--model") {
      const value = argv[index + 1];
      if (value === undefined || value.startsWith("--")) {
        return {
          ok: false,
          message: "--model benötigt einen Modellnamen.",
        };
      }
      model = value.trim();
      if (model === "") {
        return { ok: false, message: "--model darf nicht leer sein." };
      }
      index += 1;
      continue;
    }

    return { ok: false, message: `Unbekanntes Argument: ${arg}` };
  }

  return {
    ok: true,
    value: { json, output, markdown, overwrite, only, model },
  };
}

export function assertNotProductionEnv(
  nodeEnv: string | undefined
): { ok: true } | { ok: false; message: string } {
  if (nodeEnv === "production") {
    return {
      ok: false,
      message:
        "explain:evaluate ist nur für lokale Qualitätsprüfung und darf unter NODE_ENV=production nicht laufen.",
    };
  }
  return { ok: true };
}

export function assertOpenAiApiKeyPresent(
  apiKey: string | undefined
): { ok: true } | { ok: false; message: string } {
  if (!apiKey?.trim()) {
    return {
      ok: false,
      message:
        "OPENAI_API_KEY fehlt. Bitte lokal setzen (Wert wird nicht ausgegeben).",
    };
  }
  return { ok: true };
}

/**
 * DATABASE_URL wird vom produktiven Env-Modul verlangt, aber vom Eval-Tool
 * fachlich nicht genutzt. Setzt nur einen Platzhalter, wenn die Variable fehlt.
 */
export function ensureUnusedDatabaseUrlForEval(): void {
  if (!process.env.DATABASE_URL?.trim()) {
    process.env.DATABASE_URL =
      "postgresql://eval:eval@127.0.0.1:5432/ihdina_explain_eval_unused";
  }
}

export async function assertOutputPathWritable(
  path: string,
  overwrite: boolean
): Promise<{ ok: true } | { ok: false; message: string }> {
  const absolute = resolve(path);
  try {
    await access(absolute, constants.F_OK);
    if (!overwrite) {
      return {
        ok: false,
        message: `Datei existiert bereits (ohne --overwrite): ${absolute}`,
      };
    }
  } catch {
    // Datei fehlt — ok
  }
  return { ok: true };
}

async function writeReportFile(
  path: string,
  content: string,
  overwrite: boolean
): Promise<void> {
  const absolute = resolve(path);
  const check = await assertOutputPathWritable(absolute, overwrite);
  if (!check.ok) {
    throw new Error(check.message);
  }
  await mkdir(dirname(absolute), { recursive: true });
  await writeFile(absolute, content, "utf8");
}

function formatErrorReason(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  return String(error);
}

export async function evaluateCurrentExplanationsForVerses(params: {
  verses: readonly CurrentExplanationEvalVerse[];
  modelOverride: string | null;
  onProgress?: (message: string) => void;
}): Promise<CurrentExplanationEvalReport> {
  const { completeVerifiedVerseExplanation } = await import(
    "../services/explain.service.js"
  );
  const { getVerifiedQuranAyah } = await import(
    "../services/quranContext.service.js"
  );
  const { getTafsirForAyah } = await import(
    "../services/tafsirContext.service.js"
  );

  const verseReports: CurrentExplanationVerseReport[] = [];

  for (let index = 0; index < params.verses.length; index += 1) {
    const verse = params.verses[index]!;
    params.onProgress?.(
      `[${index + 1}/${params.verses.length}] ${verse.verseKey} …`
    );

    const ayah = getVerifiedQuranAyah(verse.surahName, verse.ayahNumber);
    const tafsir = getTafsirForAyah(verse.surahName, verse.ayahNumber);
    const rassoulText = tafsir.tafsir.trim();
    const base = buildVerseReportBase(verse, {
      textDe: ayah.textDe,
      rassoulSourcePresent: rassoulText.length > 0,
      rassoulTextLength: rassoulText.length,
    });

    try {
      const completion = await completeVerifiedVerseExplanation({
        surahName: verse.surahName,
        ayahNumber: verse.ayahNumber,
      });
      const sections = parseExplainSections(completion.text);

      verseReports.push({
        ...base,
        bedeutung: sections.bedeutung,
        kontext: sections.kontext,
        heute: sections.heute,
        model: completion.model,
        promptTokens: completion.promptTokens,
        completionTokens: completion.completionTokens,
        totalTokens: completion.totalTokens,
        latencyMs: completion.latencyMs,
        status: "ok",
        errorReason: null,
      });
    } catch (error) {
      verseReports.push({
        ...base,
        bedeutung: "",
        kontext: "",
        heute: "",
        model: null,
        promptTokens: null,
        completionTokens: null,
        totalTokens: null,
        latencyMs: null,
        status: "error",
        errorReason: formatErrorReason(error),
      });
    }
  }

  return buildEvalReport({
    modelOverride: params.modelOverride,
    verses: verseReports,
  });
}

function printCompactSummary(report: CurrentExplanationEvalReport): void {
  console.log("");
  console.log("=== Zusammenfassung ===");
  console.log(`Verse: ${report.verseCount}`);
  console.log(`OK: ${report.okCount}`);
  console.log(`Fehler: ${report.errorCount}`);
  for (const verse of report.verses) {
    const marker = verse.status === "ok" ? "ok" : "ERR";
    console.log(
      `  [${marker}] ${verse.verseKey}  model=${verse.model ?? "—"}  latency=${verse.latencyMs ?? "—"}ms`
    );
  }
}

export async function runEvaluateCurrentExplanationsCli(
  argv: readonly string[]
): Promise<number> {
  const productionGuard = assertNotProductionEnv(process.env.NODE_ENV);
  if (!productionGuard.ok) {
    console.error(productionGuard.message);
    return 1;
  }

  const parsed = parseEvaluateCurrentExplanationsArgs(argv);
  if (!parsed.ok) {
    console.error(parsed.message);
    return 1;
  }

  const args = parsed.value;
  const selected = resolveEvalVersesFromOnly(args.only);
  if (!selected.ok) {
    console.error(selected.message);
    return 1;
  }

  // dotenv laden, bevor produktive Env-Module importiert werden
  const { config: loadEnv } = await import("dotenv");
  loadEnv();

  if (args.model) {
    // Nur die erste Verserklärung überschreiben — Follow-ups bleiben bei OPENAI_MODEL.
    process.env.OPENAI_EXPLANATION_MODEL = args.model;
  }

  ensureUnusedDatabaseUrlForEval();

  const keyCheck = assertOpenAiApiKeyPresent(process.env.OPENAI_API_KEY);
  if (!keyCheck.ok) {
    console.error(keyCheck.message);
    return 1;
  }

  if (args.output) {
    const check = await assertOutputPathWritable(args.output, args.overwrite);
    if (!check.ok) {
      console.error(check.message);
      return 1;
    }
  }
  if (args.markdown) {
    const check = await assertOutputPathWritable(args.markdown, args.overwrite);
    if (!check.ok) {
      console.error(check.message);
      return 1;
    }
  }

  console.log(
    `Lokale Erklärungsevaluation: ${selected.verses.length} Verse (von ${CURRENT_EXPLANATION_EVAL_VERSES.length} im festen Set).`
  );

  const report = await evaluateCurrentExplanationsForVerses({
    verses: selected.verses,
    modelOverride: args.model,
    onProgress: (message) => console.log(message),
  });

  if (args.json) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    printCompactSummary(report);
  }

  if (args.output) {
    await writeReportFile(
      args.output,
      `${JSON.stringify(report, null, 2)}\n`,
      args.overwrite
    );
    console.log(`JSON-Bericht: ${resolve(args.output)}`);
  }

  if (args.markdown) {
    await writeReportFile(
      args.markdown,
      buildMarkdownReport(report),
      args.overwrite
    );
    console.log(`Markdown-Bericht: ${resolve(args.markdown)}`);
  }

  return report.errorCount > 0 ? 1 : 0;
}

const isDirectRun =
  process.argv[1] !== undefined &&
  (process.argv[1].endsWith("evaluateCurrentExplanations.ts") ||
    process.argv[1].endsWith("evaluateCurrentExplanations.js"));

if (isDirectRun) {
  runEvaluateCurrentExplanationsCli(process.argv.slice(2))
    .then((code) => {
      process.exitCode = code;
    })
    .catch((error: unknown) => {
      console.error(
        error instanceof Error ? error.message : "Unbekannter Fehler."
      );
      process.exitCode = 1;
    });
}
