"use client";
import { ActionPanel, announceSaved } from "@/components/erp/action-panel";
import { useId, useRef, useState, useTransition, type FormEvent } from "react";
import { useForm, useFieldArray, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
import { ErpFormField, ErpFormStatus } from "@/components/erp/form-field";
import {
  academicCommandSchema,
  type AcademicCommand,
  type AcademicWorkspace,
  type SessionWorkspace,
} from "./schema";
import { runAcademicCommand } from "./actions";
export const inputClass =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm focus-visible:ring-2 focus-visible:ring-ring";
export type AcademicField = {
  key: Exclude<keyof AcademicCommand, "units" | "entries">;
  label: string;
  hint?: string;
  type?: "number" | "date" | "time";
  options?: { id: string; name: string }[];
  optional?: boolean;
};
export function AcademicForm({
  defaults,
  fields,
  label,
  description,
  data,
  roster,
}: {
  defaults: Partial<AcademicCommand>;
  fields: AcademicField[];
  label: string;
  description: string;
  data?: AcademicWorkspace;
  roster?: SessionWorkspace["roster"];
}) {
  const formId = useId();
  const [pending, start] = useTransition();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(
    null,
  );
  const request = useRef<{ signature: string; id: string } | null>(null);
  const {
    register,
    handleSubmit,
    control,
    setValue,
    reset,
    formState: { errors, isValid, isDirty },
  } = useForm<AcademicCommand>({
    resolver: zodResolver(academicCommandSchema),
    mode: "onChange",
    defaultValues: {
      ...defaults,
      request_id: crypto.randomUUID(),
      reason: "",
      ...(defaults.action === "PUBLISH_CURRICULUM"
        ? { units: [{ title: "", target_date: "" }] }
        : {}),
      ...(roster
        ? {
            entries: roster.map((r) => ({
              enrollment_id: r.enrollment_id,
              status: r.status,
              note: r.note ?? "",
            })),
          }
        : {}),
    },
  });
  const units = useFieldArray({ control, name: "units" });
  const batchId = useWatch({ control, name: "batch_id" });
  const subjectId = useWatch({ control, name: "subject_id" });
  const submit = (event: FormEvent<HTMLFormElement>) =>
    handleSubmit((v) => {
      const signature = JSON.stringify({ ...v, request_id: undefined });
      if (request.current?.signature !== signature)
        request.current = { signature, id: crypto.randomUUID() };
      const request_id = request.current.id;
      setMessage(null);
      start(async () => {
        try {
          const result = await runAcademicCommand({ ...v, request_id });
          setMessage({ ok: result.ok, text: result.message });
          if (result.ok) {
            request.current = null;
            reset();
          }
        } catch {
          setMessage({
            ok: false,
            text: "Result unconfirmed. Retry the same values safely; duplicate posting is prevented.",
          });
        }
      });
    })(event);
  return (
    <ActionPanel title="Open academic action form"><form
      noValidate
      onSubmit={submit}
      className="space-y-4 rounded-xl border bg-card p-4"
    >
      <div>
        <h3 className="font-semibold">{label}</h3>
        <p className="mt-1 text-sm text-muted-foreground">{description}</p>
      </div>
      <fieldset disabled={pending} className="grid gap-4 sm:grid-cols-2">
        {[
          ...fields,
          {
            key: "reason",
            label: "Reason / Verification Note",
            hint: "Explain the plan, change or evidence being recorded.",
          } as AcademicField,
        ].map((field) => {
          let options = field.options;
          if (data) {
            if (field.key === "teacher_id")
              options = data.teachers.filter((t) =>
                t.subjects.includes(subjectId ?? ""),
              );
            if (field.key === "room_id")
              options = data.rooms.filter(
                (r) =>
                  r.branchId ===
                  data.batches.find((b) => b.id === batchId)?.branchId,
              );
            if (field.key === "curriculum_id")
              options = data.curricula
                .filter(
                  (c) => c.batchId === batchId && c.subjectId === subjectId,
                )
                .map((c) => ({ id: c.id, name: `${c.title} · v${c.version}` }));
          }
          const registration = register(field.key, {
            setValueAs: (value) =>
              value === ""
                ? undefined
                : field.type === "number"
                  ? Number(value)
                  : value,
            onChange: () => {
              if (field.key === "batch_id") {
                setValue("room_id", undefined);
                setValue("curriculum_id", undefined);
              }
              if (field.key === "subject_id") {
                setValue("teacher_id", undefined);
                setValue("curriculum_id", undefined);
              }
            },
          });
          return (
            <ErpFormField
              key={field.key}
              id={`${formId}-${field.key}`}
              label={field.label}
              required={!field.optional}
              hint={field.hint}
              error={errors[field.key]?.message}
            >
              {({ id, describedBy, invalid }) =>
                options ? (
                  <select
                    id={id}
                    className={inputClass}
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    {...registration}
                  >
                    <option value="">
                      {field.optional
                        ? "No curriculum link"
                        : "Select an option"}
                    </option>
                    {options.map((o) => (
                      <option key={o.id} value={o.id}>
                        {o.name}
                      </option>
                    ))}
                  </select>
                ) : (
                  <input
                    id={id}
                    className={inputClass}
                    type={field.type ?? "text"}
                    min={field.type === "number" ? 0 : undefined}
                    step={field.type === "number" ? 1 : undefined}
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    {...registration}
                  />
                )
              }
            </ErpFormField>
          );
        })}
      </fieldset>
      {defaults.action === "PUBLISH_CURRICULUM" && (
        <fieldset disabled={pending} className="space-y-3">
          <legend className="mb-3 text-sm font-semibold">
            Chapters / Topics / Page Ranges
          </legend>
          {units.fields.map((u, index) => (
            <div
              key={u.id}
              className="grid items-end gap-3 rounded-xl border p-3 sm:grid-cols-[1fr_1fr_auto]"
            >
              <ErpFormField
                id={`${formId}-unit-${index}`}
                label="Unit / Scope"
                required
                hint="Example: Chapter 1 · pages 1–12 · fractions"
                error={errors.units?.[index]?.title?.message}
              >
                {({ id, describedBy, invalid }) => (
                  <input
                    id={id}
                    className={inputClass}
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    {...register(`units.${index}.title`)}
                  />
                )}
              </ErpFormField>
              <ErpFormField
                id={`${formId}-target-${index}`}
                label="Target Completion Date"
                required
                error={errors.units?.[index]?.target_date?.message}
              >
                {({ id, describedBy, invalid }) => (
                  <input
                    id={id}
                    type="date"
                    className={inputClass}
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    {...register(`units.${index}.target_date`)}
                  />
                )}
              </ErpFormField>
              <Button
                type="button"
                variant="outline"
                disabled={units.fields.length === 1}
                onClick={() => units.remove(index)}
              >
                Remove
              </Button>
            </div>
          ))}
          <Button
            type="button"
            variant="outline"
            onClick={() => units.append({ title: "", target_date: "" })}
          >
            Add Curriculum Unit
          </Button>
        </fieldset>
      )}
      {roster && (
        <fieldset disabled={pending} className="space-y-3">
          <legend className="mb-3 text-sm font-semibold">
            Student Attendance
          </legend>
          {roster.map((r, index) => (
            <div
              key={r.enrollment_id}
              className="grid gap-3 rounded-xl border p-3 sm:grid-cols-3"
            >
              <div className="text-sm">
                <p className="font-semibold">{r.name}</p>
                <p className="text-xs text-muted-foreground">{r.number}</p>
              </div>
              <ErpFormField
                id={`${formId}-attendance-${index}`}
                label="Status"
                required
                error={errors.entries?.[index]?.status?.message}
              >
                {({ id, describedBy, invalid }) => (
                  <select
                    id={id}
                    className={inputClass}
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    {...register(`entries.${index}.status`)}
                  >
                    <option value="">Select status</option>
                    {["PRESENT", "ABSENT", "LATE", "EXCUSED"].map((s) => (
                      <option key={s} value={s}>
                        {s}
                      </option>
                    ))}
                  </select>
                )}
              </ErpFormField>
              <ErpFormField
                id={`${formId}-note-${index}`}
                label="Note"
                required={false}
                error={errors.entries?.[index]?.note?.message}
              >
                {({ id, describedBy, invalid }) => (
                  <input
                    id={id}
                    className={inputClass}
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    {...register(`entries.${index}.note`)}
                  />
                )}
              </ErpFormField>
            </div>
          ))}
        </fieldset>
      )}
      <Button type="submit" disabled={pending || !isValid || !isDirty} loading={pending}>
        {pending ? "Saving…" : label}
      </Button>
      <ErpFormStatus message={message} />
    </form></ActionPanel>
  );
}
