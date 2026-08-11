const BASE_URL = process.env.COINGECKO_BASE_URL || "https://api.coingecko.com/api/v3";
const HEADER_KEY = process.env.COINGECKO_HEADER_KEY || "x-cg-demo-api-key";

export async function coingeckoFetch<T>(
  path: string,
  params?: Record<string, string>
): Promise<T> {
  const apiKey = process.env.COINGECKO_API_KEY;
  if (!apiKey) {
    throw new Error("COINGECKO_API_KEY environment variable is not set");
  }

  const url = new URL(`${BASE_URL}${path}`);
  if (params) {
    for (const [key, value] of Object.entries(params)) {
      if (value) url.searchParams.set(key, value);
    }
  }

  const res = await fetch(url.toString(), {
    headers: { [HEADER_KEY]: apiKey },
  });

  if (!res.ok) {
    throw new Error(`CoinGecko API error: ${res.status} ${res.statusText}`);
  }

  return res.json() as Promise<T>;
}
