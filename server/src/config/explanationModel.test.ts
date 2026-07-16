import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { afterEach, describe, it } from "node:test";
import { fileURLToPath } from "node:url";
import { env } from "../config/env.js";
import { resolveRuleBasedExplanationJson } from "../services/openai.service.js";

describe("OPENAI_EXPLANATION_MODEL Auflösung", () => {
  const previous = process.env.OPENAI_EXPLANATION_MODEL;

  afterEach(() => {
    if (previous === undefined) {
      delete process.env.OPENAI_EXPLANATION_MODEL;
    } else {
      process.env.OPENAI_EXPLANATION_MODEL = previous;
    }
  });

  it("ohne OPENAI_EXPLANATION_MODEL verwendet Explanation OPENAI_MODEL", () => {
    delete process.env.OPENAI_EXPLANATION_MODEL;
    assert.equal(env.openaiExplanationModel, env.openaiModel);
  });

  it("leere oder nur aus Leerzeichen bestehende Variable fällt auf OPENAI_MODEL zurück", () => {
    process.env.OPENAI_EXPLANATION_MODEL = "";
    assert.equal(env.openaiExplanationModel, env.openaiModel);

    process.env.OPENAI_EXPLANATION_MODEL = "   ";
    assert.equal(env.openaiExplanationModel, env.openaiModel);
  });

  it("mit gesetztem OPENAI_EXPLANATION_MODEL verwendet nur Explanation dieses Modell", () => {
    process.env.OPENAI_EXPLANATION_MODEL = "gpt-test-explanation-only";
    assert.equal(env.openaiExplanationModel, "gpt-test-explanation-only");
    assert.notEqual(env.openaiModel, "gpt-test-explanation-only");
  });
});

describe("Explanation- vs Follow-up-Modellpfade", () => {
  const openaiSource = readFileSync(
    fileURLToPath(new URL("../services/openai.service.ts", import.meta.url)),
    "utf8"
  );
  const evalSource = readFileSync(
    fileURLToPath(
      new URL("../tools/evaluateCurrentExplanations.ts", import.meta.url)
    ),
    "utf8"
  );

  it("completeExplanation übergibt openaiExplanationModel an callChat", () => {
    assert.match(
      openaiSource,
      /model:\s*env\.openaiExplanationModel/
    );
    // Follow-up-Aufrufe ohne Explanation-Modell-Override
    const followUpStart = openaiSource.indexOf(
      "export async function completeFollowUp"
    );
    assert.ok(followUpStart > 0);
    const followUpSlice = openaiSource.slice(
      followUpStart,
      followUpStart + 2500
    );
    assert.doesNotMatch(followUpSlice, /openaiExplanationModel/);
    assert.match(followUpSlice, /callChat\(/);
  });

  it("Follow-up verwendet weiterhin OPENAI_MODEL über den callChat-Default", () => {
    assert.match(
      openaiSource,
      /const requestedModel = opts\.model \?\? env\.openaiModel/
    );
  });

  it("Evaluation-Override setzt nur OPENAI_EXPLANATION_MODEL", () => {
    assert.match(
      evalSource,
      /process\.env\.OPENAI_EXPLANATION_MODEL = args\.model/
    );
    assert.doesNotMatch(
      evalSource,
      /process\.env\.OPENAI_MODEL = args\.model/
    );
  });

  it("regelbasierte Sonderfälle lösen keinen OpenAI-Aufruf aus", () => {
    for (const key of ["2:256", "2:286", "4:34", "9:5", "94:6"]) {
      assert.ok(resolveRuleBasedExplanationJson(key));
    }
    assert.match(openaiSource, /rule-based-sensitive-verse/);
  });
});
