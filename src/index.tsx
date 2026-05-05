import { NitroModules } from 'react-native-nitro-modules';
import type { LunarDatePicker } from './LunarDatePicker.nitro';
import type {
  LDP_ConfigParams,
  LDP_PresentParams,
  LDP_PriceUpdateParams,
} from './type';

const LunarDatePickerHybridObject =
  NitroModules.createHybridObject<LunarDatePicker>('LunarDatePicker');

export function pickDate(params: LDP_PresentParams): void {
  LunarDatePickerHybridObject.present(params);
}

/**
 * bắt buộc phải config nhé
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

export * from './type';
