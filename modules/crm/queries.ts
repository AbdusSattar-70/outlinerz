import { crmAccess } from "./access";
import type { ProspectStatus } from "./prospect-status";
export type SubmissionIntent = "interest" | "admission";
export type ProspectListRow = {
  id: string;
  prospectNo: string;
  studentName: string;
  guardianName: string;
  mobile: string;
  className: string;
  schoolName: string;
  schoolNeedsReview: boolean;
  sourceName: string;
  assignedTo: string;
  assignedStaffId: string | null;
  status: ProspectStatus;
  nextFollowUpAt: string | null;
  createdAt: string;
  submissionIntent: SubmissionIntent;
  offeringLabel: string;
};
export async function getProspectList(): Promise<ProspectListRow[]> {
  const { db, organization } = await crmAccess();
  const queries = await Promise.all([
    db
      .from("prospects")
      .select("*")
      .eq("organization_id", organization.id)
      .order("created_at", { ascending: false })
      .limit(500),
    db
      .from("schools")
      .select("id,name,is_verified")
      .eq("organization_id", organization.id),
    db
      .from("offerings")
      .select("id,name")
      .eq("organization_id", organization.id),
  ]);
  for (const q of queries)
    if (q.error) throw new Error("CRM records could not be loaded.");
  const [prospects, schools, offerings] = queries;
  return (prospects.data ?? []).map((p) => {
    const school = schools.data?.find((s) => s.id === p.school_id);
    return {
      id: p.id,
      prospectNo: p.id.slice(0, 8).toUpperCase(),
      studentName: p.student_name,
      guardianName: p.guardian_name ?? "—",
      mobile: p.phone,
      className: String(p.application_snapshot.class_label ?? "—"),
      schoolName:
        school?.name ??
        String(p.application_snapshot.schoolNameSnapshot ?? "—"),
      schoolNeedsReview: school
        ? !school.is_verified
        : Boolean(p.application_snapshot.schoolNameSnapshot),
      sourceName: p.source,
      assignedTo: p.assigned_user_id?.slice(0, 8) ?? "—",
      assignedStaffId: p.assigned_user_id,
      status: p.stage,
      nextFollowUpAt: p.next_follow_up_at,
      createdAt: p.created_at,
      submissionIntent: p.submission_intent,
      offeringLabel:
        offerings.data?.find((o) => o.id === p.offering_id)?.name ??
        String(p.application_snapshot.offering_label ?? "—"),
    };
  });
}
export async function getProspectDetail(id: string) {
  const { db, organization } = await crmAccess();
  const { data, error } = await db
    .from("prospects")
    .select("*")
    .eq("organization_id", organization.id)
    .eq("id", id)
    .maybeSingle();
  if (error) throw new Error("CRM record could not be loaded.");
  if (!data) return null;
  const { data: followups, error: followupError } = await db
    .from("followups")
    .select("*")
    .eq("organization_id", organization.id)
    .eq("prospect_id", id)
    .order("created_at", { ascending: false });
  if (followupError) throw new Error("Follow-ups could not be loaded.");
  return { ...data, followups: followups ?? [] };
}
