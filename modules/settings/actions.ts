"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getErpContext } from "@/modules/platform/auth/erp-context";
import {
  editablePolicySchema,
  type EditablePolicyInput,
} from "@/modules/settings/schema";

export type SettingsMutationResult =
  | { ok: true; version?: number; correlationId?: string }
  | { ok: false; error: string; field?: string };

export async function publishPolicy(
  input: EditablePolicyInput
): Promise<SettingsMutationResult> {
  const parsed = editablePolicySchema.safeParse(input);

  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    return {
      ok: false,
      error: issue?.message ?? "Please check the policy values.",
      field: issue?.path?.[0]?.toString(),
    };
  }

  const context = await getErpContext();
  if (!context?.permissions.includes("system.settings.manage")) {
    return { ok: false, error: "You are not authorized to publish business policies." };
  }

  const value = parsed.data;

  if(value.policy!=="batch_capacity") return {ok:false,error:"Only academic capacity policies are available in this version."};
  const domain="academics";const ruleKey="batch_capacity_policy";const payload={max_students:value.maxStudents};

  const supabase = await createClient();
  const { data, error } = await supabase.rpc("publish_business_rule_version", {
    p_domain: domain,
    p_rule_key: ruleKey,
    p_payload: payload,
    p_reason: value.reason,
  });

  if (error) return { ok: false, error: error.message };

  const result = data as { version?: number; correlation_id?: string } | null;

  revalidatePath("/dashboard/settings");
  revalidatePath("/dashboard/governance/rules");
  revalidatePath("/dashboard");

  return {
    ok: true,
    version: result?.version,
    correlationId: result?.correlation_id,
  };
}
