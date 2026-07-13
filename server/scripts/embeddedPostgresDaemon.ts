/**
 * Hält eingebettetes PostgreSQL für Tests am Leben (Hintergrund-Prozess).
 */
import fs from "node:fs";
import EmbeddedPostgres from "embedded-postgres";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dataDir = path.join(__dirname, "..", ".pg-test-data");

const USER = "ihdina_test";
const PASSWORD = "ihdina_test";
const DB = "ihdina_test";
const PORT = 5433;

async function main() {
  const pg = new EmbeddedPostgres({
    databaseDir: dataDir,
    user: USER,
    password: PASSWORD,
    port: PORT,
    persistent: true,
  });

  if (!fs.existsSync(path.join(dataDir, "PG_VERSION"))) {
    await pg.initialise();
  }
  await pg.start();

  try {
    await pg.createDatabase(DB);
  } catch {
    // bereits vorhanden
  }

  const shutdown = async () => {
    await pg.stop();
    process.exit(0);
  };
  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);

  console.log(
    JSON.stringify({
      ready: true,
      databaseUrl: `postgresql://${USER}:${PASSWORD}@127.0.0.1:${PORT}/${DB}`,
      port: PORT,
    })
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
