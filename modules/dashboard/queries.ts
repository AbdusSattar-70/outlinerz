import { createClient } from "@/lib/supabase/server";
import { can, type ErpContext } from "@/types/erp";

export type DashboardOverview = {
  activeProspects: number | null;
  activeStudents: number | null;
  activeStaff: number | null;
  pendingApprovals: number | null;
  dueFollowups: number | null;
  recentProspects: Array<{
    id: string;
    prospectNo: string;
    studentName: string;
    status: string;
    createdAt: string;
  }>;
};

const activeProspectStatuses = [
  "NEW",
  "CONTACTED",
  "COUNSELLING",
  "TRIAL_SCHEDULED",
  "TRIAL_ATTENDED",
  "REGISTERED",
  "FUTURE_FOLLOW_UP",
] as const;

export async function getDashboardOverview(
  context: ErpContext
): Promise<DashboardOverview> {
  const supabase = await createClient();

  let activeProspects: number | null = null;
  let activeStudents: number | null = null;
  let activeStaff: number | null = null;
  let pendingApprovals: number | null = null;
  let dueFollowups: number | null = null;
  let recentProspects: DashboardOverview["recentProspects"] = [];

  if (can(context, "crm.prospects.view")) {
    const [activeQ, dueQ, recentQ] = await Promise.all([
      supabase
        .from("prospects")
        .select("id", { count: "exact", head: true })
        .in("status", [...activeProspectStatuses]),
      supabase
        .from("prospects")
        .select("id", { count: "exact", head: true })
        .in("status", [...activeProspectStatuses])
        .lte("next_follow_up_at", new Date().toISOString()),
      supabase
        .from("prospects")
        .select("id,prospect_no,student_name,status,created_at")
        .order("created_at", { ascending: false })
        .limit(6),
    ]);

    activeProspects = activeQ.count ?? 0;
    dueFollowups = dueQ.count ?? 0;
    recentProspects = (recentQ.data ?? []).map((row) => ({
      id: row.id,
      prospectNo: row.prospect_no,
      studentName: row.student_name,
      status: row.status,
      createdAt: row.created_at,
    }));
  }

  if (can(context, "students.view")) {
    const { count } = await supabase
      .from("students")
      .select("id,enrollments!inner(id)", { count: "exact", head: true })
      .eq("enrollments.status", "ACTIVE");

    activeStudents = count ?? 0;
  }

  if (can(context, "staff.view")) {
    const { count } = await supabase
      .from("staff")
      .select("id", { count: "exact", head: true })
      .in("status", ["ACTIVE", "ON_LEAVE"]);

    activeStaff = count ?? 0;
  }

  if (can(context, "approvals.view")) {
    const { count } = await supabase
      .from("approval_requests")
      .select("id", { count: "exact", head: true })
      .eq("status", "PENDING");

    pendingApprovals = count ?? 0;
  }

  return {
    activeProspects,
    activeStudents,
    activeStaff,
    pendingApprovals,
    dueFollowups,
    recentProspects,
  };
}
