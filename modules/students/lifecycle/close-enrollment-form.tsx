"use client";
import { useState, useTransition, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { closeEnrollment } from "./close-actions";
export function CloseEnrollmentForm({
  studentId,
  enrollmentId,
}: {
  studentId: string;
  enrollmentId: string;
}) {
  const [pending, start] = useTransition(),
    [message, setMessage] = useState("");
  const router = useRouter();
  function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    start(async () => {
      try {
        const r = await closeEnrollment({
          student_id: studentId,
          enrollment_id: enrollmentId,
          mode: f.get("mode"),
          reason: f.get("reason"),
        });
        setMessage(r.message);
        if (r.ok) router.refresh();
      } catch {
        setMessage(
          "Could not close enrollment. Review its status before retrying.",
        );
      }
    });
  }
  return (
    <details className="mt-2 max-w-sm">
      <summary className="cursor-pointer text-sm underline">
        Withdraw / complete enrollment
      </summary>
      <form onSubmit={submit} className="mt-3 space-y-3 rounded-xl border p-3">
        <p className="text-xs">
          Stops future recurring billing and releases the seat. Existing
          invoices and debts remain; financial adjustments are separate.
        </p>
        <label className="block text-sm">
          Closure type
          <select
            name="mode"
            required
            className="mt-1 w-full rounded-lg border bg-background p-2"
          >
            <option value="">Choose</option>
            <option value="WITHDRAWN">Withdraw student</option>
            <option value="COMPLETED">Programme completed</option>
          </select>
        </label>
        <label className="block text-sm">
          Reason
          <textarea
            name="reason"
            required
            minLength={5}
            maxLength={500}
            className="mt-1 w-full rounded-lg border bg-background p-2"
          />
        </label>
        <label className="flex gap-2 text-xs">
          <input type="checkbox" required />I verified this closure and
          explained any remaining dues.
        </label>
        <button
          disabled={pending}
          className="rounded-lg border px-3 py-2 text-sm"
        >
          {pending ? "Saving…" : "Confirm closure"}
        </button>
        {message && (
          <p role="status" className="text-sm">
            {message}
          </p>
        )}
      </form>
    </details>
  );
}
