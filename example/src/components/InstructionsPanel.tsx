import React from 'react';
import { StyleSheet, Text, View } from 'react-native';

export const InstructionsPanel: React.FC = () => (
  <View style={styles.container}>
    <Text style={styles.title}>💡 Instructions:</Text>
    <Text style={styles.text}>• Scroll through months</Text>
    <Text style={styles.text}>• Check console logs for details</Text>
    <Text style={styles.text}>• Watch the status above for updates</Text>
  </View>
);

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#e8f4fd',
    padding: 15,
    borderRadius: 8,
    marginTop: 10,
    width: '100%',
  },
  title: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#1976d2',
  },
  text: {
    fontSize: 14,
    marginBottom: 4,
    color: '#1976d2',
  },
});
