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
 * Lấy các phần ngày giờ theo múi giờ cố định; bỏ offset để dùng múi giờ thiết bị.
 */
export const getDatePartsInTimeZone = (date: Date, offsetHours?: number) => {
  const useDeviceTimeZone = offsetHours === undefined;
  const adjustedDate = useDeviceTimeZone
    ? date
    : new Date(date.getTime() + offsetHours * 60 * 60 * 1000);

  return {
    day: useDeviceTimeZone ? adjustedDate.getDate() : adjustedDate.getUTCDate(),
    month:
      (useDeviceTimeZone
        ? adjustedDate.getMonth()
        : adjustedDate.getUTCMonth()) + 1,
    year: useDeviceTimeZone
      ? adjustedDate.getFullYear()
      : adjustedDate.getUTCFullYear(),
    hours: useDeviceTimeZone
      ? adjustedDate.getHours()
      : adjustedDate.getUTCHours(),
    minutes: useDeviceTimeZone
      ? adjustedDate.getMinutes()
      : adjustedDate.getUTCMinutes(),
  };
};

export const formatDateInTimeZone = (
  date: Date,
  offsetHours?: number
): string => {
  const parts = getDatePartsInTimeZone(date, offsetHours);
  return `${parts.day.toString().padStart(2, '0')}/${parts.month
    .toString()
    .padStart(2, '0')}/${parts.year}`;
};

export const formatTimeInTimeZone = (
  date: Date,
  offsetHours?: number
): string => {
  const parts = getDatePartsInTimeZone(date, offsetHours);
  return `${parts.hours.toString().padStart(2, '0')}:${parts.minutes
    .toString()
    .padStart(2, '0')}`;
};

export const formatUtcOffset = (offsetHours: number): string => {
  const totalMinutes = Math.round(Math.abs(offsetHours) * 60);
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  const sign = offsetHours < 0 ? '−' : '+';
  return `UTC${sign}${hours.toString().padStart(2, '0')}:${minutes
    .toString()
    .padStart(2, '0')}`;
};

export const addYearsToDateString = (
  dateString: string,
  years: number
): string => {
  const [day = 1, month = 1, year = 1970] = dateString.split('/').map(Number);
  const targetYear = year + years;
  const lastDayOfMonth = new Date(Date.UTC(targetYear, month, 0)).getUTCDate();
  return `${Math.min(day, lastDayOfMonth).toString().padStart(2, '0')}/${month
    .toString()
    .padStart(2, '0')}/${targetYear}`;
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
export const generateSamplePrices = (
  offsetHours?: number
): Array<{
  date: string;
  price: number;
  isCheapest?: boolean;
}> => {
  const today = getDatePartsInTimeZone(new Date(), offsetHours);
  const calendarDate = new Date(
    Date.UTC(today.year, today.month - 1, today.day)
  );
  const prices: Array<{ date: string; price: number; isCheapest?: boolean }> =
    [];

  // Sinh giá cho 60 ngày tới theo ngày lịch của múi giờ đang chọn.
  for (let i = 0; i < 60; i++) {
    const day = new Date(calendarDate);
    day.setUTCDate(calendarDate.getUTCDate() + i);
    const dateString = `${day.getUTCDate().toString().padStart(2, '0')}/${(
      day.getUTCMonth() + 1
    )
      .toString()
      .padStart(2, '0')}/${day.getUTCFullYear()}`;
    prices.push({
      date: dateString,
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
