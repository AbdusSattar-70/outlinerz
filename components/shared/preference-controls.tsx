"use client";

import { Languages } from "lucide-react";
import { useLanguage } from "@/components/providers/language-provider";
import { cn } from "@/lib/utils";

export function PreferenceControls({
  compact = false,
  className,
}: {
  compact?: boolean;
  className?: string;
}) {
  const { locale, setLocale, t } = useLanguage();

  return (
    <div
      className={cn(
        "flex items-center gap-1 rounded-xl border border-border bg-background/90 p-1 shadow-sm backdrop-blur",
        className,
      )}
      aria-label={t("language")}
    >
      {!compact && (
        <span className="px-2 text-muted-foreground" aria-hidden="true">
          <Languages className="size-4" />
        </span>
      )}

      <button
        type="button"
        onClick={() => setLocale("en")}
        aria-pressed={locale === "en"}
        className={cn(
          "min-h-9 rounded-lg px-2.5 text-xs font-semibold transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
          locale === "en"
            ? "bg-primary text-primary-foreground"
            : "text-muted-foreground hover:bg-muted hover:text-foreground",
        )}
      >
        EN
      </button>

      <button
        type="button"
        onClick={() => setLocale("bn")}
        lang="bn"
        style={{fontFamily:"var(--font-bn), sans-serif"}}
        aria-pressed={locale === "bn"}
        className={cn(
          "min-h-9 rounded-lg px-2.5 text-xs font-semibold transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
          locale === "bn"
            ? "bg-primary text-primary-foreground"
            : "text-muted-foreground hover:bg-muted hover:text-foreground",
        )}
      >
        বাংলা
      </button>
    </div>
  );
}
