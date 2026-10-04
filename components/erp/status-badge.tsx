import { cn } from "@/lib/utils";

const tones: Record<string, string> = {
  NEW: "border-blue-300 bg-blue-50 text-blue-800 dark:border-blue-900 dark:bg-blue-950/40 dark:text-blue-200",
  CONTACTED:
    "border-violet-300 bg-violet-50 text-violet-800 dark:border-violet-900 dark:bg-violet-950/40 dark:text-violet-200",
  COUNSELLING:
    "border-amber-300 bg-amber-50 text-amber-800 dark:border-amber-900 dark:bg-amber-950/40 dark:text-amber-200",
  CONVERTED:
    "border-emerald-300 bg-emerald-50 text-emerald-800 dark:border-emerald-900 dark:bg-emerald-950/40 dark:text-emerald-200",
  ACTIVE:
    "border-emerald-300 bg-emerald-50 text-emerald-800 dark:border-emerald-900 dark:bg-emerald-950/40 dark:text-emerald-200",
  PENDING:
    "border-amber-300 bg-amber-50 text-amber-800 dark:border-amber-900 dark:bg-amber-950/40 dark:text-amber-200",
  APPROVED:
    "border-emerald-300 bg-emerald-50 text-emerald-800 dark:border-emerald-900 dark:bg-emerald-950/40 dark:text-emerald-200",
  REJECTED:
    "border-red-300 bg-red-50 text-red-800 dark:border-red-900 dark:bg-red-950/40 dark:text-red-200",
};

Object.assign(tones, {
  ACTIVE_ENROLLMENT: tones.ACTIVE,
  ACCEPTED: tones.APPROVED,
  READY: tones.CONTACTED,
  DRAFT: tones.PENDING,
  BILLING_POSTED: tones.CONTACTED,
  PENDING_PAYMENT: tones.PENDING,
  CANCELLED: tones.REJECTED,
  SUSPENDED: tones.REJECTED,
  CLOSED_ENROLLMENT: "border-slate-400 bg-slate-100 text-slate-700 dark:bg-slate-900 dark:text-slate-300",
});

export function StatusBadge({
  value,
  className,
}: {
  value: string;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex min-h-7 items-center rounded-full border px-2.5 py-1 text-xs font-semibold",
        tones[value] ??
          "border-border bg-muted text-muted-foreground",
        className
      )}
    >
      {value.replaceAll("_", " ")}
    </span>
  );
}
