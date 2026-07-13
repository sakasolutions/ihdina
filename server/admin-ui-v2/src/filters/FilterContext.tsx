import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  type ReactNode,
} from "react";
import { useSearchParams } from "react-router-dom";
import type { DashboardFilters } from "../api/types";
import {
  defaultFilters,
  filtersFromSearchParams,
  filtersToSearchParams,
  previousPeriod,
} from "./filterUtils";

type FilterContextValue = {
  filters: DashboardFilters;
  setFilters: (patch: Partial<DashboardFilters>) => void;
  compareFilters: DashboardFilters | null;
  platformFilterSupported: (scope: "product" | "all") => boolean;
};

const FilterContext = createContext<FilterContextValue | null>(null);

export function FilterProvider({ children }: { children: ReactNode }) {
  const [searchParams, setSearchParams] = useSearchParams();
  const filters = useMemo(
    () => filtersFromSearchParams(searchParams),
    [searchParams]
  );

  const setFilters = useCallback(
    (patch: Partial<DashboardFilters>) => {
      const next = { ...filters, ...patch };
      setSearchParams(filtersToSearchParams(next), { replace: true });
    },
    [filters, setSearchParams]
  );

  const compareFilters = useMemo(() => {
    if (filters.compare !== "previous") return null;
    const prev = previousPeriod(filters.dateFrom, filters.dateTo);
    return { ...filters, ...prev };
  }, [filters]);

  const platformFilterSupported = useCallback((scope: "product" | "all") => {
    return scope === "product";
  }, []);

  const value = useMemo(
    () => ({ filters, setFilters, compareFilters, platformFilterSupported }),
    [filters, setFilters, compareFilters, platformFilterSupported]
  );

  return <FilterContext.Provider value={value}>{children}</FilterContext.Provider>;
}

export function useFilters() {
  const ctx = useContext(FilterContext);
  if (!ctx) throw new Error("useFilters outside provider");
  return ctx;
}

export function useDefaultFiltersInit() {
  const [, setSearchParams] = useSearchParams();
  useEffect(() => {
    const sp = new URLSearchParams(window.location.search);
    if (!sp.get("preset")) {
      setSearchParams(filtersToSearchParams(defaultFilters()), { replace: true });
    }
  }, [setSearchParams]);
}
