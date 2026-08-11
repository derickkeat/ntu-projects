"use client";

import { formatCurrency, formatNumber } from "@/lib/utils";
import type { EntityHolding } from "@/lib/types";

export function HoldingsTable({ holdings }: { holdings: EntityHolding[] }) {
  return (
    <div className="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-800">
      <table className="w-full text-left text-sm">
        <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-800 dark:bg-gray-900">
          <tr>
            <th className="px-4 py-3 font-medium">Coin</th>
            <th className="px-4 py-3 text-right font-medium">Amount</th>
            <th className="px-4 py-3 text-right font-medium">% of Supply</th>
            <th className="px-4 py-3 text-right font-medium">Current Value</th>
            <th className="px-4 py-3 text-right font-medium">Entry Value</th>
            <th className="px-4 py-3 text-right font-medium">Avg Entry Price</th>
            <th className="px-4 py-3 text-right font-medium">Unrealized PnL</th>
          </tr>
        </thead>
        <tbody>
          {holdings.map((h) => (
            <tr
              key={h.coin_id}
              className="border-b border-gray-100 dark:border-gray-800"
            >
              <td className="px-4 py-3 font-medium capitalize">{h.coin_id}</td>
              <td className="px-4 py-3 text-right font-mono">
                {formatNumber(h.amount)}
              </td>
              <td className="px-4 py-3 text-right font-mono">
                {h.percentage_of_total_supply.toFixed(3)}%
              </td>
              <td className="px-4 py-3 text-right font-mono">
                {formatCurrency(h.current_value_usd)}
              </td>
              <td className="px-4 py-3 text-right font-mono">
                {h.total_entry_value_usd != null ? formatCurrency(h.total_entry_value_usd) : "N/A"}
              </td>
              <td className="px-4 py-3 text-right font-mono">
                {h.average_entry_value_usd != null ? formatCurrency(h.average_entry_value_usd) : "N/A"}
              </td>
              <td className="px-4 py-3 text-right font-mono">
                {h.unrealized_pnl != null ? (
                  <span
                    className={
                      h.unrealized_pnl >= 0 ? "text-positive" : "text-negative"
                    }
                  >
                    {formatCurrency(h.unrealized_pnl)}
                  </span>
                ) : (
                  "N/A"
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
