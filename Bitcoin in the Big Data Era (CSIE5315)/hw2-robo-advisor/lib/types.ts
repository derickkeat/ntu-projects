// Entity from /entities/list
export interface Entity {
  id: string;
  symbol: string;
  name: string;
  country: string;
}

// Company entry from /{entity}/public_treasury/{coin_id}
export interface TreasuryCompany {
  name: string;
  symbol: string;
  country: string;
  total_holdings: number;
  total_entry_value_usd: number;
  total_current_value_usd: number;
  percentage_of_total_supply: number;
}

// Response from /{entity}/public_treasury/{coin_id}
export interface PublicTreasuryResponse {
  total_holdings: number;
  total_value_usd: number;
  market_cap_dominance: number;
  companies: TreasuryCompany[];
}

// Holding within an entity's detail
export interface EntityHolding {
  coin_id: string;
  amount: number;
  percentage_of_total_supply: number;
  amount_per_share: number;
  entity_value_usd_percentage: number;
  current_value_usd: number;
  total_entry_value_usd: number;
  average_entry_value_usd: number;
  unrealized_pnl: number;
  holding_amount_change: Record<string, number>;
  holding_change_percentage: Record<string, number>;
}

// Response from /public_treasury/{entity_id}
export interface EntityDetail {
  name: string;
  id: string;
  type: string;
  symbol: string;
  country: string;
  website_url: string;
  twitter_screen_name: string;
  total_treasury_value_usd: number;
  unrealized_pnl: number | null;
  m_nav: number | null;
  total_asset_value_per_share_usd: number | null;
  holdings: EntityHolding[];
}

// Response from /public_treasury/{entity_id}/{coin_id}/holding_chart
export interface HoldingChartResponse {
  holdings: [number, number][];
  holding_value_in_usd: [number, number][];
}

// Transaction from /public_treasury/{entity_id}/transaction_history
export interface Transaction {
  date: number;
  source_url: string;
  coin_id: string;
  type: "buy" | "sell";
  holding_net_change: number;
  transaction_value_usd: number;
  holding_balance: number;
  average_entry_value_usd: number;
}

export interface TransactionResponse {
  transactions: Transaction[];
}

export interface EntitySummaryResponse {
  summary: string;
  model: string;
  generatedAt: string;
}
