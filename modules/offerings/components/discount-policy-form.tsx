"use client";
import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { saveOfferingDiscountPolicy } from "../discount-actions";
export function DiscountPolicyForm({
  offeringId,
  allowed,
}: {
  offeringId: string;
  allowed: number[];
}) {
  const [choices, setChoices] = useState(allowed),
    [message, setMessage] = useState("");
  const [pending, start] = useTransition();
  const router = useRouter();
  return (
    <section className="space-y-3 rounded-xl border p-4">
      <h3 className="font-semibold">Permitted admission discounts</h3>
      <p className="text-sm text-muted-foreground">
        Choose the tuition discounts authorized personnel may apply during
        admission. Leave all unchecked to disable admission discounts.
      </p>
      <div className="flex flex-wrap gap-3">
        {[5, 10, 15, 20, 25, 30].map((p) => (
          <label key={p} className="flex gap-2 rounded-lg border p-3 text-sm">
            <input
              type="checkbox"
              checked={choices.includes(p)}
              onChange={(e) =>
                setChoices(
                  e.target.checked
                    ? [...choices, p]
                    : choices.filter((v) => v !== p),
                )
              }
            />
            {p}%
          </label>
        ))}
      </div>
      <button
        disabled={pending}
        className="rounded-lg border px-4 py-2 text-sm"
        onClick={() =>
          start(async () => {
            const result = await saveOfferingDiscountPolicy({
              offeringId,
              percentages: choices,
            });
            setMessage(result.message);
            if (result.ok) router.refresh();
          })
        }
      >
        Save discount policy
      </button>
      {message && (
        <p role="status" className="text-sm">
          {message}
        </p>
      )}
    </section>
  );
}
