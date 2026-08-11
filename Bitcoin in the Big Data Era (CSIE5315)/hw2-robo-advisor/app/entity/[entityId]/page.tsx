import { coingeckoFetch } from "@/lib/coingecko";
import type { EntityDetail } from "@/lib/types";
import { EntityHeader } from "@/components/entity/entity-header";
import { MnavKpi } from "@/components/entity/mnav-kpi";
import { EntitySummary } from "@/components/entity/entity-summary";
import { HoldingsTable } from "@/components/entity/holdings-table";
import { HoldingChart } from "@/components/entity/holding-chart";
import { TransactionTable } from "@/components/entity/transaction-table";

export default async function Page(
  props: PageProps<"/entity/[entityId]">
) {
  const { entityId } = await props.params;

  const entity = await coingeckoFetch<EntityDetail>(
    `/public_treasury/${entityId}`
  );

  return (
    <div className="space-y-6">
      <EntityHeader entity={entity} />
      <MnavKpi entity={entity} />
      <EntitySummary entityId={entityId} />

      <div>
        <h2 className="mb-3 text-lg font-semibold">Holdings</h2>
        <HoldingsTable holdings={entity.holdings} />
      </div>

      {entity.holdings.map((h) => (
        <HoldingChart key={h.coin_id} entityId={entityId} coinId={h.coin_id} />
      ))}

      <div>
        <h2 className="mb-3 text-lg font-semibold">Transaction History</h2>
        <TransactionTable entityId={entityId} />
      </div>
    </div>
  );
}
