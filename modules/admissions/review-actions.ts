"use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { platformClient } from "@/modules/platform/rpc-client";
export async function correctAdmissionPlacement(input: unknown) {
  const parsed = z
    .object({
      admission_id: z.string().uuid(),
      offering_id: z.string().uuid(),
      batch_id: z.string().uuid(),
      reason: z.string().min(5).max(500),
    })
    .safeParse(input);
  if (!parsed.success)
    return { ok: false, message: "Choose an offering and available batch." };
  const db = await platformClient();
  const { error } = await db.rpc("correct_admission_placement", {
    p_input: parsed.data,
  });
  if (error) return { ok: false, message: error.message };
  revalidatePath("/dashboard/admissions");
  revalidatePath(`/dashboard/admissions/${parsed.data.admission_id}`);
  return {
    ok: true,
    message:
      "Placement saved. Recheck this draft, its fees and paper consent before submission.",
  };
}
const identitySchema = z.object({
 student_mobile:z.string().regex(/^$|^01[3-9][0-9]{8}$/).optional(),student_email:z.union([z.email(),z.literal("")]).optional(),present_landmark:z.string().max(160).optional(),permanent_address:z.string().max(300).optional(),permanent_same_as_present:z.enum(["true","false"]).optional(),
  student_name: z.string().trim().min(2).max(160),
  student_name_bn: z.string().max(160),
  guardian_name: z.string().trim().min(2).max(160),
  mobile: z.string().regex(/^01[3-9][0-9]{8}$/),
  alternate_mobile: z.string().regex(/^$|^01[3-9][0-9]{8}$/),
  guardian_address: z.string().trim().min(5).max(300),
  guardian_relationship: z.string().max(80),
  date_of_birth: z.union([z.iso.date(), z.literal("")]),
  gender: z.enum(["", "Female", "Male", "Other", "Prefer not to say"]),
  school_name: z.string().max(200),
  school_roll: z.string().max(40),
});
export async function editAdmissionIdentity(input: unknown) {
  const parsed = z
    .object({
      admission_id: z.string().uuid(),
      identity: identitySchema,
      reason: z.string().min(5).max(500),
    })
    .safeParse(input);
  if (!parsed.success)
    return {
      ok: false,
      message: parsed.error.issues[0]?.message ?? "Check the application.",
    };
  const db = await platformClient();
  const { error } = await db.rpc("edit_admission_identity", {
    p_input: parsed.data,
  });
  if (error) return { ok: false, message: error.message };
  revalidatePath("/dashboard/admissions");
  revalidatePath(`/dashboard/admissions/${parsed.data.admission_id}`);
  revalidatePath("/dashboard/students");
  return {
    ok: true,
    message:
      "Details corrected. Review the draft and obtain signed consent for the corrected details.",
  };
}
