import { NitroModules } from 'react-native-nitro-modules';
import type { LunarDatePicker } from './LunarDatePicker.nitro';
import type {
  LDP_ConfigParams,
  LDP_LunarDate,
  LDP_PresentParams,
  LDP_PriceUpdateParams,
} from './type';

const LunarDatePickerHybridObject =
  NitroModules.createHybridObject<LunarDatePicker>('LunarDatePicker');

export function pickDate(params: LDP_PresentParams): void {
  LunarDatePickerHybridObject.present(params);
}

/**
 * timeZoneOffset tùy chọn; bỏ qua trường này để dùng múi giờ thiết bị.
 */
export function configure(config: LDP_ConfigParams): void {
  LunarDatePickerHybridObject.configure(config);
}

/**
 * Cập nhật giá cho một tháng cụ thể.
 * Có thể gọi khi calendar đang mở để cập nhật UI ngay lập tức.
 */
export function updatePrices(params: LDP_PriceUpdateParams): void {
  LunarDatePickerHybridObject.updatePrices(params);
}

/**
 * Cập nhật maximumDate khi calendar đang mở.
 * Thường dùng trong callback onSelectFromDate để giới hạn khoảng ngày có thể chọn (ví dụ: tối đa 30 ngày tính từ from date).
 */
export function updateMaximumDate(maximumDate: string): void {
  LunarDatePickerHybridObject.updateMaximumDate(maximumDate);
}

/**
 * Lấy thông tin ngày âm lịch cho một ngày dương lịch.
 * @param date Ngày dương lịch dạng string ("YYYY-MM-DD" hoặc "DD/MM/YYYY") hoặc Date object.
 * @param timeZoneOffset Múi giờ tùy chọn (mặc định là 7 cho UTC+7 - chuẩn Âm lịch Việt Nam).
 */
export function getLunarDate(
  date: string | Date,
  timeZoneOffset: number = 7
): LDP_LunarDate {
  const dateStr =
    date instanceof Date
      ? `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(
          2,
          '0'
        )}-${String(date.getDate()).padStart(2, '0')}`
      : date;
  return LunarDatePickerHybridObject.getLunarDate(dateStr, timeZoneOffset);
}

/**
 * Lấy danh sách ngày âm lịch cho toàn bộ một tháng dương lịch.
 * Rất tối ưu khi render các Calendar hoặc Lịch theo tháng nhờ logic tính toán thông minh (LunarMonthSpanCache).
 * @param year Năm dương lịch (ví dụ: 2026).
 * @param month Tháng dương lịch (1 - 12).
 * @param timeZoneOffset Múi giờ tùy chọn (mặc định là 7 cho UTC+7 - chuẩn Âm lịch Việt Nam).
 */
export function getLunarMonth(
  year: number,
  month: number,
  timeZoneOffset: number = 7
): LDP_LunarDate[] {
  return LunarDatePickerHybridObject.getLunarMonth(year, month, timeZoneOffset);
}

export * from './type';
