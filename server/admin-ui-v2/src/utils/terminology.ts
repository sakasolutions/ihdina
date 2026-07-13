/** Nutzerfreundliche Bezeichnungen — technische Namen nur in Tooltips. */
export const PRODUCT_TRACKING = "Produkttracking";

export const EVENT_LABELS: Record<string, string> = {
  explanation_requested: "Erklärung geöffnet",
  explanation_viewed: "Erklärung angesehen",
  followup_submitted: "Folgefrage gestellt",
};

export const EVENT_TOOLTIPS: Record<string, string> = {
  explanation_requested: "ProductEvent: explanation_requested",
  explanation_viewed: "ProductEvent: explanation_viewed",
  followup_submitted: "ProductEvent: followup_submitted",
};

export const APPROX_BADGE = "vorläufige Näherung";

export function eventLabel(technicalName: string): string {
  return EVENT_LABELS[technicalName] ?? technicalName;
}
