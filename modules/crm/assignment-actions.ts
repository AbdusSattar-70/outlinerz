"use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { platformClient } from "@/modules/platform/rpc-client";
export async function assignProspect(input: unknown) {
  const parsed = z
    .object({
      prospect_id: z.string().uuid(),
      staff_id: z.union([z.string().uuid(), z.literal("")]),
      reason: z.string().min(5).max(500),
    })
    .safeParse(input);
  if (!parsed.success)
    return { ok: false, message: "Choose a staff member or Unassigned." };
  const db = await platformClient();
  const { error } = await db.rpc("assign_prospect_staff", {
    p_input: parsed.data,
  });
  if (error) return { ok: false, message: error.message };
  revalidatePath("/dashboard/crm/prospects");
  revalidatePath(`/dashboard/crm/prospects/${parsed.data.prospect_id}`);
  revalidatePath("/dashboard/governance/audit");
  return {
    ok: true,
    message:
      "Follow-up responsibility saved. Referral compensation is managed separately on the admission case.",
  };
}
