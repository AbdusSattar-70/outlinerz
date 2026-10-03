"use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { platformClient } from "@/modules/platform/rpc-client";
export async function saveExtraCharge(input: unknown) {
  const parsed = z
    .object({
      admission_id: z.string().uuid(),
      request_id: z.string().uuid(),
      name: z.string().trim().min(2).max(100),
      amount: z.number().positive().max(99999999),
      charge_type: z.enum(["ADMISSION", "EXAM", "MATERIAL", "OTHER"]),
    })
    .safeParse(input);
  if (!parsed.success)
    return {
      ok: false,
      message: "Choose the charge and enter a positive amount.",
    };
  const db = await platformClient();
  const { error } = await db.rpc("save_admission_extra_charge", {
    p_input: parsed.data,
  });
  if (error) return { ok: false, message: error.message };
  revalidatePath(`/dashboard/admissions/${parsed.data.admission_id}`);
  return {
    ok: true,
    message:
      "One-time charge added to draft. It will be invoiced at final submission.",
  };
}
export async function deactivateExtraCharge(
  admissionId: string,
  chargeId: string,
) {
  if (
    !z.string().uuid().safeParse(admissionId).success ||
    !z.string().uuid().safeParse(chargeId).success
  )
    return { ok: false, message: "Invalid charge." };
  const db = await platformClient();
  const { error } = await db.rpc("deactivate_admission_extra_charge", {
    p_admission_id: admissionId,
    p_charge_id: chargeId,
  });
  if (error) return { ok: false, message: error.message };
  revalidatePath(`/dashboard/admissions/${admissionId}`);
  return {
    ok: true,
    message: "Draft charge marked inactive. Audit history retained.",
  };
}
