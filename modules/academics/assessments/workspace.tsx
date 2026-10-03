"use client";
import { ActionPanel, announceSaved } from "@/components/erp/action-panel";

import { useState, useTransition } from "react";
import { runAssessmentCommand } from "./actions";
import type { AssessmentCommand, AssessmentWorkspace } from "./schema";

const fieldClass = "min-h-10 w-full rounded-lg border bg-background px-3 py-2 text-sm";
const buttonClass = "min-h-10 rounded-lg border px-3 text-sm font-medium disabled:opacity-50";
type Assessment = AssessmentWorkspace["assessments"][number];

export function AssessmentWorkspaceView({ data, actorId, canRecord, canReview }: {
  data: AssessmentWorkspace; actorId: string; canRecord: boolean; canReview: boolean;
}) {
  const [pending, startTransition] = useTransition();
  const [notice, setNotice] = useState("");
  function run(input: AssessmentCommand) {
    setNotice("");
    startTransition(async () => { const result = await runAssessmentCommand(input); setNotice(result.message); if(result.ok)announceSaved(result.message); });
  }
  return <div className="space-y-5">
    {notice && <p role="status" className="rounded-lg border p-3 text-sm">{notice}</p>}
    {canRecord && <ActionPanel title="Create assessment"><form onSubmit={(event) => { event.preventDefault(); const form=new FormData(event.currentTarget);
      const [batch_id,subject_id] = String(form.get("scope") || ":").split(":");
      run({ action:"CREATE", request_id:crypto.randomUUID(), batch_id, subject_id,
        title:String(form.get("title") || ""),assessment_date:String(form.get("assessment_date") || ""),max_marks:Number(form.get("max_marks")) });
    }} className="grid gap-3 rounded-2xl border bg-card p-5 sm:grid-cols-2">
      <div className="sm:col-span-2"><h2 className="font-semibold">Create assessment</h2><p className="text-sm text-muted-foreground">Choose a batch and subject with scheduled teaching. Publishing fixes the assessment terms; marks are entered separately.</p></div>
      <label className="space-y-1 text-sm">Batch and subject<select name="scope" required defaultValue="" className={fieldClass}><option value="">Select teaching scope</option>{data.scopes.map((s) => <option key={`${s.batchId}:${s.subjectId}`} value={`${s.batchId}:${s.subjectId}`}>{s.batch} · {s.subject}</option>)}</select></label>
      <label className="space-y-1 text-sm">Title<input name="title" required minLength={3} maxLength={180} className={fieldClass} /></label>
      <label className="space-y-1 text-sm">Assessment date<input name="assessment_date" type="date" required className={fieldClass} /></label>
      <label className="space-y-1 text-sm">Maximum marks<input name="max_marks" type="number" step="0.01" min="0.01" max="1000" required className={fieldClass} /></label>
      <button disabled={pending || data.scopes.length===0} className="min-h-11 rounded-lg bg-primary px-4 font-semibold text-primary-foreground disabled:opacity-50 sm:col-span-2">Create draft</button>
    </form></ActionPanel>}
    <section className="space-y-4"><h2 className="text-lg font-semibold">Assessment register</h2>
      {!data.assessments.length && <p className="rounded-xl border p-5 text-sm text-muted-foreground">No assessments in your teaching or review scope yet.</p>}
      {data.assessments.map((a) => <AssessmentCard key={a.id} item={a} actorId={actorId} canRecord={canRecord} canReview={canReview} pending={pending} run={run} />)}
    </section>
  </div>;
}

function AssessmentCard({ item:a, actorId, canRecord, canReview, pending, run }: {
  item:Assessment;actorId:string;canRecord:boolean;canReview:boolean;pending:boolean;run:(input:AssessmentCommand)=>void;
}) {
  const draft = a.submissions.find((r) => r.status==="DRAFT");
  const submitted = a.submissions.find((r) => r.status==="SUBMITTED");
  const official = a.submissions.find((r) => r.status==="APPROVED");
  const latest = a.submissions[0];
  const [reviewNote, setReviewNote] = useState("");
  return <article className="space-y-4 rounded-2xl border bg-card p-5">
    <div className="flex flex-wrap items-start justify-between gap-3"><div><h3 className="font-semibold">{a.title}</h3><p className="text-sm text-muted-foreground">{a.batch} · {a.subject} · {a.date} · maximum {a.maxMarks} marks</p></div><span className="rounded-full border px-3 py-1 text-xs font-semibold">{a.status}</span></div>
    {a.status==="DRAFT" && canRecord && a.authorId===actorId && <button type="button" className={buttonClass} disabled={pending} onClick={() => run({ action:"PUBLISH",request_id:crypto.randomUUID(),assessment_id:a.id })}>Publish assessment</button>}
    {a.status==="PUBLISHED" && <>
      <div className="flex flex-wrap gap-4 text-sm"><p>Students: {a.roster.length}</p><p>Latest result: {latest?.status || "Not recorded"}</p><p>Official: {official ? `revision ${official.revision}` : "Not yet approved"}</p></div>
      {canRecord && !submitted && a.roster.length>0 && (!draft || draft.authorId===actorId) && <ActionPanel title="Record / edit result draft"><form key={`${a.id}:${draft?.revision || 0}`} onSubmit={(event) => { event.preventDefault(); const form=new FormData(event.currentTarget);
        const entries = a.roster.map((student) => ({ enrollment_id:student.enrollmentId,
          score:Number(form.get(`score:${student.enrollmentId}`)),
          feedback:String(form.get(`feedback:${student.enrollmentId}`) || "") }));
        run({ action:"SAVE_RESULTS",request_id:crypto.randomUUID(),assessment_id:a.id,entries });
      }} className="space-y-3 rounded-xl border p-4">
        <h4 className="font-semibold">{draft ? `Edit result draft v${draft.revision}` : "Record result draft"}</h4>
        {a.roster.map((student) => {
          const saved = draft?.entries.find((e) => e.enrollment_id===student.enrollmentId);
          return <div key={student.enrollmentId} className="grid gap-2 border-b pb-3 text-sm sm:grid-cols-[minmax(10rem,1fr)_8rem_minmax(10rem,1fr)] sm:items-end"><p>{student.studentNo} · {student.name}</p><label>Marks<input name={`score:${student.enrollmentId}`} type="number" step="0.01" min="0" max={a.maxMarks} required defaultValue={saved?.score ?? ""} className={fieldClass} /></label><label>Feedback<input name={`feedback:${student.enrollmentId}`} maxLength={500} defaultValue={saved?.feedback || ""} className={fieldClass} /></label></div>;
        })}
        <button disabled={pending} className={buttonClass}>Save result draft</button>
      </form></ActionPanel>}
      {draft && draft.authorId===actorId && <button type="button" className={buttonClass} disabled={pending} onClick={() => run({ action:"SUBMIT_RESULTS",request_id:crypto.randomUUID(),assessment_id:a.id })}>Submit saved results for review</button>}
      {submitted && <p className="rounded-lg bg-muted p-3 text-sm">Result revision {submitted.revision} is awaiting independent review.</p>}
      {submitted && canReview && submitted.authorId!==actorId && <div className="space-y-2 rounded-xl border p-4"><h4 className="font-semibold">Review submitted marks</h4><ul className="space-y-1 text-sm">{submitted.entries.map((entry) => <li key={entry.enrollment_id}>{a.roster.find((s) => s.enrollmentId===entry.enrollment_id)?.name || "Student"}: {entry.score}/{a.maxMarks}{entry.feedback ? ` · ${entry.feedback}` : ""}</li>)}</ul><label className="block text-sm">Review reason<input value={reviewNote} onChange={(e) => setReviewNote(e.target.value)} maxLength={1000} className={fieldClass} /></label><div className="flex gap-2">{(["APPROVE_RESULTS","REJECT_RESULTS"] as const).map((action) => <button key={action} type="button" className={buttonClass} disabled={pending || reviewNote.trim().length<5} onClick={() => run({ action,request_id:crypto.randomUUID(),assessment_id:a.id,review_note:reviewNote })}>{action==="APPROVE_RESULTS" ? "Approve results" : "Return for correction"}</button>)}</div></div>}
      {official && <details className="text-sm"><summary className="cursor-pointer font-medium">Official results · revision {official.revision}</summary><ul className="mt-2 space-y-1">{official.entries.map((entry) => <li key={entry.enrollment_id}>{a.roster.find((s) => s.enrollmentId===entry.enrollment_id)?.name || "Student"}: {entry.score}/{a.maxMarks}</li>)}</ul></details>}
      {a.submissions.length>0 && <details className="text-sm"><summary className="cursor-pointer">Submission history ({a.submissions.length})</summary><ul className="mt-2 space-y-1">{a.submissions.map((r) => <li key={r.id}>Revision {r.revision} · {r.status}{r.reviewNote ? ` · ${r.reviewNote}` : ""}</li>)}</ul></details>}
    </>}
  </article>;
}
