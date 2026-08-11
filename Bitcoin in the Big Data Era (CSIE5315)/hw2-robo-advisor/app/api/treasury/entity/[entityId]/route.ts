import { coingeckoFetch } from "@/lib/coingecko";
import type { EntityDetail } from "@/lib/types";

export async function GET(
  request: Request,
  ctx: RouteContext<"/api/treasury/entity/[entityId]">
) {
  const { entityId } = await ctx.params;
  const { searchParams } = new URL(request.url);
  const params: Record<string, string> = {};

  const holdingAmountChange = searchParams.get("holding_amount_change");
  const holdingChangePercentage = searchParams.get("holding_change_percentage");

  if (holdingAmountChange) params.holding_amount_change = holdingAmountChange;
  if (holdingChangePercentage)
    params.holding_change_percentage = holdingChangePercentage;

  const data = await coingeckoFetch<EntityDetail>(
    `/public_treasury/${entityId}`,
    params
  );
  return Response.json(data);
}
