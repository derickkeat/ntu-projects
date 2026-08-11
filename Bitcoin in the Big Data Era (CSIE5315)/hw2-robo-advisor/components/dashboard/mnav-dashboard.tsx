"use client";

import { useState, useEffect, useCallback } from "react";
import type { Entity, EntityDetail } from "@/lib/types";
import { EntitySearch } from "./entity-search";
import { MnavComparisonTable } from "./mnav-comparison-table";
import { MnavChart } from "./mnav-chart";
import { TotalNavChart } from "./total-nav-chart";

const DEFAULT_ENTITIES = [
  "strategy",
  "metaplanet",
  "bitmine",
  "trump-media-technology-group-corp",
];
const BATCH_DELAY = 300; // ms between fetches to respect rate limits
const STORAGE_KEY = "datco-selected-entities";

function loadSelectedIds(validIds: Set<string>): Set<string> {
  if (typeof window !== "undefined") {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        const ids = JSON.parse(stored) as string[];
        const valid = ids.filter((id) => validIds.has(id));
        if (valid.length > 0) return new Set(valid);
      }
    } catch {
      // ignore
    }
  }
  return new Set(DEFAULT_ENTITIES.filter((id) => validIds.has(id)));
}

export function MnavDashboard({ entities }: { entities: Entity[] }) {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(
    () => loadSelectedIds(new Set(entities.map((e) => e.id)))
  );

  // Persist selection to localStorage
  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(Array.from(selectedIds)));
  }, [selectedIds]);
  const [details, setDetails] = useState<Map<string, EntityDetail>>(new Map());
  const [loading, setLoading] = useState(false);

  const fetchEntity = useCallback(async (id: string) => {
    const res = await fetch(`/api/treasury/entity/${id}`);
    if (!res.ok) return null;
    return (await res.json()) as EntityDetail;
  }, []);

  useEffect(() => {
    const idsToFetch = Array.from(selectedIds).filter(
      (id) => !details.has(id)
    );
    if (idsToFetch.length === 0) {
      setLoading(false);
      return;
    }

    let cancelled = false;
    setLoading(true);

    async function fetchBatch() {
      for (const id of idsToFetch) {
        if (cancelled) break;
        const detail = await fetchEntity(id);
        if (detail && !cancelled) {
          setDetails((prev) => new Map(prev).set(id, detail));
        }
        // Small delay between requests
        if (!cancelled) {
          await new Promise((r) => setTimeout(r, BATCH_DELAY));
        }
      }
      if (!cancelled) setLoading(false);
    }

    fetchBatch();
    return () => {
      cancelled = true;
    };
  }, [selectedIds, details, fetchEntity]);

  function handleToggle(id: string) {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  }

  const loadedEntities = Array.from(selectedIds)
    .map((id) => details.get(id))
    .filter((d): d is EntityDetail => d !== undefined);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4">
        <h1 className="text-2xl font-bold tracking-tight">
          DATco mNAV Dashboard
        </h1>
        <div className="w-80">
          <EntitySearch
            entities={entities}
            selectedIds={selectedIds}
            onToggle={handleToggle}
          />
        </div>
      </div>

      <div className="flex items-center justify-between gap-4 text-sm text-gray-500 dark:text-gray-400">
        <p>
          Showing {loadedEntities.length} of {selectedIds.size} selected
          entities
          {loading && " (loading...)"}
        </p>
        <p className="whitespace-nowrap text-right">
          Data provided by{" "}
          <a
            href="https://www.coingecko.com/"
            target="_blank"
            rel="noopener noreferrer"
            className="underline hover:text-gray-700 dark:hover:text-gray-300"
          >
            CoinGecko
          </a>
        </p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <MnavChart entities={loadedEntities} />
        {!loading && loadedEntities.length > 0 && (
          <TotalNavChart entities={loadedEntities} />
        )}
      </div>
      <MnavComparisonTable entities={loadedEntities} loading={loading} />
    </div>
  );
}
