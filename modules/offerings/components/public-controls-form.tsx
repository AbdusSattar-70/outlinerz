"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm, type FieldPath, type Resolver } from "react-hook-form";
import { Button } from "@/components/ui/button";
import { ErpFormField, ErpFormStatus } from "@/components/erp/form-field";
import { updateProgrammeOfferingPublicControls } from "@/modules/offerings/actions";
import {
  SHOWCASE_ICON_VALUES,
  updateOfferingPublicControlsSchema,
  type UpdateOfferingPublicControlsInput,
} from "@/modules/offerings/schema";
import type { OfferingOverview } from "@/modules/offerings/queries";

const controlClass =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm focus-visible:ring-2 focus-visible:ring-ring/30 aria-[invalid=true]:border-destructive";

type OfferingRow = OfferingOverview["offerings"][number];

const ICON_LABELS: Record<(typeof SHOWCASE_ICON_VALUES)[number], string> = {
  "clipboard-check": "Clipboard (assessment)",
  "graduation-cap": "Graduation cap",
  "users-round": "Small batch / people",
  "book-open-check": "Book with check",
  "line-chart": "Progress chart",
  "shield-check": "Trust / verified",
};

export function PublicControlsForm({
  offering,
  subjects,
  linkedSubjectIds,
  onSuccess,
}: {
  offering: OfferingRow;
  subjects: OfferingOverview["subjects"];
  linkedSubjectIds: string[];
  onSuccess?: () => void;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(
    null,
  );
  const isActive = offering.status === "ACTIVE";

  const {
    register,
    handleSubmit,
    setError,
    watch,
    formState: { errors, isDirty, isValid },
  } = useForm<UpdateOfferingPublicControlsInput>({
    resolver: zodResolver(
      updateOfferingPublicControlsSchema,
    ) as Resolver<UpdateOfferingPublicControlsInput>,
    mode: "onChange",
    defaultValues: {
      offeringId: offering.id,
      showcaseTitle: offering.showcase_title ?? "",
      showcaseTitleBn: offering.showcase_title_bn ?? "",
      showcaseDescription: offering.showcase_description ?? "",
      showcaseDescriptionBn: offering.showcase_description_bn ?? "",
      showcaseEyebrow: offering.showcase_eyebrow ?? "",
      showcaseEyebrowBn: offering.showcase_eyebrow_bn ?? "",
      publicSchedule: offering.public_schedule ?? "",
      publicScheduleBn: offering.public_schedule_bn ?? "",
      publicRequirements: offering.public_requirements ?? "",
      publicRequirementsBn: offering.public_requirements_bn ?? "",
      admissionPolicy: offering.admission_policy ?? "",
      admissionPolicyBn: offering.admission_policy_bn ?? "",
      showcaseIcon:
        (offering.showcase_icon as UpdateOfferingPublicControlsInput["showcaseIcon"]) ??
        "",
      showcaseSortOrder: offering.showcase_sort_order ?? 100,
      isWebsiteVisible: offering.is_website_visible ?? false,
      isAcceptingApplications: offering.is_accepting_applications ?? false,
      applicationsOpenOn: offering.applications_open_on ?? "",
      applicationsCloseOn: offering.applications_close_on ?? "",
      subjectIds: linkedSubjectIds,
      reason: "",
    },
  });

  const isVisible = watch("isWebsiteVisible");
  const canSubmit = isDirty && isValid && !pending;

  const submit = handleSubmit((input) => {
    setMessage(null);
    startTransition(async () => {
      const result = await updateProgrammeOfferingPublicControls(input).catch(
        () => ({
          ok: false as const,
          field: undefined as string | undefined,
          error: "Could not save. Your entries remain; retry when connected.",
        }),
      );
      if (!result.ok) {
        if (result.field) {
          setError(
            result.field as FieldPath<UpdateOfferingPublicControlsInput>,
            {
              message: result.error,
            },
          );
        }
        setMessage({ ok: false, text: result.error });
        return;
      }
      setMessage({
        ok: true,
        text: "Public controls saved. Website visibility and application intake are independent of operational status.",
      });
      onSuccess?.();
      router.refresh();
    });
  });

  return (
    <form
      onSubmit={submit}
      className="mt-4 space-y-4 rounded-xl border border-dashed border-border bg-muted/20 p-4"
      noValidate
    >
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <p className="text-sm font-semibold">
            Public controls — <span className="font-mono">{offering.code}</span>
          </p>
          <p className="mt-1 text-xs leading-5 text-muted-foreground">
            Operational status stays {offering.status}. Website visibility and
            accepting applications are separate switches. Homepage card design
            is fixed; only curated copy and icons change.
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <label className="inline-flex min-h-11 cursor-pointer items-center gap-2 rounded-xl border bg-background px-3 text-sm font-medium">
            <input
              type="checkbox"
              className="size-4 rounded border-input"
              disabled={!isActive || pending}
              {...register("isWebsiteVisible")}
            />
            Website visible
          </label>
          <label className="inline-flex min-h-11 cursor-pointer items-center gap-2 rounded-xl border bg-background px-3 text-sm font-medium">
            <input
              type="checkbox"
              className="size-4 rounded border-input"
              disabled={offering.status === "RETIRED" || pending}
              {...register("isAcceptingApplications")}
            />
            Accepting applications
          </label>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <ErpFormField
          id={`${offering.id}-eyebrow`}
          label="Eyebrow (English)"
          error={errors.showcaseEyebrow?.message}
        >
          {({ id, describedBy, invalid }) => (
            <input
              id={id}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              disabled={pending}
              {...register("showcaseEyebrow")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-eyebrow-bn`}
          label="Eyebrow (Bangla)"
          error={errors.showcaseEyebrowBn?.message}
        >
          {({ id, describedBy, invalid }) => (
            <input
              id={id}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              disabled={pending}
              {...register("showcaseEyebrowBn")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-title`}
          label="Title (English)"
          required={isVisible}
          error={errors.showcaseTitle?.message}
        >
          {({ id, describedBy, invalid }) => (
            <input
              id={id}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              disabled={pending}
              {...register("showcaseTitle")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-title-bn`}
          label="Title (Bangla)"
          error={errors.showcaseTitleBn?.message}
        >
          {({ id, describedBy, invalid }) => (
            <input
              id={id}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              disabled={pending}
              {...register("showcaseTitleBn")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-desc`}
          label="Description (English)"
          required={isVisible}
          className="sm:col-span-2"
          error={errors.showcaseDescription?.message}
        >
          {({ id, describedBy, invalid }) => (
            <textarea
              id={id}
              rows={3}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={`${controlClass} min-h-22 py-2`}
              disabled={pending}
              {...register("showcaseDescription")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-desc-bn`}
          label="Description (Bangla)"
          className="sm:col-span-2"
          error={errors.showcaseDescriptionBn?.message}
        >
          {({ id, describedBy, invalid }) => (
            <textarea
              id={id}
              rows={3}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={`${controlClass} min-h-22 py-2`}
              disabled={pending}
              {...register("showcaseDescriptionBn")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-schedule`}
          label="Public schedule (English)"
          className="sm:col-span-2"
          hint="State the intended days and times. Actual placement is confirmed by staff."
          error={errors.publicSchedule?.message}
        >
          {({ id, describedBy, invalid }) => (
            <textarea
              id={id}
              rows={2}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={`${controlClass} min-h-20 py-2`}
              disabled={pending}
              {...register("publicSchedule")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-schedule-bn`}
          label="Public schedule (Bangla)"
          className="sm:col-span-2"
          error={errors.publicScheduleBn?.message}
        >
          {({ id, describedBy, invalid }) => (
            <textarea
              id={id}
              rows={2}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={`${controlClass} min-h-20 py-2`}
              disabled={pending}
              {...register("publicScheduleBn")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-requirements`}
          label="Application requirements (English)"
          className="sm:col-span-2"
          hint="Describe eligibility and documents staff will verify. Applicants see this before submitting."
          error={errors.publicRequirements?.message}
        >
          {({ id, describedBy, invalid }) => (
            <textarea
              id={id}
              rows={3}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={`${controlClass} min-h-22 py-2`}
              disabled={pending}
              {...register("publicRequirements")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-requirements-bn`}
          label="Application requirements (Bangla)"
          className="sm:col-span-2"
          error={errors.publicRequirementsBn?.message}
        >
          {({ id, describedBy, invalid }) => (
            <textarea
              id={id}
              rows={3}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={`${controlClass} min-h-22 py-2`}
              disabled={pending}
              {...register("publicRequirementsBn")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-policy`}
          label="Admission policy (English)"
          className="sm:col-span-2"
          hint="Explain verification, placement and when admission becomes confirmed. Fees remain governed by the published plan."
          error={errors.admissionPolicy?.message}
        >
          {({ id, describedBy, invalid }) => (
            <textarea
              id={id}
              rows={3}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={`${controlClass} min-h-22 py-2`}
              disabled={pending}
              {...register("admissionPolicy")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-policy-bn`}
          label="Admission policy (Bangla)"
          className="sm:col-span-2"
          error={errors.admissionPolicyBn?.message}
        >
          {({ id, describedBy, invalid }) => (
            <textarea
              id={id}
              rows={3}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={`${controlClass} min-h-22 py-2`}
              disabled={pending}
              {...register("admissionPolicyBn")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-icon`}
          label="Icon"
          error={errors.showcaseIcon?.message}
        >
          {({ id, describedBy, invalid }) => (
            <select
              id={id}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              disabled={pending}
              {...register("showcaseIcon")}
            >
              <option value="">Default (graduation cap)</option>
              {SHOWCASE_ICON_VALUES.map((value) => (
                <option key={value} value={value}>
                  {ICON_LABELS[value]}
                </option>
              ))}
            </select>
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-sort`}
          label="Sort order"
          hint="Lower numbers appear first."
          error={errors.showcaseSortOrder?.message}
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
              {...register("showcaseSortOrder", { valueAsNumber: true })}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-open`}
          label="Applications open on"
          error={errors.applicationsOpenOn?.message}
        >
          {({ id, describedBy, invalid }) => (
            <input
              id={id}
              type="date"
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              disabled={pending}
              {...register("applicationsOpenOn")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-close`}
          label="Applications close on"
          error={errors.applicationsCloseOn?.message}
        >
          {({ id, describedBy, invalid }) => (
            <input
              id={id}
              type="date"
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              disabled={pending}
              {...register("applicationsCloseOn")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-subjects`}
          label="Subjects on this offering"
          className="sm:col-span-2"
          hint="Hold Ctrl/Cmd to select multiple. Used on public cards and forms."
          error={errors.subjectIds?.message}
        >
          {({ id, describedBy, invalid }) => (
            <select
              id={id}
              multiple
              size={Math.min(8, Math.max(3, subjects.length))}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={`${controlClass} h-auto min-h-24 py-2`}
              disabled={pending}
              {...register("subjectIds")}
            >
              {subjects.map((subject) => (
                <option key={subject.id} value={subject.id}>
                  {subject.code} — {subject.name}
                </option>
              ))}
            </select>
          )}
        </ErpFormField>
        <ErpFormField
          id={`${offering.id}-reason`}
          label="Reason"
          required
          className="sm:col-span-2"
          hint="Audit action: UPDATE_PUBLIC_CONTROLS."
          error={errors.reason?.message}
        >
          {({ id, describedBy, invalid }) => (
            <input
              id={id}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              disabled={pending}
              placeholder="e.g. Open SSC Science admissions for 2026"
              {...register("reason")}
            />
          )}
        </ErpFormField>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <Button type="submit" disabled={!canSubmit}>
          {pending ? "Saving\u2026" : "Save public controls"}
        </Button>
        {!isActive && (
          <p className="text-xs text-muted-foreground">
            Publish a Fee Plan so this offering becomes ACTIVE before enabling
            website visibility.
          </p>
        )}
      </div>
      <ErpFormStatus message={message} />
    </form>
  );
}
