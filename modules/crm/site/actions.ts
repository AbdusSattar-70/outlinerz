"use server";
import { revalidatePath } from "next/cache";
import { crmAccess } from "../access";
import { type SiteSettings } from "./model";
import { siteCopy } from "./catalogue";
export async function saveSite(input: {
  requestId: string;
  revision: number;
  settings: SiteSettings;
}) {
  const { db, organization } = await crmAccess(true);
  if (!["OWNER", "ADMIN"].includes(organization.role))
    return { error: "Access denied." };
  if (
    !/^[0-9a-f-]{36}$/i.test(input.requestId) ||
    !Number.isInteger(input.revision) ||
    input.revision < 0
  )
    return { error: "Invalid save request." };
  if (
    Object.keys(input.settings.copy).some(
      (k) => !siteCopy.some((e) => e.key === k),
    )
  )
    return { error: "Unknown content field." };
  const { data, error } = await db.rpc("crm_site_save", {
    p_org: organization.id,
    p_request: input.requestId,
    p_revision: input.revision,
    p_settings: input.settings,
  });
  if (error)
    return {
      error: error.message.includes("Reload")
        ? "Someone updated these settings. Reload before saving."
        : "Could not save. Check the names and image URLs.",
    };
  revalidatePath("/", "layout");
  return { revision: data.revision };
}
export async function saveOffering(input: {
  requestId: string;
  id: string;
  expected: import("./offering-editor").OfferingPublication;
  value: import("./offering-editor").OfferingPublication;
}) {
  const { db, organization } = await crmAccess(true);
  if (!["OWNER", "ADMIN"].includes(organization.role))
    return { error: "Access denied." };
  const { error } = await db.rpc("crm_site_offering", {
    p_org: organization.id,
    p_request: input.requestId,
    p_offering: input.id,
    p_expected: input.expected,
    p_input: input.value,
  });
  if (error)
    return {
      error: error.message.includes("Reload")
        ? "Reload before saving."
        : "Could not save programme publication.",
    };
  revalidatePath("/", "layout");
  return { ok: true };
}
