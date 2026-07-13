import { useMemo, useState } from "react";
import { fetchFeedbackList, fetchUserDetail, fetchUsers } from "../api/client";
import type { AdminUser, FeedbackItem } from "../api/types";
import { EmptyState, ErrorState, LoadingBlock } from "../components/States";
import { useQuery } from "../hooks/useQuery";
import { formatNumber, shortInstallId } from "../utils/format";

export function UsersPage() {
  const [q, setQ] = useState("");
  const [selected, setSelected] = useState<string | null>(null);
  const [proFilter, setProFilter] = useState<"all" | "free" | "pro">("all");
  const [internalFilter, setInternalFilter] = useState<"all" | "ext" | "int">("ext");
  const [feedbackFilter, setFeedbackFilter] = useState<"all" | "negative">("all");
  const [tab, setTab] = useState<"users" | "feedback">("users");

  const usersQ = useQuery(
    (k) => fetchUsers(k, { page: 1, pageSize: 100, q: q || undefined }).then((r) => r.data),
    [q]
  );
  const feedbackQ = useQuery((k) => fetchFeedbackList(k, 200).then((r) => r.data), []);
  const detailQ = useQuery(
    (k) => fetchUserDetail(k, selected!).then((r) => r.data.user),
    selected ? [selected] : ["skip"]
  );

  const filteredUsers = useMemo(() => {
    let list = usersQ.data?.users ?? [];
    if (proFilter === "free") list = list.filter((u) => !u.isPro);
    if (proFilter === "pro") list = list.filter((u) => u.isPro);
    if (internalFilter === "ext") list = list.filter((u) => !u.isInternal);
    if (internalFilter === "int") list = list.filter((u) => u.isInternal);
    return list;
  }, [usersQ.data, proFilter, internalFilter]);

  const filteredFeedback = useMemo(() => {
    let items = feedbackQ.data?.items ?? [];
    if (feedbackFilter === "negative") items = items.filter((f) => (f.rating ?? 5) <= 2);
    return items;
  }, [feedbackQ.data, feedbackFilter]);

  return (
    <>
      <div className="filter-bar">
        <div className="filter-group">
          <label htmlFor="tab">Ansicht</label>
          <select id="tab" value={tab} onChange={(e) => setTab(e.target.value as "users" | "feedback")}>
            <option value="users">Nutzerliste</option>
            <option value="feedback">Feedback-Inbox</option>
          </select>
        </div>
        {tab === "users" && (
          <>
            <div className="filter-group">
              <label htmlFor="search">Suche</label>
              <input id="search" value={q} onChange={(e) => setQ(e.target.value)} placeholder="installId / Name" />
            </div>
            <div className="filter-group">
              <label htmlFor="pf">Free/Pro</label>
              <select id="pf" value={proFilter} onChange={(e) => setProFilter(e.target.value as typeof proFilter)}>
                <option value="all">Alle</option>
                <option value="free">Free</option>
                <option value="pro">Pro</option>
              </select>
            </div>
            <div className="filter-group">
              <label htmlFor="intf">Intern</label>
              <select id="intf" value={internalFilter} onChange={(e) => setInternalFilter(e.target.value as typeof internalFilter)}>
                <option value="ext">Extern</option>
                <option value="int">Intern</option>
                <option value="all">Alle</option>
              </select>
            </div>
          </>
        )}
        {tab === "feedback" && (
          <div className="filter-group">
            <label htmlFor="ff">Bewertung</label>
            <select id="ff" value={feedbackFilter} onChange={(e) => setFeedbackFilter(e.target.value as typeof feedbackFilter)}>
              <option value="all">Alle</option>
              <option value="negative">Negativ</option>
            </select>
          </div>
        )}
      </div>

      {tab === "users" && (
        <p className="hint users-lifetime-hint">
          Nutzerliste zeigt alle bekannten Nutzer (Lifetime-Bestand). Der globale Zeitraum-Filter gilt für
          Analytics-KPIs auf den anderen Seiten, nicht für diese Liste.
        </p>
      )}

      {tab === "users" && (
        <div className="grid-2">
          <div className="card">
            <h2>Nutzer ({formatNumber(filteredUsers.length)})</h2>
            {usersQ.loading && <LoadingBlock />}
            {usersQ.error && <ErrorState message={usersQ.error} onRetry={usersQ.reload} />}
            <table className="data-table">
              <thead>
                <tr>
                  <th>Nutzer</th>
                  <th>Pro</th>
                  <th>Erster App-Start</th>
                  <th>KI</th>
                </tr>
              </thead>
              <tbody>
                {filteredUsers.map((u: AdminUser) => (
                  <tr
                    key={u.id}
                    onClick={() => setSelected(u.installId)}
                    style={{ cursor: "pointer" }}
                    className={selected === u.installId ? "active" : ""}
                  >
                    <td>
                      {u.displayName ?? shortInstallId(u.installId)}
                      {u.isInternal && <span className="badge"> intern</span>}
                    </td>
                    <td>{u.isPro ? "Pro" : "Free"}</td>
                    <td>{u.firstAppOpenAt ? u.firstAppOpenAt.slice(0, 10) : "—"}</td>
                    <td>{u._count?.aiRequestLogs ?? 0}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="card">
            <h2>Nutzerdetail</h2>
            {!selected && (
              <EmptyState title="Kein Nutzer ausgewählt" message="Wählen Sie einen Nutzer aus der Liste." />
            )}
            {selected && detailQ.loading && <LoadingBlock />}
            {selected && !detailQ.loading && detailQ.error && (
              <ErrorState message={detailQ.error} onRetry={detailQ.reload} />
            )}
            {selected && !detailQ.loading && !detailQ.error && detailQ.data && (
              <UserDetail user={detailQ.data} />
            )}
          </div>
        </div>
      )}

      {tab === "feedback" && (
        <div className="card">
          <h2>Feedback-Inbox</h2>
          <p className="hint">Freitexte nur in der Detailzeile — nicht in Aggregationen.</p>
          {feedbackQ.loading && <LoadingBlock />}
          <table className="data-table">
            <thead>
              <tr>
                <th>Datum</th>
                <th>Screen</th>
                <th>Rating</th>
                <th>Kommentar</th>
                <th>Kontext</th>
              </tr>
            </thead>
            <tbody>
              {filteredFeedback.map((f: FeedbackItem) => (
                <tr key={f.id}>
                  <td>{f.createdAt.slice(0, 10)}</td>
                  <td>{f.screen ?? "—"}</td>
                  <td className={f.rating != null && f.rating <= 2 ? "status-critical" : ""}>
                    {f.rating ?? "—"}
                  </td>
                  <td>{f.comment ? "Ja" : "—"}</td>
                  <td>{f.context ? "Ja" : "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}

function UserDetail({ user }: { user: Record<string, unknown> }) {
  const logs = (user.aiRequestLogs as { endpoint: string; status: string; createdAt: string; errorCode?: string }[]) ?? [];
  return (
    <div>
      <p>
        <strong>installId:</strong> {String(user.installId)}
      </p>
      <p>
        <strong>Erster Serverkontakt:</strong> {String(user.createdAt).slice(0, 10)}
      </p>
      <p>
        <strong>Erster App-Start:</strong>{" "}
        {user.firstAppOpenAt ? String(user.firstAppOpenAt).slice(0, 10) : "—"}
      </p>
      <h3>KI-Nutzung (letzte 100)</h3>
      <table className="data-table">
        <thead>
          <tr>
            <th>Zeit</th>
            <th>Endpoint</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {logs.slice(0, 20).map((l, i) => (
            <tr key={i}>
              <td>{l.createdAt.slice(0, 16)}</td>
              <td>{l.endpoint}</td>
              <td>
                {l.status}
                {l.errorCode ? ` (${l.errorCode})` : ""}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <EmptyState
        title="Timeline unvollständig"
        message="App-Start- und Produkttracking-Timeline erfordert einen dedizierten Detail-Endpunkt. KI-Logs und Stammdaten werden aus /users/:installId geladen."
      />
    </div>
  );
}
