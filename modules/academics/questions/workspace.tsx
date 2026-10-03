"use client";
import { ActionPanel, announceSaved } from "@/components/erp/action-panel";

import { useState, useTransition } from "react";
import { runQuestionCommand } from "./actions";
import type { QuestionCommand, QuestionWorkspace } from "./schema";

type Item = QuestionWorkspace["items"][number];

export function QuestionBank({ data, actorId, canAuthor, canReview }: {
  data: QuestionWorkspace; actorId: string; canAuthor: boolean; canReview: boolean;
}) {
  const [editing, setEditing] = useState<Item | null>(null);
  const [pending, startTransition] = useTransition();
  const [notice, setNotice] = useState("");
  const [choiceCount, setChoiceCount] = useState(4);

  function run(input: QuestionCommand, after?: () => void) {
    setNotice("");
    startTransition(async () => {
      const result = await runQuestionCommand(input);
      setNotice(result.message);
      if (result.ok) { after?.(); announceSaved(result.message); }
    });
  }

  function save(formData: FormData) {
    const type = String(formData.get("question_type")) as "MCQ" | "SHORT_ANSWER";
    const choices = type === "MCQ" ? formData.getAll("choice").map(String).map((s) => s.trim()).filter(Boolean) : [];
    const details = {
      topic: String(formData.get("topic") || ""),
      difficulty: String(formData.get("difficulty")) as "FOUNDATION" | "STANDARD" | "ADVANCED",
      question_type: type,
      prompt: String(formData.get("prompt") || ""), choices,
      answer_key: String(formData.get("answer_key") || ""),
      explanation: String(formData.get("explanation") || ""),
    };
    if (editing) run({ action: "EDIT_DRAFT", request_id: crypto.randomUUID(), item_id: editing.id, ...details }, () => { setEditing(null); setChoiceCount(4); });
    else run({ action: "CREATE_DRAFT", request_id: crypto.randomUUID(), batch_id: String(formData.get("batch_id")), subject_id: String(formData.get("subject_id")), ...details }, () => { setEditing(null); setChoiceCount(4); });
  }

  return <div className="space-y-6">
    {notice && <p role="status" className="rounded-lg border p-3 text-sm">{notice}</p>}
    {canAuthor && <section className="rounded-2xl border bg-card p-5">
      <h2 className="text-lg font-semibold">{editing ? "Edit question draft" : "Author a question"}</h2>
      <p className="mt-1 text-sm text-muted-foreground">Answers stay within the staff workspace. Submitting freezes this revision for independent review.</p>
      <ActionPanel title="Create / edit question draft" initialOpen={Boolean(editing)}><form key={editing?.id || "new"} onSubmit={event=>{event.preventDefault();save(new FormData(event.currentTarget));}} className="mt-5 grid gap-4 md:grid-cols-2">
        {!editing && <>
          <Field label="Batch"><select name="batch_id" required className={fieldClass} defaultValue=""><option value="">Select batch</option>{data.batches.map((b) => <option value={b.id} key={b.id}>{b.name}</option>)}</select></Field>
          <Field label="Subject"><select name="subject_id" required className={fieldClass} defaultValue=""><option value="">Select subject</option>{data.subjects.map((s) => <option value={s.id} key={s.id}>{s.name}</option>)}</select></Field>
        </>}
        <Field label="Topic"><input name="topic" required minLength={2} maxLength={180} defaultValue={editing?.topic} className={fieldClass} /></Field>
        <Field label="Difficulty"><select name="difficulty" defaultValue={editing?.difficulty || "STANDARD"} className={fieldClass}>{["FOUNDATION","STANDARD","ADVANCED"].map((s) => <option key={s} value={s}>{s.replaceAll("_", " ")}</option>)}</select></Field>
        <Field label="Question type"><select name="question_type" defaultValue={editing?.questionType || "MCQ"} onChange={(e) => setChoiceCount(e.target.value === "MCQ" ? 4 : 0)} className={fieldClass}><option value="MCQ">Multiple choice</option><option value="SHORT_ANSWER">Short answer</option></select></Field>
        <Field label="Question" wide><textarea name="prompt" required minLength={10} maxLength={3000} rows={3} defaultValue={editing?.prompt} className={fieldClass} /></Field>
        {choiceCount > 0 && <div className="space-y-2 md:col-span-2"><p className="text-sm font-medium">Choices (A–F)</p>{Array.from({ length: choiceCount }, (_, i) => <label key={i} className="flex items-center gap-3 text-sm">{String.fromCharCode(65+i)}<input name="choice" maxLength={500} defaultValue={editing?.choices[i] || ""} className={fieldClass} /></label>)}<button type="button" onClick={() => setChoiceCount((n) => Math.min(6,n+1))} className="text-sm underline" disabled={choiceCount>=6}>Add choice</button></div>}
        <Field label={choiceCount ? "Correct letter (A–F)" : "Model answer"}><input name="answer_key" required maxLength={1500} defaultValue={editing?.answerKey} className={fieldClass} /></Field>
        <Field label="Explanation" wide><textarea name="explanation" maxLength={3000} rows={2} defaultValue={editing?.explanation || ""} className={fieldClass} /></Field>
        <div className="flex gap-3 md:col-span-2"><button disabled={pending} className="min-h-11 rounded-lg bg-primary px-4 text-sm font-semibold text-primary-foreground disabled:opacity-50">Save draft</button>{editing && <button type="button" onClick={() => { setEditing(null); setChoiceCount(4); }} className="min-h-11 rounded-lg border px-4 text-sm">Cancel</button>}</div>
      </form></ActionPanel>
    </section>}
    <section className="space-y-4"><h2 className="text-lg font-semibold">Question history</h2>
      {data.items.length === 0 && <p className="rounded-xl border p-5 text-sm text-muted-foreground">No questions in your accessible scope yet.</p>}
      {data.items.map((q) => <article className="space-y-3 rounded-xl border bg-card p-5" key={q.id}>
        <div className="flex flex-wrap items-center justify-between gap-2"><h3 className="font-semibold">{q.topic} · v{q.revision}</h3><span className="rounded-full border px-2 py-1 text-xs font-semibold">{q.status}</span></div>
        <p className="text-xs text-muted-foreground">{q.batch} · {q.subject} · {q.difficulty} · {q.author}</p>
        <p className="whitespace-pre-wrap text-sm">{q.prompt}</p>
        {q.choices.length > 0 && <ol className="list-inside list-[upper-alpha] space-y-1 text-sm">{q.choices.map((c, i) => <li key={`${q.id}-${i}`}>{c}</li>)}</ol>}
        <p className="text-sm"><strong>Answer:</strong> {q.answerKey}</p>
        {q.explanation && <p className="text-sm"><strong>Explanation:</strong> {q.explanation}</p>}
        {q.reviewNote && <p className="rounded-lg bg-muted p-3 text-sm">Review: {q.reviewNote}</p>}
        <div className="flex flex-wrap gap-2">
          {q.authorId===actorId && q.status==="DRAFT" && <><button type="button" className={buttonClass} onClick={() => { setEditing(q); setChoiceCount(q.questionType === "MCQ" ? Math.max(2,q.choices.length) : 0); window.scrollTo({top:0,behavior:"smooth"}); }}>Edit draft</button><button type="button" className={buttonClass} disabled={pending} onClick={() => run({ action: "SUBMIT", item_id:q.id, request_id:crypto.randomUUID() })}>Submit for review</button></>}
          {q.authorId===actorId && q.status==="REJECTED" && <button type="button" className={buttonClass} disabled={pending} onClick={() => run({ action: "REVISE_REJECTED", item_id:q.id, request_id:crypto.randomUUID() })}>Start new revision</button>}
          {canReview && q.authorId!==actorId && q.status==="SUBMITTED" && <ReviewActions pending={pending} onDecide={(action,note) => run({ action, item_id:q.id, request_id:crypto.randomUUID(), review_note:note })} />}
        </div>
      </article>)}
    </section>
  </div>;
}

const fieldClass = "min-h-11 w-full rounded-lg border bg-background px-3 py-2 text-sm";
const buttonClass = "min-h-10 rounded-lg border px-3 text-sm font-medium disabled:opacity-50";
function Field({ label, wide, children }: { label: string; wide?: boolean; children: React.ReactNode }) { return <label className={`space-y-1 text-sm font-medium ${wide ? "md:col-span-2" : ""}`}><span>{label}</span>{children}</label>; }
function ReviewActions({ pending, onDecide }: { pending: boolean; onDecide: (action:"APPROVE"|"REJECT", note:string)=>void }) {
  const [note, setNote] = useState("");
  return <div className="w-full space-y-2"><label className="block text-sm">Review reason<input value={note} onChange={(e) => setNote(e.target.value)} minLength={5} maxLength={1000} className={fieldClass} /></label><div className="flex gap-2"><button type="button" className={buttonClass} disabled={pending || note.trim().length<5} onClick={() => onDecide("APPROVE",note)}>Approve</button><button type="button" className={buttonClass} disabled={pending || note.trim().length<5} onClick={() => onDecide("REJECT",note)}>Reject</button></div></div>;
}
