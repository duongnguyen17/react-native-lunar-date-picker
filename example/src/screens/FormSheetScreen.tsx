import type { LDP_Range } from '@2security/lunar-date-picker';
import { pickDate } from '@2security/lunar-date-picker';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import type { DateRange } from '../types';
import type { RootStackParamList } from '../types/navigation';
import { formatDate, generateSamplePrices, parseDate } from '../utils';

export type FormSheetScreenProps = NativeStackScreenProps<
  RootStackParamList,
  'FormSheet'
>;

export function FormSheetScreen({ route }: FormSheetScreenProps) {
  const { currentTheme } = route.params;
  const [range, setRange] = useState<DateRange | undefined>(undefined);

  const buildInitialValue = (): LDP_Range | undefined => {
    if (!range) return undefined;
    return {
      from: formatDate(range.from),
      ...(range.to ? { to: formatDate(range.to) } : {}),
    } as LDP_Range;
  };

  const handleDone = (result: LDP_Range) => {
    const from = parseDate(result.from);
    const to = result.to ? parseDate(result.to) : undefined;
    setRange({ from, to });
  };

  const openBasic = useCallback(() => {
    const today = new Date();
    const nextYear = new Date();
    nextYear.setFullYear(today.getFullYear() + 1);

    pickDate({
      theme: currentTheme,
      language: 'vi',
      title: 'Chọn ngày (Range)',
      mode: 'range',
      minimumDate: formatDate(today),
      maximumDate: formatDate(nextYear),
      initialValue: buildInitialValue(),
      onDone: handleDone,
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentTheme, range]);

  const openWithPrices = useCallback(() => {
    const today = new Date();
    const nextYear = new Date();
    nextYear.setFullYear(today.getFullYear() + 1);

    pickDate({
      theme: currentTheme,
      language: 'vi',
      title: 'Chọn ngày (Có giá)',
      mode: 'range',
      minimumDate: formatDate(today),
      maximumDate: formatDate(nextYear),
      initialValue: buildInitialValue(),
      prices: generateSamplePrices(),
      onDone: handleDone,
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentTheme, range]);

  const formatDateRange = useCallback(() => {
    if (!range) return 'Chưa chọn ngày';
    const fromDate = range.from.toLocaleDateString('vi-VN');
    const toDate = range.to?.toLocaleDateString('vi-VN');
    return `📅 ${fromDate} → ${toDate ?? '?'}`;
  }, [range]);

  return (
    <View style={styles.container}>
      <Text style={styles.sheetTitle}>FormSheet Demo</Text>
      <Text style={styles.result}>{formatDateRange()}</Text>

      <TouchableOpacity
        style={[styles.button, styles.buttonBlue]}
        onPress={openBasic}
      >
        <Text style={styles.buttonText}>🗓 Không có giá</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.button, styles.buttonGreen]}
        onPress={openWithPrices}
      >
        <Text style={styles.buttonText}>💰 Có giá (preloaded)</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    paddingTop: 24,
    paddingHorizontal: 20,
  },
  sheetTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 8,
    color: 'black',
  },
  result: {
    fontSize: 15,
    marginBottom: 24,
    textAlign: 'center',
    color: '#444',
  },
  button: {
    width: '100%',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    alignItems: 'center',
  },
  buttonBlue: { backgroundColor: '#3B82F6' },
  buttonGreen: { backgroundColor: '#16a34a' },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
