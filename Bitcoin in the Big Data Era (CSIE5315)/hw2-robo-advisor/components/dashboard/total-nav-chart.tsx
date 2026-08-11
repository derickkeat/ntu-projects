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
import type { EntityDetail, HoldingChartResponse } from "@/lib/types";
import { Skeleton } from "@/components/ui/skeleton";

interface DayEntry {
  date: string;
  timestamp: number;
  total_usd: number;
}

const DAYS_OPTIONS = [30, 90, 180, 365] as const;
const FETCH_DELAY = 300;

export function TotalNavChart({ entities }: { entities: EntityDetail[] }) {
  const [days, setDays] = useState<number>(90);
  const [data, setData] = useState<DayEntry[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (entities.length === 0) return;

    let cancelled = false;
    setLoading(true);

    async function fetchAll() {
      const allSeries: [number, number][][] = [];

      for (const entity of entities) {
        for (const holding of entity.holdings) {
          if (cancelled) return;
          try {
            const res = await fetch(
              `/api/treasury/entity/${entity.id}/chart/${holding.coin_id}?days=${days}&include_empty_intervals=true`
            );
            if (res.ok) {
              const chart = (await res.json()) as HoldingChartResponse;
              allSeries.push(chart.holding_value_in_usd);
            }
          } catch {
            // skip failed fetches
          }
          await new Promise((r) => setTimeout(r, FETCH_DELAY));
        }
      }

      if (cancelled) return;

      // Collect all unique dates across every series
      const allDates = new Set<string>();
      const seriesByDay: Map<string, number>[] = [];

      for (const series of allSeries) {
        const map = new Map<string, number>();
        for (const [timestamp, usd] of series) {
          const key = new Date(timestamp).toISOString().split("T")[0];
          map.set(key, usd);
          allDates.add(key);
        }
        seriesByDay.push(map);
      }

      // Generate a complete date range so every day is represented
      const sortedDates: string[] = [];
      const now = new Date();
      const start = new Date(now);
      start.setDate(start.getDate() - days);
      for (let d = new Date(start); d <= now; d.setDate(d.getDate() + 1)) {
        sortedDates.push(d.toISOString().split("T")[0]);
      }

      // For each date, sum values across all series using forward-fill
      // (if a series has no data for a date, carry forward the last known value)
      const entries: DayEntry[] = [];
      const lastKnown: number[] = new Array(seriesByDay.length).fill(0);

      for (const date of sortedDates) {
        let total = 0;
        for (let i = 0; i < seriesByDay.length; i++) {
          const val = seriesByDay[i].get(date);
          if (val !== undefined) {
            lastKnown[i] = val;
          }
          total += lastKnown[i];
        }
        entries.push({
          date,
          timestamp: new Date(date).getTime(),
          total_usd: total,
        });
      }

      const firstNonZero = entries.findIndex((e) => e.total_usd > 0);
      setData(firstNonZero > 0 ? entries.slice(firstNonZero) : entries);
      setLoading(false);
    }

    fetchAll();
    return () => {
      cancelled = true;
    };
  }, [entities, days]);

  return (
    <div className="rounded-xl border border-gray-200 bg-white p-6 dark:border-gray-800 dark:bg-gray-900">
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
          Total Treasury NAV Over Time (Selected Companies)
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
            <defs>
              <linearGradient id="navGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="var(--color-btc)" stopOpacity={0.3} />
                <stop offset="100%" stopColor="var(--color-btc)" stopOpacity={0.05} />
              </linearGradient>
            </defs>
            <XAxis
              dataKey="date"
              fontSize={11}
              tickFormatter={(v) => formatDate(new Date(v).getTime())}
              interval="preserveStartEnd"
            />
            <YAxis
              fontSize={11}
              tickFormatter={(v) => formatCurrency(v)}
              width={80}
            />
            <Tooltip
              labelFormatter={(v) => formatDate(new Date(v).getTime())}
              formatter={(value) => [formatCurrency(Number(value)), "Total NAV"]}
              contentStyle={{
                backgroundColor: "var(--background)",
                border: "1px solid var(--foreground)",
                borderRadius: "8px",
                fontSize: "12px",
              }}
            />
            <Area
              type="monotone"
              dataKey="total_usd"
              stroke="var(--color-btc)"
              strokeWidth={2}
              fill="url(#navGradient)"
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
