import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  normalizeVerseExplainJsonPayload,
  stripKnownExplanationSourceAttribution,
} from "./openai.service.js";
import {
  VERSE_EXPLANATION_POLICY,
  buildVerseExplanationPolicy,
} from "./verseExplanationPolicy.service.js";

const KNOWN_SOURCE =
  "Tafsīr Al-Qur'ān Al-Karīm, Muhammad Ibn Ahmad Ibn Rassoul, IB Verlag, 41. Auflage, 2008";

describe("stripKnownExplanationSourceAttribution", () => {
  it("entfernt angehängte bekannte Quellenzeile aus Feldern", () => {
    const input = `Allah ist der Lebendige.\n\nQuelle: ${KNOWN_SOURCE}`;
    assert.equal(
      stripKnownExplanationSourceAttribution(input),
      "Allah ist der Lebendige."
    );
  });

  it("entfernt angehängte bekannte Quellen-Klammerangabe", () => {
    const input = `Der Vers nennt den Thronschemel. (Quelle: ${KNOWN_SOURCE})`;
    assert.equal(
      stripKnownExplanationSourceAttribution(input),
      "Der Vers nennt den Thronschemel."
    );
  });

  it("entfernt keine normalen Inhalte ohne Quellenangabe", () => {
    const input =
      "Bitte Allah um Vergebung, Erleichterung und Barmherzigkeit. Der Vers spricht von Verantwortung.";
    assert.equal(stripKnownExplanationSourceAttribution(input), input);
  });

  it("entfernt keine mittig erwähnte allgemeine Quellenrede", () => {
    const input =
      "Im angebundenen Tafsir wird die Aussage erklärt und mit dem Vers verbunden.";
    assert.equal(stripKnownExplanationSourceAttribution(input), input);
  });
});

describe("normalizeVerseExplainJsonPayload Quellenbereinigung", () => {
  it("entfernt bekannte Quellenzeilen aus bedeutung, kontext und heute", () => {
    const normalized = normalizeVerseExplainJsonPayload(
      JSON.stringify({
        bedeutung: `Kernaussage.\n\nQuelle: ${KNOWN_SOURCE}`,
        kontext: `Nachbarverse.\n(Quelle: ${KNOWN_SOURCE})`,
        heute: `Bitte Allah um Beistand.\n\nQuelle: ${KNOWN_SOURCE}`,
      })
    );
    const parsed = JSON.parse(normalized) as {
      bedeutung: string;
      kontext: string;
      heute: string;
    };

    assert.equal(parsed.bedeutung, "Kernaussage.");
    assert.equal(parsed.kontext, "Nachbarverse.");
    assert.equal(parsed.heute, "Bitte Allah um Beistand.");
    assert.doesNotMatch(parsed.bedeutung, /Quelle:/);
    assert.doesNotMatch(parsed.kontext, /Quelle:/);
    assert.doesNotMatch(parsed.heute, /Quelle:/);
  });

  it("bestehende Quellen-Normalisierung bleibt aktiv", () => {
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /Schreibe keine Quellenangabe in die Felder "bedeutung", "kontext" oder "heute"/
    );
    const withSource = stripKnownExplanationSourceAttribution(
      `Text\n\nQuelle: ${KNOWN_SOURCE}`
    );
    assert.equal(withSource, "Text");
  });
});

describe("VERSE_EXPLANATION_POLICY Nachschärfungen", () => {
  it("verlangt exakte Begriffstreue und verbietet Allerbarmher", () => {
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /Bevorzuge die exakten Begriffe der Versübersetzung/
    );
    assert.match(VERSE_EXPLANATION_POLICY, /Allerbarmher/);
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /„Wissen“ nicht durch „Fürsorge“/
    );
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /„Thronschemel“ nicht durch „Thron“/
    );
  });

  it("2:255-Hinweis nur bedingt im Prompt", () => {
    assert.doesNotMatch(
      VERSE_EXPLANATION_POLICY,
      /außer mit Allahs Erlaubnis/
    );
    assert.match(
      buildVerseExplanationPolicy("2:255"),
      /außer mit Allahs Erlaubnis/
    );
    assert.match(
      VERSE_EXPLANATION_POLICY,
      /Aussagen aus dem aktuellen Vers niemals dem vorherigen Vers zu/
    );
  });

  it("5:51-Hinweis nur bedingt und ohne pauschales Freundschaftsverbot-Erlaubnis", () => {
    assert.doesNotMatch(VERSE_EXPLANATION_POLICY, /Schutzherren/);
    const policy = buildVerseExplanationPolicy("5:51");
    assert.match(
      policy,
      /nicht pauschal auf Freundschaft, Nachbarschaft, Zusammenarbeit/
    );
    assert.match(
      policy,
      /Friedlicher und gerechter Umgang mit Andersgläubigen darf nicht als verboten/
    );
  });
});
