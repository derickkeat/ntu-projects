export function Card({
  children,
  className = "",
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`rounded-xl border border-gray-200 bg-white p-6 dark:border-gray-800 dark:bg-gray-900 ${className}`}
    >
      {children}
    </div>
  );
}

export function CardTitle({ children }: { children: React.ReactNode }) {
  return (
    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
      {children}
    </h3>
  );
}

export function CardValue({ children }: { children: React.ReactNode }) {
  return (
    <p className="mt-1 text-2xl font-semibold tracking-tight">{children}</p>
  );
}
