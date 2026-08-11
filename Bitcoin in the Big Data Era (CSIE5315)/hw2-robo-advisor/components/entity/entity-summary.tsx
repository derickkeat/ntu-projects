"use client";

import { useState } from "react";
import type { EntitySummaryResponse } from "@/lib/types";

export function EntitySummary({ entityId }: { entityId: string }) {
  const [summary, setSummary] = useState<string>("");
  const [model, setModel] = useState<string>("");
  const [generatedAt, setGeneratedAt] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>("");

  async function generateSummary() {
    setLoading(true);
    setError("");

    try {
      const res = await fetch(`/api/treasury/entity/${entityId}/summary`, {
        method: "POST",
      });

      const data = (await res.json()) as
        | EntitySummaryResponse
        | { error?: string };

      if (!res.ok) {
        throw new Error(
          "error" in data ? data.error : "Failed to generate entity summary"
        );
      }

      if (!("summary" in data) || !("model" in data) || !("generatedAt" in data)) {
        throw new Error("Summary response was missing expected fields");
      }

      setSummary(data.summary);
      setModel(data.model);
      setGeneratedAt(data.generatedAt);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to generate summary");
    } finally {
      setLoading(false);
    }
  }

  return (
    <section className="rounded-xl border border-gray-200 bg-white p-6 dark:border-gray-800 dark:bg-gray-900">
      <div className="mb-3 flex items-center justify-between gap-2">
        <h2 className="text-lg font-semibold">AI Summary</h2>
        <button
          onClick={generateSummary}
          disabled={loading}
          className="rounded-md bg-foreground px-3 py-1.5 text-sm font-medium text-background transition-opacity hover:opacity-85 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {loading ? "Generating..." : summary ? "Regenerate" : "Generate summary"}
        </button>
      </div>

      {!summary && !loading && !error && (
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Generate a concise AI-written snapshot from current treasury holdings
          and recent transactions.
        </p>
      )}

      {loading && (
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Analyzing holdings, performance, and transaction flow...
        </p>
      )}

      {error && <p className="text-sm text-negative">{error}</p>}

      {summary && (
        <div className="space-y-3">
          <p className="whitespace-pre-wrap text-sm leading-6">{summary}</p>
          <p className="text-xs text-gray-400">
            Generated {new Date(generatedAt).toLocaleString()} with {model}
          </p>
        </div>
      )}
    </section>
  );
}
