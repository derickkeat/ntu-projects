"use client";

import { useState } from "react";
import Link from "next/link";
import { formatCurrency } from "@/lib/utils";
import type { EntityDetail } from "@/lib/types";

type SortKey = "name" | "m_nav" | "total_treasury_value_usd" | "unrealized_pnl";
type SortDir = "asc" | "desc";

export function MnavComparisonTable({
  entities,
  loading,
}: {
  entities: EntityDetail[];
  loading: boolean;
}) {
  const [sortKey, setSortKey] = useState<SortKey>("m_nav");
  const [sortDir, setSortDir] = useState<SortDir>("desc");

  const sorted = [...entities].sort((a, b) => {
    const aVal = sortKey === "name" ? a.name : (a[sortKey] ?? -Infinity);
    const bVal = sortKey === "name" ? b.name : (b[sortKey] ?? -Infinity);
    if (aVal < bVal) return sortDir === "asc" ? -1 : 1;
    if (aVal > bVal) return sortDir === "asc" ? 1 : -1;
    return 0;
  });

  function toggleSort(key: SortKey) {
    if (sortKey === key) {
      setSortDir(sortDir === "asc" ? "desc" : "asc");
    } else {
      setSortKey(key);
      setSortDir("desc");
    }
  }

  const arrow = (key: SortKey) =>
    sortKey === key ? (sortDir === "asc" ? " ↑" : " ↓") : "";

  return (
    <div className="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-800">
      <table className="w-full text-left text-sm">
        <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-800 dark:bg-gray-900">
          <tr>
            <th className="px-4 py-3 font-medium">#</th>
            <th
              className="cursor-pointer px-4 py-3 font-medium"
              onClick={() => toggleSort("name")}
            >
              Company{arrow("name")}
            </th>
            <th className="px-4 py-3 font-medium">Symbol</th>
            <th
              className="cursor-pointer px-4 py-3 text-right font-medium"
              onClick={() => toggleSort("m_nav")}
            >
              mNAV{arrow("m_nav")}
            </th>
            <th
              className="cursor-pointer px-4 py-3 text-right font-medium"
              onClick={() => toggleSort("total_treasury_value_usd")}
            >
              Treasury Value{arrow("total_treasury_value_usd")}
            </th>
            <th
              className="cursor-pointer px-4 py-3 text-right font-medium"
              onClick={() => toggleSort("unrealized_pnl")}
            >
              Unrealized PnL{arrow("unrealized_pnl")}
            </th>
            <th className="px-4 py-3 text-right font-medium">
              Value/Share
            </th>
          </tr>
        </thead>
        <tbody>
          {sorted.map((entity, i) => (
            <tr
              key={entity.id}
              className="border-b border-gray-100 hover:bg-gray-50 dark:border-gray-800 dark:hover:bg-gray-800/50"
            >
              <td className="px-4 py-3 text-gray-500">{i + 1}</td>
              <td className="px-4 py-3 font-medium">
                <Link
                  href={`/entity/${entity.id}`}
                  className="hover:underline"
                >
                  {entity.name}
                </Link>
              </td>
              <td className="px-4 py-3 font-mono text-xs">{entity.symbol}</td>
              <td className="px-4 py-3 text-right font-mono">
                {entity.m_nav != null ? (
                  <span
                    className={
                      entity.m_nav >= 1 ? "text-positive" : "text-negative"
                    }
                  >
                    {entity.m_nav.toFixed(2)}x
                  </span>
                ) : (
                  <span className="text-gray-400">N/A</span>
                )}
              </td>
              <td className="px-4 py-3 text-right font-mono">
                {formatCurrency(entity.total_treasury_value_usd)}
              </td>
              <td className="px-4 py-3 text-right font-mono">
                {entity.unrealized_pnl != null ? (
                  <span
                    className={
                      entity.unrealized_pnl >= 0
                        ? "text-positive"
                        : "text-negative"
                    }
                  >
                    {formatCurrency(entity.unrealized_pnl)}
                  </span>
                ) : (
                  <span className="text-gray-400">N/A</span>
                )}
              </td>
              <td className="px-4 py-3 text-right font-mono">
                {entity.total_asset_value_per_share_usd != null
                  ? formatCurrency(entity.total_asset_value_per_share_usd)
                  : <span className="text-gray-400">N/A</span>}
              </td>
            </tr>
          ))}
          {loading && (
            <tr>
              <td colSpan={7} className="px-4 py-3 text-center text-gray-400">
                Loading more entities...
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
