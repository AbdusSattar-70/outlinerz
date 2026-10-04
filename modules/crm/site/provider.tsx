"use client";
import Image from "next/image";
import { createContext, useContext } from "react";
import { defaultSite, type SiteSettings } from "./model";
import { useLanguage } from "@/components/providers/language-provider";
import { siteCopy } from "./catalogue";
const SiteContext = createContext<SiteSettings | null>(null);
export function SiteProvider({
  settings,
  children,
}: {
  settings: SiteSettings;
  children: React.ReactNode;
}) {
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

export function SiteName({uppercase=false}:{uppercase?:boolean}){const site=useSite()||defaultSite;const {locale}=useLanguage();return <>{locale==="bn"?site.nameBn:uppercase?site.nameEn.toUpperCase():site.nameEn}</>;}
