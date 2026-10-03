"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getErpContext } from "@/modules/platform/auth/erp-context";
import {
  recordProspectFollowupSchema,
  type RecordProspectFollowupInput,
} from "@/modules/crm/schema";
import {
  allowedProspectStatuses,
  prospectStatuses,
  type ProspectStatus,
} from "@/modules/crm/prospect-status";

export type ProspectFollowupResult =
  | { ok: true; status: string }
  | { ok: false; error: string; field?: string };

export async function recordProspectFollowup(
  input: RecordProspectFollowupInput
): Promise<ProspectFollowupResult> {
  const parsed = recordProspectFollowupSchema.safeParse(input);

  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    return {
      ok: false,
      error: issue?.message ?? "Please check the follow-up information.",
      field: issue?.path?.[0]?.toString(),
    };
  }

  const context = await getErpContext();
  if (!context || !context.permissions.includes("crm.followups.manage")) {
    return { ok: false, error: "You are not authorized to record CRM follow-ups." };
  }

  const supabase = await createClient();
  const { data: current, error: currentError } = await supabase
    .from("prospects")
    .select("status")
    .eq("id", parsed.data.prospectId)
    .maybeSingle();

  if (currentError || !current) {
    return { ok: false, error: "Prospect could not be loaded." };
  }

  if (!allowedProspectStatuses(current.status).includes(parsed.data.newStatus)) {
    return {
      ok: false,
      error: `Status cannot move from ${current.status} to ${parsed.data.newStatus} through a follow-up.`,
      field: "newStatus",
    };
  }

  const value = parsed.data;
  const nextFollowUpAt = value.nextFollowUpAt
    ? new Date(value.nextFollowUpAt).toISOString()
    : null;

  const { data, error } = await supabase.rpc("record_prospect_followup", {
    p_input: {
      prospect_id: value.prospectId,
      followup_type: value.followupType,
      notes: value.notes,
      outcome: value.outcome || null,
      new_status: value.newStatus,
      next_follow_up_at: nextFollowUpAt,
      lost_reason: value.lostReason || null,
    },
  });

  if (error) return { ok: false, error: error.message };

  const result = data as { status?: string } | null;
  const rawStatus = result?.status;
  if (rawStatus && !prospectStatuses.includes(rawStatus as ProspectStatus))
    return {
      ok: false,
      error: "Follow-up returned an unknown prospect status.",
      field: "newStatus",
    };
  const status = (rawStatus as ProspectStatus | undefined) ?? value.newStatus;

  revalidatePath("/dashboard");
  revalidatePath("/dashboard/action-center");
  revalidatePath("/dashboard/crm/prospects");
  revalidatePath(`/dashboard/crm/prospects/${value.prospectId}`);

  return { ok: true, status };
}
