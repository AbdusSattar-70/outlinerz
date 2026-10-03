"use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { crmAccess } from "./access";
export async function assignProspect(input: unknown) {
  const parsed = z
    .object({
      prospect_id: z.uuid(),
      staff_id: z.union([z.uuid(), z.literal("")]),
    })
    .safeParse(input);
  if (!parsed.success)
    return { ok: false, message: "Choose a valid staff member." };
  const { db, organization } = await crmAccess(true);
  const { error } = await db.rpc("crm_assign", {
    p_org: organization.id,
    p_prospect: parsed.data.prospect_id,
    p_user: parsed.data.staff_id || null,
  });
  if (error) return { ok: false, message: "Assignment could not be saved." };
  revalidatePath(`/dashboard/crm/prospects/${parsed.data.prospect_id}`);
  revalidatePath("/dashboard/crm/prospects");
  return { ok: true, message: "Follow-up responsibility saved." };
}
