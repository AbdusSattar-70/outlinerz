import Link from "next/link";
import type { LucideIcon } from "lucide-react";

export function StatCard({
  label,
  value,
  description,
  icon: Icon,
  href,
}: {
  label: string;
  value: string | number;
  description?: string;
  icon: LucideIcon;
  href?: string;
}) {
  const content = (
    <div className="rounded-2xl border bg-card p-5 shadow-sm">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-medium text-muted-foreground">{label}</p>
          <p className="mt-2 text-2xl font-bold tracking-tight">{value}</p>
          {description && (
            <p className="mt-2 text-xs leading-5 text-muted-foreground">
              {description}
            </p>
          )}
        </div>
        <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-muted text-foreground">
          <Icon className="size-5" aria-hidden="true" />
        </div>
      </div>
    </div>
  );
  return href ? (
    <Link
      href={href}
      className="block rounded-2xl transition hover:ring-2 hover:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
      aria-label={`${label}: ${value}. Open register`}
    >
      {content}
    </Link>
  ) : (
    content
  );
}
