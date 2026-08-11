"use client";

import { useState } from "react";
import type { Entity } from "@/lib/types";

export function EntitySearch({
  entities,
  selectedIds,
  onToggle,
}: {
  entities: Entity[];
  selectedIds: Set<string>;
  onToggle: (id: string) => void;
}) {
  const [query, setQuery] = useState("");
  const [focused, setFocused] = useState(false);

  const selected = entities.filter((e) => selectedIds.has(e.id));

  const filtered = query
    ? entities.filter(
        (e) =>
          e.name.toLowerCase().includes(query.toLowerCase()) ||
          e.symbol.toLowerCase().includes(query.toLowerCase())
      )
    : [];

  const showDropdown = focused && (query ? filtered.length > 0 : selected.length > 0);
  const dropdownItems = query ? filtered.slice(0, 20) : selected;

  return (
    <div className="relative" onBlur={(e) => {
      if (!e.currentTarget.contains(e.relatedTarget)) setFocused(false);
    }}>
      <input
        type="text"
        placeholder="Search entities to add/remove"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        onFocus={() => setFocused(true)}
        className="w-full rounded-lg border border-gray-200 bg-white px-4 py-2 text-sm outline-none focus:border-gray-400 dark:border-gray-700 dark:bg-gray-900 dark:focus:border-gray-500"
      />
      {showDropdown && (
        <ul
          onMouseDown={(e) => e.preventDefault()}
          className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border border-gray-200 bg-white shadow-lg dark:border-gray-700 dark:bg-gray-900"
        >
          {!query && (
            <li className="px-4 py-1.5 text-xs font-medium text-gray-400">
              Selected ({selected.length})
            </li>
          )}
          {dropdownItems.map((e) => (
            <li key={e.id}>
              <button
                onClick={() => {
                  onToggle(e.id);
                  if (query) setQuery("");
                }}
                className="flex w-full items-center justify-between px-4 py-2 text-left text-sm hover:bg-gray-50 dark:hover:bg-gray-800"
              >
                <span>
                  {e.name}{" "}
                  <span className="text-gray-400">{e.symbol}</span>
                </span>
                {selectedIds.has(e.id) && (
                  <span className="text-xs text-green-500">selected</span>
                )}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
