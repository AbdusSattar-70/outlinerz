"use client";

import { RecordStateButton } from "@/components/erp/record-state-button";
import { InlineWorkPanel } from "@/components/erp/inline-work-panel";
import { useState } from "react";
import { StatusBadge } from "@/components/erp/status-badge";
import { OfferingForm } from "@/modules/offerings/components/offering-form";
import { PublicControlsForm } from "@/modules/offerings/components/public-controls-form";
import type { OfferingOverview } from "@/modules/offerings/queries";

type Panel =
  | { kind: "CREATE" }
  | { kind: "EDIT"; id: string }
  | { kind: "PUBLIC"; id: string };

export function OfferingRegister({
  data,
  canManage,
}: {
  data: OfferingOverview;
  canManage: boolean;
}) {
  const [notice, setNotice] = useState("");
  const [panel, setPanel] = useState<Panel | null>(null);
  const selected =
    panel && panel.kind !== "CREATE"
      ? data.offerings.find((item) => item.id === panel.id)
      : undefined;
  const label = (rows: { id: string; name: string }[], id: string | null) =>
    rows.find((row) => row.id === id)?.name ?? "—";
  const linkedSubjectIds = selected
    ? data.offeringSubjects
        .filter((row) => row.offering_id === selected.id)
        .sort((a, b) => a.sort_order - b.sort_order)
        .map((row) => row.subject_id)
    : [];
  const close = () => setPanel(null);
  return (
    <>
      <section className="overflow-hidden rounded-2xl border bg-card">
        <div className="flex flex-wrap items-center justify-between gap-4 border-b p-5 sm:p-6">
          <div>
            <h2 className="font-semibold">Offering Register</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              {data.offerings.length} offerings, including drafts and history.
              Use row actions to edit details or public settings.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-3">

            {canManage && (
              <button
                type="button"
                onClick={() => setPanel({ kind: "CREATE" })}
                className="inline-flex min-h-11 items-center rounded-xl bg-primary px-4 text-sm font-semibold text-primary-foreground hover:opacity-90"
              >
                Create offering
              </button>
            )}
          </div>
        </div>
        {data.offerings.length ? (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[1180px] text-left text-sm">
              <thead className="bg-muted/50 text-xs uppercase tracking-wide text-muted-foreground">
                <tr>
                  <th scope="col" className="px-4 py-3">
                    Code / name
                  </th>
                  <th scope="col" className="px-4 py-3">
                    Year
                  </th>
                  <th scope="col" className="px-4 py-3">
                    Branch
                  </th>
                  <th scope="col" className="px-4 py-3">
                    Class / group
                  </th>
                  <th scope="col" className="px-4 py-3">
                    Programme
                  </th>
                  <th scope="col" className="px-4 py-3">
                    Status
                  </th>
                  <th scope="col" className="px-4 py-3">
                    Website
                  </th>
                  <th scope="col" className="px-4 py-3">
                    Applications
                  </th>
                  {canManage && (
                    <th scope="col" className="px-4 py-3 text-right">
                      Actions
                    </th>
                  )}
                </tr>
              </thead>
              <tbody>
                {data.offerings.map((row) => (
                  <tr key={row.id} className="border-t align-top">
                    <td className="px-4 py-4">
                      <p className="font-semibold">{row.code}</p>
                      <p className="mt-1 text-muted-foreground">{row.name}</p>
                    </td>
                    <td className="px-4 py-4">
                      {label(data.years, row.academic_year_id)}
                    </td>
                    <td className="px-4 py-4">
                      {label(data.branches, row.branch_id)}
                    </td>
                    <td className="px-4 py-4">
                      {label(data.classes, row.class_id)} /{" "}
                      {row.group_id
                        ? label(data.groups, row.group_id)
                        : "Not applicable"}
                    </td>
                    <td className="px-4 py-4">
                      {label(data.programs, row.program_id)}
                    </td>
                    <td className="px-4 py-4">
                      <StatusBadge value={row.status} />
                    </td>
                    <td className="px-4 py-4">
                      {row.is_website_visible ? (
                        <span className="rounded-full bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-200">
                          Visible
                        </span>
                      ) : (
                        <span className="text-muted-foreground">Hidden</span>
                      )}
                    </td>
                    <td className="px-4 py-4">
                      {row.is_accepting_applications ? (
                        <span className="rounded-full bg-blue-50 px-2 py-1 text-xs font-semibold text-blue-800 dark:bg-blue-950/40 dark:text-blue-200">
                          Open
                        </span>
                      ) : (
                        <span className="text-muted-foreground">Closed</span>
                      )}
                    </td>
                    {canManage && (
                      <td className="px-4 py-4 text-right">
                        <div className="flex flex-wrap justify-end gap-2">
                          {
                            <button
                              type="button"
                              onClick={() =>
                                setPanel({ kind: "EDIT", id: row.id })
                              }
                              className="min-h-9 rounded-lg border px-3 text-xs font-semibold hover:bg-muted"
                            >
                              Edit offering
                            </button>
                          }
                          <RecordStateButton
                            entity="offering"
                            id={row.id}
                            active={row.status !== "RETIRED"}
                          />
                          <button
                            type="button"
                            onClick={() =>
                              setPanel({ kind: "PUBLIC", id: row.id })
                            }
                            className="min-h-9 rounded-lg border px-3 text-xs font-semibold hover:bg-muted"
                          >
                            Public settings
                          </button>
                        </div>
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="p-10 text-center">
            <p className="font-semibold">No programme offerings yet</p>
            <p className="mt-1 text-sm text-muted-foreground">
              Create a draft offering, then publish its standard Fee Plan to
              activate it.
            </p>
            {canManage && (
              <button
                type="button"
                onClick={() => setPanel({ kind: "CREATE" })}
                className="mt-4 min-h-11 rounded-xl bg-primary px-4 text-sm font-semibold text-primary-foreground"
              >
                Create offering
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
      {panel?.kind === "CREATE" && (
        <InlineWorkPanel
          key="create"
          title="Create programme offering"
          description="Select the academic context. The programme name supplies the default title; an optional custom title can distinguish a particular intake."
          onClose={close}
        >
          <OfferingForm
            data={data}
            onSuccess={(text) => {
              setNotice(text);
              close();
            }}
            onCancel={close}
          />
        </InlineWorkPanel>
      )}
      {panel?.kind === "EDIT" && selected && (
        <InlineWorkPanel
          key={`edit:${selected.id}`}
          title="Edit programme offering"
          description={`${selected.code} · ${selected.name}. Used academic context remains attached to historical admissions.`}
          onClose={close}
        >
          <OfferingForm
            data={data}
            initialOffering={selected}
            onSuccess={(text) => {
              setNotice(text);
              close();
            }}
            onCancel={close}
          />
        </InlineWorkPanel>
      )}
      {panel?.kind === "PUBLIC" && selected && (
        <InlineWorkPanel
          key={`public:${selected.id}`}
          title="Website and application settings"
          description={`${selected.code} · ${selected.name}`}
          onClose={close}
        >
          <PublicControlsForm
            offering={selected}
            subjects={data.subjects}
            linkedSubjectIds={linkedSubjectIds}
            onSuccess={() => {
              setNotice("Website and application settings saved.");
              close();
            }}
          />
        </InlineWorkPanel>
      )}
    </>
  );
}
