"use client";
import { useEffect, useRef, type ReactNode } from "react";
/** Explicitly opened working region; clicking outside never destroys form input. */
export function InlineWorkPanel({
  title,
  description,
  onClose,
  children,
}: {
  title: string;
  description?: string;
  onClose: () => void;
  children: ReactNode;
}) {
  const ref = useRef<HTMLElement>(null);
  useEffect(() => {
    ref.current?.scrollIntoView({ behavior: "smooth", block: "start" });
    ref.current?.focus({ preventScroll: true });
  }, []);
  return (
    <section
      ref={ref}
      tabIndex={-1}
      aria-label={title}
      className="scroll-mt-24 space-y-5 rounded-2xl border bg-card p-5 outline-none sm:p-7"
    >
      <header className="flex items-start justify-between gap-4">
        <div>
          <h2 className="text-xl font-semibold">{title}</h2>
          {description && (
            <p className="mt-2 text-sm text-muted-foreground">{description}</p>
          )}
        </div>
        <button
          type="button"
          onClick={onClose}
          className="rounded-lg border px-3 py-2 text-sm"
        >
          Close editor
        </button>
      </header>
      {children}
    </section>
  );
}
