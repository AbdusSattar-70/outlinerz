"use client";
import { ActionPanel, announceSaved } from "@/components/erp/action-panel";

import { useState, useTransition } from "react";
import { recordHomeworkCheck } from "./actions";
import type { HomeworkWorkspace } from "./schema";

export function HomeworkFollowup({ sessionId, workspace, canRecord }: {
  sessionId: string; workspace: HomeworkWorkspace; canRecord: boolean;
}) {
  return <section className="space-y-3 rounded-2xl border bg-card p-5">
    <h2 className="font-semibold">Homework follow-up</h2>
    {!workspace.assignment ? <p className="text-sm text-muted-foreground">Submit a class log with homework to begin per-student checks.</p> : <>
      <p className="text-sm">Class-log revision {workspace.assignment.revision}: {workspace.assignment.description}</p>
      {workspace.students.length===0 ? <p className="text-sm text-muted-foreground">No students were enrolled in this batch on the class date.</p> :
        <div className="space-y-3">{workspace.students.map((student) => <StudentCheck key={`${workspace.assignment!.id}:${student.enrollmentId}:${student.latestRevision}`} sessionId={sessionId} assignmentId={workspace.assignment!.id} student={student} canRecord={canRecord} />)}</div>}
      <details className="text-sm"><summary className="cursor-pointer font-medium">Review history ({workspace.history.length})</summary><ul className="mt-2 space-y-1">{workspace.history.map((h) => <li key={h.id} className="rounded-lg border p-2">{workspace.students.find((s) => s.enrollmentId===h.enrollmentId)?.name || "Student"}: {h.status.replaceAll("_"," ")} · revision {h.revision} · {new Date(h.recordedAt).toLocaleString()}{h.feedback ? ` · ${h.feedback}` : ""}</li>)}</ul></details>
    </>}
  </section>;
}

type Student = HomeworkWorkspace["students"][number];
function StudentCheck({ sessionId, assignmentId, student, canRecord }: { sessionId: string; assignmentId: string; student: Student; canRecord: boolean }) {
  const [pending, startTransition] = useTransition();
  const [message, setMessage] = useState("");
  return <ActionPanel title="Record homework review"><form onSubmit={(event) => { event.preventDefault(); const formData=new FormData(event.currentTarget);
    setMessage("");
    startTransition(async () => {
      const result = await recordHomeworkCheck({
        request_id: crypto.randomUUID(), session_id: sessionId, class_log_id: assignmentId,
        enrollment_id: student.enrollmentId, base_revision: student.latestRevision || 0,
        status: String(formData.get("status")) as "NOT_SUBMITTED"|"NEEDS_WORK"|"COMPLETE",
        submitted_on: String(formData.get("submitted_on") || "") || undefined,
        feedback: String(formData.get("feedback") || ""),
      });
      setMessage(result.message);if(result.ok)announceSaved(result.message);
    });
  }} className="grid gap-3 rounded-xl border p-4 text-sm lg:grid-cols-[minmax(10rem,1fr)_10rem_10rem_minmax(12rem,1fr)_auto] lg:items-end">
    <div><p className="font-medium">{student.studentNo} · {student.name}</p><p className="text-xs text-muted-foreground">Last check: {student.status?.replaceAll("_"," ") || "Not checked"}</p></div>
    <label className="space-y-1">Status<select name="status" defaultValue={student.status || "NOT_SUBMITTED"} disabled={!canRecord} className="block min-h-10 w-full rounded-lg border bg-background px-2"><option value="NOT_SUBMITTED">Not submitted</option><option value="NEEDS_WORK">Needs work</option><option value="COMPLETE">Complete</option></select></label>
    <label className="space-y-1">Submitted on<input type="date" name="submitted_on" defaultValue={student.submittedOn || ""} disabled={!canRecord} className="block min-h-10 w-full rounded-lg border bg-background px-2" /></label>
    <label className="space-y-1">Feedback<input name="feedback" maxLength={1000} defaultValue={student.feedback || ""} disabled={!canRecord} className="block min-h-10 w-full rounded-lg border bg-background px-2" /></label>
    {canRecord && <button disabled={pending} className="min-h-10 rounded-lg border px-3 font-medium disabled:opacity-50">{pending?"Saving…":"Save check"}</button>}
    {message && <p role="status" className="lg:col-span-5">{message}</p>}
  </form></ActionPanel>;
}
