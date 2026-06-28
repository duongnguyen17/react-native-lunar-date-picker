import type { LDP_Range } from '@2security/lunar-date-picker';
import {
  configure,
  pickDate,
  updatePrices,
} from '@2security/lunar-date-picker';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { PICKER_CONFIG } from '../constants';
import { fetchPricesForRange } from '../services/mockApi';
import type { DateRange } from '../types';
import type { RootStackParamList } from '../types/navigation';
import { formatDate, generateSamplePrices, parseDate } from '../utils';

export type HomeScreenProps = NativeStackScreenProps<
  RootStackParamList,
  'Home'
>;

type PriceMode = 'none' | 'preloaded' | 'lazy';

export function HomeScreen({ navigation }: HomeScreenProps) {
  const [currentTheme, setCurrentTheme] = useState<'light' | 'dark'>('light');
  const [range, setRange] = useState<DateRange | undefined>(undefined);
  const [isLoading, setIsLoading] = useState(false);
  const [priceMode, setPriceMode] = useState<PriceMode>('none');

  // Track đã load tháng nào rồi (tránh gọi API 2 lần)
  const loadedMonths = useRef<Set<string>>(new Set());
  const loadingMonths = useRef<Set<string>>(new Set());

  const [showLunarDate, setShowLunarDate] = useState(true);

  useEffect(() => {
    configure({
      ...PICKER_CONFIG,
      showLunarDate,
    });
  }, [showLunarDate]);

  const toggleTheme = useCallback(() => {
    setCurrentTheme((prev) => (prev === 'light' ? 'dark' : 'light'));
  }, []);

  const toggleLunarDate = useCallback(() => {
    setShowLunarDate((prev) => !prev);
  }, []);
  
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  const buildMinMax = () => {
    const today = new Date();
    const nextYear = new Date();
    nextYear.setFullYear(today.getFullYear() + 1);
    return {
      minimumDate: formatDate(today),
      maximumDate: formatDate(nextYear),
    };
  };

  const buildInitialValue = (): LDP_Range | undefined => {
    if (!range) return undefined;
    return {
      from: formatDate(range.from),
      ...(range.to ? { to: formatDate(range.to) } : {}),
    } as LDP_Range;
  };

  const handleDone = (result: LDP_Range) => {
    console.log('✅ onDone:', result);
    setRange({
      from: parseDate(result.from),
      to: result.to ? parseDate(result.to) : undefined,
    });
  };

  // ---------------------------------------------------------------------------
  // Lazy load handlers
  // ---------------------------------------------------------------------------

  /**
   * Gọi khi calendar vừa mở xong (onMounted).
   * Tải giá cho toàn bộ range hiển thị ban đầu.
   */
  const handleMounted = useCallback(
    async (startDate: string, endDate: string) => {
      console.log(`📅 onMounted: ${startDate} → ${endDate}`);

      // Giả lập load API 1 lần cho cả cục từ startDate đến endDate
      try {
        const prices = await fetchPricesForRange(startDate, endDate);
        updatePrices({ prices });
      } catch (e) {
        console.warn(
          `Failed to load prices for range ${startDate} - ${endDate}`,
          e
        );
      }
    },
    []
  );

  /**
   * Gọi khi user chọn ngày đi (onSelectFromDate).
   * Tải giá từ ngày đó đến endDate để hiển thị giá ngày về.
   */
  const handleSelectFromDate = useCallback(
    async (startDate: string, endDate: string) => {
      console.log(`✈️ onSelectFromDate: ${startDate} → ${endDate}`);
      try {
        const prices = await fetchPricesForRange(startDate, endDate);
        updatePrices({ prices });
      } catch (e) {
        Alert.alert('Lỗi', 'Không thể tải giá. Vui lòng thử lại.');
        console.error('fetchPricesForRange failed:', e);
      }
    },
    []
  );

  // ---------------------------------------------------------------------------
  // Picker openers
  // ---------------------------------------------------------------------------

  const openPickerWithoutPrice = useCallback(() => {
    setPriceMode('none');
    pickDate({
      theme: currentTheme,
      language: 'vi',
      title: 'Chọn ngày (không có giá)',
      mode: 'range',
      ...buildMinMax(),
      initialValue: buildInitialValue(),
      onDone: handleDone,
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentTheme, range]);

  const openPickerPreloaded = useCallback(() => {
    setPriceMode('preloaded');
    const prices = generateSamplePrices();
    pickDate({
      theme: currentTheme,
      language: 'vi',
      title: 'Chọn ngày (giá có sẵn)',
      mode: 'range',
      ...buildMinMax(),
      initialValue: buildInitialValue(),
      prices,
      onDone: handleDone,
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentTheme, range]);

  const openPickerLazyLoad = useCallback(() => {
    setPriceMode('lazy');
    loadedMonths.current.clear();
    loadingMonths.current.clear();
    console.log('🚀 Starting lazy loading session...');

    pickDate({
      theme: currentTheme,
      language: 'vi',
      title: 'Chọn ngày (lazy load giá)',
      notice:
        'Lưu ý: Giá vé có thể thay đổi tùy thời điểm. Vui lòng kiểm tra kỹ trước khi thanh toán.',
      mode: 'range',
      ...buildMinMax(),
      initialValue: buildInitialValue(),
      prices: [], // truyền mảng rỗng để hiển thị price area
      onMounted: handleMounted,
      onSelectFromDate: handleSelectFromDate,
      onDone: handleDone,
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentTheme, range, handleMounted, handleSelectFromDate]);

  const openSinglePicker = useCallback(() => {
    const today = new Date();
    const lastYear = new Date();
    lastYear.setFullYear(today.getFullYear() - 1);

    pickDate({
      theme: currentTheme,
      language: 'vi',
      title: 'Chọn ngày (Single)',
      mode: 'single',
      minimumDate: formatDate(lastYear),
      maximumDate: formatDate(today),
      onDone: (result) => {
        console.log('✅ Single:', result);
        setRange({ from: parseDate(result.from), to: undefined });
      },
    });
  }, [currentTheme]);

  // ---------------------------------------------------------------------------
  // Periodic price update demo for preloaded mode
  // ---------------------------------------------------------------------------
  useEffect(() => {
    if (priceMode !== 'preloaded') return;
    let mounted = true;
    setIsLoading(true);

    const run = async () => {
      try {
        const today = new Date();
        const prices = await fetchPricesForRange(
          formatDate(today),
          formatDate(new Date(today.getFullYear(), today.getMonth() + 2, 0))
        );
        if (mounted) {
          updatePrices({ prices });
        }
      } finally {
        if (mounted) setIsLoading(false);
      }
    };

    run();
    return () => {
      mounted = false;
    };
  }, [priceMode]);

  // ---------------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------------
  const formatDateRange = useCallback(() => {
    if (!range) return 'Chưa chọn ngày';
    const fromDate = range.from.toLocaleDateString('vi-VN');
    const toDate = range.to?.toLocaleDateString('vi-VN');
    return `📅 ${fromDate} → ${toDate ?? '?'}`;
  }, [range]);

  const textColor = currentTheme === 'light' ? '#000' : '#fff';
  const bgColor = currentTheme === 'light' ? '#fff' : '#1a1a1a';
  const cardBg = currentTheme === 'light' ? '#f9fafb' : '#2d2d2d';

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: bgColor }]}>
      <ScrollView
        contentContainerStyle={styles.scroll}
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity style={styles.themeButton} onPress={toggleLunarDate}>
            <Text style={{fontSize: 12, fontWeight: 'bold'}}>{showLunarDate ? '🌕' : '🌑'}</Text>
          </TouchableOpacity>
          <Text style={[styles.title, { color: textColor }]}>
            Lunar Date Picker
          </Text>
          <TouchableOpacity style={styles.themeButton} onPress={toggleTheme}>
            <Text style={styles.themeButtonText}>
              {currentTheme === 'light' ? '🌙' : '☀️'}
            </Text>
          </TouchableOpacity>
        </View>

        {/* Selected range display */}
        <View style={[styles.card, { backgroundColor: cardBg }]}>
          <Text style={[styles.cardLabel, { color: textColor + '99' }]}>
            Kết quả
          </Text>
          <Text style={[styles.result, { color: textColor }]}>
            {formatDateRange()}
          </Text>
          {isLoading && (
            <View style={styles.loadingRow}>
              <ActivityIndicator size="small" color="#3B82F6" />
              <Text style={[styles.loadingText, { color: textColor + '99' }]}>
                Đang tải giá...
              </Text>
            </View>
          )}
        </View>

        {/* Navigate to FormSheet */}
        <TouchableOpacity
          style={styles.navigateButton}
          onPress={() => navigation.navigate('FormSheet', { currentTheme })}
        >
          <Text style={styles.navigateButtonText}>📋 Mở FormSheet Demo</Text>
        </TouchableOpacity>

        {/* Section: Range picker */}
        <Text style={[styles.sectionTitle, { color: textColor }]}>
          Range Picker
        </Text>

        <TouchableOpacity
          style={[styles.button, styles.buttonGray]}
          onPress={openPickerWithoutPrice}
        >
          <Text style={styles.buttonText}>🗓 Không có giá</Text>
          <Text style={styles.buttonSubtext}>Chế độ cơ bản</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, styles.buttonBlue]}
          onPress={openPickerPreloaded}
        >
          <Text style={styles.buttonText}>💰 Giá có sẵn (preloaded)</Text>
          <Text style={styles.buttonSubtext}>Truyền prices[] ngay khi mở</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, styles.buttonGreen]}
          onPress={openPickerLazyLoad}
        >
          <Text style={styles.buttonText}>⚡ Lazy load giá</Text>
          <Text style={styles.buttonSubtext}>
            onMounted → fetch tháng đầu{'\n'}
            onSelectFromDate → fetch từ ngày đi
          </Text>
        </TouchableOpacity>

        {/* Section: Single picker */}
        <Text style={[styles.sectionTitle, { color: textColor }]}>
          Single Picker
        </Text>

        <TouchableOpacity
          style={[styles.button, styles.buttonPurple]}
          onPress={openSinglePicker}
        >
          <Text style={styles.buttonText}>📌 Chọn 1 ngày</Text>
          <Text style={styles.buttonSubtext}>Chế độ single date</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scroll: {
    paddingHorizontal: 20,
    paddingBottom: 40,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 16,
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
  },
  themeButtonText: {
    fontSize: 20,
  },
  card: {
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
  },
  cardLabel: {
    fontSize: 12,
    marginBottom: 4,
  },
  result: {
    fontSize: 16,
    fontWeight: '600',
  },
  loadingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
    gap: 6,
  },
  loadingText: {
    fontSize: 12,
  },
  navigateButton: {
    paddingVertical: 12,
    borderRadius: 10,
    backgroundColor: '#007AFF',
    alignItems: 'center',
    marginBottom: 24,
  },
  navigateButtonText: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '600',
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '700',
    letterSpacing: 0.5,
    marginBottom: 10,
    marginTop: 8,
    textTransform: 'uppercase',
    opacity: 0.5,
  },
  button: {
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  buttonGray: {
    backgroundColor: '#6B7280',
  },
  buttonBlue: {
    backgroundColor: '#3B82F6',
  },
  buttonGreen: {
    backgroundColor: '#16a34a',
  },
  buttonPurple: {
    backgroundColor: '#7C3AED',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  buttonSubtext: {
    color: '#ffffffcc',
    fontSize: 12,
    marginTop: 4,
  },
});
