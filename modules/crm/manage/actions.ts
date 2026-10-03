"use server";
import { revalidatePath } from "next/cache";
import { crmAccess } from "../access";
import {
  manageMasterRecordSchema,
  type ManageMasterRecordInput,
} from "./schema";
export type ManageCrmMutationResult =
  | { ok: true; reference: string }
  | { ok: false; error: string; field?: string };
export async function manageCrmMasterRecord(
  input: ManageMasterRecordInput,
): Promise<ManageCrmMutationResult> {
  const parsed = manageMasterRecordSchema.safeParse(input);
  if (!parsed.success)
    return {
      ok: false,
      error: "Check the directory details.",
      field: parsed.error.issues[0]?.path[0]?.toString(),
    };
  const { db, organization } = await crmAccess(true);
  if (!["OWNER", "ADMIN"].includes(organization.role))
    return { ok: false, error: "Access denied." };
  const v = parsed.data;
  const result = await db.rpc("crm_master", {
    p_org: organization.id,
    p_request: v.requestId,
    p_input: v,
  });
  if (result.error)
    return {
      ok: false,
      error: "Could not save the record. Check for duplicate names or codes.",
    };
  revalidatePath("/dashboard/crm/manage");
  revalidatePath("/interest");
  revalidatePath("/");
  return { ok: true, reference: result.data.id };
}
