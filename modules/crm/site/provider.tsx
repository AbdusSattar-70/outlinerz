"use client";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { createContext, useContext, useEffect } from "react";
import { defaultSite, type SiteSettings } from "./model";
import { useLanguage } from "@/components/providers/language-provider";
import { siteCopy } from "./catalogue";
const SiteContext = createContext<SiteSettings | null>(null);
export function SiteProvider({
  settings,
  slug,
  children,
}: {
  settings: SiteSettings;
  slug?: string;
  children: React.ReactNode;
}) {
  const router = useRouter();
  useEffect(() => {
    if (!slug) return;
    const refresh = () => router.refresh();
    const channel =
      typeof BroadcastChannel !== "undefined"
        ? new BroadcastChannel("outlinerz-crm-content")
        : null;
    if (channel)
      channel.onmessage = (event) => {
        if (event.data?.slug === slug) refresh();
      };
    window.addEventListener("focus", refresh);
    return () => {
      channel?.close();
      window.removeEventListener("focus", refresh);
    };
  }, [slug, router]);
  return (
    <SiteContext.Provider value={settings}>{children}</SiteContext.Provider>
  );
}
export function useSite() {
  return useContext(SiteContext);
}
export function resolveSiteText(
  settings: SiteSettings | null,
  en: string,
  bn: string,
) {
  if (!settings) return { en, bn };
  const entry = siteCopy.find((e) => e.en === en && e.bn === bn);
  const value = (entry && settings.copy[entry.key]) || { en, bn };
  return {
    en: value.en.replace(/Sohoj Academy|Sohoj/g, () => settings.nameEn),
    bn: value.bn
      .replaceAll("সহজ একাডেমি", settings.nameBn)
      .replaceAll("সহজ লার্নিং", settings.nameBn + " লার্নিং"),
  };
}
export function SiteImage({
  kind,
  priority,
  ...props
}: Omit<React.ComponentProps<typeof import("next/image").default>, "src"> & {
  kind: "heroImage" | "learningImage";
}) {
  const settings = useSite() || defaultSite;
  return (
    <Image
      {...props}
      unoptimized
      priority={priority}
      src={settings[kind]}
      alt={props.alt}
    />
  );
}
export function SiteContact() {
  const s = useSite();
  const { locale } = useLanguage();
  return s && (s.phone || s.email || s.addressEn || s.addressBn) ? (
    <p className="text-sm text-muted-foreground">
      {[s.phone, s.email, locale === "bn" ? s.addressBn : s.addressEn]
        .filter(Boolean)
        .join(" · ")}
    </p>
  ) : null;
}

export function SiteName({ uppercase = false }: { uppercase?: boolean }) {
  const site = useSite() || defaultSite;
  const { locale } = useLanguage();
  return (
    <>
      {locale === "bn"
        ? site.nameBn
        : uppercase
          ? site.nameEn.toUpperCase()
          : site.nameEn}
    </>
  );
}

export function notifyPublicSite(slug: string) {
  if (typeof BroadcastChannel === "undefined") return;
  const channel = new BroadcastChannel("outlinerz-crm-content");
  channel.postMessage({ slug });
  channel.close();
}
