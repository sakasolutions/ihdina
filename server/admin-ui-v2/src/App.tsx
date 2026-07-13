import { NavLink, Navigate, Route, Routes, useLocation } from "react-router-dom";
import { useAuth } from "./auth/AuthContext";
import { LoginScreen } from "./auth/LoginScreen";
import { FilterBar } from "./filters/FilterBar";
import { FilterProvider, useDefaultFiltersInit } from "./filters/FilterContext";
import { ActivationPage } from "./pages/ActivationPage";
import { AiQualityPage } from "./pages/AiQualityPage";
import { OverviewPage } from "./pages/OverviewPage";
import { RetentionPage } from "./pages/RetentionPage";
import { UsersPage } from "./pages/UsersPage";

const NAV = [
  { to: "/", label: "Übersicht" },
  { to: "/activation", label: "Aktivierung" },
  { to: "/retention", label: "Bindung & Features" },
  { to: "/ai-quality", label: "KI & Qualität" },
  { to: "/users", label: "Nutzer & Feedback" },
];

function Shell() {
  const { logout } = useAuth();
  const location = useLocation();
  useDefaultFiltersInit();

  return (
    <div className="shell">
      <header className="topbar">
        <div className="brand">
          Ihdina Admin
          <small>Produktanalyse V2 · {location.pathname === "/" ? "Übersicht" : ""}</small>
        </div>
        <nav className="nav" aria-label="Hauptnavigation">
          {NAV.map((n) => (
            <NavLink key={n.to} to={n.to} end={n.to === "/"}>
              {n.label}
            </NavLink>
          ))}
        </nav>
        <button type="button" className="btn-ghost" onClick={logout} aria-label="Abmelden">
          Abmelden
        </button>
      </header>
      <FilterProvider>
        <FilterBar />
        <main>
          <Routes>
            <Route path="/" element={<OverviewPage />} />
            <Route path="/activation" element={<ActivationPage />} />
            <Route path="/retention" element={<RetentionPage />} />
            <Route path="/ai-quality" element={<AiQualityPage />} />
            <Route path="/users" element={<UsersPage />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
      </FilterProvider>
      <footer className="hint" style={{ marginTop: 32 }}>
        Legacy-Dashboard: <a href="/admin/">/admin/</a> · API: /api/v1/admin/analytics/*
      </footer>
    </div>
  );
}

export function App() {
  const { apiKey } = useAuth();
  if (!apiKey) return <LoginScreen />;
  return (
    <Routes>
      <Route path="/*" element={<Shell />} />
    </Routes>
  );
}
