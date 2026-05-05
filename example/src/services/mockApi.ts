import type { LDP_PriceData } from '@2security/lunar-date-picker';
import { MOCK_API_CONFIG } from '../constants';
import { formatDate, generateRandomPrice } from '../utils';

/**
 * Giả lập API fetch giá cho một tháng cụ thể
 * @param month - format MM/YYYY (ví dụ: "05/2025")
 */
export const fetchPricesForMonth = async (
  month: string
): Promise<LDP_PriceData[]> => {
  console.log(`🔄 Fetching prices for month: ${month}`);

  // Simulate network delay
  const delay =
    MOCK_API_CONFIG.MIN_DELAY +
    Math.random() * (MOCK_API_CONFIG.MAX_DELAY - MOCK_API_CONFIG.MIN_DELAY);
  await new Promise((resolve) => setTimeout(resolve, delay));

  // Parse MM/YYYY
  const [monthNum, year] = month.split('/').map(Number);

  if (!year || !monthNum) {
    throw new Error(`Invalid month format: ${month}. Expected MM/YYYY`);
  }

  const daysInMonth = new Date(year, monthNum, 0).getDate();
  const numberOfPrices =
    Math.floor(
      Math.random() *
        (MOCK_API_CONFIG.MAX_PRICES_PER_MONTH -
          MOCK_API_CONFIG.MIN_PRICES_PER_MONTH +
          1)
    ) + MOCK_API_CONFIG.MIN_PRICES_PER_MONTH;

  const prices: LDP_PriceData[] = [];

  for (let i = 0; i < numberOfPrices; i++) {
    const day = Math.floor(Math.random() * daysInMonth) + 1;
    const date = formatDate(
      new Date(year, monthNum - 1, day) // tạo Date rồi format sang DD/MM/YYYY
    );

    prices.push({
      date,
      price: generateRandomPrice(),
      isCheapest: false,
    });
  }

  // Đánh dấu giá rẻ nhất trong tháng
  if (prices.length > 0) {
    const cheapestPrice = Math.min(...prices.map((p) => p.price));
    const cheapestIndex = prices.findIndex((p) => p.price === cheapestPrice);
    if (cheapestIndex !== -1) {
      prices[cheapestIndex]!.isCheapest = true;
    }
  }

  console.log(`✅ Loaded ${prices.length} prices for month: ${month}`, prices);
  return prices;
};

/**
 * Giả lập API fetch giá trong một khoảng ngày
 * Dùng cho onMounted và onSelectFromDate callback
 * @param startDate - DD/MM/YYYY
 * @param endDate - DD/MM/YYYY
 */
export const fetchPricesForRange = async (
  startDate: string,
  endDate: string
): Promise<LDP_PriceData[]> => {
  console.log(`🔄 Fetching prices for range: ${startDate} → ${endDate}`);

  const delay =
    MOCK_API_CONFIG.MIN_DELAY +
    Math.random() * (MOCK_API_CONFIG.MAX_DELAY - MOCK_API_CONFIG.MIN_DELAY);
  await new Promise((resolve) => setTimeout(resolve, delay));

  const parseDate = (s: string): Date => {
    const [d, m, y] = s.split('/').map(Number);
    return new Date(y!, m! - 1, d!);
  };

  const start = parseDate(startDate);
  const end = parseDate(endDate);
  const prices: LDP_PriceData[] = [];

  // Sinh giá cho mỗi ngày trong range
  const current = new Date(start);
  while (current <= end) {
    prices.push({
      date: formatDate(current),
      price: generateRandomPrice(),
      isCheapest: false,
    });
    current.setDate(current.getDate() + 1);
  }

  // Đánh dấu cheapest theo từng tháng
  const byMonth: Record<string, LDP_PriceData[]> = {};
  for (const p of prices) {
    const key = p.date.slice(3); // MM/YYYY
    if (!byMonth[key]) byMonth[key] = [];
    byMonth[key]!.push(p);
  }
  for (const monthPrices of Object.values(byMonth)) {
    const minPrice = Math.min(...monthPrices.map((p) => p.price));
    const cheapest = monthPrices.find((p) => p.price === minPrice);
    if (cheapest) cheapest.isCheapest = true;
  }

  console.log(
    `✅ Loaded ${prices.length} prices for range: ${startDate} → ${endDate}`
  );
  return prices;
};
