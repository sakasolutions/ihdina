import { prisma } from "../db/client.js";
import { KNOWN_INTERNAL_INSTALL_IDS } from "../config/internalInstallIds.js";

/** Markiert nur explizit konfigurierte installIds als intern. Idempotent. */
export async function seedInternalUsers(): Promise<number> {
  if (KNOWN_INTERNAL_INSTALL_IDS.length === 0) return 0;

  let updated = 0;
  for (const installId of KNOWN_INTERNAL_INSTALL_IDS) {
    const result = await prisma.user.updateMany({
      where: { installId },
      data: { isInternal: true },
    });
    updated += result.count;
  }
  return updated;
}
