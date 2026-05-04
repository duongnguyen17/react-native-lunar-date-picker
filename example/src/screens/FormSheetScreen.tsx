import type { LDP_Range } from '@2security/lunar-date-picker';
import { pickDate } from '@2security/lunar-date-picker';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import { StyleSheet, Text } from 'react-native';
import { ButtonGroup } from '../components/ButtonGroup';
import type { DateRange } from '../types';
import type { RootStackParamList } from '../types/navigation';

export type FormSheetScreenProps = NativeStackScreenProps<
  RootStackParamList,
  'FormSheet'
>;

export function FormSheetScreen({ route }: FormSheetScreenProps) {
  const { currentTheme } = route.params;
  const [range, setRange] = useState<DateRange | undefined>(undefined);

  const openRangePicker = useCallback(() => {
    const today = new Date();
    const nextYear = new Date();
    nextYear.setFullYear(today.getFullYear() + 1);

    const formatDate = (date: Date) => {
      const day = date.getDate().toString().padStart(2, '0');
      const month = (date.getMonth() + 1).toString().padStart(2, '0');
      const year = date.getFullYear();
      return `${day}/${month}/${year}`;
    };

    const initialValue: LDP_Range | undefined = range
      ? ({
          from: formatDate(range.from),
          ...(range.to ? { to: formatDate(range.to) } : {}),
        } as LDP_Range)
      : undefined;

    pickDate({
      theme: currentTheme,
      language: 'vi',
      title: 'Chọn ngày (Range)',
      mode: 'range',
      minimumDate: formatDate(today),
      maximumDate: formatDate(nextYear),
      initialValue,
      onDone: (result) => {
        console.log('🚀 ~ FormSheetScreen ~ result:', result);
        const parseDate = (dateString: string) => {
          const [day, month, year] = dateString.split('/');
          return new Date(
            parseInt(year!, 10),
            parseInt(month!, 10) - 1,
            parseInt(day!, 10)
          );
        };
        setRange({
          from: parseDate(result.from),
          to: result.to ? parseDate(result.to) : undefined,
        });
      },
    });
  }, [range, currentTheme]);

  const formatDateRange = useCallback(() => {
    if (!range) return 'Chưa chọn ngày';
    const fromDate = range.from.toLocaleDateString();
    const toDate = range.to?.toLocaleDateString();
    return `📅 ${fromDate} → ${toDate ?? '?'}`;
  }, [range]);

  return (
    <>
      <Text style={styles.sheetTitle}>FormSheet Screen</Text>
      <Text style={styles.result}>{formatDateRange()}</Text>
      <ButtonGroup onPress={openRangePicker} textColor="black" />
    </>
  );
}

const styles = StyleSheet.create({
  sheetTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginTop: 20,
    marginBottom: 8,
    textAlign: 'center',
    color: 'black',
  },
  result: {
    fontSize: 16,
    marginTop: 12,
    textAlign: 'center',
    color: 'black',
  },
});
