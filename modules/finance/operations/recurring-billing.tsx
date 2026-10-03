"use client";
import { useState, useTransition } from "react";
import { Button } from "@/components/ui/button";
import { FinanceForm, inputClass } from "./command-form";
import { previewBilling } from "./actions";
import type { BillingPreview, FinanceWorkspace } from "./schema";
export function RecurringBilling({
  terms,
}: {
  terms: FinanceWorkspace["terms"];
}) {
  const [month, setMonth] = useState("");
  const [term, setTerm] = useState("");
  const [preview, setPreview] = useState<BillingPreview | null>(null);
  const [error, setError] = useState("");
  const [pending, start] = useTransition();
  return (
    <section className="space-y-4 rounded-2xl border p-5">
      <div>
        <h2 className="text-lg font-semibold">Recurring Billing</h2>
        <p className="text-sm text-muted-foreground">
          Preview a month or term, review each charge, then post. Only active
          enrollments are billed, using their pinned Fee Plan and approved
          discounts. One-time charges are excluded.
        </p>
      </div>
      <div className="grid items-end gap-4 sm:grid-cols-3">
        <label className="space-y-2 text-sm">
          Billing month
          <input
            aria-label="Billing month"
            type="month"
            className={inputClass}
            value={month}
            onChange={(e) => {
              setMonth(e.target.value);
              setTerm("");
              setPreview(null);
            }}
          />
        </label>
        <label className="space-y-2 text-sm">
          Or billing term
          <select
            className={inputClass}
            value={term}
            onChange={(e) => {
              setTerm(e.target.value);
              setPreview(null);
            }}
          >
            <option value="">Monthly billing</option>
            {terms.map((t) => (
              <option key={t.id} value={t.id}>
                {t.name} · {t.startsOn} – {t.endsOn}
              </option>
            ))}
          </select>
        </label>
        <Button
          disabled={pending || (!month && !term)} loading={pending}
          onClick={() =>
            start(async () => {
              setError("");
              setPreview(null);
              try {
                const selected = terms.find((t) => t.id === term);
                const result = await previewBilling(
                  selected?.startsOn ?? `${month}-01`,
                  term || undefined,
                );
                if (result.ok) setPreview(result.data);
                else setError(result.message);
              } catch {
                setError("Could not load preview. Please retry.");
              }
            })
          }
        >
          {pending ? "Loading…" : "Preview Charges"}
        </Button>
      </div>
      {error && (
        <p role="alert" className="text-sm text-destructive">
          {error}
        </p>
      )}
      {preview && (
        <>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <caption className="pb-3 text-left font-medium">
                {preview.period} · {preview.rows.length} invoices · Net BDT{" "}
                {preview.netTotal.toFixed(2)}
              </caption>
              <thead>
                <tr className="border-b">
                  <th className="py-2">Student</th>
                  <th>Gross</th>
                  <th>Discount</th>
                  <th>Net</th>
                  <th>Due</th>
                </tr>
              </thead>
              <tbody>
                {preview.rows.map((r) => (
                  <tr key={r.admissionId} className="border-b">
                    <td className="py-3">
                      {r.name}
                      <span className="block text-xs text-muted-foreground">
                        {r.number}
                      </span>
                    </td>
                    <td>{r.gross.toFixed(2)}</td>
                    <td>{r.discount.toFixed(2)}</td>
                    <td>{(r.gross - r.discount).toFixed(2)}</td>
                    <td>{r.dueOn}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {preview.rows.length ? (
            <FinanceForm
              key={preview.token}
              defaults={{
                action: "RUN_BILLING",
                period: preview.period,
                term_id: preview.termId ?? undefined,
                preview_token: preview.token,
              }}
              fields={[]}
              label="Post Reviewed Invoices"
              description="Posting creates permanent invoices. A changed preview must be reviewed again. Repeating a billing period cannot create duplicate invoices."
              onSuccess={() => setPreview(null)}
            />
          ) : (
            <p className="text-sm text-muted-foreground">
              No eligible unbilled enrollments. Check the billing cycle,
              academic year, activation status and earlier billing runs.
            </p>
          )}
        </>
      )}
    </section>
  );
}
