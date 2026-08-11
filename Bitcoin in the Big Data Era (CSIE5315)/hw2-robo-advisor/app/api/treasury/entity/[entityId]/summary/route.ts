import { coingeckoFetch } from "@/lib/coingecko";
import { summarizeEntityTreasury } from "@/lib/genai";
import type {
  EntityDetail,
  EntitySummaryResponse,
  TransactionResponse,
} from "@/lib/types";

export const runtime = "nodejs";

export async function POST(
  _request: Request,
  ctx: { params: Promise<{ entityId: string }> }
) {
  try {
    const { entityId } = await ctx.params;

    const transactionParams = {
      per_page: "100",
      order: "date_desc",
    };

    const [entity, transactionsData] = await Promise.all([
      coingeckoFetch<EntityDetail>(`/public_treasury/${entityId}`),
      coingeckoFetch<TransactionResponse>(
        `/public_treasury/${entityId}/transaction_history`,
        transactionParams
      ),
    ]);

    const { summary, model } = await summarizeEntityTreasury(
      entity,
      transactionsData.transactions
    );

    const payload: EntitySummaryResponse = {
      summary,
      model,
      generatedAt: new Date().toISOString(),
    };

    return Response.json(payload);
  } catch (error) {
    const message =
      error instanceof Error
        ? error.message
        : "Unable to generate AI summary right now";

    return Response.json({ error: message }, { status: 500 });
  }
}
