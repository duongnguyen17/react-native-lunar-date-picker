export interface LDP_Range {
  from: string; // DD/MM/YYYY
  to?: string; // DD/MM/YYYY
}

export type LDP_Mode = 'single' | 'range';

export type LDP_PresentParams = {
  theme: string;
  language: string;
  title: string;
  mode: LDP_Mode;
  onDone: (result: LDP_Range) => void;
  minimumDate?: string; // DD/MM/YYYY
  maximumDate?: string; // DD/MM/YYYY
  initialValue?: LDP_Range;
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
  monthLabelColor: string;
  secondColor: string;

  backgroundColor: string;
  weekViewBackgroundColor: string;
  selectedBackgroundColor: string;
  rangeBackgroundColor: string;

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
