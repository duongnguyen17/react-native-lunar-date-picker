import React from 'react';
import { StyleSheet, Text, View } from 'react-native';

interface LazyLoadingStatusProps {
  loadedMonths: Set<string>;
  loadingMonths: Set<string>;
  visibleMonths: string[];
}

export const LazyLoadingStatus: React.FC<LazyLoadingStatusProps> = ({
  loadedMonths,
  loadingMonths,
  visibleMonths,
}) => (
  <View style={styles.container}>
    <Text style={styles.title}>Lazy Loading Status:</Text>
    <Text style={styles.text}>
      🔍 Visible months:{' '}
      {visibleMonths.length > 0 ? visibleMonths.join(', ') : 'None'}
    </Text>
    <Text style={styles.text}>
      ✅ Loaded months: {loadedMonths.size} (
      {Array.from(loadedMonths).join(', ')})
    </Text>
    <Text style={styles.text}>
      ⏳ Loading months: {loadingMonths.size} (
      {Array.from(loadingMonths).join(', ')})
    </Text>
  </View>
);

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#f5f5f5',
    padding: 15,
    borderRadius: 8,
    marginVertical: 10,
    width: '100%',
  },
  title: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#333',
  },
  text: {
    fontSize: 14,
    marginBottom: 4,
    color: '#666',
  },
});
