import { OfferingEditor } from "@/modules/crm/site/offering-editor";
import { crmAccess } from "@/modules/crm/access";
import { defaultSite } from "@/modules/crm/site/model";
import { SiteEditor } from "@/modules/crm/site/editor";
import { redirect } from "next/navigation";
export default async function WebsiteManagement() {
  const { db, organization, crmEnabled } = await crmAccess();
  if (!["OWNER", "ADMIN"].includes(organization.role)) redirect("/dashboard");
  const { data, error } = await db
    .from("crm_sites")
    .select("revision,settings")
    .eq("organization_id", organization.id)
    .maybeSingle();
  if (error) throw new Error("Could not load organization settings.");
  const offerings = await db
    .from("offerings")
    .select("id,name,intake_open,public_visible,public_copy")
    .eq("organization_id", organization.id)
    .eq("active", true)
    .order("name");
  if (offerings.error)
    throw new Error("Could not load programme publications.");
  return (
    <div className="space-y-8">
      <SiteEditor
        slug={organization.slug}
        enabled={crmEnabled}
        initial={{
          revision: data?.revision || 0,
          settings: {
            ...defaultSite,
            nameEn: organization.name,
            nameBn: organization.name,
            ...data?.settings,
          },
        }}
      />
      <OfferingEditor
        slug={organization.slug}
        offerings={(offerings.data || []).map((o) => ({
          ...o,
          public_copy: Object.fromEntries(
            Object.entries(o.public_copy).filter(
              ([, v]) => typeof v === "string",
            ),
          ) as Record<string, string>,
        }))}
        enabled={crmEnabled}
      />
    </div>
  );
}
