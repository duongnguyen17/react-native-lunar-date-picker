export interface LDP_Range {
  from: string; // DD/MM/YYYY
  to?: string; // DD/MM/YYYY
}

export type LDP_Mode = 'single' | 'range';

export type LDP_PriceData = {
  /**
   * Ngày theo format DD/MM/YYYY
   */
  date: string;
  /**
   * Giá vé (số nguyên, đơn vị VND hoặc tương đương)
   * Khi hiển thị sẽ được làm tròn đến nghìn: 1000000 → 1.000K
   */
  price: number;
  /**
   * Đánh dấu ngày có giá rẻ nhất để tô màu khác
   */
  isCheapest?: boolean;
};

/**
 * Params để update giá theo tháng (dùng sau khi calendar đã mở)
 */
export type LDP_PriceUpdateParams = {
  /**
   * Danh sách giá cho toàn bộ calendar
   */
  prices: LDP_PriceData[];
};

export type LDP_PresentParams = {
  theme: string;
  language: string;
  title: string;
  mode: LDP_Mode;
  onDone: (result: LDP_Range) => void;
  minimumDate?: string; // DD/MM/YYYY
  maximumDate?: string; // DD/MM/YYYY
  initialValue?: LDP_Range;
  notice?: string;

  /**
   * Dữ liệu giá cho các ngày trong calendar
   * - undefined/không truyền: Price labels sẽ bị ẩn hoàn toàn
   * - [] (mảng rỗng): Price labels hiển thị nhưng trống với ngày không có data
   * - mảng có data: Price labels hiển thị với giá thực tế
   */
  prices?: LDP_PriceData[];

  /**
   * Callback được gọi khi calendar được mở và ổn định hoàn toàn
   * @param startDate - Ngày min (bắt đầu) của toàn bộ calendar (DD/MM/YYYY)
   * @param endDate - Ngày max (kết thúc) của toàn bộ calendar (DD/MM/YYYY)
   *
   * Use case: Dùng để tải prices ban đầu ngay khi calendar mở (có thể tải 1 lần cho cả cục)
   *
   * @example
   * ```typescript
   * onMounted: (startDate, endDate) => {
   *   fetchPrices(startDate, endDate).then(prices => {
   *     updatePrices({ prices });
   *   });
   * }
   * ```
   */
  onMounted?: (startDate: string, endDate: string) => void;

  /**
   * Callback được gọi khi user chọn ngày đi (from date) trong range mode
   * @param startDate - Ngày vừa được chọn làm from date (DD/MM/YYYY)
   * @param endDate - Ngày max (kết thúc) của toàn bộ calendar (DD/MM/YYYY)
   *
   * @example
   * ```typescript
   * onSelectFromDate: (startDate, endDate) => {
   *   fetchPricesForRange(startDate, endDate).then(prices => {
   *     updatePrices({ prices });
   *   });
   * }
   * ```
   */
  onSelectFromDate?: (startDate: string, endDate: string) => void;
};

/**
 * màu hex nhé
 */
export type LDP_CustomStyle = {
  titleColor: string;

  dateLabelColor: string;
  todayLabelColor: string;
  lunarDateLabelColor: string;
  selectedTextColor: string;
  weekendLabelColor: string;
  specialDayLabelColor: string;
  /**
   * Màu giá thông thường
   */
  priceLabelColor: string;
  /**
   * Màu giá rẻ nhất (khi isCheapest = true)
   */
  cheapestPriceLabelColor: string;
  monthLabelColor: string;
  secondColor: string;

  backgroundColor: string;
  weekViewBackgroundColor: string;
  selectedBackgroundColor: string;
  rangeBackgroundColor: string;

  noticeLabelColor: string;
  noticeBackgroundColor: string;

  /**
   * màu của nút submit (nút tick trên header)
   */
  submitButtonColor: string;
};

export type LDP_CustomLanguage = {
  weekdayNames: string[];
  /**
   * dùng cho phần selected hiển thị thứ ngày tháng
   */
  locale: string;
};

export type LDP_ConfigParams = {
  themes: Record<string, LDP_CustomStyle>;
  languages: Record<string, LDP_CustomLanguage>;
  yearRangeOffset: number;
  timeZoneOffset: number;

  /**
   * field này được thêm vào config thay vì present params
   * vì trong 1 app, cần có tính thống nhất cho các picker
   * để tránh dev lạm dụng mỗi chỗ 1 kiểu nên tôi cho vào đây!
   */
  showSubmitButton: boolean;
};
