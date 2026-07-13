/**
 * Startet eingebettetes PostgreSQL für lokale Tests (ohne Docker).
 * Port 5433 — getrennt von einer evtl. lokalen Produkt-/Dev-Instanz.
 */
import { execSync } from "node:child_process";
import fs from "node:fs";
import EmbeddedPostgres from "embedded-postgres";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.join(__dirname, "..");
const dataDir = path.join(serverRoot, ".pg-test-data");

const USER = "ihdina_test";
const PASSWORD = "ihdina_test";
const DB = "ihdina_test";
const PORT = 5433;

export const TEST_DATABASE_URL = `postgresql://${USER}:${PASSWORD}@127.0.0.1:${PORT}/${DB}`;

async function main() {
  const pg = new EmbeddedPostgres({
    databaseDir: dataDir,
    user: USER,
    password: PASSWORD,
    port: PORT,
    persistent: true,
  });

  const clusterReady = fs.existsSync(path.join(dataDir, "PG_VERSION"));
  if (!clusterReady) {
    await pg.initialise();
  }
  await pg.start();

  try {
    await pg.createDatabase(DB);
  } catch {
    // DB existiert bereits
  }

  process.env.DATABASE_URL = TEST_DATABASE_URL;
  process.env.OPENAI_API_KEY = process.env.OPENAI_API_KEY ?? "test-openai-key";
  process.env.ADMIN_API_KEY = process.env.ADMIN_API_KEY ?? "test-admin-key";
  process.env.NODE_ENV = "test";

  console.log(`Embedded Postgres läuft: ${TEST_DATABASE_URL}`);

  execSync("npx prisma db push --skip-generate", { cwd: serverRoot, stdio: "inherit", env: process.env });
  execSync("npx tsx scripts/seedTestDatabase.ts", { cwd: serverRoot, stdio: "inherit", env: process.env });

  // Prozess offen halten, wenn direkt gestartet
  if (process.argv.includes("--keep-alive")) {
    console.log("Halte DB-Prozess offen (Ctrl+C zum Beenden)…");
    await new Promise(() => {});
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
