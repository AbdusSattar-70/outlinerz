"use client";
import { CrmText, useCrmText } from "@/modules/crm/translations";

import { useMemo, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm, type FieldPath, type Resolver } from "react-hook-form";
import { Button } from "@/components/ui/button";
import { ErpFormField, ErpFormStatus } from "@/components/erp/form-field";
import { StatusBadge } from "@/components/erp/status-badge";
import { manageCrmMasterRecord } from "@/modules/crm/manage/actions";
import {
  manageMasterRecordSchema,
  type ManageMasterRecordInput,
  type MasterEntity,
} from "@/modules/crm/manage/schema";
import type { ManageCrmOverview } from "@/modules/crm/manage/queries";

const controlClass =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm focus-visible:ring-2 focus-visible:ring-ring/30 aria-[invalid=true]:border-destructive";

const sections: {
  entity: MasterEntity;
  title: string;
  description: string;
}[] = [
  {
    entity: "academic_year",
    title: "Academic years",
    description:
      "Names and date ranges. Several years can be active; each offering controls its own public application window.",
  },
  {
    entity: "class",
    title: "Classes",
    description:
      "Student classes used for eligibility, interest forms and offerings.",
  },
  {
    entity: "group",
    title: "Groups",
    description: "Optional streams such as Science within a class context.",
  },
  {
    entity: "subject",
    title: "Subjects",
    description: "Subjects applicants may select and offerings may include.",
  },
  {
    entity: "program",
    title: "Programmes",
    description:
      "Reusable programme definitions linked to programme offerings.",
  },
  {
    entity: "school",
    title: "Schools",
    description:
      "School directory. Verify names captured from \u201cschool not listed\u201d before relying on them.",
  },
  {
    entity: "lead_source",
    title: "Lead sources",
    description: "How enquiries found Sohoj Academy.",
  },
  {
    entity: "guardian_relationship",
    title: "Guardian relationships",
    description: "Relationship options on interest and admission forms.",
  },
];

type Row = {
  id: string;
  code?: string | null;
  name: string;
  description?: string | null;
  sort_order?: number | null;
  starts_on?: string | null;
  ends_on?: string | null;
  area_id?: string | null;
  is_active?: boolean | null;
  is_verified?: boolean | null;
};

function rowsFor(entity: MasterEntity, data: ManageCrmOverview): Row[] {
  switch (entity) {
    case "academic_year":
      return data.years.map((y) => ({
        id: y.id,
        name: y.name,
        starts_on: y.starts_on,
        ends_on: y.ends_on,
        is_active: y.is_active,
      }));
    case "class":
      return data.classes.map((c) => ({
        id: c.id,
        code: c.code,
        name: c.name,
        sort_order: c.sort_order,
        is_active: c.is_active,
      }));
    case "group":
      return data.groups.map((g) => ({
        id: g.id,
        code: g.code,
        name: g.name,
        is_active: g.is_active,
      }));
    case "subject":
      return data.subjects.map((s) => ({
        id: s.id,
        code: s.code,
        name: s.name,
        is_active: s.is_active,
      }));
    case "program":
      return data.programs.map((p) => ({
        id: p.id,
        code: p.code,
        name: p.name,
        description: p.description,
        is_active: p.is_active,
      }));
    case "school":
      return data.schools.map((s) => ({
        id: s.id,
        name: s.name,
        area_id: s.area_id,
        is_verified: s.is_verified,
        is_active: s.is_active,
      }));
    case "lead_source":
      return data.leadSources.map((s) => ({
        id: s.id,
        code: s.code,
        name: s.name,
        is_active: s.is_active,
      }));
    case "guardian_relationship":
      return data.relationships.map((r) => ({
        id: r.id,
        code: r.code,
        name: r.name,
        is_active: r.is_active,
      }));
  }
}

function emptyDefaults(entity: MasterEntity): ManageMasterRecordInput {
  return {
    requestId: crypto.randomUUID(),
    entity,
    id: "",
    code: "",
    name: "",
    description: "",
    sortOrder: 100,
    startsOn: "",
    endsOn: "",
    areaId: "",
    isActive: true,
    isVerified: false,
    reason: "",
  };
}

function fromRow(entity: MasterEntity, row: Row): ManageMasterRecordInput {
  return {
    requestId: crypto.randomUUID(),
    entity,
    id: row.id,
    code: row.code ?? "",
    name: row.name ?? "",
    description: row.description ?? "",
    sortOrder: row.sort_order ?? 100,
    startsOn: row.starts_on ?? "",
    endsOn: row.ends_on ?? "",
    areaId: row.area_id ?? "",
    isActive: row.is_active ?? true,
    isVerified: row.is_verified ?? false,
    reason: "",
  };
}

export function MasterDataWorkspace({
  data,
  canManage,
}: {
  data: ManageCrmOverview;
  canManage: boolean;
}) {
  const tr = useCrmText();

  const [entity, setEntity] = useState<MasterEntity>("class");
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formOpen, setFormOpen] = useState(false);
  const [notice, setNotice] = useState("");
  const rows = useMemo(() => rowsFor(entity, data), [entity, data]);
  const section = sections.find((item) => item.entity === entity)!;

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap gap-2">
        {sections.map((item) => (
          <button
            key={item.entity}
            type="button"
            onClick={() => {
              setEntity(item.entity);
              setEditingId(null);
              setFormOpen(false);
              setNotice("");
            }}
            className={`min-h-11 rounded-xl border px-3 text-sm font-medium transition ${
              entity === item.entity
                ? "border-primary bg-primary/10 text-primary"
                : "bg-background hover:bg-muted"
            }`}
          >
            {tr(item.title)}
          </button>
        ))}
      </div>

      <section className="rounded-2xl border bg-card p-5 sm:p-6">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h2 className="font-semibold">{tr(section.title)}</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              {tr(section.description)}
            </p>
          </div>
          <div className="flex items-center gap-3">
            <p className="text-sm text-muted-foreground">
              {rows.length}
              <CrmText text="records" />{" "}
            </p>
            {canManage && (
              <button
                type="button"
                aria-expanded={formOpen}
                onClick={() => {
                  setEditingId(null);
                  setFormOpen(!formOpen);
                  setNotice("");
                }}
                className="rounded-lg border px-4 py-2 text-sm"
              >
                {formOpen && !editingId
                  ? tr("Close create form")
                  : tr("Create record")}
              </button>
            )}
          </div>
        </div>

        <div className="mt-4 overflow-x-auto">
          <table className="w-full min-w-[640px] text-left text-sm">
            <thead>
              <tr className="border-b bg-muted/40">
                {entity !== "academic_year" && entity !== "school" && (
                  <th className="p-3">
                    <CrmText text="Code" />{" "}
                  </th>
                )}
                <th className="p-3">
                  <CrmText text="Name" />{" "}
                </th>
                {entity === "academic_year" && (
                  <th className="p-3">
                    <CrmText text="Dates" />{" "}
                  </th>
                )}
                {entity === "class" && (
                  <th className="p-3">
                    <CrmText text="Sort" />{" "}
                  </th>
                )}
                {entity === "school" && (
                  <th className="p-3">
                    <CrmText text="Verified" />{" "}
                  </th>
                )}
                <th className="p-3">
                  <CrmText text="Status" />{" "}
                </th>
                {canManage && (
                  <th className="p-3">
                    <CrmText text="Actions" />{" "}
                  </th>
                )}
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id} className="border-b last:border-0">
                  {entity !== "academic_year" && entity !== "school" && (
                    <td className="p-3 font-mono text-xs">{row.code}</td>
                  )}
                  <td className="p-3">
                    <strong>{row.name}</strong>
                    {row.description ? (
                      <span className="block text-muted-foreground">
                        {row.description}
                      </span>
                    ) : null}
                  </td>
                  {entity === "academic_year" && (
                    <td className="p-3 text-muted-foreground">
                      {row.starts_on} → {row.ends_on}
                    </td>
                  )}
                  {entity === "class" && (
                    <td className="p-3 text-muted-foreground">
                      {row.sort_order ?? "\u2014"}
                    </td>
                  )}
                  {entity === "school" && (
                    <td className="p-3">
                      {row.is_verified ? (
                        <span className="rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-semibold text-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-200">
                          <CrmText text="Verified" />{" "}
                        </span>
                      ) : (
                        <span className="text-muted-foreground">
                          <CrmText text="Pending" />{" "}
                        </span>
                      )}
                    </td>
                  )}
                  <td className="p-3">
                    <StatusBadge
                      value={row.is_active ? "ACTIVE" : "INACTIVE"}
                    />
                  </td>
                  {canManage && (
                    <td className="p-3">
                      <button
                        type="button"
                        className="text-sm font-semibold text-primary underline-offset-4 hover:underline"
                        onClick={() => {
                          setEditingId(row.id);
                          setFormOpen(true);
                          setNotice("");
                        }}
                      >
                        <CrmText text="Edit" />{" "}
                      </button>
                    </td>
                  )}
                </tr>
              ))}
              {!rows.length && (
                <tr>
                  <td className="p-6 text-sm text-muted-foreground" colSpan={6}>
                    <CrmText text="No records yet. Click Create record to add the first entry." />{" "}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {notice && (
          <p role="status" className="mt-4 rounded-lg border p-3 text-sm">
            {tr(notice)}
          </p>
        )}
        {canManage && formOpen && (
          <MasterRecordForm
            key={`${entity}:${editingId ?? "new"}`}
            entity={entity}
            areas={data.areas}
            initial={
              editingId
                ? fromRow(
                    entity,
                    rows.find((row) => row.id === editingId)!,
                  )
                : emptyDefaults(entity)
            }
            onCancelEdit={() => {
              setEditingId(null);
              setFormOpen(false);
            }}
            onSuccess={(text) => {
              setNotice(text);
              setEditingId(null);
              setFormOpen(false);
            }}
          />
        )}
      </section>
    </div>
  );
}

function MasterRecordForm({
  entity,
  areas,
  initial,
  onCancelEdit,
  onSuccess,
}: {
  entity: MasterEntity;
  areas: ManageCrmOverview["areas"];
  initial: ManageMasterRecordInput;
  onCancelEdit: () => void;
  onSuccess: (text: string) => void;
}) {
  const tr = useCrmText();

  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(
    null,
  );
  const isEdit = Boolean(initial.id);

  const {
    register,
    handleSubmit,
    reset,
    setError,
    formState: { errors, isDirty, isValid },
  } = useForm<ManageMasterRecordInput>({
    resolver: zodResolver(
      manageMasterRecordSchema,
    ) as Resolver<ManageMasterRecordInput>,
    mode: "onChange",
    defaultValues: initial,
  });

  const submit = handleSubmit((input) => {
    setMessage(null);
    startTransition(async () => {
      const result = await manageCrmMasterRecord(input).catch(() => ({
        ok: false as const,
        error: "Could not save. Please retry.",
        field: undefined,
      }));
      if (!result.ok) {
        if (result.field) {
          setError(result.field as FieldPath<ManageMasterRecordInput>, {
            message: result.error,
          });
        }
        setMessage({ ok: false, text: result.error });
        return;
      }
      setMessage({
        ok: true,
        text: isEdit
          ? "Master record updated. Deactivated values stay on history but leave new forms."
          : "Master record created.",
      });
      reset(emptyDefaults(entity));
      onSuccess(
        isEdit
          ? "Master record updated. History remains available."
          : "Master record created.",
      );
      router.refresh();
    });
  });

  return (
    <form onSubmit={submit} className="mt-6 space-y-4 border-t pt-6" noValidate>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h3 className="font-semibold">
          {isEdit ? tr("Edit record") : tr("Create record")}
        </h3>
        {
          <button
            type="button"
            className="text-sm font-medium text-muted-foreground underline-offset-4 hover:underline"
            onClick={() => {
              reset(emptyDefaults(entity));
              onCancelEdit();
            }}
          >
            <CrmText text="Close editor" />{" "}
          </button>
        }
      </div>

      <input type="hidden" {...register("requestId")} />
      <input type="hidden" {...register("entity")} />
      <input type="hidden" {...register("id")} />

      <div className="grid gap-4 sm:grid-cols-2">
        {entity !== "academic_year" && entity !== "school" && (
          <ErpFormField
            id={`${entity}-code`}
            label={tr("Code")}
            required
            hint={tr(
              "Stable identifier used in integrations and uniqueness checks.",
            )}
            error={errors.code?.message}
          >
            {({ id, describedBy, invalid }) => (
              <input
                id={id}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={controlClass}
                disabled={pending}
                {...register("code")}
              />
            )}
          </ErpFormField>
        )}

        <ErpFormField
          id={`${entity}-name`}
          label={tr("Name")}
          required
          error={errors.name?.message}
        >
          {({ id, describedBy, invalid }) => (
            <input
              id={id}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              disabled={pending}
              {...register("name")}
            />
          )}
        </ErpFormField>

        {entity === "academic_year" && (
          <>
            <ErpFormField
              id={`${entity}-starts`}
              label={tr("Starts on")}
              required
              error={errors.startsOn?.message}
            >
              {({ id, describedBy, invalid }) => (
                <input
                  id={id}
                  type="date"
                  aria-describedby={describedBy}
                  aria-invalid={invalid}
                  className={controlClass}
                  disabled={pending}
                  {...register("startsOn")}
                />
              )}
            </ErpFormField>
            <ErpFormField
              id={`${entity}-ends`}
              label={tr("Ends on")}
              required
              error={errors.endsOn?.message}
            >
              {({ id, describedBy, invalid }) => (
                <input
                  id={id}
                  type="date"
                  aria-describedby={describedBy}
                  aria-invalid={invalid}
                  className={controlClass}
                  disabled={pending}
                  {...register("endsOn")}
                />
              )}
            </ErpFormField>
          </>
        )}

        {entity === "class" && (
          <ErpFormField
            id={`${entity}-sort`}
            label={tr("Sort order")}
            hint={tr("Lower numbers appear first in forms.")}
            error={errors.sortOrder?.message}
          >
            {({ id, describedBy, invalid }) => (
              <input
                id={id}
                type="number"
                min={0}
                max={9999}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={controlClass}
                disabled={pending}
                {...register("sortOrder", { valueAsNumber: true })}
              />
            )}
          </ErpFormField>
        )}

        {entity === "program" && (
          <ErpFormField
            id={`${entity}-description`}
            label={tr("Description")}
            className="sm:col-span-2"
            error={errors.description?.message}
          >
            {({ id, describedBy, invalid }) => (
              <textarea
                id={id}
                rows={3}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={`${controlClass} min-h-[5rem] py-2`}
                disabled={pending}
                {...register("description")}
              />
            )}
          </ErpFormField>
        )}

        {entity === "school" && (
          <>
            <ErpFormField
              id={`${entity}-area`}
              label={tr("Area")}
              hint={tr("Optional location grouping.")}
              error={errors.areaId?.message}
            >
              {({ id, describedBy, invalid }) => (
                <select
                  id={id}
                  aria-describedby={describedBy}
                  aria-invalid={invalid}
                  className={controlClass}
                  disabled={pending}
                  {...register("areaId")}
                >
                  <option value="">
                    <CrmText text="No area" />{" "}
                  </option>
                  {areas.map((area) => (
                    <option key={area.id} value={area.id}>
                      {area.name}
                    </option>
                  ))}
                </select>
              )}
            </ErpFormField>
            <label className="inline-flex min-h-11 items-center gap-2 rounded-xl border bg-background px-3 text-sm font-medium sm:mt-8">
              <input
                type="checkbox"
                className="size-4 rounded border-input"
                disabled={pending}
                {...register("isVerified")}
              />
              <CrmText text="Verified school directory entry" />{" "}
            </label>
          </>
        )}

        <label className="inline-flex min-h-11 items-center gap-2 rounded-xl border bg-background px-3 text-sm font-medium">
          <input
            type="checkbox"
            className="size-4 rounded border-input"
            disabled={pending}
            {...register("isActive")}
          />
          {entity === "academic_year"
            ? tr("Active academic year")
            : tr("Active for new applications")}
        </label>

        <ErpFormField
          id={`${entity}-reason`}
          label={tr("Reason")}
          required
          className="sm:col-span-2"
          hint={tr("Recorded in the audit trail.")}
          error={errors.reason?.message}
        >
          {({ id, describedBy, invalid }) => (
            <input
              id={id}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              disabled={pending}
              placeholder={tr("e.g. Opening 2026 academic year")}
              {...register("reason")}
            />
          )}
        </ErpFormField>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <Button type="submit" disabled={!isDirty || !isValid || pending}>
          {pending
            ? tr("Saving…")
            : isEdit
              ? tr("Save changes")
              : tr("Create record")}
        </Button>
        <p className="text-xs text-muted-foreground">
          <CrmText text="Records are deactivated, not deleted, so historical admissions stay readable." />{" "}
        </p>
      </div>
      <ErpFormStatus message={message} />
    </form>
  );
}
