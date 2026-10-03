import { notFound } from "next/navigation";
import { z } from "zod";
import { crmAccess } from "@/modules/crm/access";
import { getProspectDetail } from "@/modules/crm/queries";
import { ProspectDetailView } from "@/modules/crm/components/prospect-detail-view";
export default async function ProspectDetailPage({
  params,
}: {
  params: Promise<{ prospectId: string }>;
}) {
  const { prospectId } = await params;
  if (!z.uuid().safeParse(prospectId).success) notFound();
  const { db, organization, crmEnabled } = await crmAccess();
  const prospect = await getProspectDetail(prospectId);
  if (!prospect) notFound();
  const writable =
    crmEnabled && ["OWNER", "ADMIN", "OPERATOR"].includes(organization.role);
  const { data: members, error } = writable
    ? await db
        .from("memberships")
        .select("user_id,role")
        .eq("organization_id", organization.id)
        .eq("active", true)
        .in("role", ["OWNER", "ADMIN", "OPERATOR"])
    : { data: [], error: null };
  if (error) throw new Error("Assignment options could not be loaded.");
  return (
    <ProspectDetailView
      prospect={prospect}
      writable={writable}
      staff={(members ?? []).map((m) => ({
        id: m.user_id,
        name: m.user_id.slice(0, 8),
      }))}
    />
  );
}
