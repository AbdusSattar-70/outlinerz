"use client";
import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { runAdmissionCommand } from "../actions";
export const discountReasons = {
  FINANCIAL_HARDSHIP: "Financial hardship",
  SIBLING: "Sibling enrolled",
  MERIT: "Academic merit",
  LAUNCH_OFFER: "Published launch offer",
  STAFF_FAMILY: "Staff family",
  OTHER: "Other verified circumstance",
};
export function AdmissionDiscountForm({
  admissionId,
  allowed,
  selected,
  reason,
}: {
  admissionId: string;
  allowed: number[];
  selected: number;
  reason: string | null;
}) {
  const [percent, setPercent] = useState(selected),
    [why, setWhy] = useState(reason ?? ""),
    [message, setMessage] = useState("");
  const [pending, start] = useTransition();
  const router = useRouter();
  return (
    <section className="space-y-3 rounded-xl border p-4">
      <h3 className="font-semibold">Tuition discount</h3>
      <p className="text-sm text-muted-foreground">
        Applies to tuition from the initial billing month through this academic
        year. Admission, exam and material fees stay unchanged.
      </p>
      <label className="block text-sm">
        Discount
        <select
          className="ml-3 rounded-lg border bg-background p-2"
          value={percent}
          onChange={(e) => setPercent(Number(e.target.value))}
        >
          <option value={0}>No discount</option>
          {allowed.map((p) => (
            <option key={p} value={p}>
              {p}%
            </option>
          ))}
        </select>
      </label>
      {percent > 0 && (
        <fieldset>
          <legend className="text-sm">Reason for discount</legend>
          <div className="mt-2 grid gap-2 sm:grid-cols-2">
            {Object.entries(discountReasons).map(([key, label]) => (
              <label
                key={key}
                className="flex items-center gap-2 rounded border p-2 text-sm"
              >
                <input
                  type="radio"
                  name="discount-reason"
                  checked={why === key}
                  onChange={() => setWhy(key)}
                />
                {label}
              </label>
            ))}
          </div>
        </fieldset>
      )}
      <button
        disabled={pending || (percent > 0 && !why)}
        className="rounded-lg border px-4 py-2 text-sm"
        onClick={() =>
          start(async () => {
            const result = await runAdmissionCommand({
              action: "SAVE_DISCOUNT",
              admissionId,
              requestId: crypto.randomUUID(),
              reason:
                "Confirmed selected discount and eligibility with guardian",
              discountPercent: percent,
              discountReason: why,
            });
            setMessage(result.message);
            if (result.ok) router.refresh();
          })
        }
      >
        Save discount choice
      </button>
      {message && (
        <p role="status" className="text-sm">
          {message}
        </p>
      )}
    </section>
  );
}
