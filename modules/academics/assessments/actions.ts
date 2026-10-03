"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getErpContext } from "@/modules/platform/auth/erp-context";
import { assessmentCommandSchema, type AssessmentCommand } from "./schema";

export async function runAssessmentCommand(input: AssessmentCommand) {
  const parsed = assessmentCommandSchema.safeParse(input);
  if (!parsed.success) return { ok: false, message: parsed.error.issues[0]?.message ?? "Check the assessment." };
  const context = await getErpContext();
  if (!context?.permissions.includes("academics.view")) return { ok: false, message: "Academic access required." };
  const db = await createClient();
  const { error } = await db.rpc("assessment_command" as never, { p_input: parsed.data } as never);
  if (error) return { ok: false, message: error.message };
  revalidatePath("/dashboard/academics/assessments");
  return { ok: true, message: "Assessment workflow updated." };
}
