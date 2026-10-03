import type { ReactNode } from "react";
import Link from "next/link";
import Navbar from "@/components/home-navbar/navbar";
import Logo from "@/components/shared/logo";
import { LocalizedText } from "@/components/shared/localized-text";

export function PublicPageShell({
  organizationSlug,
  eyebrow,
  title,
  description,
  children,
}: {
  organizationSlug?: string;
  eyebrow: [string, string];
  title: [string, string];
  description: [string, string];
  children: ReactNode;
}) {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <Navbar organizationSlug={organizationSlug} />
      <main id="main-content">
        <header className="border-b border-border bg-linear-to-b from-blue-950/50 to-background">
          <div className="mx-auto max-w-7xl px-5 py-14 sm:px-6 lg:px-8 lg:py-20">
            <Link
              href={
                organizationSlug
                  ? `/?organization=${encodeURIComponent(organizationSlug)}`
                  : "/"
              }
              className="text-sm font-medium text-muted-foreground transition hover:text-foreground"
            >
              <LocalizedText en="← Home" bn="← মূল পাতা" />
            </Link>
            <p className="mt-8 text-xs font-bold uppercase tracking-[0.22em] text-blue-300">
              <LocalizedText en={eyebrow[0]} bn={eyebrow[1]} />
            </p>
            <h1 className="mt-3 max-w-4xl text-4xl font-bold tracking-[-0.04em] sm:text-5xl lg:text-6xl">
              <LocalizedText en={title[0]} bn={title[1]} />
            </h1>
            <p className="mt-5 max-w-3xl text-base leading-8 text-muted-foreground sm:text-lg">
              <LocalizedText en={description[0]} bn={description[1]} />
            </p>
          </div>
        </header>
        {children}
      </main>
      <footer className="border-t border-border bg-background">
        <div className="mx-auto flex max-w-7xl flex-col gap-5 px-5 py-8 sm:px-6 md:flex-row md:items-center md:justify-between lg:px-8">
          <Logo size={76} />
          <nav
            aria-label="Footer"
            className="flex flex-wrap gap-x-5 gap-y-2 text-sm text-muted-foreground"
          >
            <Link
              href={`/about${organizationSlug ? `?organization=${encodeURIComponent(organizationSlug)}` : ""}`}
              className="hover:text-foreground"
            >
              <LocalizedText en="About" bn="পরিচিতি" />
            </Link>
            <Link
              href={`/faq${organizationSlug ? `?organization=${encodeURIComponent(organizationSlug)}` : ""}`}
              className="hover:text-foreground"
            >
              <LocalizedText en="FAQ" bn="প্রশ্নোত্তর" />
            </Link>
            <Link href="/journal" className="hover:text-foreground">
              <LocalizedText en="Journal" bn="শিক্ষা-জার্নাল" />
            </Link>
            <Link
              href={`/interest${organizationSlug ? `?organization=${encodeURIComponent(organizationSlug)}` : ""}`}
              className="hover:text-foreground"
            >
              <LocalizedText en="Register Interest" bn="আগ্রহ নিবন্ধন" />
            </Link>
          </nav>
          <p className="text-xs text-muted-foreground">© Outlinerz</p>
        </div>
      </footer>
    </div>
  );
}
