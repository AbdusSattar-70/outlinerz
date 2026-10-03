import "server-only";
import { organizationClient } from "@/modules/organizations/server";
export function publicSlug(value?: string) {
  return (
    value?.trim() || process.env.NEXT_PUBLIC_ORGANIZATION_SLUG?.trim() || ""
  );
}
export async function getPublicOptions(slug: string) {
  if (!slug) return null;
  const db = await organizationClient();
  const { data, error } = await db.rpc("crm_public_options", { p_slug: slug });
  if (error) return null;
  return data;
}
