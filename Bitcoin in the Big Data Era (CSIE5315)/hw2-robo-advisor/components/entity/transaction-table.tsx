"use client";

import { useState, useEffect } from "react";
import { formatCurrency, formatDate } from "@/lib/utils";
import { TypeBadge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import type { Transaction, TransactionResponse } from "@/lib/types";

const PAGE_SIZE = 20;

export function TransactionTable({ entityId }: { entityId: string }) {
  const [allTransactions, setAllTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);

    async function fetchTx() {
      try {
        const res = await fetch(
          `/api/treasury/entity/${entityId}/transactions?per_page=250`
        );
        if (!res.ok) throw new Error();
        const data = (await res.json()) as TransactionResponse;
        if (!cancelled) {
          setAllTransactions(data.transactions);
        }
      } catch {
        if (!cancelled) setAllTransactions([]);
      }
      if (!cancelled) setLoading(false);
    }

    fetchTx();
    return () => {
      cancelled = true;
    };
  }, [entityId]);

  if (loading) return <Skeleton className="h-64 w-full rounded-xl" />;

  if (allTransactions.length === 0) {
    return (
      <p className="py-8 text-center text-sm text-gray-400">
        No transaction history available
      </p>
    );
  }

  const totalPages = Math.ceil(allTransactions.length / PAGE_SIZE);
  const transactions = allTransactions.slice(
    (page - 1) * PAGE_SIZE,
    page * PAGE_SIZE
  );

  return (
    <div>
      <div className="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-800">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-800 dark:bg-gray-900">
            <tr>
              <th className="px-4 py-3 font-medium">Date</th>
              <th className="px-4 py-3 font-medium">Coin</th>
              <th className="px-4 py-3 font-medium">Type</th>
              <th className="px-4 py-3 text-right font-medium">Net Change</th>
              <th className="px-4 py-3 text-right font-medium">Value (USD)</th>
              <th className="px-4 py-3 text-right font-medium">Balance After</th>
              <th className="px-4 py-3 font-medium">Source</th>
            </tr>
          </thead>
          <tbody>
            {transactions.map((tx, i) => (
              <tr
                key={`${tx.date}-${tx.coin_id}-${i}`}
                className="border-b border-gray-100 dark:border-gray-800"
              >
                <td className="px-4 py-3">{formatDate(tx.date)}</td>
                <td className="px-4 py-3 capitalize">{tx.coin_id}</td>
                <td className="px-4 py-3">
                  <TypeBadge type={tx.type} />
                </td>
                <td className="px-4 py-3 text-right font-mono">
                  <span
                    className={
                      tx.holding_net_change >= 0
                        ? "text-positive"
                        : "text-negative"
                    }
                  >
                    {tx.holding_net_change >= 0 ? "+" : ""}
                    {tx.holding_net_change.toLocaleString()}
                  </span>
                </td>
                <td className="px-4 py-3 text-right font-mono">
                  {formatCurrency(tx.transaction_value_usd)}
                </td>
                <td className="px-4 py-3 text-right font-mono">
                  {tx.holding_balance.toLocaleString()}
                </td>
                <td className="px-4 py-3">
                  {tx.source_url && (
                    <a
                      href={tx.source_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-gray-400 hover:text-foreground"
                    >
                      Link
                    </a>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="mt-3 flex items-center justify-between">
        <button
          onClick={() => setPage((p) => Math.max(1, p - 1))}
          disabled={page === 1}
          className="rounded-md px-3 py-1.5 text-sm font-medium text-gray-500 hover:bg-gray-100 disabled:opacity-30 dark:hover:bg-gray-800"
        >
          Previous
        </button>
        <span className="text-sm text-gray-400">
          Page {page} of {totalPages}
        </span>
        <button
          onClick={() => setPage((p) => p + 1)}
          disabled={page >= totalPages}
          className="rounded-md px-3 py-1.5 text-sm font-medium text-gray-500 hover:bg-gray-100 disabled:opacity-30 dark:hover:bg-gray-800"
        >
          Next
        </button>
      </div>
    </div>
  );
}
