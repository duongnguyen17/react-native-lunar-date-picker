import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import type { PickerLanguage } from '../constants';

type LanguageSelectorProps = {
  selectedLanguage: PickerLanguage;
  onSelect: (language: PickerLanguage) => void;
  textColor: string;
};

const LANGUAGE_OPTIONS: Array<{ key: PickerLanguage; label: string }> = [
  { key: 'vi', label: 'Tiếng Việt' },
  { key: 'en', label: 'English · en_US' },
];

export function LanguageSelector({
  selectedLanguage,
  onSelect,
  textColor,
}: LanguageSelectorProps) {
  return (
    <View style={styles.container}>
      <Text style={[styles.label, { color: textColor }]}>🌐 Ngôn ngữ lịch</Text>
      <View style={styles.options}>
        {LANGUAGE_OPTIONS.map(({ key, label }) => {
          const isSelected = selectedLanguage === key;
          return (
            <TouchableOpacity
              key={key}
              accessibilityRole="button"
              accessibilityState={{ selected: isSelected }}
              style={[styles.option, isSelected && styles.optionSelected]}
              onPress={() => onSelect(key)}
            >
              <Text
                style={[
                  styles.optionText,
                  isSelected && styles.optionTextSelected,
                ]}
              >
                {label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    borderRadius: 12,
    padding: 14,
    marginBottom: 16,
    backgroundColor: '#F3F4F6',
  },
  label: {
    fontSize: 14,
    fontWeight: '700',
    marginBottom: 10,
  },
  options: {
    flexDirection: 'row',
    gap: 8,
  },
  option: {
    flex: 1,
    alignItems: 'center',
    borderRadius: 8,
    paddingVertical: 10,
    paddingHorizontal: 6,
    backgroundColor: '#E5E7EB',
  },
  optionSelected: {
    backgroundColor: '#007AFF',
  },
  optionText: {
    color: '#374151',
    fontSize: 13,
    fontWeight: '600',
  },
  optionTextSelected: {
    color: '#FFFFFF',
  },
});
