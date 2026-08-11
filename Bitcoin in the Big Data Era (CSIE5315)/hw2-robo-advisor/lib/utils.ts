export function formatCurrency(value: number): string {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    notation: value >= 1_000_000_000 ? "compact" : "standard",
    maximumFractionDigits: value >= 1_000_000 ? 2 : 0,
  }).format(value);
}

export function formatNumber(value: number): string {
  return new Intl.NumberFormat("en-US", {
    notation: value >= 1_000_000 ? "compact" : "standard",
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatPercent(value: number): string {
  return new Intl.NumberFormat("en-US", {
    style: "percent",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value / 100);
}

export function formatDate(timestamp: number): string {
  return new Date(timestamp).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
