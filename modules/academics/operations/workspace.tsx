"use client";
import Link from "next/link";
import { useState } from "react";
import { StatusBadge } from "@/components/erp/status-badge";
import { AcademicForm, type AcademicField } from "./command-form";
import type { AcademicWorkspace } from "./schema";
const weekdays = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
];
export function AcademicOperations({
  data,
  permissions,
}: {
  data: AcademicWorkspace;
  permissions: string[];
}) {
  const [tab, setTab] = useState("sessions");
  const manage = permissions.includes("academics.sessions.manage");
  const curriculum = permissions.includes("academics.curriculum.manage");
  const placement: AcademicField[] = [
    { key: "batch_id", label: "Batch", options: data.batches },
    { key: "subject_id", label: "Subject", options: data.subjects },
    {
      key: "teacher_id",
      label: "Assigned Teacher",
      options: data.teachers,
      hint: "Only teachers with the selected subject qualification are offered.",
    },
    {
      key: "room_id",
      label: "Room",
      options: data.rooms,
      hint: "Room must belong to the batch branch and fit its configured capacity.",
    },
  ];
  const times: AcademicField[] = [
    {
      key: "start_time",
      label: "Starts At",
      type: "time",
      hint: "Organization local time; Asia/Dhaka for Sohoj.",
    },
    { key: "end_time", label: "Ends At", type: "time" },
  ];
  const dates: AcademicField[] = [
    { key: "starts_on", label: "From Date", type: "date" },
    { key: "ends_on", label: "Through Date", type: "date" },
  ];
  const plan: AcademicField[] = [
    {
      key: "curriculum_id",
      label: "Curriculum Version",
      options: [],
      optional: true,
      hint: "Link the exact batch/subject plan used by these sessions.",
    },
    {
      key: "planned_scope",
      label: "Planned Teaching Scope",
      hint: "Specify chapters, topics, pages or revision work. This records a plan, not completed teaching.",
    },
  ];
  return (
    <div className="space-y-5">
      <nav aria-label="Academic sections" className="flex flex-wrap gap-2">
        {[
          ["sessions", "Class Sessions"],
          ["routines", "Routine Templates"],
          ["curriculum", "Curriculum"],
          ["rooms", "Rooms"],
        ].map(([id, label]) => (
          <button
            key={id}
            className={`min-h-11 rounded-xl border px-4 text-sm font-medium ${tab === id ? "bg-primary text-primary-foreground" : "bg-card"}`}
            aria-pressed={tab === id}
            onClick={() => setTab(id)}
          >
            {label}
          </button>
        ))}
      </nav>
      {tab === "sessions" && (
        <div className="space-y-4">
          {manage && (
            <details className="rounded-xl border p-4">
              <summary className="cursor-pointer font-semibold">
                Schedule a Single Class
              </summary>
              <div className="mt-4">
                <AcademicForm
                  data={data}
                  defaults={{ action: "CREATE_SESSION" }}
                  fields={[
                    ...placement,
                    { key: "starts_on", label: "Class Date", type: "date" },
                    ...times,
                    ...plan,
                  ]}
                  label="Schedule Class"
                  description="Checks teacher, batch and room availability. This creates a dated occurrence; recording attendance and actual teaching are separate activities."
                />
              </div>
            </details>
          )}
          {!data.sessions.length && (
            <p className="rounded-xl border border-dashed p-6 text-sm">
              No accessible sessions in this date range. Managers can schedule a
              class or generate occurrences from a routine. Teachers see their
              assigned classes.
            </p>
          )}
          {data.sessions.map((s) => (
            <article key={s.id} className="rounded-2xl border bg-card p-5">
              <div className="flex flex-wrap justify-between gap-3">
                <div>
                  <Link
                    className="text-lg font-semibold underline"
                    href={`/dashboard/academics/sessions/${s.id}`}
                  >
                    {s.batch} · {s.subject}
                  </Link>
                  <p className="mt-1 text-sm">
                    {s.date} · {s.startTime}–{s.endTime} ({s.timezone})
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {s.teacher} · {s.room}
                  </p>
                </div>
                <StatusBadge value={s.status} />
              </div>
              <p className="mt-3 text-sm">Plan: {s.scope}</p>
              <p className="mt-2 text-xs text-muted-foreground">
                Latest attendance: {s.latestStatus ?? "Not recorded"} · Official
                approved revision: {s.approvedRevision ?? "None"}
              </p>
            </article>
          ))}
        </div>
      )}
      {tab === "routines" && (
        <div className="space-y-4">
          {manage && (
            <AcademicForm
              data={data}
              defaults={{ action: "CREATE_ROUTINE" }}
              fields={[
                ...placement,
                {
                  key: "weekday",
                  label: "Weekday",
                  type: "number",
                  options: weekdays.map((name, i) => ({ id: String(i), name })),
                },
                ...times,
                ...dates,
              ]}
              label="Create Weekly Routine"
              description="A routine reserves a weekly slot over its effective period. Generate dated sessions separately; retiring a routine preserves already scheduled occurrences."
            />
          )}
          {data.routines.map((r) => (
            <article
              key={r.id}
              className="space-y-4 rounded-xl border bg-card p-5"
            >
              <div>
                <h2 className="font-semibold">
                  {r.batch} · {r.subject}
                  {r.retired ? " · Retired" : ""}
                </h2>
                <p className="mt-1 text-sm">
                  {weekdays[r.weekday]} · {r.startTime}–{r.endTime} ·{" "}
                  {r.startsOn} through {r.endsOn}
                </p>
                <p className="text-sm text-muted-foreground">
                  {r.teacher} · {r.room}
                </p>
              </div>
              {manage && !r.retired && (
                <>
                  <AcademicForm
                    data={data}
                    defaults={{
                      action: "GENERATE_SESSIONS",
                      routine_id: r.id,
                      batch_id: r.batchId,
                      subject_id: r.subjectId,
                    }}
                    fields={[...dates, ...plan]}
                    label="Generate Dated Sessions"
                    description="Choose dates inside this routine. Existing occurrences, including cancelled ones, are preserved. Any conflict rejects the whole request. Generate up to 94 days per request."
                  />
                  <details>
                    <summary className="cursor-pointer text-sm">
                      Retire Routine
                    </summary>
                    <div className="mt-3">
                      <AcademicForm
                        defaults={{
                          action: "RETIRE_ROUTINE",
                          routine_id: r.id,
                        }}
                        fields={[]}
                        label="Retire Routine"
                        description="Stops further generation from this template. Existing classes remain and must be cancelled individually if required."
                      />
                    </div>
                  </details>
                </>
              )}
            </article>
          ))}
          {!data.routines.length && (
            <p className="text-sm text-muted-foreground">
              No routine templates yet.
            </p>
          )}
        </div>
      )}
      {tab === "curriculum" && (
        <div className="space-y-4">
          {curriculum && (
            <AcademicForm
              data={data}
              defaults={{ action: "PUBLISH_CURRICULUM" }}
              fields={[
                { key: "batch_id", label: "Batch", options: data.batches },
                { key: "subject_id", label: "Subject", options: data.subjects },
                { key: "title", label: "Plan Title" },
              ]}
              label="Publish Curriculum Version"
              description="Define chapter/topic/page targets. Publishing another version preserves earlier plans and session references. Completion must later be evidenced by actual teaching records."
            />
          )}
          {data.curricula.map((c) => (
            <article key={c.id} className="rounded-xl border bg-card p-5">
              <h2 className="font-semibold">
                {c.title} · v{c.version}
              </h2>
              <p className="mt-1 text-sm text-muted-foreground">
                {c.batch} · {c.subject}
              </p>
              <ul className="mt-3 space-y-2 text-sm">
                {c.units.map((u, n) => (
                  <li
                    key={n}
                    className="flex flex-wrap justify-between gap-2 border-b pb-2"
                  >
                    <span>{u.title}</span>
                    <span>Target {u.target_date}</span>
                  </li>
                ))}
              </ul>
            </article>
          ))}
          {!data.curricula.length && (
            <p className="text-sm text-muted-foreground">
              No accessible curriculum versions yet.
            </p>
          )}
        </div>
      )}
      {tab === "rooms" && (
        <div className="space-y-4">
          {manage && (
            <AcademicForm
              defaults={{ action: "CREATE_ROOM" }}
              fields={[
                { key: "branch_id", label: "Branch", options: data.branches },
                { key: "name", label: "Room Name" },
                { key: "capacity", label: "Student Capacity", type: "number" },
              ]}
              label="Create Classroom"
              description="Set actual room capacity. A room must accommodate the whole configured batch and cannot be double-booked."
            />
          )}
          <div className="grid gap-3 sm:grid-cols-2">
            {data.rooms.map((r) => (
              <article key={r.id} className="rounded-xl border bg-card p-4">
                <h2 className="font-semibold">{r.name}</h2>
                <p className="text-sm">
                  {data.branches.find((b) => b.id === r.branchId)?.name} ·{" "}
                  {r.capacity} students
                </p>
              </article>
            ))}
          </div>
          {!data.rooms.length && (
            <p className="text-sm text-muted-foreground">
              Create a classroom before scheduling sessions.
            </p>
          )}
        </div>
      )}
    </div>
  );
}
