"use client";

import Link from "next/link";
import { CalendarDays, ClipboardList, DoorOpen } from "lucide-react";
import { StatusBadge } from "@/components/erp/status-badge";
import type { AcademicWorkspace } from "@/modules/academics/operations/schema";

type SessionRow = AcademicWorkspace["sessions"][number];

function groupSessions(sessions: SessionRow[], today: string) {
  const todayList: SessionRow[] = [];
  const upcoming: SessionRow[] = [];
  const past: SessionRow[] = [];
  for (const session of sessions) {
    if (session.date === today) todayList.push(session);
    else if (session.date > today) upcoming.push(session);
    else past.push(session);
  }
  return { todayList, upcoming, past };
}

function attendanceLabel(session: SessionRow) {
  if (session.approvedRevision != null) {
    return `Official revision ${session.approvedRevision}`;
  }
  if (session.latestStatus === "SUBMITTED") return "Awaiting review";
  if (session.latestStatus === "DRAFT") return "Draft saved";
  if (session.latestStatus === "REJECTED") return "Rejected — correct and resubmit";
  return "Not recorded";
}

function SessionCard({
  session,
  today,
}: {
  session: SessionRow;
  today: string;
}) {
  const isToday = session.date === today;
  const cancelled = session.status === "CANCELLED";
  const canOpenAttendance =
    !cancelled &&
    (session.date < today ||
      session.date === today ||
      session.latestStatus != null);

  return (
    <article className="rounded-2xl border bg-card p-5 shadow-sm">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="min-w-0 space-y-1">
          <div className="flex flex-wrap items-center gap-2">
            {isToday && (
              <span className="rounded-full bg-blue-100 px-2 py-0.5 text-[11px] font-bold uppercase tracking-wide text-blue-800 dark:bg-blue-950 dark:text-blue-200">
                Today
              </span>
            )}
            <StatusBadge value={session.status} />
          </div>
          <h3 className="text-lg font-semibold tracking-tight">
            {session.batch} · {session.subject}
          </h3>
          <p className="text-sm text-muted-foreground">
            {session.date} · {session.startTime}–{session.endTime} (
            {session.timezone})
          </p>
          <p className="flex items-center gap-1.5 text-sm text-muted-foreground">
            <DoorOpen className="size-3.5 shrink-0" aria-hidden="true" />
            {session.room}
            <span className="text-muted-foreground/60">·</span>
            {session.teacher}
          </p>
        </div>
        <div className="text-right text-xs leading-5 text-muted-foreground">
          <p className="font-medium text-foreground/80">Attendance</p>
          <p>{attendanceLabel(session)}</p>
        </div>
      </div>
      {session.scope ? (
        <p className="mt-3 text-sm leading-6 text-muted-foreground">
          Plan: {session.scope}
        </p>
      ) : null}
      <div className="mt-4 flex flex-wrap gap-2">
        <Link
          href={`/dashboard/academics/sessions/${session.id}`}
          className="inline-flex min-h-11 items-center justify-center rounded-xl bg-blue-700 px-4 text-sm font-semibold text-white hover:bg-blue-800"
        >
          {canOpenAttendance && !cancelled ? "Open class / attendance" : "View session"}
        </Link>
      </div>
    </article>
  );
}

function SessionGroup({
  title,
  description,
  sessions,
  today,
  empty,
}: {
  title: string;
  description: string;
  sessions: SessionRow[];
  today: string;
  empty: string;
}) {
  return (
    <section className="space-y-3">
      <div>
        <h2 className="text-base font-semibold">{title}</h2>
        <p className="text-sm text-muted-foreground">{description}</p>
      </div>
      {!sessions.length ? (
        <p className="rounded-xl border border-dashed p-5 text-sm text-muted-foreground">
          {empty}
        </p>
      ) : (
        <div className="space-y-3">
          {sessions.map((session) => (
            <SessionCard key={session.id} session={session} today={today} />
          ))}
        </div>
      )}
    </section>
  );
}

export function TeacherWorkspace({
  data,
  today,
  staffName,
  staffNo,
  canRecordAttendance,
  canManageSessions,
}: {
  data: AcademicWorkspace;
  today: string;
  staffName: string | null;
  staffNo: string | null;
  canRecordAttendance: boolean;
  canManageSessions: boolean;
}) {
  const { todayList, upcoming, past } = groupSessions(data.sessions, today);

  return (
    <div className="space-y-8">
      <div className="grid gap-4 sm:grid-cols-3">
        <div className="rounded-2xl border bg-card p-5">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-sm text-muted-foreground">Today</p>
              <p className="mt-1 text-2xl font-bold">{todayList.length}</p>
              <p className="mt-1 text-xs text-muted-foreground">
                Assigned class{todayList.length === 1 ? "" : "es"}
              </p>
            </div>
            <CalendarDays className="size-5 text-muted-foreground" aria-hidden="true" />
          </div>
        </div>
        <div className="rounded-2xl border bg-card p-5">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-sm text-muted-foreground">Upcoming</p>
              <p className="mt-1 text-2xl font-bold">{upcoming.length}</p>
              <p className="mt-1 text-xs text-muted-foreground">Next 14 days</p>
            </div>
            <ClipboardList className="size-5 text-muted-foreground" aria-hidden="true" />
          </div>
        </div>
        <div className="rounded-2xl border bg-card p-5">
          <p className="text-sm text-muted-foreground">Teaching identity</p>
          <p className="mt-1 text-base font-semibold">
            {staffName ?? "No linked Staff identity"}
          </p>
          <p className="mt-1 text-xs text-muted-foreground">
            {staffNo
              ? `Staff ${staffNo}`
              : "Link your Auth profile to a Staff record so assigned sessions appear."}
          </p>
        </div>
      </div>

      {!staffName && (
        <div
          role="status"
          className="rounded-2xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-100"
        >
          Your sign-in is active, but no Staff identity is linked to this profile.
          Session assignment uses the Staff record (not only the TEACHER role).
          Staff records link automatically when your confirmed sign-in email matches
          the email on exactly one active Staff record. Ask an administrator to check
          the email under People → Staff.
        </div>
      )}

      {!canRecordAttendance && (
        <div
          role="status"
          className="rounded-2xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-100"
        >
          You can view assigned classes, but recording attendance requires the{" "}
          <code className="rounded bg-amber-100 px-1 dark:bg-amber-900">
            academics.attendance.record
          </code>{" "}
          permission (and assignment scope). Request it through Settings if needed.
        </div>
      )}

      <SessionGroup
        title="Today’s classes"
        description="Open a class after its start time to save and submit attendance. Nobody is marked present automatically."
        sessions={todayList}
        today={today}
        empty="No classes assigned to you today in the current range."
      />

      <SessionGroup
        title="Upcoming"
        description="Generated or scheduled occurrences in the next two weeks that you can access."
        sessions={upcoming}
        today={today}
        empty="No upcoming assigned classes in the next 14 days."
      />

      {past.length > 0 && (
        <SessionGroup
          title="Recent"
          description="Earlier sessions in this window. Official attendance stays on the approved revision."
          sessions={past}
          today={today}
          empty="No recent sessions."
        />
      )}

      {canManageSessions && (
        <p className="text-sm text-muted-foreground">
          Need rooms, routines or bulk generation? Open{" "}
          <Link
            className="font-semibold underline underline-offset-4"
            href="/dashboard/academics/operations"
          >
            Academic Operations
          </Link>
          .
        </p>
      )}
    </div>
  );
}
