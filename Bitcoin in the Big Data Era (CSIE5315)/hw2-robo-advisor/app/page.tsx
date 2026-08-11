import { coingeckoFetch } from "@/lib/coingecko";
import type { Entity } from "@/lib/types";
import { MnavDashboard } from "@/components/dashboard/mnav-dashboard";

export default async function Page() {
  const entities = await coingeckoFetch<Entity[]>("/entities/list", {
    entity_type: "company",
    per_page: "250",
  });

  return <MnavDashboard entities={entities} />;
}
