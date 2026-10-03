"use client";
import { announceSaved } from "@/components/erp/action-panel";
import { useRef, useState, useTransition, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import {
  saveExtraCharge,
  deactivateExtraCharge,
} from "../extra-charge-actions";
export function ExtraChargeForm({
  admissionId,
  charges,
}: {
  admissionId: string;
  charges: { id: string; name: string; amount: number; is_active: boolean }[];
}) {
  const [pending, start] = useTransition(),
    [message, setMessage] = useState("");
  const request = useRef(crypto.randomUUID());
  const router = useRouter();
  function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = e.currentTarget,
      f = new FormData(form);
    const type = String(f.get("type"));
    const names: Record<string, string> = {
      ADMISSION: "Additional registration fee",
      EXAM: "Additional examination fee",
      MATERIAL: "Additional learning materials",
      OTHER: "Other agreed one-time charge",
    };
    start(async () => {
      const r = await saveExtraCharge({
        admission_id: admissionId,
        request_id: request.current,
        name: names[type],
        charge_type: type,
        amount: Number(f.get("amount")),
      });
      setMessage(r.message);
      if (r.ok) {
        request.current = crypto.randomUUID();
        form.reset();
        announceSaved();
        router.refresh();
      }
    });
  }
  return (
    <details data-action-panel className="rounded-xl border p-4">
      <summary className="cursor-pointer font-semibold">
        Additional one-time fees, if needed
      </summary>
      <p className="mt-2 text-sm text-muted-foreground">
        Standard fees remain above. Add only charges explained and agreed with
        the guardian; tuition discounts do not reduce these charges.
      </p>
      <ul className="mt-3 space-y-2">
        {charges.map((c) => (
          <li key={c.id} className="flex justify-between gap-3 text-sm">
            <span>
              {c.name} · BDT {c.amount.toFixed(2)} ·{" "}
              {c.is_active ? "Active" : "Inactive"}
            </span>
            {c.is_active && (
              <button
                type="button"
                disabled={pending}
                className="underline"
                onClick={() =>
                  start(async () => {
                    const r = await deactivateExtraCharge(admissionId, c.id);
                    setMessage(r.message);
                    if (r.ok) router.refresh();
                  })
                }
              >
                Mark inactive
              </button>
            )}
          </li>
        ))}
      </ul>
      <form onSubmit={submit} className="mt-4 grid gap-3 sm:grid-cols-3">
        <label className="text-sm">
          Charge
          <select
            name="type"
            className="mt-1 w-full rounded border bg-background p-3"
          >
            <option value="ADMISSION">Registration</option>
            <option value="EXAM">Exam</option>
            <option value="MATERIAL">Materials</option>
            <option value="OTHER">Other one-time fee</option>
          </select>
        </label>
        <label className="text-sm">
          Amount (BDT)
          <input
            type="number"
            step="0.01"
            min="0.01"
            max="99999999"
            required
            name="amount"
            className="mt-1 w-full rounded border bg-background p-3"
          />
        </label>
        <button
          disabled={pending}
          className="self-end rounded border p-3 text-sm"
        >
          Add to draft
        </button>
      </form>
      {message && (
        <p role="status" className="mt-3 text-sm">
          {message}
        </p>
      )}
    </details>
  );
}
