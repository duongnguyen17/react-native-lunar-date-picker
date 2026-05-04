import React from 'react';
import { Button, StyleSheet, Text, View } from 'react-native';

interface ButtonGroupProps {
  onPress: () => void;
  textColor: string;
}

export const ButtonGroup: React.FC<ButtonGroupProps> = ({
  onPress,
  textColor,
}) => (
  <View style={styles.container}>
    <Text style={[styles.sectionTitle, { color: textColor }]}>
      📅 Range Picker
    </Text>
    <Button title="Open Range Picker" onPress={onPress} />
  </View>
);

const styles = StyleSheet.create({
  container: {
    gap: 10,
    width: '100%',
    marginVertical: 20,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginTop: 15,
    marginBottom: 5,
    color: '#333',
    textAlign: 'center',
  },
});
