import "server-only";
import { cache } from "react";
import { organizationClient } from "@/modules/organizations/server";
import { SiteProvider } from "./provider";
import { defaultSite } from "./model";
export const getSiteSettings = cache(async (slug?: string) => {
  if (!slug) return defaultSite;
  const db = await organizationClient();
  const { data, error } = await db.rpc("crm_site_public", { p_slug: slug });
  if (error) throw new Error("Organization website settings are unavailable.");
  return data
    ? { ...defaultSite, nameEn: data.name, nameBn: data.name, ...data.settings }
    : defaultSite;
});
export async function PublicSite({
  slug,
  children,
}: {
  slug?: string;
  children: React.ReactNode;
}) {
  return (
    <SiteProvider slug={slug} settings={await getSiteSettings(slug)}>
      {children}
    </SiteProvider>
  );
}
