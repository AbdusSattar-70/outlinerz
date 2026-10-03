"use client";
import { useId, useRef, useState, useTransition, type FormEvent } from "react";
import { useForm, type FieldPath } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { ErpFormField, ErpFormStatus } from "@/components/erp/form-field";
import { studentCommandSchema, type StudentCommand } from "./schema";
import { runStudentCommand } from "./actions";
export const inputClass =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm focus-visible:ring-2 focus-visible:ring-ring";
export type StudentField = {
  key: FieldPath<StudentCommand>;
  label: string;
  hint?: string;
  type?: "number" | "date";
  options?: { id: string; name: string }[];
  optional?: boolean;
  max?: number;
};
export function StudentForm({
  defaults,
  fields,
  label,
  description,
  onSuccess,
}: {
  defaults: Partial<StudentCommand>;
  fields: StudentField[];
  label: string;
  description?: string;
  onSuccess?: () => void;
}) {
  const formId = useId();
  const [admissionId, setAdmissionId] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(
    null,
  );
  const request = useRef<{ signature: string; id: string } | null>(null);
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isValid, isDirty },
  } = useForm<StudentCommand>({
    resolver: zodResolver(
      studentCommandSchema.superRefine((value, ctx) => {
        for (const field of fields) {
          const amount = value[field.key];
          if (
            field.max !== undefined &&
            typeof amount === "number" &&
            amount > field.max
          )
            ctx.addIssue({
              code: "custom",
              path: [field.key],
              message: `Amount cannot exceed ${field.max.toFixed(2)}.`,
            });
        }
      }),
    ),
    mode: "onChange",
    defaultValues: { ...defaults, request_id: crypto.randomUUID(), reason: "" },
  });
  const submit = (event: FormEvent<HTMLFormElement>) =>
    handleSubmit((value) => {
      const signature = JSON.stringify({ ...value, request_id: undefined });
      if (request.current?.signature !== signature)
        request.current = { signature, id: crypto.randomUUID() };
      const request_id = request.current.id;
      setMessage(null);
      startTransition(async () => {
        try {
          const result = await runStudentCommand({ ...value, request_id });
          setMessage({ ok: result.ok, text: result.message });
          if (result.ok) {
            request.current = null;
            setAdmissionId(result.admissionId ?? null);
            reset();
            onSuccess?.();
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
    <form
      noValidate
      onSubmit={submit}
      className="space-y-4 rounded-xl border bg-card p-4"
    >
      <div>
        <h3 className="font-semibold">{label}</h3>
        {description && (
          <p className="mt-1 text-sm text-muted-foreground">{description}</p>
        )}
      </div>
      <fieldset disabled={pending} className="grid gap-4 sm:grid-cols-2">
        {[
          ...fields,
          {
            key: "reason",
            label: "Reason / Verification Note",
            hint: "Explain the placement change or the identity evidence you verified.",
          } as StudentField,
        ].map((field) => (
          <ErpFormField
            key={field.key}
            id={`${formId}-${field.key}`}
            label={field.label}
            hint={field.hint}
            required={!field.optional}
            error={errors[field.key]?.message}
          >
            {({ id, describedBy, invalid }) =>
              field.options ? (
                <select
                  id={id}
                  className={inputClass}
                  aria-describedby={describedBy}
                  aria-invalid={invalid}
                  {...register(field.key)}
                >
                  <option value="">Select {field.label}</option>
                  {field.options.map((o) => (
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
                  step={field.type === "number" ? "0.01" : undefined}
                  min={field.type === "number" ? 0 : undefined}
                  max={field.max}
                  aria-describedby={describedBy}
                  aria-invalid={invalid}
                  {...register(
                    field.key,
                    field.type === "number" ? { valueAsNumber: true } : {},
                  )}
                />
              )
            }
          </ErpFormField>
        ))}
      </fieldset>
      {defaults.action === "MERGE" && (
        <label className="flex items-start gap-3 text-sm">
          <input
            type="checkbox"
            className="mt-1 size-4"
            disabled={pending}
            {...register("confirmed_same_person")}
          />
          I verified that both records belong to the same student, not siblings
          or people sharing a guardian mobile.
        </label>
      )}
      {errors.confirmed_same_person && (
        <p role="alert" className="text-sm text-destructive">
          {errors.confirmed_same_person.message}
        </p>
      )}
      <Button type="submit" disabled={pending || !isValid || !isDirty} loading={pending}>
        {pending ? "Saving…" : label}
      </Button>
      <ErpFormStatus message={message} />
      {admissionId && (
        <Link
          className="inline-block text-sm font-semibold underline"
          href={`/dashboard/admissions#${admissionId}`}
        >
          Open enrollment draft in Admissions
        </Link>
      )}
    </form>
  );
}
