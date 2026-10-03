"use client";
import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { runAdmissionCommand } from "../actions";
export function FinalSubmissionReview({
  admissionId,
  total,
  discountPercent,
  tuitionTotal,
}: {
  admissionId: string;
  total: number;
  discountPercent: number;
  tuitionTotal: number;
}) {
  const [checks, setChecks] = useState<string[]>([]),
    [message, setMessage] = useState("");
  const [pending, start] = useTransition();
  const router = useRouter();
  const labels = [
    "Student and guardian details are correct",
    "Programme, class and batch are correct",
    "Standard charges and saved discount were explained to the guardian",
    "Referral source and signed paper consent are on file",
  ];
  return (
    <section className="mt-5 space-y-4 rounded-xl border p-4">
      <h3 className="font-semibold">Review before final submission</h3>
      <p className="text-sm text-muted-foreground">
        Standard initial charges: BDT {total.toFixed(2)}. Saved tuition
        discount: {discountPercent}%. Estimated initial amount due: BDT{" "}
        {(total - Math.round(tuitionTotal * discountPercent) / 100).toFixed(2)}.
        Final submission issues the Student ID and initial invoice together. No
        money is recorded unless you post an actual payment afterwards.
      </p>
      <div className="space-y-2">
        {labels.map((label) => (
          <label
            key={label}
            className="flex items-start gap-3 rounded-lg border p-3 text-sm"
          >
            <input
              type="checkbox"
              checked={checks.includes(label)}
              onChange={(e) =>
                setChecks(
                  e.target.checked
                    ? [...checks, label]
                    : checks.filter((c) => c !== label),
                )
              }
            />
            {label}
          </label>
        ))}
      </div>
      <button
        disabled={pending || checks.length !== labels.length}
        className="min-h-11 rounded-xl bg-primary px-5 text-sm font-semibold text-primary-foreground disabled:opacity-40"
        onClick={() =>
          start(async () => {
            try {
              const r = await runAdmissionCommand({
                action: "FINALIZE",
                admissionId,
                requestId: crypto.randomUUID(),
                reason:
                  "Reviewed identity, placement, standard charges, discount, referral and signed paper consent",
              });
              setMessage(r.message);
              if (r.ok) router.refresh();
            } catch {
              setMessage(
                "Could not finalize. Check the case status before retrying.",
              );
            }
          })
        }
      >
        {pending
          ? "Submitting admission…"
          : "Confirm admission and create invoice"}
      </button>
      {message && (
        <p role="status" className="text-sm">
          {message}
        </p>
      )}
    </section>
  );
}
