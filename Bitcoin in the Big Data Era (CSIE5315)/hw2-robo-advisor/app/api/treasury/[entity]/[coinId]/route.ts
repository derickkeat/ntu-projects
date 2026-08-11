import { coingeckoFetch } from "@/lib/coingecko";
import type { PublicTreasuryResponse } from "@/lib/types";

export async function GET(
  request: Request,
  ctx: RouteContext<"/api/treasury/[entity]/[coinId]">
) {
  const { entity, coinId } = await ctx.params;
  const { searchParams } = new URL(request.url);
  const params: Record<string, string> = {};

  const perPage = searchParams.get("per_page");
  const page = searchParams.get("page");
  const order = searchParams.get("order");

  if (perPage) params.per_page = perPage;
  if (page) params.page = page;
  if (order) params.order = order;

  const data = await coingeckoFetch<PublicTreasuryResponse>(
    `/${entity}/public_treasury/${coinId}`,
    params
  );
  return Response.json(data);
}
