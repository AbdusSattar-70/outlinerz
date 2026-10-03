"use client";
import { announceSaved } from "@/components/erp/action-panel";
import { useState, useTransition, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import type { AdmissionWorkspace } from "../schema";
import { correctAdmissionPlacement } from "../review-actions";
export function AdmissionPlacementEditor({
  admissionId,
  batchId,
  data,
}: {
  admissionId: string;
  batchId: string;
  data: AdmissionWorkspace;
}) {
  const current = data.batches.find((b) => b.id === batchId);
  const [offering, setOffering] = useState(current?.offeringId ?? ""),
    [batch, setBatch] = useState(batchId),
    [message, setMessage] = useState("");
  const [pending, start] = useTransition();
  const router = useRouter();
  function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    start(async () => {
      try {
        const result = await correctAdmissionPlacement({
          admission_id: admissionId,
          offering_id: offering,
          batch_id: batch,
          reason: "Corrected academic placement with student or guardian",
        });
        setMessage(result.message);
        if (result.ok) { announceSaved(result.message); router.refresh(); }
      } catch {
        setMessage("Could not save placement. Please try again.");
      }
    });
  }
  return (
    <details data-action-panel className="rounded-xl border p-4">
      <summary className="cursor-pointer font-semibold">
        Correct programme / batch or refresh fees
      </summary>
      <form className="mt-4 space-y-3" onSubmit={submit}>
        <label className="block text-sm">
          Programme offering
          <select
            required
            value={offering}
            onChange={(e) => {
              setOffering(e.target.value);
              setBatch("");
            }}
            className="mt-1 w-full rounded-lg border bg-background p-3"
          >
            <option value="">Select offering</option>
            {data.offerings.map((o) => (
              <option key={o.id} value={o.id} disabled={o.feeReady === false}>
                {o.name} · {o.className} · {o.yearName}
                {o.feeReady === false ? " · fee setup needed" : ""}
              </option>
            ))}
          </select>
        </label>
        <label className="block text-sm">
          Available batch
          <select
            required
            value={batch}
            onChange={(e) => setBatch(e.target.value)}
            className="mt-1 w-full rounded-lg border bg-background p-3"
          >
            <option value="">Select batch</option>
            {data.batches
              .filter((b) => b.offeringId === offering && b.isActive)
              .map((b) => (
                <option
                  key={b.id}
                  value={b.id}
                  disabled={b.occupied >= b.capacity}
                >
                  {b.name} · {b.capacity - b.occupied} seats available
                </option>
              ))}
          </select>
        </label>
        <p className="text-sm text-muted-foreground">
          Changing placement or refreshing the fee plan returns to Draft. Review
          fees, discounts and signed consent again. Earlier records stay in the
          audit history.
        </p>
        <button disabled={pending} className="rounded-lg border px-4 py-2">
          {pending ? "Saving…" : "Save verified placement"}
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
