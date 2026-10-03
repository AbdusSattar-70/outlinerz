"use client";

import { useEffect } from "react";
import { AlertTriangle, RotateCcw } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function DashboardError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("ERP route error", {
      message: error.message,
      digest: error.digest,
    });
  }, [error]);

  return (
    <section
      role="alert"
      className="rounded-2xl border border-destructive/30 bg-card p-6 shadow-sm"
    >
      <div className="flex items-start gap-4">
        <div className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-destructive/10 text-destructive">
          <AlertTriangle className="size-5" aria-hidden="true" />
        </div>

        <div className="min-w-0 flex-1">
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-destructive">
            This section could not be loaded
          </p>
          <h2 className="mt-1 text-lg font-semibold">
            The ERP shell is still available
          </h2>
          <p className="mt-2 max-w-2xl text-sm leading-6 text-muted-foreground">
            No action is assumed to have succeeded. Retry this section. If the
            problem continues, share the reference below with support.
          </p>

          {error.digest && (
            <div className="mt-4 rounded-xl bg-muted px-3 py-2 text-xs">
              Reference: <code>{error.digest}</code>
            </div>
          )}

          <Button type="button" onClick={reset} className="mt-5 min-h-11">
            <RotateCcw className="mr-2 size-4" aria-hidden="true" />
            Retry this section
          </Button>
        </div>
      </div>
    </section>
  );
}
