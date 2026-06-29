import OpenAI from "openai";
import { env } from "../config/env.js";
import { AppError, ErrorCodes } from "../utils/errors.js";
const systemPromptExplain = `Du bist ein hilfsbereiter, islamischer Bildungs-Assistent für eine Premium-Koran-App. Deine Aufgabe ist es, Koranverse basierend auf klassischem, anerkanntem Tafsir (wie Ibn Kathir) auf Deutsch zu erklären.
REGELN: 1. Erkläre den Kontext und die Bedeutung für das heutige Leben. 2. Du darfst NIEMALS Fiqh-Fragen beantworten, Fatwas erteilen oder Dinge als Haram/Halal deklarieren. Wenn eine Frage in diese Richtung geht, weise höflich darauf hin, dass du eine KI bist und der Nutzer einen qualifizierten Gelehrten fragen soll. 3. Antworte in klarem, respektvollem und leicht verständlichem Deutsch.
AUSGABE: Du antwortest ausschließlich mit EINEM gültigen JSON-Objekt (kein Markdown, kein Text außerhalb). Pflichtfelder exakt so benannt: "bedeutung", "kontext", "heute" — jeweils ein String mit kurzen Absätzen (Zeilenumbruch \\n). Keine weiteren Top-Level-Keys.`;
let client = null;
function getClient() {
    if (!client)
        client = new OpenAI({ apiKey: env.openaiApiKey });
    return client;
}
/** Liefert ein JSON-String mit bedeutung/kontext/heute — so erwartet die App die drei Pillen. */
function normalizeVerseExplainJsonPayload(raw) {
    let t = raw.trim();
    const fenceOpen = /^```(?:json)?\s*/i;
    if (fenceOpen.test(t)) {
        t = t.replace(fenceOpen, "").replace(/\s*```\s*$/i, "").trim();
    }
    try {
        const parsed = JSON.parse(t);
        if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
            const pick = (a, b) => {
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
    }
    catch {
        /* Fließtext-Fallback */
    }
    return JSON.stringify({
        bedeutung: raw.trim(),
        kontext: "",
        heute: "",
    });
}
export async function completeExplanation(params) {
    const userContent = `Erkläre folgenden Vers aus dem Koran:\n` +
        `Sure: ${params.surahName}, Vers: ${params.ayahNumber}\n` +
        `Arabisch: ${params.textAr}\n` +
        `Deutsche Übersetzung: ${params.textDe}\n\n` +
        `Fülle die drei Felder: "bedeutung" (Kernaussage + inhaltliche Erklärung), "kontext" (Einordnung, Hintergrund), "heute" (Bedeutung fürs heutige Leben).`;
    const out = await callChat([
        { role: "system", content: systemPromptExplain },
        { role: "user", content: userContent },
    ], { maxTokens: 900, temperature: 0.45, responseFormatJsonObject: true });
    return { ...out, text: normalizeVerseExplainJsonPayload(out.text) };
}
export async function completeFollowUp(messages) {
    return callChat(messages, { maxTokens: 600, temperature: 0.5 });
}
const systemPromptReflection = `Du schreibst einen kurzen, warmen Nachdenk-Impuls für eine islamische Gebet-App auf Deutsch.

Regeln:
- 3–5 Sätze, maximal 280 Zeichen, ein Fließtext
- Am Ende genau eine offene Frage zum Nachdenken
- Respektvoll, emotional, nicht belehrend
- KEINE Khutbah, KEINE Predigt, KEIN „Ich predige…"
- KEINE Fatwa, KEIN Halal/Haram, KEINE Rechtsauskunft
- KEINE erfundenen Hadithe, Verse oder Gelehrtenzitate

Wenn der Nutzer "friday" schreibt: Jumuʿah, Gemeinschaft, Besinnung vor dem Freitagsgebet — nicht Ersatz für die Hutbe des Imams.
Wenn der Nutzer "daily" schreibt: allgemeiner islamischer Impuls (Dankbarkeit, Geduld, Aufrichtigkeit).

Antworte nur mit dem Impfstext, ohne Anführungszeichen oder JSON.`;
const systemPromptTakeaway = `Du schreibst genau EINEN kurzen persönlichen Impuls auf Deutsch für „Für dich heute" in einer Koran-App.

Regeln:
- Genau ein Satz, maximal 140 Zeichen
- Bezogen auf den gegebenen Vers (Sure + Ayah + Übersetzung)
- Warm, konkret, keine Predigt, keine Fatwa, keine erfundenen Zitate
- Keine Anführungszeichen am Anfang/Ende

Antworte nur mit diesem einen Satz, sonst nichts.`;
export async function completeReflectionMoment(kind) {
    return callChat([
        { role: "system", content: systemPromptReflection },
        { role: "user", content: `kind: ${kind}` },
    ], { maxTokens: 180, temperature: 0.65 });
}
export async function completeTakeaway(params) {
    const userContent = `Sure: ${params.surahName}, Vers: ${params.ayahNumber}\n` +
        `Deutsche Übersetzung: ${params.textDe}`;
    return callChat([
        { role: "system", content: systemPromptTakeaway },
        { role: "user", content: userContent },
    ], { maxTokens: 120, temperature: 0.55 });
}
async function callChat(messages, opts) {
    try {
        const t0 = Date.now();
        const res = await getClient().chat.completions.create({
            model: env.openaiModel,
            messages,
            max_tokens: opts.maxTokens,
            temperature: opts.temperature,
            ...(opts.responseFormatJsonObject
                ? { response_format: { type: "json_object" } }
                : {}),
        });
        const latencyMs = Date.now() - t0;
        const text = res.choices[0]?.message?.content?.trim();
        if (!text) {
            throw new AppError(ErrorCodes.AI_TEMPORARILY_UNAVAILABLE, "Empty response from AI provider.", 503);
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
    }
    catch (e) {
        if (e instanceof AppError)
            throw e;
        const msg = e instanceof Error ? e.message : "Unknown AI error";
        console.error("[openai]", msg);
        throw new AppError(ErrorCodes.AI_TEMPORARILY_UNAVAILABLE, "AI service is temporarily unavailable.", 503);
    }
}
export { systemPromptExplain };
