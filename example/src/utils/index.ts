/**
 * Format Date thành DD/MM/YYYY (format của source mới)
 */
export const formatDate = (date: Date): string => {
  const day = date.getDate().toString().padStart(2, '0');
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const year = date.getFullYear();
  return `${day}/${month}/${year}`;
};

/**
 * Parse DD/MM/YYYY thành Date
 */
export const parseDate = (dateString: string): Date => {
  const [day, month, year] = dateString.split('/');
  return new Date(
    parseInt(year!, 10),
    parseInt(month!, 10) - 1,
    parseInt(day!, 10)
  );
};

/**
 * Sinh số ngẫu nhiên trong khoảng, làm tròn tới nghìn
 */
export const generateRandomPrice = (): number => {
  const base = Math.floor(Math.random() * 3000 + 500); // 500K – 3500K
  return base * 1000;
};

/**
 * Tạo danh sách prices mẫu cho tháng hiện tại và tháng tới
 * Trả về mảng LDP_PriceData với date format DD/MM/YYYY
 */
export const generateSamplePrices = (): Array<{
  date: string;
  price: number;
  isCheapest?: boolean;
}> => {
  const today = new Date();
  const prices: Array<{ date: string; price: number; isCheapest?: boolean }> =
    [];

  // Sinh giá cho 60 ngày tới
  for (let i = 0; i < 60; i++) {
    const d = new Date(today);
    d.setDate(today.getDate() + i);
    prices.push({
      date: formatDate(d),
      price: generateRandomPrice(),
      isCheapest: false,
    });
  }

  // Đánh dấu cheapest trong từng tháng
  const byMonth: Record<string, typeof prices> = {};
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

  return prices;
};
