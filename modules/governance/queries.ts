import { createClient } from "@/lib/supabase/server";

export async function getApprovalList() {
  const supabase = await createClient();
  const { data } = await supabase
    .from("approval_requests")
    .select(
      "id,workflow_type,entity_type,entity_id,requested_action,status,requested_at,request_note,decision_note",
    )
    .order("requested_at", { ascending: false })
    .limit(200);

  return data ?? [];
}

export type AuditRow = {
  id: string;
  occurred_at: string;
  actor_profile_id: string | null;
  actor_staff_id: string | null;
  actor_role_code: string | null;
  actor_name: string | null;
  actor_staff_no: string | null;
  identity_snapshot: boolean;
  entity_type: string;
  entity_id: string;
  action: string;
  reason: string | null;
  correlation_id: string;
  before_data: unknown;
  after_data: unknown;
  metadata: unknown;
};
export async function getAuditList(correlation?: string) {
  const { platformClient } = await import("@/modules/platform/rpc-client");
  const db = await platformClient();
  const { data, error } = await db.rpc("audit_event_list", {
    p_correlation: correlation ?? null,
  });
  if (error) throw new Error(error.message);
  return data as AuditRow[];
}

export async function getBusinessRules() {
  const supabase = await createClient();
  const { data } = await supabase
    .from("business_rule_versions")
    .select(
      "id,domain,rule_key,version,status,effective_from,effective_to,payload,change_reason,created_at",
    )
    .order("domain")
    .order("rule_key")
    .order("version", { ascending: false });

  return data ?? [];
}

export type AuditPageData={rows:Pick<AuditRow,"id"|"occurred_at"|"action"|"entity_type"|"entity_id"|"reason"|"actor_profile_id"|"actor_name"|"actor_staff_no"|"actor_role_code">[];total:number;page:number;pageSize:number;activity:{date:string;admissions:number|null;invoices:number|null;grossIssued:number|null;collected:number|null;refunds:number|null}};
export async function getAuditPage(filters:Record<string,string>):Promise<AuditPageData>{
 const {platformClient}=await import("@/modules/platform/rpc-client");const db=await platformClient();
 const {data,error}=await db.rpc("audit_event_page",{p_filters:filters});if(error)throw Error(error.message);return data as unknown as AuditPageData;
}
