"use client";
import { useRouter } from "next/navigation";
import { finishWorkflow } from "@/modules/platform/navigation/workflow-return";
import { useId, useRef, useState, useTransition, type FormEvent } from "react";
import { useForm, type FieldPath } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
import { ErpFormField, ErpFormStatus } from "@/components/erp/form-field";
import { financeCommandSchema, type FinanceCommand } from "./schema";
import { runFinanceCommand } from "./actions";
export const inputClass =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm focus-visible:ring-2 focus-visible:ring-ring";
export type FinanceField = {
  key: FieldPath<FinanceCommand>;
  label: string;
  hint?: string;
  type?: "number" | "date";
  options?: { id: string; name: string }[];
  optional?: boolean;
  max?: number;
};
export function FinanceForm({
  defaults,
  fields,
  label,
  description,
  onSuccess,
}: {
  defaults: Partial<FinanceCommand>;
  fields: FinanceField[];
  label: string;
  description?: string;
  onSuccess?: () => void;
}) {
  const router = useRouter();
  const formId = useId();
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
  } = useForm<FinanceCommand>({
    resolver: zodResolver(
      financeCommandSchema.superRefine((value, ctx) => {
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
          const result = await runFinanceCommand({ ...value, request_id });
          setMessage({ ok: result.ok, text: result.message });
          if (result.ok) {
            request.current = null;
            reset();
            onSuccess?.();
            finishWorkflow(router);
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
            hint: "Explain the decision or verify the actual money movement.",
          } as FinanceField,
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
      <Button type="submit" disabled={pending || !isValid || !isDirty} loading={pending}>
        {pending ? "Saving…" : label}
      </Button>
      <ErpFormStatus message={message} />
    </form>
  );
}
