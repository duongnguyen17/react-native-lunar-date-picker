import { PICKER_CONFIG } from '../../example/src/constants';

describe('example weekday configuration', () => {
  it('provides weekday labels Monday through Sunday for each language', () => {
    expect(PICKER_CONFIG.languages.vi?.weekdayNames).toEqual([
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'CN',
    ]);
    expect(PICKER_CONFIG.languages.en?.weekdayNames).toEqual([
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ]);
    expect(PICKER_CONFIG.languages.en?.locale).toBe('en_US');
  });
});
