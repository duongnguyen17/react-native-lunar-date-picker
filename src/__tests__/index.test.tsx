import { getLunarDate, getLunarMonth } from '../index';
import { NitroModules } from 'react-native-nitro-modules';

jest.mock('react-native-nitro-modules', () => {
  const mockHybridObject = {
    present: jest.fn(),
    configure: jest.fn(),
    updatePrices: jest.fn(),
    updateMaximumDate: jest.fn(),
    getLunarDate: jest.fn((dateStr: string) => ({
      day: 11,
      month: 10,
      year: 2026,
      solarDate: dateStr,
    })),
    getLunarMonth: jest.fn((year: number, month: number) => [
      { day: 1, month: 10, year: 2026, solarDate: `${year}-${month}-01` },
      { day: 2, month: 10, year: 2026, solarDate: `${year}-${month}-02` },
    ]),
  };

  return {
    NitroModules: {
      createHybridObject: jest.fn(() => mockHybridObject),
    },
  };
});

describe('LunarDatePicker Public APIs', () => {
  it('getLunarDate formats Date objects correctly', () => {
    const mockHybrid = NitroModules.createHybridObject(
      'LunarDatePicker'
    ) as unknown as { getLunarDate: jest.Mock };
    const testDate = new Date(2026, 10, 20); // Nov 20, 2026
    const res = getLunarDate(testDate, 7);

    expect(mockHybrid.getLunarDate).toHaveBeenCalledWith('2026-11-20', 7);
    expect(res.day).toBe(11);
    expect(res.month).toBe(10);
    expect(res.year).toBe(2026);
  });

  it('getLunarDate handles string date inputs and defaults to UTC+7', () => {
    const mockHybrid = NitroModules.createHybridObject(
      'LunarDatePicker'
    ) as unknown as { getLunarDate: jest.Mock };
    const res = getLunarDate('20/11/2026');

    expect(mockHybrid.getLunarDate).toHaveBeenCalledWith('20/11/2026', 7);
    expect(res.day).toBe(11);
  });

  it('getLunarMonth defaults to UTC+7 when offset is not provided', () => {
    const mockHybrid = NitroModules.createHybridObject(
      'LunarDatePicker'
    ) as unknown as { getLunarMonth: jest.Mock };
    const res = getLunarMonth(2026, 11);

    expect(mockHybrid.getLunarMonth).toHaveBeenCalledWith(2026, 11, 7);
    expect(res.length).toBe(2);
  });
});
