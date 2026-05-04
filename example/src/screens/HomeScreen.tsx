import type { LDP_Range } from '@2security/lunar-date-picker';
import { configure, pickDate } from '@2security/lunar-date-picker';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useEffect, useState } from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ButtonGroup } from '../components/ButtonGroup';
import { PICKER_CONFIG } from '../constants';
import type { DateRange } from '../types';
import type { RootStackParamList } from '../types/navigation';

export type HomeScreenProps = NativeStackScreenProps<
  RootStackParamList,
  'Home'
>;

export function HomeScreen({ navigation }: HomeScreenProps) {
  const [currentTheme, setCurrentTheme] = useState<'light' | 'dark'>('light');
  const [range, setRange] = useState<DateRange | undefined>(undefined);

  useEffect(() => {
    configure(PICKER_CONFIG);
  }, []);

  const toggleTheme = useCallback(() => {
    setCurrentTheme((prev) => (prev === 'light' ? 'dark' : 'light'));
  }, []);

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
      title: 'Chọn ngày vòng lặp (Home)',
      mode: 'single',
      minimumDate: formatDate(today),
      maximumDate: formatDate(nextYear),
      initialValue,
      onDone: (result) => {
        console.log('🚀 ~ HomeScreen ~ result:', result);
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

  const textColor = currentTheme === 'light' ? '#000' : '#fff';
  const backgroundColor = currentTheme === 'light' ? '#fff' : '#000';

  return (
    <SafeAreaView style={[styles.container, { backgroundColor }]}>
      <View style={styles.header}>
        <View style={styles.placeholder} />
        <Text style={[styles.title, { color: textColor }]}>
          Test Lunar Date Picker
        </Text>
        <TouchableOpacity style={styles.themeButton} onPress={toggleTheme}>
          <Text style={styles.themeButtonText}>
            {currentTheme === 'light' ? '🌙' : '☀️'}
          </Text>
        </TouchableOpacity>
      </View>

      <TouchableOpacity
        style={styles.navigateButton}
        onPress={() => navigation.navigate('FormSheet', { currentTheme })}
      >
        <Text style={styles.navigateButtonText}>📋 Mở FormSheet</Text>
      </TouchableOpacity>

      <Text
        style={[styles.result, styles.resultContainer, { color: textColor }]}
      >
        {formatDateRange()}
      </Text>
      <ButtonGroup onPress={openRangePicker} textColor={textColor} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    width: '100%',
  },
  placeholder: {
    width: 40,
    height: 40,
  },
  title: {
    fontSize: 18,
    fontWeight: 'bold',
    flex: 1,
    textAlign: 'center',
  },
  themeButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#f0f0f0',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#ddd',
  },
  themeButtonText: {
    fontSize: 20,
  },
  navigateButton: {
    marginTop: 40,
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 10,
    backgroundColor: '#007AFF',
  },
  navigateButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  resultContainer: {
    marginTop: 40,
  },
  result: {
    fontSize: 16,
    marginTop: 12,
    textAlign: 'center',
  },
});
