import { ProspectAssignmentForm } from "@/modules/crm/components/prospect-assignment-form";
import { platformClient } from "@/modules/platform/rpc-client";
import Link from "next/link";
import { notFound } from "next/navigation";
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
import { ProspectFollowupForm } from "@/modules/crm/components/prospect-followup-form";
import { getProspectDetail } from "@/modules/crm/queries";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { can } from "@/types/erp";

export default async function ProspectDetailPage({
  params,
}: {
  params: Promise<{ prospectId: string }>;
}) {
  const context = await requirePermission("crm.prospects.view");
  const { prospectId } = await params;
  const prospect = await getProspectDetail(prospectId);

  if (!prospect) notFound();
  const db = await platformClient();
  const assignment = can(context, "crm.prospects.manage")
    ? await db.rpc("prospect_assignment_options")
    : null;
  if (assignment?.error) throw new Error(assignment.error.message);

  return (
    <div className="space-y-7">
      {prospect.applicationSnapshot && (
        <section className="rounded-xl border border-amber-500/30 bg-card p-5">
          <h2 className="font-semibold">
            Applicant choices — not verified placement
          </h2>
          <p className="mt-2 text-sm">
            Class: {prospect.applicationSnapshot.class_label ?? "Not provided"}{" "}
            · Programme:{" "}
            {prospect.applicationSnapshot.offering_label ?? "General interest"}
          </p>
          <p className="mt-1 text-sm">
            Subjects:{" "}
            {prospect.applicationSnapshot.subject_labels?.join(", ") ||
              "Not provided"}
          </p>
          <p className="mt-2 text-xs text-muted-foreground">
            These statements are preserved separately. Verify identity and
            choose the correct programme and batch when starting admission.
          </p>
        </section>
      )}
      <PageHeader
        eyebrow="CRM & Student Bank"
        title={prospect.studentName}
        description={`${prospect.prospectNo} • Prospect history remains linked even after future Student conversion.`}
        actions={
          <div className="flex flex-wrap gap-2">
            {can(context, "admissions.create") &&
            prospect.status !== "CONVERTED" &&
            prospect.status !== "LOST" ? (
              <Link
                href={`/dashboard/admissions?prospect=${prospect.id}`}
                className="inline-flex min-h-11 items-center gap-2 rounded-xl bg-blue-700 px-4 text-sm font-semibold text-white hover:bg-blue-800"
              >
                Start admission
              </Link>
            ) : null}
            <Link
              href="/dashboard/crm/prospects"
              className="inline-flex min-h-11 items-center gap-2 rounded-xl border bg-background px-4 text-sm font-semibold hover:bg-muted"
            >
              <ArrowLeft className="size-4" aria-hidden="true" />
              Back to Prospects
            </Link>
          </div>
        }
      />

      {assignment && (
        <ProspectAssignmentForm
          prospectId={prospect.id}
          selected={prospect.assignedStaffId}
          staff={assignment.data}
        />
      )}
      <div className="grid gap-5 xl:grid-cols-[1.15fr_.85fr]">
        <section className="rounded-2xl border bg-card p-5 sm:p-6">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
              <p className="text-sm text-muted-foreground">Current status</p>
              <div className="mt-2">
                <StatusBadge value={prospect.status} />
              </div>
            </div>
            <div className="text-right text-xs text-muted-foreground">
              <p>Created</p>
              <p className="mt-1 font-medium text-foreground">
                {new Date(prospect.createdAt).toLocaleString()}
              </p>
              <p className="mt-3 capitalize text-foreground">
                {prospect.submissionIntent} request
              </p>
              <p className="mt-1 text-[11px] leading-4 text-muted-foreground">
                {prospect.offeringLabel}
              </p>
            </div>
          </div>

          {prospect.schoolNeedsReview ? (
            <div className="mt-6 rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-100">
              <p className="font-medium">School name needs staff review</p>
              <p className="mt-1 leading-6">
                Submitted as free text:{" "}
                <span className="font-semibold">{prospect.schoolName}</span>.
                Confirm or create the school in Manage CRM, then continue
                follow-up or admission.
              </p>
              <Link
                href="/dashboard/crm/manage"
                className="mt-3 inline-flex text-sm font-semibold underline underline-offset-4"
              >
                Open Manage CRM
              </Link>
            </div>
          ) : null}

          <dl className="mt-6 grid gap-4 sm:grid-cols-2">
            <Info
              icon={UserRound}
              label="Guardian"
              value={`${prospect.guardianName} • ${prospect.relationship}`}
            />
            <Info
              icon={Phone}
              label="Contact"
              value={
                prospect.alternateMobile
                  ? `${prospect.mobile} / ${prospect.alternateMobile}`
                  : prospect.mobile
              }
            />
            <Info
              icon={GraduationCap}
              label="Current Class"
              value={prospect.className}
            />
            <Info
              icon={School}
              label="School"
              value={
                prospect.schoolNeedsReview
                  ? `${prospect.schoolName} (needs review)`
                  : prospect.schoolName
              }
            />
            <Info icon={MapPin} label="Area" value={prospect.area} />
            <Info
              icon={CalendarClock}
              label="Next Follow-up"
              value={
                prospect.nextFollowUpAt
                  ? new Date(prospect.nextFollowUpAt).toLocaleString()
                  : "Not scheduled"
              }
            />
          </dl>

          <div className="mt-6 grid gap-4 border-t pt-5 sm:grid-cols-2">
            <Detail label="Lead Source" value={prospect.sourceName} />
            <Detail label="Follow-up staff" value={prospect.assignedTo} />
            <Detail
              label="Preferred Schedule"
              value={prospect.preferredSchedule?.replaceAll("_", " ") ?? "—"}
            />
            <Detail
              label="Preferred Days"
              value={
                prospect.preferredDays?.length
                  ? prospect.preferredDays.join(", ")
                  : "—"
              }
            />
            <Detail
              label="Trial Interest"
              value={prospect.trialInterest ? "Yes" : "No"}
            />
            <Detail
              label="Interested Programs"
              value={
                prospect.programs.length ? prospect.programs.join(", ") : "—"
              }
            />
            <Detail
              label="Interested Subjects"
              value={
                prospect.subjects.length ? prospect.subjects.join(", ") : "—"
              }
            />
            <Detail label="Referral" value={prospect.referralNote ?? "—"} />
          </div>

          {prospect.notes && (
            <div className="mt-5 rounded-xl bg-muted/40 p-4">
              <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                Original Note
              </p>
              <p className="mt-2 text-sm leading-6">{prospect.notes}</p>
            </div>
          )}

          {prospect.lostReason && (
            <div className="mt-5 rounded-xl border border-red-300 bg-red-50 p-4 text-red-950 dark:border-red-900 dark:bg-red-950/30 dark:text-red-100">
              <p className="text-xs font-semibold uppercase tracking-wide">
                Lost Reason
              </p>
              <p className="mt-2 text-sm leading-6">{prospect.lostReason}</p>
            </div>
          )}
        </section>

        <section className="overflow-hidden rounded-2xl border bg-card">
          <div className="border-b px-5 py-4">
            <h2 className="font-semibold">Follow-up Timeline</h2>
            <p className="mt-1 text-xs text-muted-foreground">
              Newest activity first. Existing timeline records are not
              rewritten.
            </p>
          </div>

          <div className="divide-y">
            {prospect.followups.length ? (
              prospect.followups.map((item) => (
                <article key={item.id} className="px-5 py-4">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-medium">
                        {item.type.replaceAll("_", " ")}
                      </p>
                      <p className="mt-1 text-xs text-muted-foreground">
                        {item.recordedBy} •{" "}
                        {new Date(item.occurredAt).toLocaleString()}
                      </p>
                    </div>
                  </div>
                  <p className="mt-3 text-sm leading-6">{item.notes}</p>
                  {item.outcome && (
                    <p className="mt-2 text-sm text-muted-foreground">
                      Outcome: {item.outcome}
                    </p>
                  )}
                  {item.nextFollowUpAt && (
                    <p className="mt-2 text-xs font-medium text-blue-700 dark:text-blue-300">
                      Next: {new Date(item.nextFollowUpAt).toLocaleString()}
                    </p>
                  )}
                </article>
              ))
            ) : (
              <p className="px-5 py-8 text-sm text-muted-foreground">
                No follow-up activity has been recorded yet.
              </p>
            )}
          </div>
        </section>
      </div>

      {can(context, "crm.followups.manage") &&
        prospect.status !== "CONVERTED" && (
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
  return (
    <div className="flex gap-3 rounded-xl border p-3">
      <div className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-muted">
        <Icon className="size-4" aria-hidden="true" />
      </div>
      <div className="min-w-0">
        <dt className="text-xs text-muted-foreground">{label}</dt>
        <dd className="mt-1 break-words text-sm font-medium">{value}</dd>
      </div>
    </div>
  );
}

function Detail({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-xs font-medium text-muted-foreground">{label}</dt>
      <dd className="mt-1 text-sm">{value}</dd>
    </div>
  );
}
