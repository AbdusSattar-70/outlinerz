import "server-only";
import { requireOrganization } from "@/modules/organizations/server";
export async function crmAccess(write = false) {
  const session = await requireOrganization();
  const allowed = write
    ? ["OWNER", "ADMIN", "OPERATOR"]
    : ["OWNER", "ADMIN", "OPERATOR", "ACADEMIC"];
  if (!allowed.includes(session.organization.role))
    throw new Error("CRM access denied.");
  const { data, error } = await session.db
    .from("organization_modules")
    .select("enabled")
    .eq("organization_id", session.organization.id)
    .eq("module", "CRM")
    .maybeSingle();
  if (error || (write && !data?.enabled))
    throw new Error("CRM is unavailable for this organization.");
  return { ...session, crmEnabled: Boolean(data?.enabled) };
}
