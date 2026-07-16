import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { describe, it } from "node:test";
import { fileURLToPath } from "node:url";
import {
  VERSE_EXPLANATION_POLICY,
  buildVerseExplanationPolicy,
} from "./verseExplanationPolicy.service.js";

describe("VERSE_EXPLANATION_POLICY Qualitätsregeln", () => {
  it("Bedeutung verlangt Erhalt zentraler Begriffe und verbietet Tautologien", () => {
    assert.match(VERSE_EXPLANATION_POLICY, /Zentrale Begriffe aus dem Vers müssen erhalten bleiben/);
    assert.match(VERSE_EXPLANATION_POLICY, /Thronschemel/);
    assert.match(VERSE_EXPLANATION_POLICY, /Thron/);
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /Allah ist der einzige Allah/
    );
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /Wiederhole den Vers nicht nur Satz für Satz/
    );
  });

  it("Kontext darf nur bereitgestellte Nachbarverse und Tafsir verwenden", () => {
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /tatsächlich bereitgestellte Nachbarverse/
    );
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /bereitgestellten Rassoul-Tafsir/
    );
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /Kein Kontext aus allgemeinem Modellwissen/
    );
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /Nenne keine Versnummer, deren Text nicht im Prompt vorhanden ist/
    );
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /direkt davor.*nur.*tatsächlich übergeben/s
    );
  });

  it("Offenbarungsanlässe aus Modellwissen sind verboten", () => {
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /Keine erfundenen Offenbarungsanlässe/
    );
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /Erfinde keine historischen Hintergründe, Offenbarungsanlässe/
    );
  });

  it("sichtbare Garantie-Disclaimer in Heute sind verboten", () => {
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /ohne eine persönliche Garantie zu formulieren/
    );
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /kann als allgemeine Ermutigung verstanden werden/
    );
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /Interne Sicherheitsregeln dürfen nicht sichtbar formuliert werden/
    );
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /sichtbare Disclaimer/
    );
  });

  it("Heute darf warm, gläubig und Allah-bezogen formuliert sein", () => {
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /Heute darf den Glauben ansprechen, aber keine neuen Glaubensaussagen erfinden/
    );
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /warm, gläubig und emotional/
    );
    assert.match(VERSE_EXPLANATION_POLICY, /Duʿā/);
    assert.match(VERSE_EXPLANATION_POLICY, /Tawakkul/);
    assert.match(VERSE_EXPLANATION_POLICY, /Hoffnung/);
  });

  it("deterministische Verse stehen nicht mehr im globalen Prompt", () => {
    assert.doesNotMatch(VERSE_EXPLANATION_POLICY, /4:34:/);
    assert.doesNotMatch(VERSE_EXPLANATION_POLICY, /2:256:/);
    assert.doesNotMatch(VERSE_EXPLANATION_POLICY, /2:286:/);
    assert.doesNotMatch(VERSE_EXPLANATION_POLICY, /9:5:/);
    assert.doesNotMatch(VERSE_EXPLANATION_POLICY, /94:6:/);
    assert.doesNotMatch(VERSE_EXPLANATION_POLICY, /private Gewaltanweisung/);
    assert.doesNotMatch(VERSE_EXPLANATION_POLICY, /Allah überfordert dich nicht/);
  });

  it("verse-spezifische Regeln eines anderen Verses landen nicht im normalen Prompt", () => {
    const normal = buildVerseExplanationPolicy("1:1");
    assert.equal(normal, VERSE_EXPLANATION_POLICY);
    assert.doesNotMatch(normal, /Schutzherren/);
    assert.doesNotMatch(normal, /5:51/);
    assert.doesNotMatch(normal, /24:31/);
    assert.doesNotMatch(normal, /49:13/);
    assert.doesNotMatch(normal, /außer mit Allahs Erlaubnis/);

    const for255 = buildVerseExplanationPolicy("2:255");
    assert.match(for255, /außer mit Allahs Erlaubnis/);
    assert.doesNotMatch(for255, /Schutzherren/);

    const for551 = buildVerseExplanationPolicy("5:51");
    assert.match(for551, /Schutzherren/);
    assert.match(
      for551,
      /Freundschaft, Nachbarschaft, Zusammenarbeit/
    );
    assert.doesNotMatch(for551, /außer mit Allahs Erlaubnis/);
  });

  it("bedingte Hinweise für 5:51, 24:31 und 49:13 bleiben verfügbar", () => {
    assert.match(
      buildVerseExplanationPolicy("5:51"),
      /keine freundschaftlichen oder gerechten Beziehungen/
    );
    assert.match(
      buildVerseExplanationPolicy("24:31"),
      /Keine individuelle Fatwa zu konkreter Kleidung/
    );
    assert.match(
      buildVerseExplanationPolicy("49:13"),
      /Gottesfurcht ist der genannte Maßstab/
    );
  });
});

describe("regelbasierte Sonderfälle in openai.service", () => {
  const openaiSource = readFileSync(
    fileURLToPath(new URL("./openai.service.ts", import.meta.url)),
    "utf8"
  );

  it("nutzt eine zentrale Map für deterministische Erklärungen", () => {
    assert.match(openaiSource, /RULE_BASED_EXPLANATION_JSON_BY_VERSE_KEY/);
    assert.match(openaiSource, /"2:256"/);
    assert.match(openaiSource, /"2:286"/);
    assert.match(openaiSource, /"4:34"/);
    assert.match(openaiSource, /"9:5"/);
    assert.match(openaiSource, /"94:6"/);
    assert.match(openaiSource, /resolveRuleBasedExplanationJson/);
  });

  it("4:34-Fallback enthält eine verständliche Kernaussage", () => {
    assert.match(
      openaiSource,
      /Verantwortung der Männer für die Frauen/
    );
    assert.match(openaiSource, /finanziellen Versorgung/);
    assert.match(openaiSource, /Vers 4:35/);
  });

  it("94:6-Fallback enthält keine sichtbaren Garantie-Disclaimer", () => {
    const fallbackMatch = openaiSource.match(
      /ASH_SHARH_94_6_EXPLANATION_FALLBACK_JSON = JSON\.stringify\(\{([\s\S]*?)\}\);/
    );
    assert.ok(fallbackMatch);
    const fallbackBody = fallbackMatch![1]!;
    assert.doesNotMatch(
      fallbackBody,
      /ohne .*Garantie|allgemeine Ermutigung|Daraus folgt keine/
    );
    assert.match(fallbackBody, /Hoffnung/);
    assert.match(fallbackBody, /Bitte Allah/);
  });
});

describe("Produktionsabläufe unverändert angebunden", () => {
  it("bestehende API-, Limit- und Analytics-Abläufe bleiben in explain.service", () => {
    const explainSource = readFileSync(
      fileURLToPath(new URL("./explain.service.ts", import.meta.url)),
      "utf8"
    );
    assert.match(explainSource, /getOrCreateUser/);
    assert.match(explainSource, /getDailyVerseExplainCount/);
    assert.match(explainSource, /bumpDailyVerseExplainCount/);
    assert.match(explainSource, /logAiRequest/);
    assert.match(
      explainSource,
      /completion = await completeVerifiedVerseExplanation\(/
    );
    assert.match(explainSource, /buildVerseExplanationPolicy/);
  });

  it("Evaluationswerkzeug verwendet weiterhin exakt die Produktionslogik", () => {
    const toolSource = readFileSync(
      fileURLToPath(
        new URL("../tools/evaluateCurrentExplanations.ts", import.meta.url)
      ),
      "utf8"
    );
    assert.match(toolSource, /completeVerifiedVerseExplanation/);
    assert.doesNotMatch(toolSource, /logAiRequest/);
    assert.doesNotMatch(toolSource, /getOrCreateUser/);
    assert.doesNotMatch(toolSource, /bumpDaily/);
  });
});
