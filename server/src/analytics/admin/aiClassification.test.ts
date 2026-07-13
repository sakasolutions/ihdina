import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  classifyAiRequestLog,
  AI_LIMIT_ERROR_CODES,
  isRuleBasedModel,
} from "./aiClassification.js";
import { ErrorCodes } from "../../utils/errors.js";

describe("classifyAiRequestLog", () => {
  it("classifies limit codes as limit_blocked", () => {
    for (const code of AI_LIMIT_ERROR_CODES) {
      assert.equal(
        classifyAiRequestLog({
          status: "error",
          errorCode: code,
          endpoint: "POST /api/v1/explain",
          model: null,
          promptTokens: 0,
          completionTokens: 0,
        }),
        "limit_blocked"
      );
    }
  });

  it("classifies successful AI with tokens as success_ai", () => {
    assert.equal(
      classifyAiRequestLog({
        status: "ok",
        errorCode: null,
        endpoint: "POST /api/v1/explain",
        model: "gpt-4o-mini",
        promptTokens: 100,
        completionTokens: 50,
      }),
      "success_ai"
    );
  });

  it("classifies known rule-based model as success_rule_based", () => {
    assert.equal(
      classifyAiRequestLog({
        status: "success",
        errorCode: null,
        endpoint: "POST /api/v1/explain",
        model: "rule-based-sensitive-verse",
        promptTokens: 0,
        completionTokens: 0,
      }),
      "success_rule_based"
    );
    assert.ok(isRuleBasedModel("rule-based-sensitive-verse"));
  });

  it("classifies success without tokens or model as success_unclassified", () => {
    assert.equal(
      classifyAiRequestLog({
        status: "success",
        errorCode: null,
        endpoint: "POST /api/v1/explain",
        model: null,
        promptTokens: 0,
        completionTokens: 0,
      }),
      "success_unclassified"
    );
  });

  it("classifies provider errors as technical_error", () => {
    assert.equal(
      classifyAiRequestLog({
        status: "error",
        errorCode: ErrorCodes.AI_TEMPORARILY_UNAVAILABLE,
        endpoint: "POST /api/v1/explain",
        model: "gpt-4o-mini",
        promptTokens: 10,
        completionTokens: 0,
      }),
      "technical_error"
    );
  });

  it("classifies PRO_REQUIRED as policy_or_controlled", () => {
    assert.equal(
      classifyAiRequestLog({
        status: "error",
        errorCode: ErrorCodes.PRO_REQUIRED,
        endpoint: "POST /api/v1/follow-up",
        model: null,
        promptTokens: 0,
        completionTokens: 0,
      }),
      "policy_or_controlled"
    );
  });

  it("never classifies limits as technical_error", () => {
    const cat = classifyAiRequestLog({
      status: "error",
      errorCode: ErrorCodes.FREE_LIMIT_REACHED,
      endpoint: "POST /api/v1/explain",
      model: "gpt-4o-mini",
      promptTokens: 0,
      completionTokens: 0,
    });
    assert.notEqual(cat, "technical_error");
    assert.equal(cat, "limit_blocked");
  });
});
