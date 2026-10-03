"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";
import { requireErpContext } from "@/modules/platform/auth/erp-context";

const schema = z.object({
  admissionId: z.string().uuid(),
  requestId: z.string().uuid(),
  guardianSignedOn: z.iso.date(),
  studentSigned: z.boolean(),
  physicalCopyReference: z.string().trim().max(160).optional(),
  reason: z.string().trim().min(5).max(500),
});

export async function receivePhysicalConsent(input: unknown): Promise<{ ok: boolean; message: string }> {
  const parsed = schema.safeParse(input);
  if (!parsed.success) return { ok: false, message: parsed.error.issues[0]?.message ?? "Check the signed paper form details." };
  const context = await requireErpContext();
  if (!context.permissions.includes("admissions.create")) return { ok: false, message: "Admission permission required." };
  const db = (await createClient()) as unknown as SupabaseClient;
  const { error } = await db.rpc("record_physical_admission_consent", { p_input: {
    admission_id: parsed.data.admissionId,
    request_id: parsed.data.requestId,
    guardian_signed_on: parsed.data.guardianSignedOn,
    student_signed: parsed.data.studentSigned,
    physical_copy_reference: parsed.data.physicalCopyReference || null,
    reason: parsed.data.reason,
  } });
  if (error) return { ok: false, message: error.message };
  revalidatePath("/dashboard/admissions");
  revalidatePath(`/dashboard/admissions/${parsed.data.admissionId}`);
  return { ok: true, message: "Paper consent received and recorded. Keep the signed original in the student file." };
}
