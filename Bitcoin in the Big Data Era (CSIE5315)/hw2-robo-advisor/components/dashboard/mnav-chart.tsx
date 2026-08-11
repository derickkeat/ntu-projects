"use client";

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  ReferenceLine,
  Cell,
} from "recharts";
import type { EntityDetail } from "@/lib/types";

export function MnavChart({ entities }: { entities: EntityDetail[] }) {
  const data = [...entities]
    .filter((e) => e.m_nav != null)
    .sort((a, b) => b.m_nav! - a.m_nav!)
    .slice(0, 20)
    .map((e) => ({
      name: e.name,
      m_nav: e.m_nav!,
    }));

  if (data.length === 0) return null;

  return (
    <div className="rounded-xl border border-gray-200 bg-white p-6 dark:border-gray-800 dark:bg-gray-900">
      <h3 className="mb-4 text-sm font-medium text-gray-500 dark:text-gray-400">
        mNAV Comparison (1.0x = fair value)
      </h3>
      <ResponsiveContainer width="100%" height={Math.max(300, data.length * 32)}>
        <BarChart data={data} layout="vertical" margin={{ left: 120 }}>
          <XAxis type="number" domain={[0, "auto"]} fontSize={12} />
          <YAxis
            type="category"
            dataKey="name"
            width={120}
            fontSize={11}
            tickLine={false}
          />
          <Tooltip
            formatter={(value) => [`${Number(value).toFixed(2)}x`, "mNAV"]}
            contentStyle={{
              backgroundColor: "var(--background)",
              border: "1px solid var(--foreground)",
              borderRadius: "8px",
              fontSize: "12px",
            }}
          />
          <ReferenceLine x={1} stroke="var(--foreground)" strokeDasharray="3 3" />
          <Bar dataKey="m_nav" radius={[0, 4, 4, 0]}>
            {data.map((entry) => (
              <Cell
                key={entry.name}
                fill={
                  entry.m_nav >= 1
                    ? "var(--color-positive)"
                    : "var(--color-negative)"
                }
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
