import { getSiteSettings } from "@/modules/crm/site/server";
import { SiteProvider } from "@/modules/crm/site/provider";
import { defaultSite } from "@/modules/crm/site/model";
import type { ReactNode } from "react";
import { requireOrganization } from "@/modules/organizations/server";
import { WorkspaceShell } from "@/modules/organizations/workspace-shell";
export default async function DashboardLayout({
  children,
}: {
  children: ReactNode;
}) {
  const { db, organization } = await requireOrganization();
  const { data, error } = await db
    .from("organization_modules")
    .select("enabled")
    .eq("organization_id", organization.id)
    .eq("module", "CRM")
    .maybeSingle();
  if (error) throw new Error("Module settings could not be loaded.");
  const site = await getSiteSettings(organization.slug);
  const settings =
    site === defaultSite
      ? { ...site, nameEn: organization.name, nameBn: organization.name }
      : site;
  return (
    <SiteProvider settings={settings}>
      <WorkspaceShell
        organization={organization}
        crmEnabled={Boolean(data?.enabled)}
      >
        {children}
      </WorkspaceShell>
    </SiteProvider>
  );
}
