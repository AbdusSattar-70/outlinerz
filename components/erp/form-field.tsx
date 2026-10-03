import type { ReactNode } from "react";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";

export function ErpFormField({
  id,
  label,
  hint,
  required = false,
  error,
  className,
  children,
}: {
  id: string;
  label: string;
  hint?: string;
  required?: boolean;
  error?: string | null;
  className?: string;
  children: (props: {
    id: string;
    describedBy?: string;
    invalid: boolean;
  }) => ReactNode;
}) {
  const hintId = hint ? `${id}-hint` : undefined;
  const errorId = error ? `${id}-error` : undefined;
  const describedBy = [hintId, errorId].filter(Boolean).join(" ") || undefined;

  return (
    <div className={cn("grid gap-2", className)}>
      <div className="flex items-center justify-between gap-3">
        <Label htmlFor={id}>{label}</Label>
        <span className="text-xs text-muted-foreground">
          {required ? "Required" : "Optional"}
        </span>
      </div>

      {children({ id, describedBy, invalid: Boolean(error) })}

      {hint && (
        <p id={hintId} className="text-xs leading-5 text-muted-foreground">
          {hint}
        </p>
      )}

      {error && (
        <p
          id={errorId}
          role="alert"
          className="text-xs font-medium leading-5 text-destructive"
        >
          {error}
        </p>
      )}
    </div>
  );
}

export function ErpFormStatus({
  message,
}: {
  message: { ok: boolean; text: string } | null;
}) {
  if (!message) return null;

  return (
    <div
      role={message.ok ? "status" : "alert"}
      aria-live="polite"
      aria-atomic="true"
      className={cn(
        "rounded-xl border p-4 text-sm leading-6",
        message.ok
          ? "border-emerald-300 bg-emerald-50 text-emerald-950 dark:border-emerald-900 dark:bg-emerald-950/30 dark:text-emerald-100"
          : "border-destructive/40 bg-destructive/10 text-destructive"
      )}
    >
      {message.text}
    </div>
  );
}
