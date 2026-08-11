export function PnlBadge({ value }: { value: number }) {
  const isPositive = value >= 0;
  return (
    <span
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${
        isPositive
          ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
          : "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400"
      }`}
    >
      {isPositive ? "+" : ""}
      {value.toFixed(2)}%
    </span>
  );
}

export function TypeBadge({ type }: { type: "buy" | "sell" }) {
  return (
    <span
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${
        type === "buy"
          ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
          : "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400"
      }`}
    >
      {type === "buy" ? "Buy" : "Sell"}
    </span>
  );
}
