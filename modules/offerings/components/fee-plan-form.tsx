"use client";
import { finishWorkflow } from "@/modules/platform/navigation/workflow-return";

import { DiscountPolicyForm } from "./discount-policy-form";
import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  useFieldArray,
  useForm,
  useWatch,
  type FieldPath,
} from "react-hook-form";
import { Button } from "@/components/ui/button";
import { ErpFormField, ErpFormStatus } from "@/components/erp/form-field";
import { publishFeePlan } from "@/modules/offerings/actions";
import {
  publishFeePlanSchema,
  type PublishFeePlanInput,
} from "@/modules/offerings/schema";
import type { OfferingOverview } from "@/modules/offerings/queries";

const controlClass =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm focus-visible:ring-2 focus-visible:ring-ring/30 aria-[invalid=true]:border-destructive";
const initialComponent: PublishFeePlanInput["components"][number] = {
  code: "TUITION",
  name: "Tuition",
  amount: 0,
  chargeType: "TUITION",
  recurrence: "PER_CYCLE",
};

export function FeePlanForm({
  data,
  today,
  initialOfferingId = "",
}: {
  data: OfferingOverview;
  today: string;
  initialOfferingId?: string;
}) {
  const starting = data.plans.find(
    (plan) =>
      plan.offering_id === initialOfferingId && plan.status === "ACTIVE",
  );
  const planComponents = (planId: string) =>
    data.components
      .filter((row) => row.fee_plan_version_id === planId)
      .map((row) => ({
        code: row.code,
        name: row.name,
        amount: Number(row.amount),
        chargeType:
          row.charge_type as PublishFeePlanInput["components"][number]["chargeType"],
        recurrence:
          row.recurrence as PublishFeePlanInput["components"][number]["recurrence"],
      }));
  const router = useRouter();
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
    setValue,
    formState: { errors, isDirty, isValid },
  } = useForm<PublishFeePlanInput>({
    resolver: zodResolver(publishFeePlanSchema),
    mode: "onChange",
    defaultValues: {
      offeringId: initialOfferingId,
      billingCycle: starting?.billing_cycle ?? "MONTHLY",
      dueDay: starting?.due_day ?? null,
      effectiveFrom: today,
      reason: "",
      components: starting ? planComponents(starting.id) : [initialComponent],
    },
  });
  const { fields, append, remove, replace } = useFieldArray({
    control,
    name: "components",
  });
  const cycle = useWatch({ control, name: "billingCycle" });
  const selectedOffering = useWatch({ control, name: "offeringId" });
  const active = data.plans.find(
    (plan) => plan.offering_id === selectedOffering && plan.status === "ACTIVE",
  );
  const chosenOffering = data.offerings.find(
    (row) => row.id === selectedOffering,
  );

  const submit = handleSubmit((input) => {
    setMessage(null);
    startTransition(async () => {
      const result = await publishFeePlan(input);
      if (!result.ok) {
        if (result.field)
          setError(result.field as FieldPath<PublishFeePlanInput>, {
            message: result.error,
          });
        setMessage({ ok: false, text: result.error });
        return;
      }
      reset();
      setMessage({
        ok: true,
        text: `${result.reference} published. Current fees saved. Existing admission fee terms remain unchanged.`,
      });
      finishWorkflow(router);
    });
  });

  return (
    <section className="rounded-2xl border bg-card p-5 sm:p-6">
      <h2 className="text-lg font-semibold">Standard Fee Plan</h2>
      <p className="mt-1 text-sm text-muted-foreground">
        These are the standard charges inherited during Admission. Configure
        allowed tuition discounts below. Authorized admission personnel can
        apply them with a recorded reason.
      </p>
      <form onSubmit={submit} noValidate className="mt-5 space-y-6">
        <div className="grid gap-5 md:grid-cols-2">
          <ErpFormField
            id="fee-offering"
            label="Programme Offering"
            required
            hint="Choose the exact year, branch, class and programme context."
            error={errors.offeringId?.message}
          >
            {({ id, describedBy, invalid }) => (
              <select
                id={id}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={controlClass}
                {...register("offeringId", {
                  onChange: (event) => {
                    const plan = data.plans.find(
                      (row) =>
                        row.offering_id === event.target.value &&
                        row.status === "ACTIVE",
                    );
                    setValue("billingCycle", plan?.billing_cycle ?? "MONTHLY", {
                      shouldDirty: true,
                    });
                    setValue("dueDay", plan?.due_day ?? null, {
                      shouldDirty: true,
                    });
                    replace(
                      plan ? planComponents(plan.id) : [initialComponent],
                    );
                  },
                })}
              >
                <option value="">Select an offering</option>
                {data.offerings
                  .filter((offering) => offering.status !== "RETIRED")
                  .map((offering) => (
                    <option key={offering.id} value={offering.id}>
                      {offering.code} — {offering.name}
                    </option>
                  ))}
              </select>
            )}
          </ErpFormField>
          <ErpFormField
            id="fee-cycle"
            label="Billing Cycle"
            required
            hint="Tuition repeats with this cycle; one-time charges do not."
            error={errors.billingCycle?.message}
          >
            {({ id, describedBy, invalid }) => (
              <select
                id={id}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={controlClass}
                {...register("billingCycle", {
                  onChange: (event) => {
                    if (event.target.value !== "MONTHLY")
                      setValue("dueDay", null, {
                        shouldDirty: true,
                        shouldValidate: true,
                      });
                  },
                })}
              >
                <option value="MONTHLY">Monthly</option>
                <option value="TERM">Per term</option>
                <option value="ONE_TIME">One-time programme</option>
              </select>
            )}
          </ErpFormField>
          {cycle === "MONTHLY" && (
            <ErpFormField
              id="fee-due-day"
              label="Monthly Due Day"
              required
              hint="Use a day from 1 to 28 to avoid missing dates in shorter months."
              error={errors.dueDay?.message}
            >
              {({ id, describedBy, invalid }) => (
                <input
                  id={id}
                  type="number"
                  min={1}
                  max={28}
                  aria-describedby={describedBy}
                  aria-invalid={invalid}
                  className={controlClass}
                  {...register("dueDay", {
                    setValueAs: (value: string) =>
                      value === "" ? null : Number(value),
                  })}
                />
              )}
            </ErpFormField>
          )}
          <ErpFormField
            id="fee-effective"
            label="Effective Date"
            required
            hint="Publication starts today. Future scheduling is a later controlled workflow."
            error={errors.effectiveFrom?.message}
          >
            {({ id, describedBy, invalid }) => (
              <input
                id={id}
                type="date"
                min={today}
                max={today}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={controlClass}
                {...register("effectiveFrom")}
              />
            )}
          </ErpFormField>
        </div>

        {active && (
          <p className="rounded-xl border bg-muted/40 p-3 text-sm">
            Current plan: saved effective {active.effective_from}. Editing
            updates current charges. Historical admission terms remain
            preserved.
          </p>
        )}

        <fieldset className="space-y-4 rounded-xl border p-4">
          <legend className="px-2 font-semibold">Fee Components</legend>
          <p className="text-sm text-muted-foreground">
            Keep Tuition as a per-cycle component. Add admission, exam or
            material charges separately. Amounts are in BDT.
          </p>
          {fields.map((field, index) => (
            <div
              key={field.id}
              className="grid gap-3 rounded-xl border bg-muted/20 p-4 sm:grid-cols-2 lg:grid-cols-5"
            >
              <ErpFormField
                id={`fee-code-${index}`}
                label="Code"
                required
                error={errors.components?.[index]?.code?.message}
              >
                {({ id, describedBy, invalid }) => (
                  <input
                    id={id}
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    className={controlClass}
                    {...register(`components.${index}.code`)}
                  />
                )}
              </ErpFormField>
              <ErpFormField
                id={`fee-name-${index}`}
                label="Name"
                required
                error={errors.components?.[index]?.name?.message}
              >
                {({ id, describedBy, invalid }) => (
                  <input
                    id={id}
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    className={controlClass}
                    {...register(`components.${index}.name`)}
                  />
                )}
              </ErpFormField>
              <ErpFormField
                id={`fee-amount-${index}`}
                label="Amount (BDT)"
                required
                error={errors.components?.[index]?.amount?.message}
              >
                {({ id, describedBy, invalid }) => (
                  <input
                    id={id}
                    type="number"
                    min={0}
                    step="0.01"
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    className={controlClass}
                    {...register(`components.${index}.amount`, {
                      valueAsNumber: true,
                    })}
                  />
                )}
              </ErpFormField>
              <ErpFormField
                id={`fee-type-${index}`}
                label="Charge Type"
                required
                error={errors.components?.[index]?.chargeType?.message}
              >
                {({ id, describedBy, invalid }) => (
                  <select
                    id={id}
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    className={controlClass}
                    {...register(`components.${index}.chargeType`)}
                  >
                    {(
                      [
                        "TUITION",
                        "ADMISSION",
                        "EXAM",
                        "MATERIAL",
                        "OTHER",
                      ] as const
                    ).map((type) => (
                      <option key={type} value={type}>
                        {type}
                      </option>
                    ))}
                  </select>
                )}
              </ErpFormField>
              <ErpFormField
                id={`fee-recurrence-${index}`}
                label="Frequency"
                required
                error={errors.components?.[index]?.recurrence?.message}
              >
                {({ id, describedBy, invalid }) => (
                  <select
                    id={id}
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    className={controlClass}
                    {...register(`components.${index}.recurrence`)}
                  >
                    <option value="PER_CYCLE">Per billing cycle</option>
                    <option value="ONE_TIME">One time</option>
                  </select>
                )}
              </ErpFormField>
              {fields.length > 1 && (
                <Button
                  type="button"
                  variant="outline"
                  className="w-fit"
                  onClick={() => remove(index)}
                >
                  Remove component
                </Button>
              )}
            </div>
          ))}
          {errors.components?.root?.message && (
            <p role="alert" className="text-sm text-destructive">
              {errors.components.root.message}
            </p>
          )}
          <Button
            type="button"
            variant="outline"
            onClick={() =>
              append({
                code: "",
                name: "",
                amount: 0,
                chargeType: "OTHER",
                recurrence: "ONE_TIME",
              })
            }
          >
            Add Component
          </Button>
        </fieldset>

        <ErpFormField
          id="fee-reason"
          label="Publication Reason"
          required
          hint="This explanation is recorded with the save and audit event."
          error={errors.reason?.message}
        >
          {({ id, describedBy, invalid }) => (
            <textarea
              id={id}
              rows={2}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={`${controlClass} py-3`}
              {...register("reason")}
            />
          )}
        </ErpFormField>
        <div className="flex flex-wrap items-center gap-4">
          <Button type="submit" disabled={!isDirty || !isValid || pending}>
            {pending ? "Saving…" : "Save Fee Plan"}
          </Button>
          <ErpFormStatus message={message} />
        </div>
      </form>
      {chosenOffering && (
        <div className="mt-6">
          <DiscountPolicyForm
            key={chosenOffering.id}
            offeringId={chosenOffering.id}
            allowed={chosenOffering.allowed_discount_percentages ?? []}
          />
        </div>
      )}
    </section>
  );
}
