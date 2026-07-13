import { useState, type FormEvent } from "react";
import { useAuth } from "./AuthContext";

export function LoginScreen() {
  const { login } = useAuth();
  const [key, setKey] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    const trimmed = key.trim();
    if (!trimmed) {
      setError("Bitte Admin-API-Schlüssel eingeben.");
      return;
    }
    setError(null);
    setLoading(true);
    try {
      const res = await fetch(
        "/api/v1/admin/analytics/overview?dateFrom=2026-01-01&dateTo=2026-01-02",
        { headers: { Authorization: `Bearer ${trimmed}`, Accept: "application/json" } }
      );
      if (res.status === 401 || res.status === 403) {
        setError("Ungültiger Admin-Schlüssel.");
        return;
      }
      if (!res.ok) {
        setError("Server nicht erreichbar. Bitte später erneut versuchen.");
        return;
      }
      login(trimmed);
    } catch {
      setError("Verbindung fehlgeschlagen. Ist der Server erreichbar?");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="login-screen">
      <form className="login-card" onSubmit={onSubmit}>
        <h1>Ihdina Admin</h1>
        <p className="muted">Produktanalyse · V2</p>
        <label htmlFor="api-key">Admin API-Schlüssel</label>
        <input
          id="api-key"
          type="password"
          autoComplete="off"
          value={key}
          onChange={(e) => setKey(e.target.value)}
          placeholder="Bearer-Token"
          disabled={loading}
        />
        {error && (
          <p className="status-warning" role="alert">
            {error}
          </p>
        )}
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? "Prüfe…" : "Anmelden"}
        </button>
        <p className="hint">
          Der Schlüssel wird nur in dieser Browser-Sitzung gespeichert (sessionStorage).
        </p>
      </form>
    </div>
  );
}
