import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { completeVerifiedVerseExplanation } from "./explain.service.js";
import { resolveRuleBasedExplanationJson } from "./openai.service.js";
import { env } from "../config/env.js";

function parseSections(text: string): {
  bedeutung: string;
  kontext: string;
  heute: string;
} {
  return JSON.parse(text) as {
    bedeutung: string;
    kontext: string;
    heute: string;
  };
}

describe("regelbasierte Explanation-Sonderfälle", () => {
  const cases: Array<{
    verseKey: string;
    surahName: string;
    ayahNumber: number;
  }> = [
    { verseKey: "2:256", surahName: "Al-Baqarah", ayahNumber: 256 },
    { verseKey: "2:286", surahName: "Al-Baqarah", ayahNumber: 286 },
    { verseKey: "4:34", surahName: "An-Nisa", ayahNumber: 34 },
    { verseKey: "9:5", surahName: "At-Tawbah", ayahNumber: 5 },
    { verseKey: "94:6", surahName: "Ash-Sharh", ayahNumber: 6 },
  ];

  for (const entry of cases) {
    it(`${entry.verseKey} verwendet keinen OpenAI-Aufruf`, async () => {
      assert.ok(resolveRuleBasedExplanationJson(entry.verseKey));

      const result = await completeVerifiedVerseExplanation({
        surahName: entry.surahName,
        ayahNumber: entry.ayahNumber,
      });

      assert.equal(result.model, "rule-based-sensitive-verse");
      assert.equal(result.latencyMs, 0);
      assert.equal(result.promptTokens, null);
      assert.equal(result.completionTokens, null);
    });
  }

  it("2:256 enthält keine falsche Zuordnung zum vorherigen Vers", async () => {
    const result = await completeVerifiedVerseExplanation({
      surahName: "Al-Baqarah",
      ayahNumber: 256,
    });
    const parsed = parseSections(result.text);

    assert.match(parsed.bedeutung, /keinen Zwang im Glauben/);
    assert.match(parsed.bedeutung, /Rechtleitung und Verirrung/);
    assert.match(parsed.bedeutung, /festen Bindung an Allah/);
    assert.match(parsed.kontext, /2:255/);
    assert.match(parsed.kontext, /Einzigartigkeit, Wissen und Macht/);
    assert.match(parsed.kontext, /Finsternis ins Licht/);
    assert.doesNotMatch(
      parsed.kontext,
      /vorherigen Vers.*falsche Götter|Ablehnung falscher Götter.*vorherigen/i
    );
    assert.match(parsed.heute, /Einsicht und Überzeugung/);
    assert.match(parsed.heute, /ohne Zwang/);
  });

  it("2:286 enthält keine Belastungsgarantie", async () => {
    const result = await completeVerifiedVerseExplanation({
      surahName: "Al-Baqarah",
      ayahNumber: 286,
    });
    const parsed = parseSections(result.text);
    const all = `${parsed.bedeutung}\n${parsed.kontext}\n${parsed.heute}`;

    assert.match(parsed.bedeutung, /Verantwortung mit Bittgebet/);
    assert.match(parsed.bedeutung, /Vergebung, Barmherzigkeit, Erleichterung und Beistand/);
    assert.match(parsed.kontext, /Rechenschaft, Glauben und die Bitte um Vergebung/);
    assert.match(parsed.kontext, /Sure Al-Baqarah/);
    assert.match(parsed.heute, /Bittgebet an Allah/);
    assert.match(parsed.heute, /Vergebung, Erleichterung, Barmherzigkeit und Beistand/);
    assert.doesNotMatch(all, /Allah überfordert dich nicht/i);
    assert.doesNotMatch(all, /Du kannst jede Belastung tragen/i);
    assert.doesNotMatch(all, /Allah verlangt nichts Unmögliches von dir/i);
  });

  it("9:5 enthält die Grenze gegen private Gewaltanweisungen", async () => {
    const result = await completeVerifiedVerseExplanation({
      surahName: "At-Tawbah",
      ayahNumber: 5,
    });
    const parsed = parseSections(result.text);

    assert.match(parsed.kontext, /9:4/);
    assert.match(parsed.kontext, /9:6/);
    assert.match(parsed.heute, /keine private Gewaltanweisung/);
    assert.match(parsed.heute, /Vertragstreue|Schutz|Barmherzigkeit/);
    assert.match(parsed.heute, /ohne allgemeine politische Anwendung/);
  });

  it("94:6 enthält weder sofortige Erleichterungsgarantie noch sichtbaren Disclaimer", async () => {
    const result = await completeVerifiedVerseExplanation({
      surahName: "Ash-Sharh",
      ayahNumber: 6,
    });
    const parsed = parseSections(result.text);
    const all = `${parsed.bedeutung}\n${parsed.kontext}\n${parsed.heute}`;

    assert.match(parsed.bedeutung, /mit der Erschwernis Erleichterung/);
    assert.match(parsed.bedeutung, /ohne Zeitpunkt oder konkrete Form/);
    assert.match(parsed.kontext, /94:5 und 94:6/);
    assert.match(parsed.heute, /Hoffnung|Allah/);
    assert.doesNotMatch(all, /sofort|garantiert|immer Erleichterung/i);
    assert.doesNotMatch(
      all,
      /ohne eine persönliche Garantie|allgemeine Ermutigung|Daraus folgt keine/
    );
  });

  it("4:34 bleibt regelbasiert und informativ", async () => {
    const result = await completeVerifiedVerseExplanation({
      surahName: "An-Nisa",
      ayahNumber: 34,
    });
    const parsed = parseSections(result.text);

    assert.equal(result.model, "rule-based-sensitive-verse");
    assert.match(parsed.bedeutung, /Verantwortung/);
    assert.match(parsed.kontext, /4:35/);
  });

  it("ein normaler Vers läuft weiterhin über das konfigurierte Modell (gpt-4.1-Pfad)", () => {
    assert.equal(resolveRuleBasedExplanationJson("2:255"), null);
    assert.equal(resolveRuleBasedExplanationJson("1:1"), null);
    assert.equal(resolveRuleBasedExplanationJson("13:28"), null);
    // Produktionspfad: callChat nutzt env.openaiModel (lokal typisch gpt-4.1).
    assert.ok(typeof env.openaiModel === "string" && env.openaiModel.length > 0);
  });
});
