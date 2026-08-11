export function Skeleton({ className = "" }: { className?: string }) {
  return (
    <div
      className={`animate-pulse rounded-md bg-gray-200 dark:bg-gray-800 ${className}`}
    />
  );
}

export function CardSkeleton() {
  return (
    <div className="rounded-xl border border-gray-200 bg-white p-6 dark:border-gray-800 dark:bg-gray-900">
      <Skeleton className="h-4 w-24" />
      <Skeleton className="mt-2 h-8 w-32" />
    </div>
  );
}

export function TableSkeleton({ rows = 5 }: { rows?: number }) {
  return (
    <div className="space-y-3">
      <Skeleton className="h-10 w-full" />
      {Array.from({ length: rows }).map((_, i) => (
        <Skeleton key={i} className="h-12 w-full" />
      ))}
    </div>
  );
}

export function ChartSkeleton() {
  return <Skeleton className="h-80 w-full rounded-xl" />;
}
