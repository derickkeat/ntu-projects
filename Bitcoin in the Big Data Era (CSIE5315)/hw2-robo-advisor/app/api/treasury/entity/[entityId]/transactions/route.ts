import { coingeckoFetch } from "@/lib/coingecko";
import type { TransactionResponse } from "@/lib/types";

export async function GET(
  request: Request,
  ctx: RouteContext<"/api/treasury/entity/[entityId]/transactions">
) {
  const { entityId } = await ctx.params;
  const { searchParams } = new URL(request.url);
  const params: Record<string, string> = {};

  const perPage = searchParams.get("per_page");
  const page = searchParams.get("page");
  const order = searchParams.get("order");
  const coinIds = searchParams.get("coin_ids");

  if (perPage) params.per_page = perPage;
  if (page) params.page = page;
  if (order) params.order = order;
  if (coinIds) params.coin_ids = coinIds;

  const data = await coingeckoFetch<TransactionResponse>(
    `/public_treasury/${entityId}/transaction_history`,
    params
  );
  return Response.json(data);
}
