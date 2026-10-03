"use server";

import { revalidatePath } from "next/cache";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";
import { getErpContext } from "@/modules/platform/auth/erp-context";
import {
  manageMasterRecordSchema,
  type ManageMasterRecordInput,
} from "@/modules/crm/manage/schema";

export type ManageCrmMutationResult =
  | { ok: true; reference: string }
  | { ok: false; error: string; field?: string };

export async function manageCrmMasterRecord(
  input: ManageMasterRecordInput,
): Promise<ManageCrmMutationResult> {
  const parsed = manageMasterRecordSchema.safeParse(input);
  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    return {
      ok: false,
      error: issue?.message ?? "Check the master-data details.",
      field: issue?.path[0]?.toString(),
    };
  }

  const context = await getErpContext();
  if (!context?.permissions.includes("system.master_data.manage")) {
    return { ok: false, error: "You are not authorized to manage CRM master data." };
  }

  const value = parsed.data;
  const supabase = await createClient();
  const rpcClient = supabase as unknown as {
    rpc: (
      fn: "manage_crm_master_record",
      args: { p_input: Record<string, unknown> },
    ) => Promise<{ data: unknown; error: { message: string } | null }>;
  };

  const { data, error } = await rpcClient.rpc("manage_crm_master_record", {
    p_input: {
      entity: value.entity,
      id: value.id || null,
      code: value.code ?? null,
      name: value.name ?? null,
      description: value.description ?? null,
      sort_order: value.sortOrder ?? 0,
      starts_on: value.startsOn || null,
      ends_on: value.endsOn || null,
      area_id: value.areaId || null,
      is_active: value.isActive,
      is_verified: value.isVerified ?? false,
      reason: value.reason,
    },
  });

  if (error) return { ok: false, error: error.message };

  // If a gateway returns an empty body for an edit, read the persisted row
  // before asking the operator to retry a write that may already have succeeded.
  const response = typeof data === "string" ? safeJson(data) : data;
  const result = Array.isArray(response) ? response[0] : response;
  let savedId = isResult(result) ? result.id : null;
  const action = isResult(result) ? result.action : undefined;
  if (!savedId && value.id) {
    const table = {
      academic_year: "academic_years",
      class: "classes",
      group: "academic_groups",
      subject: "subjects",
      program: "programs",
      school: "schools",
      lead_source: "lead_sources",
      guardian_relationship: "guardian_relationships",
    }[value.entity];
    const reader = supabase as unknown as SupabaseClient;
    const columns = value.entity === "academic_year"
      ? "id,name,starts_on,ends_on,is_active"
      : value.entity === "school" ? "id,name,is_active" : "id,name,code,is_active";
    const { data: row, error: readError } = await reader.from(table)
      .select(columns)
      .eq("id", value.id).maybeSingle();
    const saved = row as { id: string; name: string; code?: string; starts_on?: string; ends_on?: string; is_active: boolean } | null;
    if (!readError && saved && saved.name === value.name?.trim() &&
        (value.entity !== "academic_year" ||
          (saved.starts_on === value.startsOn && saved.ends_on === value.endsOn)) &&
        (value.entity === "academic_year" || value.entity === "school" ||
          saved.code === value.code?.trim().toUpperCase()) &&
        saved.is_active === value.isActive) savedId = saved.id;
  }
  if (!savedId) return { ok: false, error: "Could not confirm the saved record. Refresh the list before trying again." };

  revalidatePath("/dashboard/crm/manage");
  revalidatePath("/dashboard/crm/prospects");
  revalidatePath("/dashboard/academics/offerings");
  revalidatePath("/interest");
  revalidatePath("/");

  return { ok: true, reference: `${action ?? (value.id ? "UPDATE" : "CREATE")}:${savedId}` };
}

function safeJson(value: string): unknown {
  try { return JSON.parse(value) as unknown; } catch { return null; }
}
function isResult(value: unknown): value is { id: string; action?: string } {
  return typeof value === "object" && value !== null && "id" in value &&
    typeof value.id === "string" && value.id.length > 0;
}
