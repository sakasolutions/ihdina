import OpenAI from "openai";
import { env } from "../config/env.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

const systemPromptExplain = `Du bist ein hilfsbereiter, islamischer Bildungs-Assistent für eine Premium-Koran-App. Deine Aufgabe ist es, Koranverse basierend auf klassischem, anerkanntem Tafsir (wie Ibn Kathir) auf Deutsch zu erklären.
REGELN: 1. Erkläre den Kontext und die Bedeutung für das heutige Leben. 2. Du darfst NIEMALS Fiqh-Fragen beantworten, Fatwas erteilen oder Dinge als Haram/Halal deklarieren. Wenn eine Frage in diese Richtung geht, weise höflich darauf hin, dass du eine KI bist und der Nutzer einen qualifizierten Gelehrten fragen soll. 3. Antworte in klarem, respektvollem und leicht verständlichem Deutsch.
AUSGABE: Du antwortest ausschließlich mit EINEM gültigen JSON-Objekt (kein Markdown, kein Text außerhalb). Pflichtfelder exakt so benannt: "bedeutung", "kontext", "heute" — jeweils ein String mit kurzen Absätzen (Zeilenumbruch \\n). Keine weiteren Top-Level-Keys.`;

let client: OpenAI | null = null;

function getClient(): OpenAI {
  if (!client) client = new OpenAI({ apiKey: env.openaiApiKey });
  return client;
}

export type ChatCompletionResult = {
  text: string;
  model: string;
  promptTokens: number | null;
  completionTokens: number | null;
  totalTokens: number | null;
  latencyMs: number;
};

/** Liefert ein JSON-String mit bedeutung/kontext/heute — so erwartet die App die drei Pillen. */
function normalizeVerseExplainJsonPayload(raw: string): string {
  let t = raw.trim();
  const fenceOpen = /^```(?:json)?\s*/i;
  if (fenceOpen.test(t)) {
    t = t.replace(fenceOpen, "").replace(/\s*```\s*$/i, "").trim();
  }
  try {
    const parsed = JSON.parse(t) as Record<string, unknown>;
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
      const pick = (a: string, b: string): string => {
        const v = parsed[a] ?? parsed[b];
        return typeof v === "string" ? v : "";
      };
      const bedeutung = pick("bedeutung", "Bedeutung");
      const kontext = pick("kontext", "Kontext");
      const heute = pick("heute", "Heute");
      if (bedeutung !== "" || kontext !== "" || heute !== "") {
        return JSON.stringify({ bedeutung, kontext, heute });
      }
    }
  } catch {
    /* Fließtext-Fallback */
  }
  return JSON.stringify({
    bedeutung: raw.trim(),
    kontext: "",
    heute: "",
  });
}

export async function completeExplanation(params: {
  surahName: string;
  ayahNumber: number;
  textAr: string;
  textDe: string;
}): Promise<ChatCompletionResult> {
  const userContent =
    `Erkläre folgenden Vers aus dem Koran:\n` +
    `Sure: ${params.surahName}, Vers: ${params.ayahNumber}\n` +
    `Arabisch: ${params.textAr}\n` +
    `Deutsche Übersetzung: ${params.textDe}\n\n` +
    `Fülle die drei Felder: "bedeutung" (Kernaussage + inhaltliche Erklärung), "kontext" (Einordnung, Hintergrund), "heute" (Bedeutung fürs heutige Leben).`;

  const out = await callChat(
    [
      { role: "system", content: systemPromptExplain },
      { role: "user", content: userContent },
    ],
    { maxTokens: 900, temperature: 0.45, responseFormatJsonObject: true }
  );
  return { ...out, text: normalizeVerseExplainJsonPayload(out.text) };
}

export async function completeFollowUp(
  messages: OpenAI.Chat.ChatCompletionMessageParam[]
): Promise<ChatCompletionResult> {
  return callChat(messages, { maxTokens: 600, temperature: 0.5 });
}

async function callChat(
  messages: OpenAI.Chat.ChatCompletionMessageParam[],
  opts: { maxTokens: number; temperature: number; responseFormatJsonObject?: boolean }
): Promise<ChatCompletionResult> {
  try {
    const t0 = Date.now();
    const res = await getClient().chat.completions.create({
      model: env.openaiModel,
      messages,
      max_tokens: opts.maxTokens,
      temperature: opts.temperature,
      ...(opts.responseFormatJsonObject
        ? { response_format: { type: "json_object" as const } }
        : {}),
    });
    const latencyMs = Date.now() - t0;
    const text = res.choices[0]?.message?.content?.trim();
    if (!text) {
      throw new AppError(
        ErrorCodes.AI_TEMPORARILY_UNAVAILABLE,
        "Empty response from AI provider.",
        503
      );
    }
    const u = res.usage;
    const model = res.model ?? env.openaiModel;
    return {
      text,
      model,
      promptTokens: u?.prompt_tokens ?? null,
      completionTokens: u?.completion_tokens ?? null,
      totalTokens: u?.total_tokens ?? null,
      latencyMs,
    };
  } catch (e) {
    if (e instanceof AppError) throw e;
    const msg = e instanceof Error ? e.message : "Unknown AI error";
    console.error("[openai]", msg);
    throw new AppError(
      ErrorCodes.AI_TEMPORARILY_UNAVAILABLE,
      "AI service is temporarily unavailable.",
      503
    );
  }
}

export { systemPromptExplain };
