import "server-only";
import { cache } from "react";
import { cookies } from "next/headers";
import { ORGANIZATION_COOKIE } from "@/modules/organizations/server";
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

/** A cookie is a selection hint, never authorization. Explicit public links take precedence. */
export const resolvePublicSlug = cache(async (value?: string) => {
  const explicit = publicSlug(value);
  if (explicit) return explicit;
  const selected = (await cookies()).get(ORGANIZATION_COOKIE)?.value;
  if (!selected || !/^[0-9a-f-]{36}$/i.test(selected)) return "";
  const db = await organizationClient();
  const {
    data: { user },
    error: authError,
  } = await db.auth.getUser();
  if (authError || !user) return "";
  const { data: membership, error } = await db
    .from("memberships")
    .select("organization_id")
    .eq("user_id", user.id)
    .eq("organization_id", selected)
    .eq("active", true)
    .maybeSingle();
  if (error) throw new Error("Organization access could not be loaded.");
  if (!membership) return "";
  const { data: organization, error: orgError } = await db
    .from("organizations")
    .select("slug")
    .eq("id", membership.organization_id)
    .maybeSingle();
  if (orgError) throw new Error("Organization could not be loaded.");
  return organization?.slug || "";
});
