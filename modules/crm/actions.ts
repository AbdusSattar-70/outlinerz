"use server";
import { revalidatePath } from "next/cache";
import { crmAccess } from "./access";
import {
  recordProspectFollowupSchema,
  type RecordProspectFollowupInput,
} from "./schema";
export type ProspectFollowupResult =
  { ok: true; status: string } | { ok: false; error: string; field?: string };
export async function recordProspectFollowup(
  input: RecordProspectFollowupInput,
): Promise<ProspectFollowupResult> {
  const parsed = recordProspectFollowupSchema.safeParse(input);
  if (!parsed.success)
    return {
      ok: false,
      error: "Check the follow-up details.",
      field: parsed.error.issues[0]?.path[0]?.toString(),
    };
  const { db, organization } = await crmAccess(true);
  const v = parsed.data;
  const { data, error } = await db.rpc("crm_followup", {
    p_org: organization.id,
    p_request: v.requestId,
    p_input: {
      prospect_id: v.prospectId,
      followup_type: v.followupType,
      note: v.notes,
      outcome: v.outcome ?? null,
      stage: v.newStatus,
      lost_reason: v.lostReason ?? null,
      next_follow_up_at: v.nextFollowUpAt
        ? new Date(v.nextFollowUpAt).toISOString()
        : null,
    },
  });
  if (error)
    return {
      ok: false,
      error: "Could not save the follow-up. Refresh and retry.",
    };
  revalidatePath("/dashboard/crm/prospects");
  revalidatePath(`/dashboard/crm/prospects/${v.prospectId}`);
  return { ok: true, status: data.stage };
}
