import { GoogleGenAI } from "@google/genai";
import type { EntityDetail, Transaction } from "@/lib/types";

const DEFAULT_MODEL = process.env.GOOGLE_GENAI_MODEL || "gemini-3.1-flash-lite-preview";

let cachedClient: GoogleGenAI | null = null;

function getClient() {
  if (!cachedClient) {
    cachedClient = new GoogleGenAI({});
  }

  return cachedClient;
}

function toCompactUsd(value: number | null) {
  if (value == null) return "N/A";
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    notation: "compact",
    maximumFractionDigits: 2,
  }).format(value);
}

function buildPrompt(entity: EntityDetail, transactions: Transaction[]) {
  const topHoldings = [...entity.holdings]
    .sort((a, b) => b.current_value_usd - a.current_value_usd)
    .slice(0, 5)
    .map((holding) => ({
      coin: holding.coin_id,
      currentValueUsd: holding.current_value_usd,
      entryValueUsd: holding.total_entry_value_usd,
      unrealizedPnl: holding.unrealized_pnl,
      shareOfSupply: holding.percentage_of_total_supply,
      portfolioWeight: holding.entity_value_usd_percentage,
    }));

  const recentTransactions = transactions
    .slice(0, 20)
    .map((tx) => ({
      date: new Date(tx.date).toISOString().split("T")[0],
      coin: tx.coin_id,
      type: tx.type,
      netChange: tx.holding_net_change,
      usdValue: tx.transaction_value_usd,
    }));

  return `
You are a financial analyst assistant focused on public crypto treasury holdings.
Using only the provided data, write a concise summary for an investor audience.

Rules:
- Do not make up facts.
- If a metric is missing, explicitly say it is unavailable.
- Keep it concise: 4 bullet points maximum.
- Include observations on concentration, performance, and recent transaction behavior.
- End with one short "watch item" sentence.

Entity:
- Name: ${entity.name}
- Symbol: ${entity.symbol}
- Country: ${entity.country}
- Total treasury value (USD): ${toCompactUsd(entity.total_treasury_value_usd)}
- mNAV: ${entity.m_nav != null ? `${entity.m_nav.toFixed(2)}x` : "N/A"}
- Unrealized PnL: ${toCompactUsd(entity.unrealized_pnl)}
- Asset value per share: ${toCompactUsd(entity.total_asset_value_per_share_usd)}

Top holdings (largest by current USD value):
${JSON.stringify(topHoldings, null, 2)}

Recent transactions (up to 20 latest):
${JSON.stringify(recentTransactions, null, 2)}
`.trim();
}

export async function summarizeEntityTreasury(
  entity: EntityDetail,
  transactions: Transaction[]
) {
  const model = DEFAULT_MODEL;
  const ai = getClient();
  const response = await ai.models.generateContent({
    model,
    contents: buildPrompt(entity, transactions),
    config: {
      temperature: 0.2,
      maxOutputTokens: 450,
    },
  });

  const summary = response.text?.trim();
  if (!summary) {
    throw new Error("Failed to generate a summary from the model response");
  }

  return { summary, model };
}
