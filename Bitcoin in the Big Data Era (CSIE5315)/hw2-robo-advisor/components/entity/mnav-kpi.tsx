import { Card, CardTitle, CardValue } from "@/components/ui/card";
import { formatCurrency } from "@/lib/utils";
import type { EntityDetail } from "@/lib/types";

export function MnavKpi({ entity }: { entity: EntityDetail }) {
  return (
    <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
      <Card>
        <CardTitle>mNAV</CardTitle>
        <CardValue>
          {entity.m_nav != null ? (
            <span className={entity.m_nav >= 1 ? "text-positive" : "text-negative"}>
              {entity.m_nav.toFixed(2)}x
            </span>
          ) : (
            <span className="text-gray-400">N/A</span>
          )}
        </CardValue>
      </Card>
      <Card>
        <CardTitle>Treasury Value</CardTitle>
        <CardValue>{formatCurrency(entity.total_treasury_value_usd)}</CardValue>
      </Card>
      <Card>
        <CardTitle>Unrealized PnL</CardTitle>
        <CardValue>
          {entity.unrealized_pnl != null ? (
            <span
              className={entity.unrealized_pnl >= 0 ? "text-positive" : "text-negative"}
            >
              {formatCurrency(entity.unrealized_pnl)}
            </span>
          ) : (
            <span className="text-gray-400">N/A</span>
          )}
        </CardValue>
      </Card>
      <Card>
        <CardTitle>Asset Value / Share</CardTitle>
        <CardValue>
          {entity.total_asset_value_per_share_usd != null
            ? formatCurrency(entity.total_asset_value_per_share_usd)
            : <span className="text-gray-400">N/A</span>}
        </CardValue>
      </Card>
    </div>
  );
}
