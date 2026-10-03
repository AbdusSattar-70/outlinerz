import Link from "next/link";
import { LocalizedText } from "@/components/shared/localized-text";
import { getReferrerWorkspace } from "@/modules/referrals/queries";
import { PageHeader } from "@/components/erp/page-header";
import { getAcademicWorkspace } from "@/modules/academics/operations/queries";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { TeacherWorkspace } from "@/modules/teacher/workspace";

function organizationToday() {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Dhaka",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
}

function addDays(isoDate: string, days: number) {
  const base = new Date(`${isoDate}T00:00:00Z`);
  base.setUTCDate(base.getUTCDate() + days);
  return base.toISOString().slice(0, 10);
}

export default async function TeacherDashboardPage() {
  const context = await requirePermission("academics.view");
  const today = organizationToday();
  // Include a short look-back so teachers can finish recent attendance.
  const from = addDays(today, -7);
  const to = addDays(today, 14);
  const [data, referrals] = await Promise.all([getAcademicWorkspace(from, to), getReferrerWorkspace()]);

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="Teaching"
        title="My Classes"
        description="Your assigned class sessions only. Record attendance on the session page after the class starts; an independent reviewer approves the submission."
      />
      <Link href="/dashboard/referrals" className="block space-y-2 rounded-xl border p-5"><h2 className="font-semibold"><LocalizedText en="My referrals and financial statement" bn="আমার রেফারাল ও আর্থিক হিসাব"/></h2><p><LocalizedText en="Acquisition rate" bn="শিক্ষার্থী আনার বোনাসের হার"/>: {referrals.policy.acquisitionPercent??"—"}% · <LocalizedText en="Referred students" bn="রেফার করা শিক্ষার্থী"/>: {referrals.students.length}</p><p><LocalizedText en="View collections, discounts, referral rewards, teaching earnings, payments and advance offsets →" bn="আদায়, ছাড়, রেফারাল বোনাস, পাঠদানের আয়, পরিশোধ ও অগ্রিম সমন্বয় দেখুন →"/></p></Link>
      <Link className="inline-block rounded-lg border p-3" href="/dashboard/my-work"><LocalizedText en="My attendance, compensation terms & tasks →" bn="আমার উপস্থিতি, পারিশ্রমিকের শর্ত ও কাজ →"/></Link>
      <TeacherWorkspace
        data={data}
        today={today}
        staffName={context.staffName}
        staffNo={context.staffNo}
        canRecordAttendance={context.permissions.includes(
          "academics.attendance.record",
        )}
        canManageSessions={context.permissions.includes(
          "academics.sessions.manage",
        )}
      />
    </div>
  );
}
