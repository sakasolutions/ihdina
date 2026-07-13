export function LoadingBlock({ rows = 3 }: { rows?: number }) {
  return (
    <div className="card" aria-busy="true" aria-label="Lädt">
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="skeleton" style={{ height: 20, marginBottom: 8 }} />
      ))}
    </div>
  );
}

export function EmptyState({ title, message }: { title: string; message: string }) {
  return (
    <div className="card empty-state" role="status">
      <h3>{title}</h3>
      <p className="muted">{message}</p>
    </div>
  );
}

export function ErrorState({
  message,
  onRetry,
}: {
  message: string;
  onRetry?: () => void;
}) {
  return (
    <div className="card error-state" role="alert">
      <p className="status-critical">{message}</p>
      {onRetry && (
        <button type="button" className="btn-ghost" onClick={onRetry}>
          Erneut versuchen
        </button>
      )}
    </div>
  );
}
