export default function DashboardLoading() {
  return (
    <div className="space-y-7" aria-busy="true" aria-live="polite">
      <div className="space-y-3">
        <div className="h-3 w-28 animate-pulse rounded-full bg-muted" />
        <div className="h-8 w-64 max-w-full animate-pulse rounded-xl bg-muted" />
        <div className="h-4 w-full max-w-2xl animate-pulse rounded-full bg-muted" />
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {Array.from({ length: 4 }).map((_, index) => (
          <div key={index} className="rounded-2xl border bg-card p-5">
            <div className="h-4 w-28 animate-pulse rounded-full bg-muted" />
            <div className="mt-4 h-8 w-20 animate-pulse rounded-lg bg-muted" />
            <div className="mt-3 h-3 w-full animate-pulse rounded-full bg-muted" />
          </div>
        ))}
      </div>

      <div className="rounded-2xl border bg-card p-5">
        <div className="h-5 w-40 animate-pulse rounded-lg bg-muted" />
        <div className="mt-5 space-y-3">
          {Array.from({ length: 5 }).map((_, index) => (
            <div
              key={index}
              className="h-12 w-full animate-pulse rounded-xl bg-muted/70"
            />
          ))}
        </div>
      </div>

      <span className="sr-only">Loading this ERP section…</span>
    </div>
  );
}
