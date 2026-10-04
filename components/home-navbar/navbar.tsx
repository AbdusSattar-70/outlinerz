"use client";

import { useEffect, useRef } from "react";
import Link from "next/link";
import { ArrowRight, Menu, X } from "lucide-react";
import Logo from "@/components/shared/logo";
import { PreferenceControls } from "@/components/shared/preference-controls";
import { useLanguage } from "@/components/providers/language-provider";
import { useSite, resolveSiteText } from "@/modules/crm/site/provider";
import { cn } from "@/lib/utils";

export default function Navbar({
  organizationSlug,
}: {
  organizationSlug?: string;
}) {
  const { t, locale } = useLanguage();
  const site = useSite();
  const why = resolveSiteText(site, "Why Sohoj", "কেন সহজ একাডেমি");
  const homeHref = organizationSlug
    ? `/?organization=${encodeURIComponent(organizationSlug)}`
    : "/";
  const withTenant = (href: string) =>
    organizationSlug && !href.startsWith("/auth")
      ? href.replace(
          /^(\/[^#?]*)(.*)$/,
          `$1?organization=${encodeURIComponent(organizationSlug)}$2`,
        )
      : href;
  const detailsRef = useRef<HTMLDetailsElement>(null);

  const links = [
    [t("programs"), "/#programs"],
    [t("learningMethod"), "/#method"],
    [locale === "bn" ? why.bn : why.en, "/#why-sohoj"],
    [t("aboutUs"), "/about"],
    [t("faq"), "/faq"],
    [t("journal"), "/journal"],
  ] as const;

  useEffect(() => {
    const details = detailsRef.current;
    if (!details) return;

    const close = () => details.removeAttribute("open");

    const onPointerDown = (event: PointerEvent) => {
      if (!details.open) return;
      if (details.contains(event.target as Node)) return;
      close();
    };

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape" && details.open) close();
    };

    // Lock body scroll while menu is open
    const onToggle = () => {
      document.body.style.overflow = details.open ? "hidden" : "";
    };

    details.addEventListener("toggle", onToggle);
    document.addEventListener("pointerdown", onPointerDown, true);
    document.addEventListener("keydown", onKeyDown);

    return () => {
      details.removeEventListener("toggle", onToggle);
      document.removeEventListener("pointerdown", onPointerDown, true);
      document.removeEventListener("keydown", onKeyDown);
      document.body.style.overflow = "";
    };
  }, []);

  const closeMenu = () => {
    detailsRef.current?.removeAttribute("open");
  };

  return (
    <header className="sticky top-0 z-50 border-b border-border/60 bg-background/80 backdrop-blur-xl supports-[backdrop-filter]:bg-background/70">
      <a
        href="#main-content"
        className="sr-only z-[60] rounded-md bg-primary px-4 py-2 text-primary-foreground focus:not-sr-only focus:absolute focus:left-4 focus:top-3"
      >
        {t("skipToContent")}
      </a>

      <nav
        aria-label="Primary navigation"
        className="relative mx-auto flex h-16 max-w-7xl items-center justify-between gap-6 px-5 sm:h-[4.25rem] sm:px-6 lg:px-8"
      >
        <Link
          href={homeHref}
          aria-label={`${site?.nameEn || "Sohoj Academy"} home`}
          className="relative z-10 shrink-0 rounded-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
        >
          <Logo size={64} priority className="sm:hidden" />
          <Logo size={72} priority className="hidden sm:block" />
        </Link>

        {/* Desktop links */}
        <div className="hidden flex-1 items-center justify-center gap-0.5 xl:flex">
          {links.map(([label, href]) => (
            <Link
              key={href}
              href={withTenant(href)}
              className={cn(
                "relative rounded-lg px-3.5 py-2 text-[13px] font-medium tracking-[-0.01em]",
                "text-muted-foreground transition-colors duration-200",
                "hover:bg-muted/70 hover:text-foreground",
                "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
              )}
            >
              {label}
            </Link>
          ))}
        </div>

        <div className="relative z-10 flex items-center gap-2 sm:gap-3">
          <div className="hidden sm:block">
            <PreferenceControls compact />
          </div>

          <Link
            href="/auth"
            className={cn(
              "hidden sm:inline-flex items-center gap-1.5",
              "h-9 rounded-full bg-blue-700 px-4 text-[13px] font-semibold text-white",
              "shadow-[0_1px_2px_rgba(29,78,216,0.2)]",
              "transition-[background-color,box-shadow,transform] duration-200",
              "hover:bg-blue-800 hover:shadow-[0_4px_12px_-2px_rgba(29,78,216,0.35)]",
              "active:scale-[0.98]",
              "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-600 focus-visible:ring-offset-2",
            )}
          >
            {t("digitalCampus")}
            <ArrowRight className="size-3.5 opacity-90" aria-hidden="true" />
          </Link>

          {/* ── Mobile / tablet menu ── */}
          <details ref={detailsRef} className="group xl:hidden">
            <summary
              className={cn(
                "flex size-9 cursor-pointer list-none items-center justify-center",
                "rounded-full border border-border/80 bg-background text-foreground",
                "shadow-sm transition-colors hover:bg-muted",
                "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
                "[&::-webkit-details-marker]:hidden",
              )}
            >
              <Menu className="size-4 group-open:hidden" aria-hidden="true" />
              <X
                className="hidden size-4 group-open:block"
                aria-hidden="true"
              />
              <span className="sr-only">Toggle navigation menu</span>
            </summary>

            {/* Backdrop */}
            <div
              className="fixed inset-0 top-16 z-40 bg-slate-950/40 backdrop-blur-[2px] sm:top-[4.25rem]"
              aria-hidden="true"
              onClick={closeMenu}
            />

            {/* Sheet panel */}
            <div
              className={cn(
                "fixed inset-x-0 top-16 z-50 sm:top-[4.25rem]",
                "max-h-[min(28rem,calc(100dvh-4.5rem))] overflow-y-auto",
                "border-b border-border/80 bg-background/95 shadow-[0_20px_40px_-16px_rgba(15,23,42,0.2)]",
                "backdrop-blur-xl",
                "animate-in fade-in-0 slide-in-from-top-2 duration-200",
              )}
            >
              <div className="mx-auto max-w-7xl px-5 py-5 sm:px-6 lg:px-8">
                {/* Language — mobile only */}
                <div className="mb-4 flex items-center justify-between gap-3 sm:hidden">
                  <p className="text-xs font-medium uppercase tracking-[0.14em] text-muted-foreground">
                    {t("language")}
                  </p>
                  <PreferenceControls compact />
                </div>

                {/* Nav links */}
                <div className="grid gap-1 sm:grid-cols-2 sm:gap-2">
                  {links.map(([label, href], i) => (
                    <Link
                      key={href}
                      href={withTenant(href)}
                      onClick={closeMenu}
                      className={cn(
                        "group/link flex items-center justify-between gap-3",
                        "rounded-xl border border-transparent px-3.5 py-3.5",
                        "text-[15px] font-medium tracking-[-0.01em] text-foreground",
                        "transition-colors duration-150",
                        "hover:border-border hover:bg-muted/60",
                        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
                      )}
                    >
                      <span className="flex items-center gap-3">
                        <span className="w-5 text-xs font-semibold tabular-nums text-muted-foreground/70">
                          {String(i + 1).padStart(2, "0")}
                        </span>
                        {label}
                      </span>
                      <ArrowRight
                        className="size-4 text-muted-foreground opacity-0 transition-all group-hover/link:translate-x-0.5 group-hover/link:opacity-100"
                        aria-hidden="true"
                      />
                    </Link>
                  ))}
                </div>

                {/* CTA — mobile only */}
                <div className="mt-5 border-t border-border/60 pt-5 sm:hidden">
                  <Link
                    href="/auth"
                    onClick={closeMenu}
                    className={cn(
                      "flex h-12 w-full items-center justify-center gap-2",
                      "rounded-xl bg-blue-700 text-sm font-semibold text-white",
                      "shadow-[0_4px_14px_-4px_rgba(29,78,216,0.45)]",
                      "transition hover:bg-blue-800 active:scale-[0.99]",
                    )}
                  >
                    {t("openDigitalCampus")}
                    <ArrowRight className="size-4" aria-hidden="true" />
                  </Link>
                  <p className="mt-3 text-center text-xs leading-5 text-muted-foreground">
                    <LocalizedOrFallback />
                  </p>
                </div>
              </div>
            </div>
          </details>
        </div>
      </nav>
    </header>
  );
}

/** Small helper so we don't need extra i18n keys if missing */
function LocalizedOrFallback() {
  const { locale } = useLanguage();
  return locale === "bn"
    ? "শিক্ষার্থী ও অভিভাবক পোর্টাল"
    : "Student & guardian portal";
}
