import { backfillFirstAppOpenAt } from "../services/analyticsIngest.service.js";

async function main() {
  const updated = await backfillFirstAppOpenAt();
  console.log(`[backfillFirstAppOpenAt] rows updated: ${updated}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
