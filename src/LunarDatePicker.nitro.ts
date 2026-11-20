import type { HybridObject } from 'react-native-nitro-modules';
import type {
  LDP_ConfigParams,
  LDP_LunarDate,
  LDP_PresentParams,
  LDP_PriceUpdateParams,
} from './type';

export interface LunarDatePicker
  extends HybridObject<{ ios: 'swift'; android: 'kotlin' }> {
  present(params: LDP_PresentParams): void;

  configure(config: LDP_ConfigParams): void;

  updatePrices(params: LDP_PriceUpdateParams): void;

  updateMaximumDate(maximumDate: string): void;

  getLunarDate(solarDate: string, timeZoneOffset?: number): LDP_LunarDate;

  getLunarMonth(
    year: number,
    month: number,
    timeZoneOffset?: number
  ): LDP_LunarDate[];
}
