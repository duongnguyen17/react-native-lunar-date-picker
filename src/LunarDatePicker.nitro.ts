import type { HybridObject } from 'react-native-nitro-modules';
import type { LDP_ConfigParams, LDP_PresentParams } from './type';

export interface LunarDatePicker
  extends HybridObject<{ ios: 'swift'; android: 'kotlin' }> {
  present(params: LDP_PresentParams): void;

  configure(config: LDP_ConfigParams): void;
}
