"use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { platformClient } from "@/modules/platform/rpc-client";
export async function closeEnrollment(input: unknown) {
  const parsed = z
    .object({
      student_id: z.string().uuid(),
      enrollment_id: z.string().uuid(),
      mode: z.enum(["WITHDRAWN", "COMPLETED"]),
      reason: z.string().trim().min(5).max(500),
    })
    .safeParse(input);
  if (!parsed.success)
    return { ok: false, message: "Choose a closure type and reason." };
  const db = await platformClient();
  const { data, error } = await db.rpc("close_student_enrollment", {
    p_input: parsed.data,
  });
  if (error) return { ok: false, message: error.message };
  for (const p of [
    "/dashboard/students",
    "/dashboard/admissions",
    "/dashboard/finance/billing",
    "/dashboard/academics/batches",
    "/dashboard/governance/audit",
    "/dashboard",
  ])
    revalidatePath(p);
  revalidatePath(`/dashboard/students/${parsed.data.student_id}`);
  revalidatePath("/dashboard/admissions/[admissionId]", "page");
  return { ok: true, message: data.message as string };
}
