import { useCallback, useEffect, useRef, useState } from "react";
import { ApiAuthError } from "../api/auth";
import { useAuth } from "../auth/AuthContext";

type QueryState<T> = {
  data: T | null;
  loading: boolean;
  error: string | null;
  authError: boolean;
  reload: () => void;
};

export function useQuery<T>(
  fetcher: (apiKey: string, signal: AbortSignal) => Promise<T>,
  deps: unknown[]
): QueryState<T> {
  const { apiKey, logout } = useAuth();
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [authError, setAuthError] = useState(false);
  const gen = useRef(0);
  const fetcherRef = useRef(fetcher);
  fetcherRef.current = fetcher;

  const load = useCallback(() => {
    if (!apiKey) return;
    if (deps.includes("skip")) {
      setLoading(false);
      setError(null);
      setData(null);
      return;
    }
    const id = ++gen.current;
    setLoading(true);
    setError(null);
    setAuthError(false);
    setData(null);
    const ac = new AbortController();
    fetcherRef
      .current(apiKey, ac.signal)
      .then((res) => {
        if (id !== gen.current) return;
        setData(res);
      })
      .catch((e: unknown) => {
        if (id !== gen.current) return;
        if (e instanceof ApiAuthError) {
          setAuthError(true);
          logout();
          return;
        }
        setError(e instanceof Error ? e.message : "Unbekannter Fehler");
      })
      .finally(() => {
        if (id === gen.current) setLoading(false);
      });
    return () => ac.abort();
  }, [apiKey, logout, ...deps]);

  useEffect(() => {
    const cleanup = load();
    return cleanup;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [load, ...deps]);

  return { data, loading, error, authError, reload: () => load() };
}

export function mergeQuality(...responses: ({ meta: { dataQuality: import("../api/types").DataQualityHint[] } } | null | undefined)[]) {
  const map = new Map<string, import("../api/types").DataQualityHint>();
  for (const r of responses) {
    for (const h of r?.meta.dataQuality ?? []) {
      map.set(`${h.code}:${h.affectedMetric ?? ""}`, h);
    }
  }
  return [...map.values()];
}
