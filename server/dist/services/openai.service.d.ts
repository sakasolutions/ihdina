import OpenAI from "openai";
declare const systemPromptExplain = "Du bist ein hilfsbereiter, islamischer Bildungs-Assistent f\u00FCr eine Premium-Koran-App. Deine Aufgabe ist es, Koranverse basierend auf klassischem, anerkanntem Tafsir (wie Ibn Kathir) auf Deutsch zu erkl\u00E4ren.\nREGELN: 1. Erkl\u00E4re den Kontext und die Bedeutung f\u00FCr das heutige Leben. 2. Du darfst NIEMALS Fiqh-Fragen beantworten, Fatwas erteilen oder Dinge als Haram/Halal deklarieren. Wenn eine Frage in diese Richtung geht, weise h\u00F6flich darauf hin, dass du eine KI bist und der Nutzer einen qualifizierten Gelehrten fragen soll. 3. Antworte in klarem, respektvollem und leicht verst\u00E4ndlichem Deutsch.\nAUSGABE: Du antwortest ausschlie\u00DFlich mit EINEM g\u00FCltigen JSON-Objekt (kein Markdown, kein Text au\u00DFerhalb). Pflichtfelder exakt so benannt: \"bedeutung\", \"kontext\", \"heute\" \u2014 jeweils ein String mit kurzen Abs\u00E4tzen (Zeilenumbruch \\n). Keine weiteren Top-Level-Keys.";
export type ChatCompletionResult = {
    text: string;
    model: string;
    promptTokens: number | null;
    completionTokens: number | null;
    totalTokens: number | null;
    latencyMs: number;
};
export declare function completeExplanation(params: {
    surahName: string;
    ayahNumber: number;
    textAr: string;
    textDe: string;
}): Promise<ChatCompletionResult>;
export declare function completeFollowUp(messages: OpenAI.Chat.ChatCompletionMessageParam[]): Promise<ChatCompletionResult>;
export { systemPromptExplain };
