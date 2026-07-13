/**
 * Eindeutig bekannte Entwickler-/Test-installIds.
 * Nur explizit gelistete IDs werden bei Seed/Migration als isInternal=true gesetzt.
 * Keine Heuristik (kein Display-Name, keine hohe Nutzung).
 */
export const KNOWN_INTERNAL_INSTALL_IDS: readonly string[] = [
  // Leer — Nutzer manuell per Admin PATCH /users/:installId { "isInternal": true } markieren.
];
