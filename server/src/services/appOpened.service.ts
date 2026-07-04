import { prisma } from "../db/client.js";
import { getOrCreateUser } from "./user.service.js";

export async function recordAppOpened(installId: string): Promise<void> {
  const user = await getOrCreateUser(installId);
  await prisma.appOpenEvent.create({
    data: { userId: user.id },
  });
}
