import { useCallback, useState } from 'react';

export const useMonthLoading = () => {
  const [loadedMonths, setLoadedMonths] = useState<Set<string>>(new Set());
  const [loadingMonths, setLoadingMonths] = useState<Set<string>>(new Set());
  const [visibleMonths, setVisibleMonths] = useState<string[]>([]);

  const resetState = useCallback(() => {
    setLoadedMonths(new Set());
    setLoadingMonths(new Set());
    setVisibleMonths([]);
  }, []);

  const updateVisibleMonths = useCallback((month: string) => {
    setVisibleMonths((prev) => {
      if (!prev.includes(month)) {
        return [...prev, month].sort();
      }
      return prev;
    });
  }, []);

  const addLoadingMonth = useCallback((month: string) => {
    setLoadingMonths((prev) => new Set([...prev, month]));
  }, []);

  const removeLoadingMonth = useCallback((month: string) => {
    setLoadingMonths((prev) => {
      const newSet = new Set(prev);
      newSet.delete(month);
      return newSet;
    });
  }, []);

  const addLoadedMonth = useCallback((month: string) => {
    setLoadedMonths((prev) => new Set([...prev, month]));
  }, []);

  const isMonthProcessed = useCallback(
    (month: string) => {
      return loadedMonths.has(month) || loadingMonths.has(month);
    },
    [loadedMonths, loadingMonths]
  );

  return {
    loadedMonths,
    loadingMonths,
    visibleMonths,
    resetState,
    updateVisibleMonths,
    addLoadingMonth,
    removeLoadingMonth,
    addLoadedMonth,
    isMonthProcessed,
  };
};
