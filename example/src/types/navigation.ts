import type { PickerLanguage } from '../constants';

export type RootStackParamList = {
  Home: undefined;
  FormSheet: {
    currentTheme: 'light' | 'dark';
    selectedLanguage: PickerLanguage;
    selectedTimeZoneOffset?: number;
  };
};
