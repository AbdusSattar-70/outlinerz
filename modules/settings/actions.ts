"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getErpContext } from "@/modules/platform/auth/erp-context";
import {
  editablePolicySchema,
  rolePermissionUpdateSchema,
  userAccessUpdateSchema,
  type EditablePolicyInput,
  type RolePermissionUpdateInput,
  type UserAccessUpdateInput,
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
  let domain: string;
  let ruleKey: string;
  let payload: Record<string, boolean | number | string>;

  switch (value.policy) {
    case "batch_capacity":
      domain = "academics";
      ruleKey = "batch_capacity_policy";
      payload = { max_students: value.maxStudents };
      break;
    case "teacher_compensation":
      domain = "teacher_compensation";
      ruleKey = "default_policy";
      payload = {
        teaching_pool_percent: value.teachingPoolPercent,
        teaching_pool_review_max_percent: value.teachingPoolReviewMaxPercent,
        acquisition_bonus_percent: value.acquisitionBonusPercent,
        retention_3_month_percent: value.retention3MonthPercent,
        retention_6_month_percent: value.retention6MonthPercent,
      };
      break;
    case "admission_activation":
      domain = "admissions";
      ruleKey = "activation_policy";
      payload = {
        requires_admission_acceptance: value.requiresAdmissionAcceptance,
        requires_initial_billing_posted: value.requiresInitialBillingPosted,
        payment_requirement: value.paymentRequirement,
        minimum_payment_percent: value.minimumPaymentPercent,
        allow_credit_enrollment: value.allowCreditEnrollment,
        count_student_active_only_when_enrollment_active:
          value.countStudentActiveOnlyWhenEnrollmentActive,
      };
      break;
  }

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

export async function updateRolePermissions(
  input: RolePermissionUpdateInput
): Promise<SettingsMutationResult> {
  const parsed = rolePermissionUpdateSchema.safeParse(input);

  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    return {
      ok: false,
      error: issue?.message ?? "Please check the access-control change.",
      field: issue?.path?.[0]?.toString(),
    };
  }

  if (parsed.data.roleCode === "ADMIN") {
    return {
      ok: false,
      error: "The bootstrap ADMIN role is protected and cannot be edited here.",
    };
  }

  const context = await getErpContext();
  if (!context?.permissions.includes("system.roles.manage")) {
    return { ok: false, error: "You are not authorized to manage role permissions." };
  }

  const supabase = await createClient();
  const { data, error } = await supabase.rpc("set_role_permissions", {
    p_role_code: parsed.data.roleCode,
    p_permission_codes: parsed.data.permissionCodes,
    p_reason: parsed.data.reason,
  });

  if (error) return { ok: false, error: error.message };

  const result = data as { correlation_id?: string } | null;

  revalidatePath("/dashboard/settings");
  revalidatePath("/dashboard");

  return { ok: true, correlationId: result?.correlation_id };
}


export async function updateUserOperationalAccess(
  input: UserAccessUpdateInput
): Promise<SettingsMutationResult> {
  const parsed = userAccessUpdateSchema.safeParse(input);

  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    return {
      ok: false,
      error: issue?.message ?? "Please check the user access change.",
      field: issue?.path?.[0]?.toString(),
    };
  }

  if (parsed.data.roleCodes.includes("ADMIN")) {
    return {
      ok: false,
      error: "ADMIN access is protected and cannot be assigned through this editor.",
    };
  }

  const context = await getErpContext();
  if (!context?.permissions.includes("system.users.manage")) {
    return { ok: false, error: "You are not authorized to manage user access." };
  }

  const supabase = await createClient();
  const { data, error } = await supabase.rpc("set_user_operational_roles", {
    p_profile_id: parsed.data.profileId,
    p_role_codes: parsed.data.roleCodes,
    p_reason: parsed.data.reason,
  });

  if (error) return { ok: false, error: error.message };

  const result = data as { correlation_id?: string } | null;

  revalidatePath("/dashboard/settings");
  revalidatePath("/dashboard");

  return { ok: true, correlationId: result?.correlation_id };
}
