"use client";

import { useState, useEffect } from "react";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { formatCurrency, formatDate } from "@/lib/utils";
import type { HoldingChartResponse } from "@/lib/types";
import { Skeleton } from "@/components/ui/skeleton";

interface ChartPoint {
  date: string;
  timestamp: number;
  holdings: number;
  value_usd: number;
}

const DAYS_OPTIONS = [30, 90, 180, 365, 730] as const;

export function HoldingChart({
  entityId,
  coinId,
}: {
  entityId: string;
  coinId: string;
}) {
  const [days, setDays] = useState<number>(90);
  const [data, setData] = useState<ChartPoint[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);

    async function fetchChart() {
      try {
        const res = await fetch(
          `/api/treasury/entity/${entityId}/chart/${coinId}?days=${days}&include_empty_intervals=true`
        );
        if (!res.ok) throw new Error();
        const chart = (await res.json()) as HoldingChartResponse;

        if (cancelled) return;

        const holdingsByDay = new Map<string, number>();
        for (const [t, v] of chart.holdings) {
          holdingsByDay.set(new Date(t).toISOString().split("T")[0], v);
        }
        const valueByDay = new Map<string, number>();
        for (const [t, v] of chart.holding_value_in_usd) {
          valueByDay.set(new Date(t).toISOString().split("T")[0], v);
        }

        // Generate a complete date range so every day is represented
        const sortedDates: string[] = [];
        const now = new Date();
        const start = new Date(now);
        start.setDate(start.getDate() - days);
        for (let d = new Date(start); d <= now; d.setDate(d.getDate() + 1)) {
          sortedDates.push(d.toISOString().split("T")[0]);
        }

        // Forward-fill missing days
        let lastHoldings = 0;
        let lastUsd = 0;
        const points: ChartPoint[] = sortedDates.map((date) => {
          const h = holdingsByDay.get(date);
          const u = valueByDay.get(date);
          if (h !== undefined) lastHoldings = h;
          if (u !== undefined) lastUsd = u;
          return {
            date,
            timestamp: new Date(date).getTime(),
            holdings: lastHoldings,
            value_usd: lastUsd,
          };
        });

        // Trim leading zero-value days
        const firstNonZero = points.findIndex(
          (p) => p.holdings > 0 || p.value_usd > 0
        );
        setData(firstNonZero > 0 ? points.slice(firstNonZero) : points);
      } catch {
        setData([]);
      }
      if (!cancelled) setLoading(false);
    }

    fetchChart();
    return () => {
      cancelled = true;
    };
  }, [entityId, coinId, days]);

  return (
    <div className="rounded-xl border border-gray-200 bg-white p-6 dark:border-gray-800 dark:bg-gray-900">
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
          {coinId.charAt(0).toUpperCase() + coinId.slice(1)} Holdings Over Time
        </h3>
        <div className="flex gap-1">
          {DAYS_OPTIONS.map((d) => (
            <button
              key={d}
              onClick={() => setDays(d)}
              className={`rounded-md px-2.5 py-1 text-xs font-medium transition-colors ${
                days === d
                  ? "bg-foreground text-background"
                  : "text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800"
              }`}
            >
              {d}d
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <Skeleton className="h-72 w-full" />
      ) : data.length > 0 ? (
        <ResponsiveContainer width="100%" height={288}>
          <AreaChart data={data}>
            <XAxis
              dataKey="date"
              fontSize={11}
              tickFormatter={(v) => formatDate(new Date(v).getTime())}
              interval="preserveStartEnd"
            />
            <YAxis
              yAxisId="usd"
              orientation="right"
              fontSize={11}
              tickFormatter={(v) => formatCurrency(v)}
              width={80}
            />
            <YAxis
              yAxisId="amount"
              orientation="left"
              fontSize={11}
              width={70}
            />
            <Tooltip
              labelFormatter={(v) => formatDate(new Date(v).getTime())}
              formatter={(value, name) => [
                name === "value_usd"
                  ? formatCurrency(Number(value))
                  : Number(value).toLocaleString(),
                name === "value_usd" ? "USD Value" : "Holdings",
              ]}
              contentStyle={{
                backgroundColor: "var(--background)",
                border: "1px solid var(--foreground)",
                borderRadius: "8px",
                fontSize: "12px",
              }}
            />
            <Area
              yAxisId="amount"
              type="stepAfter"
              dataKey="holdings"
              stroke="var(--color-btc)"
              fill="var(--color-btc)"
              fillOpacity={0.15}
              strokeWidth={2}
            />
            <Area
              yAxisId="usd"
              type="monotone"
              dataKey="value_usd"
              stroke="var(--color-eth)"
              fill="var(--color-eth)"
              fillOpacity={0.1}
              strokeWidth={2}
            />
          </AreaChart>
        </ResponsiveContainer>
      ) : (
        <p className="py-12 text-center text-sm text-gray-400">
          No chart data available
        </p>
      )}
    </div>
  );
}
