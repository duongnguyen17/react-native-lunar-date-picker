import { NitroModules } from 'react-native-nitro-modules';
import type { LunarDatePicker } from './LunarDatePicker.nitro';
import type { LDP_ConfigParams, LDP_PresentParams } from './type';

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

export * from './type';
