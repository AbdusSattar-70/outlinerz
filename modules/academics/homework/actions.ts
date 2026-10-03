"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getErpContext } from "@/modules/platform/auth/erp-context";
import { homeworkCommandSchema, type HomeworkCommand } from "./schema";

export async function recordHomeworkCheck(input: HomeworkCommand) {
  const parsed = homeworkCommandSchema.safeParse(input);
  if (!parsed.success) return { ok: false, message: parsed.error.issues[0]?.message ?? "Check homework review." };
  const context = await getErpContext();
  if (!context?.permissions.includes("academics.view") ||
    !(context.permissions.includes("academics.attendance.record") || context.permissions.includes("academics.sessions.manage"))) return { ok: false, message: "Teaching permission required." };
  const db = await createClient();
  const { error } = await db.rpc("homework_command" as never, { p_input: parsed.data } as never);
  if (error) return { ok: false, message: error.message };
  revalidatePath(`/dashboard/academics/sessions/${parsed.data.session_id}`);
  return { ok: true, message: "Homework check recorded." };
}
