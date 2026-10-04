"use server";
import { revalidatePath } from "next/cache";
import { getErpContext } from "@/modules/platform/auth/erp-context";
import { admissionClient } from "./queries";
import { commandSchema, type AdmissionCommand } from "./schema";
import type { Json } from "@/types/database";
export async function runAdmissionCommand(input: AdmissionCommand): Promise<{
  ok: boolean;
  message: string;
  field?: string;
  entityId?: string;
}> {
  const parsed = commandSchema.safeParse(input);
  if (!parsed.success)
    return {
      ok: false,
      message: parsed.error.issues[0].message,
      field: parsed.error.issues[0].path[0]?.toString(),
    };
  const v = parsed.data;
  if(["PAY","BILL","REFRESH_FEES","SAVE_DISCOUNT"].includes(v.action)) return {ok:false,message:"This version supports academic admission only."};
  const context = await getErpContext();
  const permission =
    v.action === "CREATE_BATCH" || v.action === "EDIT_BATCH"
      ? "academics.manage"
      : "admissions.create";
  if (!context?.permissions.includes(permission))
    return {
      ok: false,
      message: "You do not have permission for this action.",
    };
  const payload: Record<string, Json> = {
    action: v.action,
    request_id: v.requestId,
    reason: v.reason,
  };
  const fields = {
    studentName: "student_name",
    guardianName: "guardian_name",
    mobile: "mobile",
    offeringId: "offering_id",
    prospectId: "prospect_id",
    confirmPlacementCorrection: "confirm_placement_correction",
    batchId: "batch_id",
    admissionId: "admission_id",
    code: "code",
    name: "name",
    capacity: "capacity",
  } as const;
  for (const [key, column] of Object.entries(fields)) {
    const value = v[key as keyof typeof fields];
    if (value !== undefined) payload[column] = value;
  }
  const db = await admissionClient();
  const command =
    v.action === "CREATE_BATCH" || v.action === "EDIT_BATCH"
        ? "batch_command"
        : v.action === "CREATE"
          ? "create_prospect_admission"
          : "admission_command";
  const { data, error } = await db.rpc(command, { p_input: payload });
  if (error) return { ok: false, message: error.message };
  const result = data as { id?: string; status?: string };
  for (const path of [
    "/dashboard/admissions",
    "/dashboard/academics/batches",
    "/dashboard/students",
    "/dashboard/crm/prospects",
    "/dashboard/governance/audit",
    "/dashboard",
  ])
    revalidatePath(path);
  if (typeof result.id === "string")
    revalidatePath(`/dashboard/admissions/${result.id}`);
  return {
    ok: true,
    message: v.action === "CREATE_BATCH"
        ? "Batch created."
        : v.action === "EDIT_BATCH"
          ? "Batch updated."
          : `Saved: ${(result.status ?? "completed").replaceAll("_", " ")}.`,
    entityId: result.id,
  };
}
