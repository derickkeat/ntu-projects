import type { EntityDetail } from "@/lib/types";

export function EntityHeader({ entity }: { entity: EntityDetail }) {
  return (
    <div className="flex items-center gap-4">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">{entity.name}</h1>
        <div className="mt-1 flex items-center gap-3 text-sm text-gray-500 dark:text-gray-400">
          <span className="font-mono">{entity.symbol}</span>
          <span>{entity.country}</span>
          {entity.website_url && (
            <a
              href={entity.website_url}
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-foreground"
            >
              Website
            </a>
          )}
          {entity.twitter_screen_name && (
            <a
              href={`https://x.com/${entity.twitter_screen_name}`}
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-foreground"
            >
              @{entity.twitter_screen_name}
            </a>
          )}
        </div>
      </div>
    </div>
  );
}
