import Link from "next/link";
import { notFound } from "next/navigation";
import { z } from "zod";
import { PageHeader } from "@/components/erp/page-header";
import { StatusBadge } from "@/components/erp/status-badge";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import {
  getSessionWorkspace,
  getClassLogWorkspace,
} from "@/modules/academics/operations/queries";
import { ClassLogForm } from "@/modules/academics/operations/class-log-form";
import { getHomeworkWorkspace } from "@/modules/academics/homework/queries";
import { HomeworkFollowup } from "@/modules/academics/homework/workspace";
import { AcademicForm } from "@/modules/academics/operations/command-form";
export default async function SessionPage({
  params,
}: {
  params: Promise<{ sessionId: string }>;
}) {
  const context = await requirePermission("academics.view");
  const { sessionId } = await params;
  if (!z.string().uuid().safeParse(sessionId).success) notFound();
  const [data, classLogs, homework] = await Promise.all([
    getSessionWorkspace(sessionId),
    getClassLogWorkspace(sessionId),
    getHomeworkWorkspace(sessionId),
  ]);
  const s = data.session;
  const latest = data.submissions[0];
  const approved = data.submissions.find((a) => a.status === "APPROVED");
  const can = (p: string) => context.permissions.includes(p);
  const began = s.canRecordNow;
  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Dated Class Session"
        title={`${s.batch} · ${s.subject}`}
        description={`${s.date} · ${s.teacher} · ${s.room}`}
      />
      <div className="flex flex-wrap gap-4 text-sm">
        <Link className="underline" href="/dashboard/teacher">
          Back to My Classes
        </Link>
        <Link className="underline" href="/dashboard/academics/operations">
          Academic Operations
        </Link>
      </div>
      <section className="space-y-3 rounded-2xl border bg-card p-5">
        <StatusBadge value={s.status} />
        <p className="text-sm">
          {new Date(s.startsAt).toLocaleString("en-GB", {
            timeZone: s.timezone,
          })}{" "}
          –{" "}
          {new Date(s.endsAt).toLocaleTimeString("en-GB", {
            timeZone: s.timezone,
          })}{" "}
          · {s.timezone}
        </p>
        <p className="text-sm">
          <strong>Planned scope:</strong> {s.scope}
        </p>
        {s.curriculumTitle && (
          <div>
            <p className="text-sm">
              Pinned curriculum: {s.curriculumTitle} · v{s.curriculumVersion}
            </p>
            <ul className="mt-2 space-y-1 text-xs text-muted-foreground">
              {s.units.map((u, n) => (
                <li key={n}>
                  {u.title} · target {u.target_date}
                </li>
              ))}
            </ul>
          </div>
        )}
        <p className="text-xs text-muted-foreground">
          A scheduled class or approved attendance does not prove curriculum
          completion. Actual teaching/coverage records are separate.
        </p>
        {s.cancellationReason && (
          <p className="text-sm">Cancellation reason: {s.cancellationReason}</p>
        )}
      </section>
      <section className="rounded-2xl border bg-card p-5">
        <h2 className="font-semibold">Official Attendance</h2>
        {approved ? (
          <>
            <p className="mt-2 text-sm">
              Approved revision {approved.revision}. Later drafts or rejected
              corrections do not replace this record.
            </p>
            <div className="mt-3 grid gap-2 sm:grid-cols-4">
              {["PRESENT", "ABSENT", "LATE", "EXCUSED"].map((status) => (
                <p key={status} className="rounded-lg bg-muted/40 p-3 text-sm">
                  {status}:{" "}
                  <strong>
                    {approved.entries.filter((e) => e.status === status).length}
                  </strong>
                </p>
              ))}
            </div>
          </>
        ) : (
          <p className="mt-2 text-sm text-muted-foreground">
            No attendance has been approved for this class.
          </p>
        )}
      </section>
      {s.status === "SCHEDULED" && !began && (
        <p className="text-sm text-muted-foreground">
          Attendance opens after the class starts.
        </p>
      )}
      {s.status === "SCHEDULED" &&
        began &&
        latest?.status !== "SUBMITTED" &&
        can("academics.attendance.record") &&
        (data.roster.length ? (
          <AcademicForm
            key={latest?.id ?? "first"}
            defaults={{
              action: "SAVE_ATTENDANCE",
              session_id: s.id,
              base_id: latest?.id,
            }}
            roster={data.roster}
            fields={[]}
            label={
              latest ? "Save Attendance Revision" : "Save Attendance Draft"
            }
            description="Choose a status for every student. No one is marked present automatically. Saving creates a draft; an independent approval is needed to finalize it. The first saved roster is retained for corrections."
          />
        ) : (
          <p className="rounded-xl border border-dashed p-5 text-sm">
            No eligible enrollments on the class date. Check the batch placement
            and enrollment dates.
          </p>
        ))}
      {s.status === "SCHEDULED" &&
        latest?.status === "DRAFT" &&
        latest.recordedBy === context.profileId &&
        can("academics.attendance.record") && (
          <AcademicForm
            defaults={{
              action: "SUBMIT_ATTENDANCE",
              session_id: s.id,
              attendance_id: latest.id,
            }}
            fields={[]}
            label="Submit Saved Attendance"
            description={`Submit saved revision ${latest.revision} for independent approval. Save any unsaved edits above before submitting.`}
          />
        )}
      {latest?.status === "SUBMITTED" &&
        (latest.recordedBy === context.profileId ? (
          <p className="rounded-xl border p-5 text-sm">
            Awaiting review by a different authorized person. You cannot approve
            your own attendance.
          </p>
        ) : (
          can("academics.attendance.approve") && (
            <AcademicForm
              defaults={{
                action: "DECIDE_ATTENDANCE",
                approval_id: latest.approvalId ?? undefined,
              }}
              fields={[
                {
                  key: "decision",
                  label: "Decision",
                  options: [
                    { id: "APPROVED", name: "Approve" },
                    { id: "REJECTED", name: "Reject for correction" },
                  ],
                },
              ]}
              label="Record Attendance Decision"
              description="Review every saved student status and note below before approving. Rejection preserves the submitted revision and permits a corrected draft."
            />
          )
        ))}
      <section className="space-y-4">
        {s.status === "SCHEDULED" &&
          began &&
          (can("academics.attendance.record") ||
            can("academics.sessions.manage")) && (
            <ClassLogForm sessionId={s.id} workspace={classLogs} />
          )}
        <div>
          <h2 className="font-semibold">Actual Class Log History</h2>
          <p className="text-sm text-muted-foreground">
            Submitted records are immutable. Corrections create a new revision.
          </p>
        </div>
        {classLogs.logs
          .filter((log) => log.status === "SUBMITTED")
          .map((log) => (
            <article
              key={log.id}
              className="space-y-2 rounded-xl border bg-card p-4"
            >
              <p className="text-sm font-semibold">
                Revision {log.revision} · Submitted{" "}
                {new Date(log.submitted_at!).toLocaleString("en-GB", {
                  timeZone: s.timezone,
                })}
              </p>
              <p className="text-sm">{log.class_summary}</p>
              {log.unit_progress.length > 0 && (
                <ul className="list-disc pl-5 text-sm">
                  {log.unit_progress.map((entry) => (
                    <li key={entry.unit_index}>
                      {classLogs.units[entry.unit_index]?.title}:{" "}
                      {entry.status.replaceAll("_", " ")}
                      {entry.note ? ` — ${entry.note}` : ""}
                    </li>
                  ))}
                </ul>
              )}
              {log.unfinished_reason && (
                <p className="text-sm">
                  <strong>Unfinished content:</strong> {log.unfinished_reason}
                </p>
              )}
              {log.homework && (
                <p className="text-sm">
                  <strong>Homework:</strong> {log.homework}
                </p>
              )}
              {log.next_session_plan && (
                <p className="text-sm">
                  <strong>Next class:</strong> {log.next_session_plan}
                </p>
              )}
            </article>
          ))}
        {!classLogs.logs.some((log) => log.status === "SUBMITTED") && (
          <p className="rounded-xl border border-dashed p-4 text-sm text-muted-foreground">
            No actual teaching log has been submitted for this class.
          </p>
        )}
      </section>
      <HomeworkFollowup sessionId={sessionId} workspace={homework} canRecord={s.status === "SCHEDULED" && began && (can("academics.attendance.record") || can("academics.sessions.manage"))} />
      <section className="space-y-3">
        <h2 className="font-semibold">Attendance Revision History</h2>
        {data.submissions.map((a) => (
          <details
            key={a.id}
            open={a.id === latest?.id}
            className="rounded-xl border bg-card p-4"
          >
            <summary className="cursor-pointer text-sm font-semibold">
              Revision {a.revision} · {a.status} · {a.recorder}
            </summary>
            <p className="mt-3 text-sm">{a.reason}</p>
            {a.decisionNote && (
              <p className="mt-1 text-sm">Decision: {a.decisionNote}</p>
            )}
            <div className="mt-3 overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b">
                    <th className="py-2">Student</th>
                    <th>Status</th>
                    <th>Note</th>
                  </tr>
                </thead>
                <tbody>
                  {a.entries.map((e) => (
                    <tr key={e.enrollment_id} className="border-b">
                      <td className="py-2">
                        {e.number} · {e.name}
                      </td>
                      <td>{e.status}</td>
                      <td>{e.note || "—"}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </details>
        ))}
      </section>
      {can("academics.sessions.manage") &&
        s.status === "SCHEDULED" &&
        !data.submissions.some((a) =>
          ["SUBMITTED", "APPROVED"].includes(a.status),
        ) && (
          <details className="rounded-xl border p-4">
            <summary className="cursor-pointer text-sm">
              Cancel This Occurrence
            </summary>
            <div className="mt-3">
              <AcademicForm
                defaults={{ action: "CANCEL_SESSION", session_id: s.id }}
                fields={[]}
                label="Cancel Session"
                description="Retains the original schedule and reason. The routine is unchanged. Sessions with submitted or approved attendance cannot be cancelled."
              />
            </div>
          </details>
        )}
    </div>
  );
}
