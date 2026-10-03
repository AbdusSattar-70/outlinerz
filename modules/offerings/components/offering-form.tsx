"use client";
import { finishWorkflow } from "@/modules/platform/navigation/workflow-return";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm, useWatch, type FieldPath } from "react-hook-form";
import { Button } from "@/components/ui/button";
import { ErpFormField, ErpFormStatus } from "@/components/erp/form-field";
import {
  createProgrammeOffering,
  updateProgrammeOffering,
} from "@/modules/offerings/actions";
import {
  offeringFormSchema,
  type OfferingFormInput,
  type UpdateOfferingInput,
} from "@/modules/offerings/schema";
import type { OfferingOverview } from "@/modules/offerings/queries";

const controlClass =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm focus-visible:ring-2 focus-visible:ring-ring/30 aria-[invalid=true]:border-destructive";
type OfferingRow = OfferingOverview["offerings"][number];

export function OfferingForm({
  data,
  initialOffering,
  onSuccess,
  onCancel,
}: {
  data: OfferingOverview;
  initialOffering?: OfferingRow;
  onSuccess?: (text: string) => void;
  onCancel?: () => void;
}) {
  const router = useRouter();
  const isEditing = Boolean(initialOffering);
  const contextLocked = Boolean(
    initialOffering && initialOffering.status !== "DRAFT",
  );
  const [pending, startTransition] = useTransition();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(
    null,
  );
  const {
    register,
    control,
    handleSubmit,
    reset,
    setError,
    formState: { errors, isDirty, isValid },
  } = useForm<OfferingFormInput>({
    resolver: zodResolver(offeringFormSchema),
    mode: "onChange",
    defaultValues: initialOffering
      ? {
          offeringId: initialOffering.id,
          requestId: crypto.randomUUID(),
          branchId: initialOffering.branch_id,
          academicYearId: initialOffering.academic_year_id,
          classId: initialOffering.class_id,
          programId: initialOffering.program_id,
          groupId: initialOffering.group_id ?? "",
          code: initialOffering.code,
          name: initialOffering.name,
          reason: "",
        }
      : {
          branchId: "",
          academicYearId: "",
          classId: "",
          programId: "",
          groupId: "",
          code: "",
          name: "",
          reason: "",
        },
  });
  const programId = useWatch({ control, name: "programId" });
  const programmeName =
    data.programs.find((p) => p.id === programId)?.name ?? "Programme name";
  const choices = [
    {
      key: "branchId",
      label: "Branch",
      hint: "The campus where classes will run.",
      values: data.branches,
    },
    {
      key: "academicYearId",
      label: "Academic Year",
      hint: "Choose the year this offering belongs to.",
      values: data.years,
    },
    {
      key: "classId",
      label: "Class",
      hint: "The eligible student class.",
      values: data.classes,
    },
    {
      key: "programId",
      label: "Programme",
      hint: "The academic product being offered.",
      values: data.programs,
    },
  ] as const;
  const submit = handleSubmit((input) => {
    setMessage(null);
    startTransition(async () => {
      const result = isEditing
        ? await updateProgrammeOffering(input as UpdateOfferingInput).catch(
            () => ({
              ok: false as const,
              field: undefined as string | undefined,
              error:
                "Could not save. Your entries are retained; check connection and retry.",
            }),
          )
        : await createProgrammeOffering(input).catch(() => ({
            ok: false as const,
            field: undefined as string | undefined,
            error:
              "Could not create. Your entries are retained; check connection and retry.",
          }));
      if (!result.ok) {
        if (result.field)
          setError(result.field as FieldPath<OfferingFormInput>, {
            message: result.error,
          });
        setMessage({ ok: false, text: result.error });
        return;
      }
      setMessage({
        ok: true,
        text: isEditing
          ? "Offering details saved. Existing placements and public settings stay attached."
          : "Offering created as a draft. Publish its Fee Plan to activate it.",
      });
      finishWorkflow(router);
      onSuccess?.(
        isEditing
          ? "Offering details saved."
          : "Offering created. Set fees and permitted discounts next.",
      );
      if (!isEditing) reset();
    });
  });
  return (
    <form onSubmit={submit} noValidate className="space-y-5">
      {isEditing && (
        <>
          <input type="hidden" {...register("offeringId")} />
          <input type="hidden" {...register("requestId")} />
        </>
      )}
      <div className="grid gap-5 md:grid-cols-2">
        {choices.map((choice) => (
          <ErpFormField
            key={choice.key}
            id={"offering-" + (initialOffering?.id ?? "new") + "-" + choice.key}
            label={choice.label}
            required
            hint={
              contextLocked
                ? "Academic context is locked after an offering becomes active."
                : choice.hint
            }
            error={errors[choice.key]?.message}
          >
            {({ id, describedBy, invalid }) => (
              <select
                id={id}
                disabled={contextLocked}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={controlClass}
                {...register(choice.key)}
              >
                <option value="">Select {choice.label}</option>
                {choice.values.map((option) => (
                  <option key={option.id} value={option.id}>
                    {option.name}
                  </option>
                ))}
              </select>
            )}
          </ErpFormField>
        ))}
        <ErpFormField
          id={"offering-" + (initialOffering?.id ?? "new") + "-group"}
          label="Academic Group"
          hint={
            contextLocked
              ? "Academic context is locked after activation."
              : "Choose Science when this class is restricted to the Science group."
          }
          error={errors.groupId?.message}
        >
          {({ id, describedBy, invalid }) => (
            <select
              id={id}
              disabled={contextLocked}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              {...register("groupId")}
            >
              <option value="">All groups / not applicable</option>
              {data.groups.map((group) => (
                <option key={group.id} value={group.id}>
                  {group.name}
                </option>
              ))}
            </select>
          )}
        </ErpFormField>
        <ErpFormField
          id={"offering-" + (initialOffering?.id ?? "new") + "-code"}
          label="Offering Code"
          required
          hint="Unique staff-facing code, for example SSC10-SCI-MAIN."
          error={errors.code?.message}
        >
          {({ id, describedBy, invalid }) => (
            <input
              id={id}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              {...register("code")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={"offering-" + (initialOffering?.id ?? "new") + "-name"}
          label="Custom offering title"
          hint={`Optional. Leave blank to use ${programmeName}.`}
          error={errors.name?.message}
        >
          {({ id, describedBy, invalid }) => (
            <input
              id={id}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass}
              placeholder={programmeName}
              {...register("name")}
            />
          )}
        </ErpFormField>
        <ErpFormField
          id={"offering-" + (initialOffering?.id ?? "new") + "-reason"}
          label={isEditing ? "Reason for edit" : "Creation Reason"}
          required
          hint="Saved with the audit record so staff can understand the change."
          error={errors.reason?.message}
          className="md:col-span-2"
        >
          {({ id, describedBy, invalid }) => (
            <textarea
              id={id}
              rows={2}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={controlClass + " py-3"}
              {...register("reason")}
            />
          )}
        </ErpFormField>
      </div>
      <ErpFormStatus message={message} />
      <div className="flex flex-wrap items-center gap-3">
        <Button type="submit" disabled={!isDirty || !isValid || pending}>
          {pending
            ? "Saving…"
            : isEditing
              ? "Save offering changes"
              : "Create draft offering"}
        </Button>
        {onCancel && (
          <Button
            type="button"
            variant="outline"
            disabled={pending} loading={pending}
            onClick={onCancel}
          >
            Cancel
          </Button>
        )}
      </div>
    </form>
  );
}
