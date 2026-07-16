import assert from "node:assert/strict";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, it } from "node:test";
import {
  CURRENT_EXPLANATION_EVAL_VERSES,
  createEmptyExplanationReview,
  parseExplainSections,
  resolveEvalVersesFromOnly,
  verseKeySet,
} from "./currentExplanationEvalSet.js";
import {
  buildEvalReport,
  buildMarkdownReport,
  buildVerseReportBase,
  reportContainsFullTafsirDump,
  type CurrentExplanationVerseReport,
} from "./currentExplanationEvalReport.js";
import {
  assertNotProductionEnv,
  assertOpenAiApiKeyPresent,
  assertOutputPathWritable,
  parseEvaluateCurrentExplanationsArgs,
} from "./evaluateCurrentExplanations.js";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

describe("currentExplanationEvalSet", () => {
  it("festes Testset enthält exakt 20 eindeutige Verse", () => {
    assert.equal(CURRENT_EXPLANATION_EVAL_VERSES.length, 20);
    const keys = CURRENT_EXPLANATION_EVAL_VERSES.map((v) => v.verseKey);
    assert.equal(new Set(keys).size, 20);
    assert.deepEqual(keys, [
      "1:1",
      "1:5",
      "2:153",
      "2:186",
      "2:255",
      "2:256",
      "2:286",
      "3:159",
      "3:173",
      "4:34",
      "5:51",
      "9:5",
      "13:28",
      "16:90",
      "24:31",
      "29:69",
      "39:53",
      "49:13",
      "57:20",
      "94:6",
    ]);
  });

  it("--only akzeptiert nur Verse aus diesem Set", () => {
    const result = resolveEvalVersesFromOnly("2:255,4:34");
    assert.equal(result.ok, true);
    if (!result.ok) return;
    assert.deepEqual(
      result.verses.map((v) => v.verseKey),
      ["2:255", "4:34"]
    );
    assert.ok(verseKeySet().has("2:255"));
  });

  it("unbekannter Vers bei --only wird abgelehnt", () => {
    const result = resolveEvalVersesFromOnly("2:255,99:1");
    assert.equal(result.ok, false);
    if (result.ok) return;
    assert.match(result.message, /Unbekannter Verse-Key/);
  });
});

describe("currentExplanationEvalReport", () => {
  it("JSON-Bericht enthält alle drei Antwortbereiche und leere Review-Felder", () => {
    const verse = CURRENT_EXPLANATION_EVAL_VERSES[4]!;
    const base = buildVerseReportBase(verse, {
      textDe: "Allah — es gibt keinen Gott außer Ihm…",
      rassoulSourcePresent: true,
      rassoulTextLength: 1200,
    });
    const entry: CurrentExplanationVerseReport = {
      ...base,
      bedeutung: "Bedeutungstext",
      kontext: "Kontexttext",
      heute: "Heutetext",
      model: "gpt-4o-mini",
      promptTokens: 10,
      completionTokens: 20,
      totalTokens: 30,
      latencyMs: 100,
      status: "ok",
      errorReason: null,
    };

    const report = buildEvalReport({
      modelOverride: null,
      verses: [entry],
    });

    assert.equal(report.verses[0]?.bedeutung, "Bedeutungstext");
    assert.equal(report.verses[0]?.kontext, "Kontexttext");
    assert.equal(report.verses[0]?.heute, "Heutetext");
    assert.deepEqual(report.verses[0]?.review, createEmptyExplanationReview());
    assert.equal(report.verses[0]?.review.meaningFaithful, null);
    assert.equal(report.verses[0]?.review.notes, "");
    assert.equal(reportContainsFullTafsirDump(report), false);
  });

  it("Markdown enthält die Prüfrubrik pro Vers ohne Tafsir-Volltext", () => {
    const verse = CURRENT_EXPLANATION_EVAL_VERSES[0]!;
    const report = buildEvalReport({
      modelOverride: null,
      verses: [
        {
          ...buildVerseReportBase(verse, {
            textDe: "Im Namen Allahs…",
            rassoulSourcePresent: true,
            rassoulTextLength: 50,
          }),
          bedeutung: "A",
          kontext: "B",
          heute: "C",
          model: "rule-based-sensitive-verse",
          promptTokens: null,
          completionTokens: null,
          totalTokens: null,
          latencyMs: 0,
          status: "ok",
          errorReason: null,
        },
      ],
    });

    const md = buildMarkdownReport(report);
    assert.match(md, /Bedeutung quellentreu: ☐/);
    assert.match(md, /Kontext belegt: ☐/);
    assert.match(md, /Heute gläubig und lebendig: ☐/);
    assert.match(md, /Heute hilfreich: ☐/);
    assert.match(md, /Unbelegtes persönliches Versprechen: ☐/);
    assert.match(md, /Versteckte Rechts-\/Fatwa-Aussage: ☐/);
    assert.match(md, /Notizen:/);
    assert.doesNotMatch(md, /"tafsir"/i);
    assert.doesNotMatch(md, /ANGEBUNDENER TAFSIR ZUM AUSGEWÄHLTEN VERS/);
  });

  it("parseExplainSections liest bedeutung/kontext/heute", () => {
    const sections = parseExplainSections(
      JSON.stringify({
        bedeutung: "b",
        kontext: "k",
        heute: "h",
      })
    );
    assert.deepEqual(sections, {
      bedeutung: "b",
      kontext: "k",
      heute: "h",
    });
  });
});

describe("evaluateCurrentExplanations CLI guards", () => {
  it("Production-Modus wird blockiert", () => {
    const result = assertNotProductionEnv("production");
    assert.equal(result.ok, false);
    if (result.ok) return;
    assert.match(result.message, /production/i);
  });

  it("fehlender API-Key wird sauber behandelt", () => {
    const result = assertOpenAiApiKeyPresent(undefined);
    assert.equal(result.ok, false);
    if (result.ok) return;
    assert.match(result.message, /OPENAI_API_KEY fehlt/);
    assert.doesNotMatch(result.message, /sk-/);
  });

  it("Output-Dateien werden ohne --overwrite nicht überschrieben", async () => {
    const dir = await mkdtemp(join(tmpdir(), "ihdina-explain-eval-"));
    const path = join(dir, "report.json");
    await writeFile(path, "{}\n", "utf8");

    const blocked = await assertOutputPathWritable(path, false);
    assert.equal(blocked.ok, false);

    const allowed = await assertOutputPathWritable(path, true);
    assert.equal(allowed.ok, true);

    const content = await readFile(path, "utf8");
    assert.equal(content, "{}\n");
  });

  it("CLI parst --only und --model", () => {
    const parsed = parseEvaluateCurrentExplanationsArgs([
      "--only",
      "2:255,94:6",
      "--model",
      "gpt-4o-mini",
      "--json",
    ]);
    assert.equal(parsed.ok, true);
    if (!parsed.ok) return;
    assert.equal(parsed.value.only, "2:255,94:6");
    assert.equal(parsed.value.model, "gpt-4o-mini");
    assert.equal(parsed.value.json, true);
  });
});

describe("explain evaluation isolation", () => {
  it("kein Import oder Aufruf von Analytics-/Limit-/DB-Schreiblogik im Tool", () => {
    const toolPath = fileURLToPath(
      new URL("./evaluateCurrentExplanations.ts", import.meta.url)
    );
    const source = readFileSync(toolPath, "utf8");

    assert.doesNotMatch(source, /analyticsIngest/);
    assert.doesNotMatch(source, /logAiRequest/);
    assert.doesNotMatch(source, /dailyExplanationUsageQueries/);
    assert.doesNotMatch(source, /getOrCreateUser/);
    assert.doesNotMatch(source, /bumpDaily/);
    assert.doesNotMatch(source, /prisma/i);
    assert.doesNotMatch(source, /from ["'].*usageLog/);
    assert.match(source, /completeVerifiedVerseExplanation/);
  });

  it("bestehende Explanation-Sonderfälle bleiben im OpenAI-Service unverändert referenziert", () => {
    const openaiPath = fileURLToPath(
      new URL("../services/openai.service.ts", import.meta.url)
    );
    const source = readFileSync(openaiPath, "utf8");
    assert.match(source, /AN_NISA_4_34_EXPLANATION_FALLBACK_JSON/);
    assert.match(source, /ASH_SHARH_94_6_EXPLANATION_FALLBACK_JSON/);
    assert.match(source, /normalizeVerseExplainJsonPayload/);
    assert.match(source, /hasAshSharh94_6Overreach/);
    assert.match(source, /hasAnNisa4_34UnsafeViolenceFraming/);
  });

  it("explain.service nutzt die extrahierte Produktionsfunktion unverändert im Kern", () => {
    const explainPath = fileURLToPath(
      new URL("../services/explain.service.ts", import.meta.url)
    );
    const source = readFileSync(explainPath, "utf8");
    assert.match(source, /export async function completeVerifiedVerseExplanation/);
    assert.match(
      source,
      /completion = await completeVerifiedVerseExplanation\(/
    );
    assert.match(source, /VERSE_EXPLANATION_POLICY/);
    assert.match(source, /buildVerifiedQuranPromptContext/);
    assert.match(source, /buildTafsirPromptContext/);
    assert.match(source, /completeExplanation/);
  });
});
