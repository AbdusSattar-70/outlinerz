"use client";
import { finishWorkflow } from "@/modules/platform/navigation/workflow-return";

import { useState, useTransition, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  useForm,
  useWatch,
  type FieldPath,
  type UseFormRegisterReturn,
} from "react-hook-form";
import { Save, ShieldCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ErpFormField, ErpFormStatus } from "@/components/erp/form-field";
import { publishPolicy } from "@/modules/settings/actions";
import {
  batchCapacityPolicySchema,
  type BatchCapacityPolicyInput,
} from "@/modules/settings/schema";
import type { SettingsPolicyRow } from "@/modules/settings/queries";

const inputClass =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm text-foreground outline-none transition focus-visible:border-ring focus-visible:ring-2 focus-visible:ring-ring/30 aria-[invalid=true]:border-destructive";

type Payload = Record<string, unknown>;

function asPayload(value: unknown): Payload {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Payload)
    : {};
}

function numberValue(payload: Payload, key: string, fallback = 0) {
  const value = payload[key];
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

export function PolicyControlCenter({ rules }: { rules: SettingsPolicyRow[] }) {
 const rule=rules.find(row=>row.domain==="academics"&&row.ruleKey==="batch_capacity_policy");
 return rule ? <BatchCapacityEditor rule={rule}/> : <p>Open a branch to initialize its capacity policy.</p>;
}

function BatchCapacityEditor({ rule }: { rule: SettingsPolicyRow }) {
  const router = useRouter();
  const payload = asPayload(rule.payload);
  const currentMax = numberValue(payload, "max_students", 1);
  const [pending, startTransition] = useTransition();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(
    null,
  );

  const {
    register,
    handleSubmit,
    control,
    reset,
    setError,
    formState: { errors, isValid },
  } = useForm<BatchCapacityPolicyInput>({
    resolver: zodResolver(batchCapacityPolicySchema),
    mode: "onChange",
    defaultValues: {
      policy: "batch_capacity",
      maxStudents: currentMax,
      reason: "",
    },
  });

  const maxStudents = useWatch({ control, name: "maxStudents" });
  const reason = useWatch({ control, name: "reason" });
  const hasChange = rule.version === 0 || maxStudents !== currentMax;
  const canSubmit =
    hasChange && isValid && reason.trim().length >= 5 && !pending;

  const submit = handleSubmit((input) => {
    setMessage(null);
    startTransition(async () => {
      const result = await publishPolicy(input).catch(() => ({
        ok: false as const,
        field: undefined as string | undefined,
        error:
          "Could not save settings. Your entries remain; retry when connected.",
      }));
      if (!result.ok) {
        if (result.field) {
          setError(result.field as FieldPath<BatchCapacityPolicyInput>, {
            type: "server",
            message: result.error,
          });
        }
        setMessage({ ok: false, text: result.error });
        return;
      }

      reset({ ...input, reason: "" });
      setMessage({
        ok: true,
        text: "Batch capacity settings saved.",
      });
      finishWorkflow(router);
    });
  });

  return (
    <PolicyCard
      title="Batch Capacity"
      description="Maximum students allowed in a normal batch. Capacity enforcement reads the active policy at transaction time."
      version={rule.version}
    >
      <form onSubmit={submit} noValidate className="grid gap-4">
        <ErpFormField
          id="policy-batch-capacity"
          label="Maximum Students per Batch"
          required
          hint={`Current active value: ${currentMax}. Existing historical enrollments are not rewritten when this changes.`}
          error={errors.maxStudents?.message}
        >
          {({ id, describedBy, invalid }) => (
            <input
              id={id}
              type="number"
              min={1}
              max={500}
              step={1}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={inputClass}
              {...register("maxStudents", { valueAsNumber: true })}
            />
          )}
        </ErpFormField>

        <ReasonField
          register={register("reason")}
          error={errors.reason?.message}
          hint="Explain the operational reason, for example a change in room size or teaching model."
        />

        <PolicyFooter
          changed={hasChange}
          pending={pending}
          canSubmit={canSubmit}
          message={message}
        />
      </form>
    </PolicyCard>
  );
}

function PolicyCard({
  title,
  description,
  version,
  className,
  children,
}: {
  title: string;
  description: string;
  version: number;
  className?: string;
  children: ReactNode;
}) {
  return (
    <details
      className={`rounded-2xl border bg-card p-5 sm:p-6 ${className ?? ""}`}
    >
      <summary className="flex cursor-pointer list-none items-start justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <ShieldCheck
              className="size-4 text-blue-700 dark:text-blue-300"
              aria-hidden="true"
            />
            <h3 className="font-semibold">{title}</h3>
          </div>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">
            {description}
          </p>
        </div>
        <span className="shrink-0 rounded-full border bg-muted/40 px-2.5 py-1 text-xs font-semibold">
          {version === 0 ? "Create settings" : "Edit settings"}
        </span>
      </summary>
      <div className="mt-5">{children}</div>
    </details>
  );
}

function ReasonField({
  register,
  error,
  hint,
}: {
  register: UseFormRegisterReturn;
  error?: string;
  hint: string;
}) {
  return (
    <ErpFormField
      id={`policy-reason-${register.name}`}
      label="Change Reason"
      required
      hint={hint}
      error={error}
    >
      {({ id, describedBy, invalid }) => (
        <textarea
          id={id}
          rows={3}
          aria-describedby={describedBy}
          aria-invalid={invalid}
          className={`${inputClass} py-2.5`}
          {...register}
        />
      )}
    </ErpFormField>
  );
}

function PolicyFooter({
  changed,
  pending,
  canSubmit,
  message,
}: {
  changed: boolean;
  pending: boolean;
  canSubmit: boolean;
  message: { ok: boolean; text: string } | null;
}) {
  return (
    <div className="grid gap-3 border-t pt-4">
      <ErpFormStatus message={message} />
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-xs text-muted-foreground">
          {changed
            ? "Changes apply to future operations. Earlier settings remain in history."
            : "Change an operating value and record why."}
        </p>
        <Button
          type="submit"
          disabled={!canSubmit}
          className="min-h-11 shrink-0"
        >
          <Save className="mr-2 size-4" aria-hidden="true" />
          {pending ? "Saving…" : "Save settings"}
        </Button>
      </div>
    </div>
  );
}
