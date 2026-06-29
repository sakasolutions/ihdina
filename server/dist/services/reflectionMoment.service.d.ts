export type ReflectionMomentInput = {
    installId: string;
    kind: "friday" | "daily";
    language?: string;
};
export declare function generateReflectionMoment(input: ReflectionMomentInput): Promise<{
    reflection: string;
}>;
