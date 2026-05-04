import type { LDP_ConfigParams } from '@2security/lunar-date-picker';

export const PICKER_CONFIG: LDP_ConfigParams = {
  languages: {
    vi: {
      weekdayNames: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
      locale: 'vi_VN',
    },
    en: {
      weekdayNames: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      locale: 'en_US',
    },
  },
  themes: {
    light: {
      backgroundColor: '#ffffff',
      titleColor: '#000000',
      dateLabelColor: '#030712',
      lunarDateLabelColor: '#6B7280',
      weekendLabelColor: '#E27B00',
      rangeBackgroundColor: '#EFF6FF',
      monthLabelColor: '#030712',
      selectedTextColor: '#FFFFFF',
      specialDayLabelColor: '#ff3300',
      weekViewBackgroundColor: '#F3F4F6',
      selectedBackgroundColor: '#3B82F6',
      secondColor: '#FBAF1A',
      todayLabelColor: '#33cc33',
      submitButtonColor: '#007AFF',
    },
    dark: {
      backgroundColor: '#000000',
      titleColor: '#ffffff',
      dateLabelColor: '#ffffff',
      lunarDateLabelColor: '#ffffff',
      weekendLabelColor: '#ff3300',
      rangeBackgroundColor: '#00264d',
      monthLabelColor: '#ffffff',
      selectedTextColor: '#000000',
      specialDayLabelColor: '#ff3300',
      weekViewBackgroundColor: '#000000',
      selectedBackgroundColor: '#3399ff',
      secondColor: '#FBAF1A',
      todayLabelColor: '#33cc33',
      submitButtonColor: '#007AFF',
    },
  },
  yearRangeOffset: 2,
  timeZoneOffset: 7,
  showSubmitButton: true,
};

export const MOCK_API_CONFIG = {
  MIN_DELAY: 1000,
  MAX_DELAY: 3000,
} as const;

export const UPDATE_INTERVAL = 3000;
