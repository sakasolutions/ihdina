import OpenAI from "openai";
import { env } from "../config/env.js";
import { AppError, ErrorCodes } from "../utils/errors.js";

const systemPromptExplain = `Du bist ein hilfsbereiter, islamischer Bildungs-Assistent für eine Premium-Koran-App. Deine Aufgabe ist es, Koranverse basierend auf klassischem, anerkanntem Tafsir (wie Ibn Kathir) auf Deutsch zu erklären.
REGELN: 1. Erkläre den Kontext und die Bedeutung für das heutige Leben. 2. Du darfst NIEMALS Fiqh-Fragen beantworten, Fatwas erteilen oder Dinge als Haram/Halal deklarieren. Wenn eine Frage in diese Richtung geht, weise höflich darauf hin, dass du eine KI bist und der Nutzer einen qualifizierten Gelehrten fragen soll. 3. Antworte in klarem, respektvollem und leicht verständlichem Deutsch. Formatiere die Antwort mit kurzen Absätzen.`;

let client: OpenAI | null = null;

function getClient(): OpenAI {
  if (!client) client = new OpenAI({ apiKey: env.openaiApiKey });
  return client;
}

export async function completeExplanation(params: {
  surahName: string;
  ayahNumber: number;
  textAr: string;
  textDe: string;
}): Promise<string> {
  const userContent =
    `Erkläre folgenden Vers aus dem Koran:\n` +
    `Sure: ${params.surahName}, Vers: ${params.ayahNumber}\n` +
    `Arabisch: ${params.textAr}\n` +
    `Deutsche Übersetzung: ${params.textDe}\n\n` +
    `Gib eine strukturierte Erklärung mit: Kernaussage, Erklärung, Kontext und Bedeutung für heute.`;

  return callChat([
    { role: "system", content: systemPromptExplain },
    { role: "user", content: userContent },
  ], { maxTokens: 800, temperature: 0.5 });
}

export async function completeFollowUp(
  messages: OpenAI.Chat.ChatCompletionMessageParam[]
): Promise<string> {
  return callChat(messages, { maxTokens: 600, temperature: 0.5 });
}

async function callChat(
  messages: OpenAI.Chat.ChatCompletionMessageParam[],
  opts: { maxTokens: number; temperature: number }
): Promise<string> {
  try {
    const res = await getClient().chat.completions.create({
      model: env.openaiModel,
      messages,
      max_tokens: opts.maxTokens,
      temperature: opts.temperature,
    });
    const text = res.choices[0]?.message?.content?.trim();
    if (!text) {
      throw new AppError(
        ErrorCodes.AI_TEMPORARILY_UNAVAILABLE,
        "Empty response from AI provider.",
        503
      );
    }
    return text;
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
