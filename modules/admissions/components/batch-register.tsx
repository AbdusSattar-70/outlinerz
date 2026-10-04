"use client";

import { RecordStateButton } from "@/components/erp/record-state-button";
import { InlineWorkPanel } from "@/components/erp/inline-work-panel";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { AdmissionCommandForm } from "./command-form";
import type { AdmissionWorkspace } from "../schema";
import { StatusBadge } from "@/components/erp/status-badge";

export function BatchRegister({
  data,
  canManage,
}: {
  data: AdmissionWorkspace;
  canManage: boolean;
}) {
  const router = useRouter();
  const [notice, setNotice] = useState("");
  const [form, setForm] = useState<{
    action: "CREATE_BATCH" | "EDIT_BATCH";
    id?: string;
  } | null>(null);
  const selected = form?.id
    ? data.batches.find((batch) => batch.id === form.id)
    : undefined;
  const close = () => setForm(null);

  return (
    <div className="space-y-5">
      <section className="flex flex-wrap items-center justify-between gap-4 rounded-2xl border bg-card p-5 sm:p-6">
        <div>
          <h2 className="text-lg font-semibold">Batch register</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            View each cohort, its programme context, seat limit and enrolled
            count. Edit a batch without changing its historical offering
            assignments.
          </p>
        </div>
        {canManage && (
          <button
            type="button"
            onClick={() => setForm({ action: "CREATE_BATCH" })}
            className="inline-flex min-h-11 items-center justify-center rounded-xl bg-primary px-4 text-sm font-semibold text-primary-foreground hover:opacity-90"
          >
            Create batch
          </button>
        )}
      </section>

      <section className="overflow-hidden rounded-2xl border bg-card">
        {data.batches.length ? (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[900px] text-left text-sm">
              <thead className="bg-muted/50 text-xs uppercase tracking-wide text-muted-foreground">
                <tr>
                  <th className="px-4 py-3">Batch</th>
                  <th className="px-4 py-3">Code</th>
                  <th className="px-4 py-3">Programme offering</th>
                  <th className="px-4 py-3">Year / class / branch</th>
                  <th className="px-4 py-3">Seats</th>
                  <th className="px-4 py-3">Status</th>
                  {canManage && (
                    <th className="px-4 py-3 text-right">Action</th>
                  )}
                </tr>
              </thead>
              <tbody>
                {data.batches.map((batch) => (
                  <tr key={batch.id} className="border-t align-top">
                    <td className="px-4 py-4">
                      <p className="font-semibold">{batch.name}</p>
                      <p className="mt-1 text-xs text-muted-foreground">
                        {batch.className}
                      </p>
                    </td>
                    <td className="px-4 py-4 font-mono text-xs">
                      {batch.code}
                    </td>
                    <td className="px-4 py-4">
                      <p className="font-medium">{batch.offeringName}</p>
                    </td>
                    <td className="px-4 py-4 text-muted-foreground">
                      {batch.yearName}
                      <br />
                      {batch.className}
                      {batch.branchName ? ` · ${batch.branchName}` : ""}
                    </td>
                    <td className="px-4 py-4">
                      <p className="font-semibold">
                        {batch.occupied} enrolled{" "}
                        <span className="font-normal text-muted-foreground">
                          / {batch.capacity} seats
                        </span>
                      </p>
                      <div className="mt-2 h-1.5 w-32 overflow-hidden rounded-full bg-muted">
                        <div
                          className="h-full rounded-full bg-primary"
                          style={{
                            width: `${Math.min(100, batch.capacity ? (batch.occupied / batch.capacity) * 100 : 0)}%`,
                          }}
                        />
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <StatusBadge
                        value={batch.isActive ? "ACTIVE" : "INACTIVE"}
                      />
                    </td>
                    {canManage && (
                      <td className="px-4 py-4 text-right">
                        <button
                          type="button"
                          onClick={() =>
                            setForm({ action: "EDIT_BATCH", id: batch.id })
                          }
                          className="min-h-9 rounded-lg border px-3 text-sm font-medium hover:bg-muted"
                        >
                          Edit
                        </button>
                        <div className="mt-2">
                          <RecordStateButton
                            entity="batch"
                            id={batch.id}
                            active={batch.isActive}
                          />
                        </div>
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="p-8 text-center">
            <p className="font-medium">No batches yet</p>
            <p className="mt-1 text-sm text-muted-foreground">
              Activate an academic offering, then create the first batch.
            </p>
            {canManage && (
              <button
                type="button"
                onClick={() => setForm({ action: "CREATE_BATCH" })}
                className="mt-4 rounded-xl bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground"
              >
                Create batch
              </button>
            )}
          </div>
        )}
      </section>

      {notice && (
        <p role="status" className="rounded-xl border p-4 text-sm">
          {notice}
        </p>
      )}
      {form && (
        <InlineWorkPanel
          key={`${form.action}:${form.id ?? "new"}`}
          title={form.action === "CREATE_BATCH" ? "Create batch" : "Edit batch"}
          description="Set the cohort name, short code and available capacity."
          onClose={close}
        >
          <AdmissionCommandForm
            key={`${form.action}:${form.id ?? "new"}`}
            action={form.action}
            data={data}
            label={
              form.action === "CREATE_BATCH"
                ? "Create batch"
                : "Save batch changes"
            }
            description={
              form.action === "CREATE_BATCH"
                ? `Capacity cannot exceed the active policy limit of ${data.capacityLimit ?? "not configured"} students.`
                : `Capacity cannot be below ${selected?.occupied ?? 0} students already enrolled or above the current policy limit of ${data.capacityLimit ?? "not configured"}. Programme, year and class stay attached to the batch.`
            }
            initialBatch={selected}
            onSuccess={() => {
              close();
              router.refresh();
            }}
            onCancel={close}
          />
        </InlineWorkPanel>
      )}
    </div>
  );
}
