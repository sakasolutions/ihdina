import { createContext, useContext, useMemo, useState, type ReactNode } from "react";
import {
  clearStoredApiKey,
  getStoredApiKey,
  setStoredApiKey,
} from "../api/auth";

type AuthContextValue = {
  apiKey: string | null;
  login: (key: string) => void;
  logout: () => void;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [apiKey, setApiKey] = useState<string | null>(() => getStoredApiKey());

  const value = useMemo(
    () => ({
      apiKey,
      login: (key: string) => {
        setStoredApiKey(key);
        setApiKey(key);
      },
      logout: () => {
        clearStoredApiKey();
        setApiKey(null);
      },
    }),
    [apiKey]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth outside provider");
  return ctx;
}
