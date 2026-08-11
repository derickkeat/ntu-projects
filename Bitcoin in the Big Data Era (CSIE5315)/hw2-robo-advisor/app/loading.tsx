import { CardSkeleton, TableSkeleton, ChartSkeleton } from "@/components/ui/skeleton";

export default function Loading() {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <CardSkeleton />
        <CardSkeleton />
        <CardSkeleton />
        <CardSkeleton />
      </div>
      <ChartSkeleton />
      <TableSkeleton rows={10} />
    </div>
  );
}
