"use client";
import { CrmText, useCrmText } from "@/modules/crm/translations";
import { ActionPanel } from "@/components/erp/action-panel";

import { useMemo, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm, useWatch, type FieldPath } from "react-hook-form";
import { PhoneCall } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ErpFormField, ErpFormStatus } from "@/components/erp/form-field";
import { WorkflowGuide } from "@/components/erp/workflow-guide";
import { recordProspectFollowup } from "@/modules/crm/actions";
import {
  recordProspectFollowupSchema,
  type RecordProspectFollowupInput,
} from "@/modules/crm/schema";
import {
  allowedProspectStatuses,
  type ProspectStatus,
} from "@/modules/crm/prospect-status";

const inputClass =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm text-foreground outline-none transition focus-visible:border-ring focus-visible:ring-2 focus-visible:ring-ring/30 aria-[invalid=true]:border-destructive";

export function ProspectFollowupForm({
  prospectId,
  currentStatus,
}: {
  prospectId: string;
  currentStatus: ProspectStatus;
}) {
  const tr = useCrmText();

  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(
    null,
  );

  const statuses = useMemo(
    () => allowedProspectStatuses(currentStatus),
    [currentStatus],
  );

  const {
    register,
    handleSubmit,
    control,
    reset,
    setError,
    formState: { errors, isDirty, isValid },
  } = useForm<RecordProspectFollowupInput>({
    resolver: zodResolver(recordProspectFollowupSchema),
    mode: "onChange",
    reValidateMode: "onChange",
    shouldUnregister: true,
    defaultValues: {
      requestId: crypto.randomUUID(),
      prospectId,
      followupType: "CALL",
      notes: "",
      outcome: "",
      newStatus: currentStatus,
      nextFollowUpAt: "",
      lostReason: "",
    },
  });

  const newStatus = useWatch({ control, name: "newStatus" });

  const submit = handleSubmit((input) => {
    setMessage(null);

    startTransition(async () => {
      const result = await recordProspectFollowup(input).catch(() => ({
        ok: false as const,
        error: "Could not save. Please retry.",
        field: undefined,
      }));

      if (result.ok) {
        const nextStatus = result.status as ProspectStatus;
        reset({
          requestId: crypto.randomUUID(),
          prospectId,
          followupType: "CALL",
          notes: "",
          outcome: "",
          newStatus: nextStatus,
          nextFollowUpAt: "",
          lostReason: "",
        });
        setMessage({
          ok: true,
          text: "Follow-up recorded.",
        });
        router.refresh();
        return;
      }

      if (result.field) {
        setError(result.field as FieldPath<RecordProspectFollowupInput>, {
          type: "server",
          message: result.error,
        });
      }

      setMessage({ ok: false, text: result.error });
    });
  });

  const canSubmit = isDirty && isValid && !pending;

  return (
    <section className="rounded-2xl border bg-card p-5 sm:p-6">
      <div className="mb-5">
        <p className="text-xs font-bold uppercase tracking-[0.16em] text-blue-700 dark:text-blue-300">
          <CrmText text="CRM workflow" />{" "}
        </p>
        <h2 className="mt-1 text-lg font-semibold">
          <CrmText text="Record Follow-up" />{" "}
        </h2>
        <p className="mt-2 text-sm leading-6 text-muted-foreground">
          <CrmText text="Record what happened, update the controlled Prospect status if needed, and schedule the next action in one auditable transaction." />{" "}
        </p>
      </div>

      <WorkflowGuide
        steps={[
          "Choose how the follow-up happened and record a useful factual note.",
          "Select the resulting Prospect status. Only valid lifecycle transitions are offered.",
          "Schedule the next follow-up when future action is required.",
          "The timeline and Prospect record update together under one correlation ID.",
        ]}
      />

      <ActionPanel title={tr("Record counselling / follow-up")}>
        <form
          onSubmit={submit}
          noValidate
          className="mt-6 grid gap-5 md:grid-cols-2"
        >
          <input type="hidden" {...register("requestId")} />
          <input type="hidden" {...register("prospectId")} />

          <ErpFormField
            id="followup-type"
            label={tr("Follow-up Type")}
            required
            error={errors.followupType?.message}
          >
            {({ id, describedBy, invalid }) => (
              <select
                id={id}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={inputClass}
                {...register("followupType")}
              >
                <option value="CALL">
                  <CrmText text="Phone Call" />{" "}
                </option>
                <option value="WHATSAPP">
                  <CrmText text="WhatsApp / Messaging" />{" "}
                </option>
                <option value="IN_PERSON">
                  <CrmText text="In Person" />{" "}
                </option>
                <option value="COUNSELLING">
                  <CrmText text="Counselling" />{" "}
                </option>
                <option value="TRIAL">
                  <CrmText text="Trial Class" />{" "}
                </option>
                <option value="OTHER">
                  <CrmText text="Other" />{" "}
                </option>
              </select>
            )}
          </ErpFormField>

          <ErpFormField
            id="followup-status"
            label={tr("Resulting Status")}
            required
            hint={tr(
              "Conversion to Student is not performed here; it belongs to the Admission workflow.",
            )}
            error={errors.newStatus?.message}
          >
            {({ id, describedBy, invalid }) => (
              <select
                id={id}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={inputClass}
                {...register("newStatus")}
              >
                {statuses.map((status) => (
                  <option key={status} value={status}>
                    {tr(status)}
                  </option>
                ))}
              </select>
            )}
          </ErpFormField>

          <ErpFormField
            id="followup-notes"
            label={tr("Follow-up Notes")}
            required
            hint={tr(
              "Record the meaningful facts discussed or observed. Avoid vague notes such as ‘talked’.",
            )}
            error={errors.notes?.message}
            className="md:col-span-2"
          >
            {({ id, describedBy, invalid }) => (
              <textarea
                id={id}
                rows={4}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={`${inputClass} py-2.5`}
                {...register("notes")}
              />
            )}
          </ErpFormField>

          <ErpFormField
            id="followup-outcome"
            label={tr("Outcome")}
            hint={tr(
              "Optional concise outcome, for example: guardian wants a trial class before admission.",
            )}
            error={errors.outcome?.message}
          >
            {({ id, describedBy, invalid }) => (
              <input
                id={id}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={inputClass}
                {...register("outcome")}
              />
            )}
          </ErpFormField>

          <ErpFormField
            id="followup-next"
            label={tr("Next Follow-up")}
            required={false}
            hint={tr(
              "Use this whenever another contact is expected. Action Center will surface it when due.",
            )}
            error={errors.nextFollowUpAt?.message}
          >
            {({ id, describedBy, invalid }) => (
              <input
                id={id}
                type="datetime-local"
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={inputClass}
                {...register("nextFollowUpAt")}
              />
            )}
          </ErpFormField>

          {newStatus === "LOST" && (
            <ErpFormField
              id="followup-lost-reason"
              label={tr("Lost Reason")}
              required
              hint={tr(
                "Use a factual reason that management can analyze later.",
              )}
              error={errors.lostReason?.message}
              className="md:col-span-2"
            >
              {({ id, describedBy, invalid }) => (
                <textarea
                  id={id}
                  rows={3}
                  aria-describedby={describedBy}
                  aria-invalid={invalid}
                  className={`${inputClass} py-2.5`}
                  {...register("lostReason")}
                />
              )}
            </ErpFormField>
          )}

          <div className="md:col-span-2">
            <ErpFormStatus message={message} />
          </div>

          <div className="md:col-span-2 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-end">
            {!canSubmit && !pending && (
              <p className="text-xs text-muted-foreground">
                <CrmText text="Add the required follow-up details and resolve validation errors to enable saving." />{" "}
              </p>
            )}
            <Button type="submit" disabled={!canSubmit} className="min-h-11">
              <PhoneCall className="mr-2 size-4" aria-hidden="true" />
              {pending ? tr("Saving Follow-up…") : tr("Record Follow-up")}
            </Button>
          </div>
        </form>
      </ActionPanel>
    </section>
  );
}
