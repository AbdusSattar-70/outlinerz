"use client";
import Link from "next/link";
import {
  ArrowLeft,
  CalendarClock,
  GraduationCap,
  MapPin,
  Phone,
  School,
  UserRound,
} from "lucide-react";
import { PageHeader } from "@/components/erp/page-header";
import { StatusBadge } from "@/components/erp/status-badge";
import { ProspectAssignmentForm } from "./prospect-assignment-form";
import { ProspectFollowupForm } from "./prospect-followup-form";
import { useLanguage } from "@/components/providers/language-provider";
import { useCrmText } from "../translations";
import type { Prospect, Followup } from "@/modules/organizations/database";
export function ProspectDetailView({
  prospect: p,
  writable,
  staff,
}: {
  prospect: Prospect & { followups: Followup[] };
  writable: boolean;
  staff: { id: string; name: string }[];
}) {
  const tr = useCrmText();
  const { locale } = useLanguage();
  const date = (v: string) =>
    new Date(v).toLocaleString(locale === "bn" ? "bn-BD" : "en-GB");
  const s = p.application_snapshot;
  const text = (key: string) => String(s[key] ?? "—");
  const strings = (key: string) =>
    Array.isArray(s[key]) ? (s[key] as string[]) : [];
  const prospect = {
    id: p.id,
    studentName: p.student_name,
    prospectNo: p.id.slice(0, 8).toUpperCase(),
    applicationSnapshot: {
      class_label: text("class_label"),
      offering_label: text("offering_label"),
      subject_labels: strings("subject_labels"),
    },
    status: p.stage,
    createdAt: p.created_at,
    submissionIntent: p.submission_intent,
    offeringLabel: text("offering_label"),
    assignedStaffId: p.assigned_user_id,
    assignedTo: p.assigned_user_id?.slice(0, 8) || "—",
    guardianName: p.guardian_name || "—",
    relationship: text("relationship"),
    mobile: p.phone,
    alternateMobile:
      text("alternateMobile") === "—" ? null : text("alternateMobile"),
    className: text("class_label"),
    schoolName: text("schoolNameSnapshot"),
    schoolNeedsReview: !!s.schoolNameSnapshot && !p.school_id,
    area: text("area"),
    nextFollowUpAt: p.next_follow_up_at,
    sourceName: p.source,
    preferredSchedule: text("preferredSchedule"),
    preferredDays: strings("preferredDays"),
    trialInterest: s.trialInterest === true,
    programs: strings("program_labels"),
    subjects: strings("subject_labels"),
    referralNote: text("referralNote"),
    notes: p.notes,
    lostReason: p.lost_reason,
    followups: p.followups.map((f) => ({
      id: f.id,
      type: f.followup_type,
      recordedBy: f.recorded_by?.slice(0, 8) || "—",
      occurredAt: f.completed_at || f.due_at,
      notes: f.note,
      outcome: f.outcome,
      nextFollowUpAt: f.next_follow_up_at,
    })),
  };
  return (
    <div className="space-y-7">
      {prospect.applicationSnapshot && (
        <section className="rounded-xl border border-amber-500/30 bg-card p-5">
          <h2 className="font-semibold">
            {tr("Applicant choices — not verified placement")}
          </h2>
          <p className="mt-2 text-sm">
            {tr("Class")}:{" "}
            {prospect.applicationSnapshot.class_label ?? tr("Not provided")} ·{" "}
            {tr("Programme")}:{" "}
            {prospect.applicationSnapshot.offering_label ??
              tr("General interest")}
          </p>
          <p className="mt-1 text-sm">
            {tr("Subjects")}:{" "}
            {prospect.applicationSnapshot.subject_labels?.join(", ") ||
              tr("Not provided")}
          </p>
          <p className="mt-2 text-xs text-muted-foreground">
            {tr(
              "These statements are preserved separately. Verify identity and choose the correct programme and batch when starting admission.",
            )}
          </p>
        </section>
      )}
      <PageHeader
        eyebrow={tr("CRM & Student Bank")}
        title={prospect.studentName}
        description={`${prospect.prospectNo} • ${tr("Prospect history remains linked after admission.")}`}
        actions={
          <div className="flex flex-wrap gap-2">
            <Link
              href="/dashboard/crm/prospects"
              className="inline-flex min-h-11 items-center gap-2 rounded-xl border bg-background px-4 text-sm font-semibold hover:bg-muted"
            >
              <ArrowLeft className="size-4" aria-hidden="true" />
              {tr("Back to Prospects")}
            </Link>
          </div>
        }
      />

      {writable && (
        <ProspectAssignmentForm
          prospectId={prospect.id}
          selected={prospect.assignedStaffId}
          staff={staff}
        />
      )}
      <div className="grid gap-5 xl:grid-cols-[1.15fr_.85fr]">
        <section className="rounded-2xl border bg-card p-5 sm:p-6">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
              <p className="text-sm text-muted-foreground">
                {tr("Current status")}
              </p>
              <div className="mt-2">
                <StatusBadge value={prospect.status} />
              </div>
            </div>
            <div className="text-right text-xs text-muted-foreground">
              <p>{tr("Created")}</p>
              <p className="mt-1 font-medium text-foreground">
                {date(prospect.createdAt)}
              </p>
              <p className="mt-3 capitalize text-foreground">
                {tr(
                  prospect.submissionIntent === "admission"
                    ? "Admission request"
                    : "Interest request",
                )}
              </p>
              <p className="mt-1 text-[11px] leading-4 text-muted-foreground">
                {prospect.offeringLabel}
              </p>
            </div>
          </div>

          {prospect.schoolNeedsReview ? (
            <div className="mt-6 rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-100">
              <p className="font-medium">
                {tr("School name needs staff review")}
              </p>
              <p className="mt-1 leading-6">
                {tr("Submitted as free text")}:{" "}
                <span className="font-semibold">{prospect.schoolName}</span>.
                {tr(
                  "Confirm or create the school in Manage CRM, then continue follow-up or admission.",
                )}
              </p>
              <Link
                href="/dashboard/crm/manage"
                className="mt-3 inline-flex text-sm font-semibold underline underline-offset-4"
              >
                {tr("Open Manage CRM")}
              </Link>
            </div>
          ) : null}

          <dl className="mt-6 grid gap-4 sm:grid-cols-2">
            <Info
              icon={UserRound}
              label={tr("Guardian")}
              value={`${prospect.guardianName} • ${prospect.relationship}`}
            />
            <Info
              icon={Phone}
              label={tr("Contact")}
              value={
                prospect.alternateMobile
                  ? `${prospect.mobile} / ${prospect.alternateMobile}`
                  : prospect.mobile
              }
            />
            <Info
              icon={GraduationCap}
              label={tr("Current Class")}
              value={prospect.className}
            />
            <Info
              icon={School}
              label={tr("School")}
              value={
                prospect.schoolNeedsReview
                  ? `${prospect.schoolName} (${tr("needs review")})`
                  : prospect.schoolName
              }
            />
            <Info icon={MapPin} label={tr("Area")} value={prospect.area} />
            <Info
              icon={CalendarClock}
              label={tr("Next Follow-up")}
              value={
                prospect.nextFollowUpAt
                  ? date(prospect.nextFollowUpAt)
                  : tr("Not scheduled")
              }
            />
          </dl>

          <div className="mt-6 grid gap-4 border-t pt-5 sm:grid-cols-2">
            <Detail label={tr("Lead Source")} value={prospect.sourceName} />
            <Detail label={tr("Follow-up staff")} value={prospect.assignedTo} />
            <Detail
              label={tr("Preferred Schedule")}
              value={prospect.preferredSchedule?.replaceAll("_", " ") ?? "—"}
            />
            <Detail
              label={tr("Preferred Days")}
              value={
                prospect.preferredDays?.length
                  ? prospect.preferredDays.map(tr).join(", ")
                  : "—"
              }
            />
            <Detail
              label={tr("Trial Interest")}
              value={prospect.trialInterest ? tr("Yes") : tr("No")}
            />
            <Detail
              label={tr("Interested Programs")}
              value={
                prospect.programs.length ? prospect.programs.join(", ") : "—"
              }
            />
            <Detail
              label={tr("Interested Subjects")}
              value={
                prospect.subjects.length ? prospect.subjects.join(", ") : "—"
              }
            />
            <Detail
              label={tr("Referral")}
              value={prospect.referralNote ?? "—"}
            />
          </div>

          {prospect.notes && (
            <div className="mt-5 rounded-xl bg-muted/40 p-4">
              <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                {tr("Original Note")}
              </p>
              <p className="mt-2 text-sm leading-6">{prospect.notes}</p>
            </div>
          )}

          {prospect.lostReason && (
            <div className="mt-5 rounded-xl border border-red-300 bg-red-50 p-4 text-red-950 dark:border-red-900 dark:bg-red-950/30 dark:text-red-100">
              <p className="text-xs font-semibold uppercase tracking-wide">
                {tr("Lost Reason")}
              </p>
              <p className="mt-2 text-sm leading-6">{prospect.lostReason}</p>
            </div>
          )}
        </section>

        <section className="overflow-hidden rounded-2xl border bg-card">
          <div className="border-b px-5 py-4">
            <h2 className="font-semibold">{tr("Follow-up timeline")}</h2>
            <p className="mt-1 text-xs text-muted-foreground">
              {tr(
                "Newest activity first. Existing timeline records are not rewritten.",
              )}
            </p>
          </div>

          <div className="divide-y">
            {prospect.followups.length ? (
              prospect.followups.map((item) => (
                <article key={item.id} className="px-5 py-4">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-medium">{tr(item.type)}</p>
                      <p className="mt-1 text-xs text-muted-foreground">
                        {item.recordedBy} • {date(item.occurredAt)}
                      </p>
                    </div>
                  </div>
                  <p className="mt-3 text-sm leading-6">
                    {tr(item.notes || "")}
                  </p>
                  {item.outcome && (
                    <p className="mt-2 text-sm text-muted-foreground">
                      {tr("Outcome")}: {item.outcome}
                    </p>
                  )}
                  {item.nextFollowUpAt && (
                    <p className="mt-2 text-xs font-medium text-blue-700 dark:text-blue-300">
                      {tr("Next")}: {date(item.nextFollowUpAt)}
                    </p>
                  )}
                </article>
              ))
            ) : (
              <p className="px-5 py-8 text-sm text-muted-foreground">
                {tr("No follow-up activity has been recorded yet.")}
              </p>
            )}
          </div>
        </section>
      </div>

      {writable && prospect.status !== "ADMITTED" && (
        <ProspectFollowupForm
          prospectId={prospect.id}
          currentStatus={prospect.status}
        />
      )}
    </div>
  );
}

function Info({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof UserRound;
  label: string;
  value: string;
}) {
  const tr = useCrmText();
  return (
    <div className="flex gap-3 rounded-xl border p-3">
      <div className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-muted">
        <Icon className="size-4" aria-hidden="true" />
      </div>
      <div className="min-w-0">
        <dt className="text-xs text-muted-foreground">{tr(label)}</dt>
        <dd className="mt-1 break-words text-sm font-medium">{value}</dd>
      </div>
    </div>
  );
}

function Detail({ label, value }: { label: string; value: string }) {
  const tr = useCrmText();
  return (
    <div>
      <dt className="text-xs font-medium text-muted-foreground">{tr(label)}</dt>
      <dd className="mt-1 text-sm">{value}</dd>
    </div>
  );
}
