export const formatDateToString = (date: Date): string => {
  return date.toISOString().split('T')[0] || '';
};

export const createDateFromDaysOffset = (daysOffset: number): Date => {
  return new Date(Date.now() + daysOffset * 24 * 60 * 60 * 1000);
};
