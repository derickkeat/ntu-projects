import { coingeckoFetch } from "@/lib/coingecko";
import type { Entity } from "@/lib/types";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const params: Record<string, string> = {};

  const entityType = searchParams.get("entity_type");
  const perPage = searchParams.get("per_page");
  const page = searchParams.get("page");

  if (entityType) params.entity_type = entityType;
  if (perPage) params.per_page = perPage;
  if (page) params.page = page;

  const data = await coingeckoFetch<Entity[]>("/entities/list", params);
  return Response.json(data);
}
