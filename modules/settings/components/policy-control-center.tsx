"use client";
import { ReferralPolicyEditor } from "./referral-policy-editor";
import { finishWorkflow } from "@/modules/platform/navigation/workflow-return";

import { useEffect, useState, useTransition, type ReactNode } from "react";
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
  admissionActivationPolicySchema,
  batchCapacityPolicySchema,
  teacherCompensationPolicySchema,
  type AdmissionActivationPolicyInput,
  type BatchCapacityPolicyInput,
  type TeacherCompensationPolicyInput,
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

function booleanValue(payload: Payload, key: string, fallback: boolean) {
  const value = payload[key];
  return typeof value === "boolean" ? value : fallback;
}

function stringValue(payload: Payload, key: string, fallback: string) {
  const value = payload[key];
  return typeof value === "string" ? value : fallback;
}

export function PolicyControlCenter({ rules }: { rules: SettingsPolicyRow[] }) {
  const draft = (
    domain: string,
    ruleKey: string,
    payload: Payload,
  ): SettingsPolicyRow => ({
    id: "unsaved",
    domain,
    ruleKey,
    version: 0,
    status: "DRAFT",
    payload,
    changeReason: "Not configured",
    effectiveFrom: "",
  });
  const batchRule =
    rules.find(
      (rule) =>
        rule.domain === "academics" && rule.ruleKey === "batch_capacity_policy",
    ) ?? draft("academics", "batch_capacity_policy", { max_students: 12 });
  const compensationRule =
    rules.find(
      (rule) =>
        rule.domain === "teacher_compensation" &&
        rule.ruleKey === "default_policy",
    ) ??
    draft("teacher_compensation", "default_policy", {
      teaching_pool_percent: 30,
      teaching_pool_review_max_percent: 40,
      acquisition_bonus_percent: 50,
      retention_3_month_percent: 15,
      retention_6_month_percent: 20,
    });
  const admissionRule =
    rules.find(
      (rule) =>
        rule.domain === "admissions" && rule.ruleKey === "activation_policy",
    ) ??
    draft("admissions", "activation_policy", {
      requires_admission_acceptance: true,
      requires_initial_billing_posted: true,
      payment_requirement: "FULL",
      minimum_payment_percent: 100,
      allow_credit_enrollment: false,
      count_student_active_only_when_enrollment_active: true,
    });

  return (
    <div className="grid gap-5 xl:grid-cols-2">
      <ReferralPolicyEditor rules={rules} />
      {batchRule && <BatchCapacityEditor rule={batchRule} />}
      {admissionRule && <AdmissionActivationEditor rule={admissionRule} />}
      {compensationRule && (
        <TeacherCompensationEditor
          rule={compensationRule}
          className="xl:col-span-2"
        />
      )}
    </div>
  );
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

function TeacherCompensationEditor({
  rule,
  className,
}: {
  rule: SettingsPolicyRow;
  className?: string;
}) {
  const router = useRouter();
  const payload = asPayload(rule.payload);
  const current = {
    teachingPoolPercent: numberValue(payload, "teaching_pool_percent"),
    teachingPoolReviewMaxPercent: numberValue(
      payload,
      "teaching_pool_review_max_percent",
    ),
    acquisitionBonusPercent: numberValue(payload, "acquisition_bonus_percent"),
    retention3MonthPercent: numberValue(payload, "retention_3_month_percent"),
    retention6MonthPercent: numberValue(payload, "retention_6_month_percent"),
  };

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
  } = useForm<TeacherCompensationPolicyInput>({
    resolver: zodResolver(teacherCompensationPolicySchema),
    mode: "onChange",
    defaultValues: {
      policy: "teacher_compensation",
      ...current,
      reason: "",
    },
  });

  const values = useWatch({ control });
  const reason = useWatch({ control, name: "reason" });
  const hasChange =
    rule.version === 0 ||
    values.teachingPoolPercent !== current.teachingPoolPercent ||
    values.teachingPoolReviewMaxPercent !==
      current.teachingPoolReviewMaxPercent ||
    values.acquisitionBonusPercent !== current.acquisitionBonusPercent ||
    values.retention3MonthPercent !== current.retention3MonthPercent ||
    values.retention6MonthPercent !== current.retention6MonthPercent;

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
          setError(result.field as FieldPath<TeacherCompensationPolicyInput>, {
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
        text: "Teacher compensation settings saved. Historic settlements keep their recorded terms.",
      });
      finishWorkflow(router);
    });
  });

  const percentFields = [
    {
      name: "teachingPoolPercent" as const,
      label: "Teaching Remuneration Pool",
      hint: "Percentage of Net Collected Tuition allocated to the normal teaching pool.",
    },
    {
      name: "teachingPoolReviewMaxPercent" as const,
      label: "Teaching Pool Review Maximum",
      hint: "Upper management-approved ceiling for the teaching pool.",
    },
    {
      name: "retention3MonthPercent" as const,
      label: "3-Month Retention Bonus",
      hint: "Percentage applied at the configured three-month retention milestone.",
    },
    {
      name: "retention6MonthPercent" as const,
      label: "6-Month Retention Bonus",
      hint: "Percentage applied at the configured six-month retention milestone.",
    },
  ];

  return (
    <PolicyCard
      title="Teacher Compensation"
      description="These percentages govern future compensation calculations. Finalized historical settlements retain the policy version they used."
      version={rule.version}
      className={className}
    >
      <form onSubmit={submit} noValidate className="grid gap-4">
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {percentFields.map((field) => (
            <ErpFormField
              key={field.name}
              id={`policy-${field.name}`}
              label={field.label}
              required
              hint={field.hint}
              error={errors[field.name]?.message}
            >
              {({ id, describedBy, invalid }) => (
                <div className="relative">
                  <input
                    id={id}
                    type="number"
                    min={0}
                    max={100}
                    step="0.01"
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    className={`${inputClass} pr-9`}
                    {...register(field.name, { valueAsNumber: true })}
                  />
                  <span className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">
                    %
                  </span>
                </div>
              )}
            </ErpFormField>
          ))}
        </div>

        <ReasonField
          register={register("reason")}
          error={errors.reason?.message}
          hint="Explain why management is changing compensation terms. Earlier settings remain in history."
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

function AdmissionActivationEditor({ rule }: { rule: SettingsPolicyRow }) {
  const router = useRouter();
  const payload = asPayload(rule.payload);
  const current: Omit<AdmissionActivationPolicyInput, "policy" | "reason"> = {
    requiresAdmissionAcceptance: booleanValue(
      payload,
      "requires_admission_acceptance",
      true,
    ),
    requiresInitialBillingPosted: booleanValue(
      payload,
      "requires_initial_billing_posted",
      true,
    ),
    paymentRequirement: stringValue(
      payload,
      "payment_requirement",
      "NONE",
    ) as AdmissionActivationPolicyInput["paymentRequirement"],
    minimumPaymentPercent: numberValue(payload, "minimum_payment_percent"),
    allowCreditEnrollment: booleanValue(
      payload,
      "allow_credit_enrollment",
      true,
    ),
    countStudentActiveOnlyWhenEnrollmentActive: booleanValue(
      payload,
      "count_student_active_only_when_enrollment_active",
      true,
    ),
  };

  const [pending, startTransition] = useTransition();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(
    null,
  );

  const {
    register,
    handleSubmit,
    control,
    reset,
    setValue,
    setError,
    formState: { errors, isValid },
  } = useForm<AdmissionActivationPolicyInput>({
    resolver: zodResolver(admissionActivationPolicySchema),
    mode: "onChange",
    defaultValues: {
      policy: "admission_activation",
      ...current,
      reason: "",
    },
  });

  const values = useWatch({ control });
  const paymentRequirement = useWatch({ control, name: "paymentRequirement" });
  const reason = useWatch({ control, name: "reason" });

  useEffect(() => {
    if (paymentRequirement === "NONE") {
      setValue("minimumPaymentPercent", 0, {
        shouldDirty: true,
        shouldValidate: true,
      });
    } else if (paymentRequirement === "FULL") {
      setValue("minimumPaymentPercent", 100, {
        shouldDirty: true,
        shouldValidate: true,
      });
    }
  }, [paymentRequirement, setValue]);

  const hasChange =
    rule.version === 0 ||
    values.requiresAdmissionAcceptance !==
      current.requiresAdmissionAcceptance ||
    values.requiresInitialBillingPosted !==
      current.requiresInitialBillingPosted ||
    values.paymentRequirement !== current.paymentRequirement ||
    values.minimumPaymentPercent !== current.minimumPaymentPercent ||
    values.allowCreditEnrollment !== current.allowCreditEnrollment ||
    values.countStudentActiveOnlyWhenEnrollmentActive !==
      current.countStudentActiveOnlyWhenEnrollmentActive;

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
          setError(result.field as FieldPath<AdmissionActivationPolicyInput>, {
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
        text: "Admission activation settings saved. Historic admissions keep their recorded terms.",
      });
      finishWorkflow(router);
    });
  });

  return (
    <PolicyCard
      title="Admission Activation"
      description="Controls when an accepted admission becomes an ACTIVE enrollment. Billing and payment remain separate business facts."
      version={rule.version}
    >
      <form onSubmit={submit} noValidate className="grid gap-4">
        <div className="grid gap-2">
          <BooleanPolicyField
            label="Require accepted admission"
            description="Enrollment cannot activate while the Admission Case is still draft/unaccepted."
            registration={register("requiresAdmissionAcceptance")}
          />
          <BooleanPolicyField
            label="Require initial billing posted"
            description="The initial invoice/charge must exist before activation."
            registration={register("requiresInitialBillingPosted")}
          />
          <BooleanPolicyField
            label="Allow credit enrollment"
            description="Allows ACTIVE enrollment with an unpaid receivable when the payment policy permits it."
            registration={register("allowCreditEnrollment")}
          />
          <BooleanPolicyField
            label="Count only ACTIVE enrollments as active students"
            description="Protects dashboard student counts from drafts and admission-only records."
            registration={register(
              "countStudentActiveOnlyWhenEnrollmentActive",
            )}
          />
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <ErpFormField
            id="policy-payment-requirement"
            label="Payment Requirement Before Activation"
            required
            hint="NONE allows activation without payment; MINIMUM_PERCENT requires a partial payment; FULL requires full initial payment."
            error={errors.paymentRequirement?.message}
          >
            {({ id, describedBy, invalid }) => (
              <select
                id={id}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={inputClass}
                {...register("paymentRequirement")}
              >
                <option value="NONE">No payment required</option>
                <option value="MINIMUM_PERCENT">Minimum percentage</option>
                <option value="FULL">Full payment required</option>
              </select>
            )}
          </ErpFormField>

          <ErpFormField
            id="policy-minimum-payment"
            label="Minimum Payment"
            required
            hint="Automatically fixed to 0% for NONE and 100% for FULL. Enter the required percentage for MINIMUM_PERCENT."
            error={errors.minimumPaymentPercent?.message}
          >
            {({ id, describedBy, invalid }) => (
              <div className="relative">
                <input
                  id={id}
                  type="number"
                  min={0}
                  max={100}
                  step="0.01"
                  disabled={paymentRequirement !== "MINIMUM_PERCENT"}
                  aria-describedby={describedBy}
                  aria-invalid={invalid}
                  className={`${inputClass} pr-9 disabled:cursor-not-allowed disabled:opacity-60`}
                  {...register("minimumPaymentPercent", {
                    valueAsNumber: true,
                  })}
                />
                <span className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">
                  %
                </span>
              </div>
            )}
          </ErpFormField>
        </div>

        <ReasonField
          register={register("reason")}
          error={errors.reason?.message}
          hint="Explain why the activation/payment rule is changing; this is a high-impact operational policy."
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

function BooleanPolicyField({
  label,
  description,
  registration,
}: {
  label: string;
  description: string;
  registration: UseFormRegisterReturn;
}) {
  return (
    <label className="flex cursor-pointer items-start gap-3 rounded-xl border p-3 hover:bg-muted/30">
      <input
        type="checkbox"
        className="mt-1 size-4 shrink-0"
        {...registration}
      />
      <span>
        <span className="block text-sm font-medium">{label}</span>
        <span className="mt-1 block text-xs leading-5 text-muted-foreground">
          {description}
        </span>
      </span>
    </label>
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
