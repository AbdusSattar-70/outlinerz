"use server";

import { revalidatePath } from "next/cache";
import { getErpContext } from "@/modules/platform/auth/erp-context";
import { createOfferingClient } from "@/modules/offerings/database-contract";
import {
  createOfferingSchema,
  updateOfferingSchema,
  updateOfferingPublicControlsSchema,
  type CreateOfferingInput,
  type UpdateOfferingInput,
  type UpdateOfferingPublicControlsInput,
} from "@/modules/offerings/schema";

export type OfferingMutationResult =
  | { ok: true; reference: string }
  | { ok: false; error: string; field?: string };

export async function createProgrammeOffering(
  input: CreateOfferingInput,
): Promise<OfferingMutationResult> {
  const parsed = createOfferingSchema.safeParse(input);
  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    return {
      ok: false,
      error: issue?.message ?? "Check the offering details.",
      field: issue?.path[0]?.toString(),
    };
  }
  const context = await getErpContext();
  if (!context?.permissions.includes("academics.manage")) {
    return { ok: false, error: "You are not authorized to create offerings." };
  }
  const value = parsed.data;
  const db = await createOfferingClient();
  const { data, error } = await db.rpc("create_programme_offering", {
    p_input: {
      branch_id: value.branchId,
      academic_year_id: value.academicYearId,
      class_id: value.classId,
      program_id: value.programId,
      group_id: value.groupId || null,
      code: value.code,
      name: value.name,
      reason: value.reason,
    },
  });
  if (error) return { ok: false, error: error.message };
  const result = data as { offering_id?: string } | null;
  if (!result?.offering_id)
    return { ok: false, error: "Offering creation returned no identity." };
  revalidatePath("/dashboard/academics/offerings");
  return { ok: true, reference: result.offering_id };
}

export async function updateProgrammeOffering(
  input: UpdateOfferingInput,
): Promise<OfferingMutationResult> {
  const parsed = updateOfferingSchema.safeParse(input);
  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    return {
      ok: false,
      error: issue?.message ?? "Check the offering details.",
      field: issue?.path[0]?.toString(),
    };
  }
  const context = await getErpContext();
  if (!context?.permissions.includes("academics.manage"))
    return { ok: false, error: "You are not authorized to edit offerings." };
  const value = parsed.data;
  const db = await createOfferingClient();
  const { data, error } = await db.rpc("update_programme_offering", {
    p_input: {
      offering_id: value.offeringId,
      request_id: value.requestId,
      branch_id: value.branchId,
      academic_year_id: value.academicYearId,
      class_id: value.classId,
      program_id: value.programId,
      group_id: value.groupId || null,
      code: value.code,
      name: value.name,
      reason: value.reason,
    },
  });
  if (error) return { ok: false, error: error.message };
  const result = data as { offering_id?: string } | null;
  if (!result?.offering_id)
    return { ok: false, error: "Offering update returned no identity." };
  for (const path of [
    "/dashboard/academics/offerings",
    "/dashboard/academics/batches",
    "/dashboard/admissions",
    "/",
  ])
    revalidatePath(path);
  return { ok: true, reference: result.offering_id };
}

export async function updateProgrammeOfferingPublicControls(
  input: UpdateOfferingPublicControlsInput,
): Promise<OfferingMutationResult> {
  const parsed = updateOfferingPublicControlsSchema.safeParse(input);
  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    return {
      ok: false,
      error: issue?.message ?? "Check public controls.",
      field: issue?.path[0]?.toString(),
    };
  }
  const context = await getErpContext();
  if (!context?.permissions.includes("academics.manage")) {
    return {
      ok: false,
      error: "You are not authorized to update offering public controls.",
    };
  }
  const value = parsed.data;
  const db = await createOfferingClient();
  const { data, error } = await db.rpc(
    "update_programme_offering_public_controls",
    {
      p_input: {
        offering_id: value.offeringId,
        showcase_title: value.showcaseTitle || null,
        showcase_title_bn: value.showcaseTitleBn || null,
        showcase_description: value.showcaseDescription || null,
        showcase_description_bn: value.showcaseDescriptionBn || null,
        showcase_eyebrow: value.showcaseEyebrow || null,
        showcase_eyebrow_bn: value.showcaseEyebrowBn || null,
        public_schedule: value.publicSchedule || null,
        public_schedule_bn: value.publicScheduleBn || null,
        public_requirements: value.publicRequirements || null,
        public_requirements_bn: value.publicRequirementsBn || null,
        admission_policy: value.admissionPolicy || null,
        admission_policy_bn: value.admissionPolicyBn || null,
        showcase_icon: value.showcaseIcon || null,
        showcase_sort_order: value.showcaseSortOrder,
        is_website_visible: value.isWebsiteVisible,
        is_accepting_applications: value.isAcceptingApplications,
        applications_open_on: value.applicationsOpenOn?.trim() || null,
        applications_close_on: value.applicationsCloseOn?.trim() || null,
        subject_ids: value.subjectIds,
        reason: value.reason,
      },
    },
  );
  if (error) return { ok: false, error: error.message };
  const result = data as { offering_id?: string } | null;
  if (!result?.offering_id) {
    return { ok: false, error: "Public controls update returned no identity." };
  }
  revalidatePath("/dashboard/academics/offerings");
  revalidatePath("/");
  revalidatePath("/interest");
  return { ok: true, reference: result.offering_id };
}

