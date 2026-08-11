import { coingeckoFetch } from "@/lib/coingecko";
import type { HoldingChartResponse } from "@/lib/types";

export async function GET(
  request: Request,
  ctx: RouteContext<"/api/treasury/entity/[entityId]/chart/[coinId]">
) {
  const { entityId, coinId } = await ctx.params;
  const { searchParams } = new URL(request.url);
  const params: Record<string, string> = {};

  const days = searchParams.get("days");
  const includeEmpty = searchParams.get("include_empty_intervals");

  if (days) params.days = days;
  if (includeEmpty) params.include_empty_intervals = includeEmpty;

  const data = await coingeckoFetch<HoldingChartResponse>(
    `/public_treasury/${entityId}/${coinId}/holding_chart`,
    params
  );
  return Response.json(data);
}
