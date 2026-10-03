"use client";

import type { ReactNode } from "react";
import { Label } from "@/components/ui/label";
import { useLanguage } from "@/components/providers/language-provider";
import { cn } from "@/lib/utils";

export function FormField({
  id,
  label,
  hint,
  required = false,
  children,
  className,
}: {
  id: string;
  label: string;
  hint?: string;
  required?: boolean;
  children: ReactNode;
  className?: string;
}) {
  const { locale } = useLanguage();
  const hintId = hint ? `${id}-hint` : undefined;

  return (
    <div className={cn("grid gap-2", className)}>
      <div className="flex items-center justify-between gap-3">
        <Label htmlFor={id}>{label}</Label>
        <span className="text-xs text-muted-foreground">
          {required
            ? locale === "bn"
              ? "আবশ্যক"
              : "Required"
            : locale === "bn"
              ? "ঐচ্ছিক"
              : "Optional"}
        </span>
      </div>
      <div aria-describedby={hintId}>{children}</div>
      {hint && (
        <p id={hintId} className="text-xs leading-5 text-muted-foreground">
          {hint}
        </p>
      )}
    </div>
  );
}

export function FormStatus({
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
        "rounded-xl border p-3 text-sm",
        message.ok
          ? "border-emerald-500/30 bg-emerald-500/5 text-foreground"
          : "border-destructive/40 bg-destructive/5 text-destructive"
      )}
    >
      {message.text}
    </div>
  );
}
