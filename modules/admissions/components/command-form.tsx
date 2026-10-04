"use client";
import { finishWorkflow } from "@/modules/platform/navigation/workflow-return";
import { useRouter } from "next/navigation";
import { useRef, useState, useTransition, type FormEvent } from "react";
import { useForm, useWatch, type FieldPath } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
import { ErpFormField, ErpFormStatus } from "@/components/erp/form-field";
import {
  commandSchema,
  type AdmissionCommand,
  type AdmissionWorkspace,
  type AdmissionCommandFormData,
} from "../schema";
import { runAdmissionCommand } from "../actions";
const REASON_PRESETS: Partial<Record<AdmissionCommand["action"], string[]>> = {
  FINALIZE: [
    "Reviewed student identity and academic placement",
  ],
  RETURN_TO_DRAFT: ["Return to draft to correct application details"],
  READY: [
    "Confirmed student identity, guardian contact, programme and batch",
    "Verified public application against supporting documents",
    "Corrected details with guardian present",
  ],
  ACCEPT: [
    "Confirmed enrollment after identity and placement verification",
    "Confirmed enrollment with verified student and guardian details",
  ],
  BILL: ["Posted initial charges from the pinned Fee Plan"],
  ACTIVATE: [
    "Activation policy and batch capacity checked",
    "Activated with outstanding balance allowed by policy",
  ],
  PAY: ["Cash received at front desk", "Bank transfer confirmed"],
  EDIT_DRAFT: ["Corrected identity details with guardian"],
  CREATE: ["Creating draft from verified enquiry"],
  CREATE_BATCH: ["Opening a new teaching batch for this offering"],
};

const inputClass =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm focus-visible:ring-2 focus-visible:ring-ring aria-[invalid=true]:border-destructive";
type Option = { id: string; name: string; disabled?: boolean };
export function AdmissionCommandForm({
  action,
  data,
  admissionId,
  label,
  description,
  maxAmount,
  identity,
  defaultProspectId,
  initialBatch,
  onSuccess,
  onCancel,
}: {
  action: AdmissionCommand["action"];
  data: AdmissionCommandFormData;
  admissionId?: string;
  label: string;
  description: string;
  maxAmount?: number;
  identity?: { name: string; guardian: string; mobile: string };
  defaultProspectId?: string;
  initialBatch?: { id: string; code: string; name: string; capacity: number };
  onSuccess?: () => void;
  onCancel?: () => void;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
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
    setError,
    formState: { errors, isDirty },
  } = useForm<AdmissionCommand>({
    resolver: zodResolver(commandSchema),
    mode: "onChange",
    defaultValues: {
      action,
      admissionId,
      requestId: crypto.randomUUID(),
      reason: "",
      ...(identity
        ? {
            studentName: identity.name,
            guardianName: identity.guardian,
            mobile: identity.mobile,
          }
        : {}),
      ...(action === "CREATE_BATCH"
        ? { capacity: data.capacityLimit ?? undefined }
        : {}),
      ...(action === "EDIT_BATCH" && initialBatch
        ? {
            batchId: initialBatch.id,
            code: initialBatch.code,
            name: initialBatch.name,
            capacity: initialBatch.capacity,
          }
        : {}),
      ...(action === "CREATE" && defaultProspectId
        ? (() => {
            const nextProspect = data.prospects.find(
              (p) => p.id === defaultProspectId,
            );
            const classMatched = data.offerings.filter(
              (o) =>
                o.feeReady !== false &&
                (!nextProspect?.classId || o.classId === nextProspect.classId),
            );
            const preferred =
              nextProspect?.interestedOfferingId &&
              classMatched.some(
                (o) => o.id === nextProspect.interestedOfferingId,
              )
                ? nextProspect.interestedOfferingId
                : classMatched[0]?.id;
            return {
              prospectId: defaultProspectId,
              offeringId: preferred,
            };
          })()
        : {}),
    },
  });
  const prospectId = useWatch({ control, name: "prospectId" });
  const offeringId = useWatch({ control, name: "offeringId" });
  const prospect = data.prospects.find((p) => p.id === prospectId);
  const field = (
    key: FieldPath<AdmissionCommand>,
    title: string,
    hint: string,
    options?: Option[],
    numeric = false,
    required = true,
  ) => (
    <ErpFormField
      key={key}
      id={`${action}-${admissionId ?? "new"}-${key}`}
      label={title}
      required={required}
      hint={hint}
      error={errors[key]?.message}
    >
      {({ id, describedBy, invalid }) =>
        options ? (
          <select
            id={id}
            className={inputClass}
            aria-describedby={describedBy}
            aria-invalid={invalid}
            {...register(key, {
              onChange: (event) => {
                if (key === "prospectId") {
                  const nextProspect = data.prospects.find(
                    (p) => p.id === event.target.value,
                  );
                  const classMatched = data.offerings.filter(
                    (o) =>
                      o.feeReady !== false &&
                      (!nextProspect?.classId ||
                        o.classId === nextProspect.classId),
                  );
                  const preferred =
                    nextProspect?.interestedOfferingId &&
                    data.offerings.some(
                      (o) =>
                        o.id === nextProspect.interestedOfferingId &&
                        o.feeReady !== false,
                    )
                      ? nextProspect.interestedOfferingId
                      : (classMatched[0]?.id ?? "");
                  setValue("confirmPlacementCorrection", false);
                  setValue("offeringId", preferred, {
                    shouldDirty: true,
                    shouldValidate: true,
                  });
                  setValue("batchId", "", {
                    shouldDirty: true,
                    shouldValidate: true,
                  });
                }
                if (key === "offeringId")
                  setValue("batchId", "", {
                    shouldDirty: true,
                    shouldValidate: true,
                  });
              },
            })}
          >
            <option value="">Select {title}</option>
            {options.length === 0 ? (
              <option value="" disabled>
                No valid options available
              </option>
            ) : (
              options.map((o) => (
                <option key={o.id} value={o.id} disabled={o.disabled}>
                  {o.name}
                </option>
              ))
            )}
          </select>
        ) : (
          <input
            id={id}
            className={inputClass}
            aria-describedby={describedBy}
            aria-invalid={invalid}
            type={numeric ? "number" : "text"}
            step={key === "amount" ? "0.01" : numeric ? "1" : undefined}
            min={numeric ? 0 : undefined}
            max={
              key === "amount"
                ? maxAmount
                : key === "capacity"
                  ? (data.capacityLimit ?? 500)
                  : undefined
            }
            {...register(key, { valueAsNumber: numeric })}
          />
        )
      }
    </ErpFormField>
  );
  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    void handleSubmit((values) => {
      const signature = JSON.stringify(values);
      if (!request.current || request.current.signature !== signature) {
        request.current = { signature, id: crypto.randomUUID() };
      }
      const payload = { ...values, requestId: request.current.id };
      setMessage(null);
      startTransition(async () => {
        if (action === "CREATE" && prospect && offeringId) {
          const chosen = data.offerings.find((o) => o.id === offeringId);
          if (
            chosen &&
            ((prospect.classId && prospect.classId !== chosen.classId) ||
              (prospect.interestedOfferingId &&
                prospect.interestedOfferingId !== chosen.id)) &&
            !values.confirmPlacementCorrection
          ) {
            setMessage({
              ok: false,
              text: "Confirm the corrected programme and class before creating the draft.",
            });
            return;
          }
        }
        const result = await runAdmissionCommand(payload).catch(() => ({
          ok: false as const,
          message:
            "Could not confirm the result. Your entries remain; retry the same values safely.",
          field: undefined as string | undefined,
        }));
        if (!result.ok) {
          if (result.field)
            setError(result.field as FieldPath<AdmissionCommand>, {
              message: result.message,
            });
          setMessage({ ok: false, text: result.message });
          return;
        }
        request.current = null;
        onSuccess?.();
        if (action === "CREATE" && typeof result.entityId === "string") {
          router.push(`/dashboard/admissions/${result.entityId}`);
          return;
        }
        finishWorkflow(router);
        reset({
          action,
          admissionId,
          requestId: crypto.randomUUID(),
          reason: "",
          ...(identity
            ? {
                studentName: identity.name,
                guardianName: identity.guardian,
                mobile: identity.mobile,
              }
            : {}),
          ...(action === "CREATE_BATCH"
            ? { capacity: data.capacityLimit ?? undefined }
            : {}),
          ...(action === "CREATE" && defaultProspectId
            ? (() => {
                const nextProspect = data.prospects.find(
                  (p) => p.id === defaultProspectId,
                );
                const classMatched = data.offerings.filter(
                  (o) =>
                    o.feeReady !== false &&
                    (!nextProspect?.classId ||
                      o.classId === nextProspect.classId),
                );
                const preferred =
                  nextProspect?.interestedOfferingId &&
                  classMatched.some(
                    (o) => o.id === nextProspect.interestedOfferingId,
                  )
                    ? nextProspect.interestedOfferingId
                    : classMatched[0]?.id;
                return {
                  prospectId: defaultProspectId,
                  offeringId: preferred,
                };
              })()
            : {}),
        });
        setMessage({ ok: true, text: result.message ?? "Saved." });
      });
    })();
  };
  return (
    <form onSubmit={submit} className="space-y-4 rounded-2xl border p-5">
      <div>
        <h3 className="font-semibold">{label}</h3>
        <p className="mt-1 text-sm text-muted-foreground">{description}</p>
      </div>
      <div className="grid gap-4 md:grid-cols-2">
        {(action === "CREATE_BATCH" || action === "EDIT_BATCH") && (
          <>
            {action === "CREATE_BATCH" &&
              field(
                "offeringId",
                "Offering",
                "Choose the programme offering this batch belongs to.",
                data.offerings.map((o) => ({
                  id: o.id,
                  name: `${o.name} · ${o.yearName} · ${o.branchName ?? "No branch"} · ${o.className}`,
                })),
              )}
            {field(
              "code",
              "Batch Code",
              "Short operational code used in schedules and reports.",
            )}
            {field(
              "name",
              "Batch Name",
              "Use the name staff and guardians recognize.",
            )}
            {field(
              "capacity",
              "Capacity",
              `Current policy maximum: ${data.capacityLimit ?? "not configured"}.`,
              undefined,
              true,
            )}
            {action === "EDIT_BATCH" && (
              <input type="hidden" {...register("batchId")} />
            )}
          </>
        )}
        {action === "CREATE" && (
          <>
            {field(
              "prospectId",
              "Prospect",
              data.prospects.length
                ? "Select an existing enquiry. Identity and guardian details are inherited."
                : "No open enquiries are available. Use staff intake for a new applicant, or continue an enquiry in CRM first.",
              data.prospects.map((p) => ({
                id: p.id,
                name: `${p.number} · ${p.name} · ${p.mobile}`,
              })),
            )}
            {field(
              "offeringId",
              "Programme offering",
              (() => {
                if (!prospect) {
                  return "Select a Prospect first.";
                }
                if (!data.offerings.length) {
                  return "No ACTIVE programme offering exists. Create and activate one under Academics → Offerings.";
                }
                if (data.offerings.every((o) => o.feeReady === false)) {
                  return "Review and activate an academic offering before creating an admission.";
                }
                const classMatched = data.offerings.filter(
                  (o) => !prospect.classId || o.classId === prospect.classId,
                );
                if (!classMatched.length) {
                  return "No offering matches the recorded class. Select the intended active offering below and confirm the placement correction.";
                }
                if (
                  prospect.interestedOfferingId &&
                  !classMatched.some(
                    (o) => o.id === prospect.interestedOfferingId,
                  )
                ) {
                  return "The recorded interest is unavailable. Select the intended active offering and confirm the change below.";
                }
                return prospect.classId
                  ? "Choose the intended active offering. A different class needs explicit confirmation below."
                  : "Confirm the intended programme. Class is taken from the offering when the Prospect has none.";
              })(),
              (() => {
                if (!prospect) return [];
                return data.offerings.map((o) => ({
                  id: o.id,
                  name: `${o.name} · ${o.yearName} · ${o.branchName ?? "No branch"} · ${o.className}${o.feeReady === false ? " · Offering unavailable" : ""}`,
                  disabled: o.feeReady === false,
                }));
              })(),
            )}
            {prospect && data.offerings.some((o) => o.feeReady === false) && (
              <a
                className="text-sm font-medium text-primary underline md:col-span-2"
                href="/dashboard/finance/fee-plans"
              >
                Open Fee Plans to finish setup
              </a>
            )}
            {prospect &&
              offeringId &&
              (() => {
                const chosen = data.offerings.find((o) => o.id === offeringId);
                const differs =
                  chosen &&
                  ((prospect.classId && prospect.classId !== chosen.classId) ||
                    (prospect.interestedOfferingId &&
                      prospect.interestedOfferingId !== chosen.id));
                return differs ? (
                  <label className="flex items-start gap-3 rounded-xl border border-amber-500/40 p-4 text-sm md:col-span-2">
                    <input
                      type="checkbox"
                      className="mt-1"
                      {...register("confirmPlacementCorrection")}
                    />
                    <span>
                      Confirm the selected programme and class differ from this
                      Prospect’s enquiry. I verified the intended placement with
                      the student or guardian; the correction will be recorded
                      in the audit trail.
                    </span>
                  </label>
                ) : null;
              })()}
            {field(
              "batchId",
              "Batch",
              (() => {
                if (!offeringId) {
                  return "Select a programme offering first.";
                }
                const active = data.batches.filter(
                  (b) => b.isActive && b.offeringId === offeringId,
                );
                if (!active.length) {
                  return "No active batch exists for this offering. Create one under Academics → Batches, then return here.";
                }
                if (
                  active.every(
                    (b) =>
                      b.occupied >=
                      Math.min(b.capacity, data.capacityLimit ?? b.capacity),
                  )
                ) {
                  return "All batches for this offering are full. Open a new batch or raise capacity, then return here.";
                }
                return "Choose an active batch in the selected offering. Full batches cannot be selected.";
              })(),
              data.batches
                .filter((b) => b.isActive && b.offeringId === offeringId)
                .map((b) => ({
                  id: b.id,
                  name: `${b.name} · ${b.occupied}/${b.capacity} seats`,
                  disabled:
                    b.occupied >=
                    Math.min(b.capacity, data.capacityLimit ?? b.capacity),
                })),
            )}
          </>
        )}
        {action === "EDIT_DRAFT" && (
          <>
            {field(
              "studentName",
              "Student Name",
              "Use the verified student name.",
            )}
            {field(
              "guardianName",
              "Guardian Name",
              "Primary guardian for contact and billing.",
            )}
            {field("mobile", "Mobile", "Bangladesh mobile, 01XXXXXXXXX.")}
          </>
        )}
        {action === "PAY" && (
          <>
            {field(
              "amount",
              "Amount received",
              maxAmount
                ? `Outstanding balance about BDT ${maxAmount.toFixed(2)}.`
                : "Enter the amount actually received.",
              undefined,
              true,
            )}
            {field(
              "paymentMethodId",
              "Payment method",
              "How the payment was received.",
              data.paymentMethods.map((m) => ({ id: m.id, name: m.name })),
            )}
            {field(
              "externalReference",
              "External reference",
              "Optional bank or gateway reference.",
              undefined,
              false,
              false,
            )}
          </>
        )}
        {(() => {
          const presets = REASON_PRESETS[action] ?? [];
          const label =
            action === "READY"
              ? "Verification note"
              : action === "ACCEPT"
                ? "Acceptance note"
                : action === "BILL"
                  ? "Billing note"
                  : action === "ACTIVATE"
                    ? "Enrollment decision note"
                    : action === "PAY"
                      ? "Payment note"
                      : "Staff note";
          return (
            <ErpFormField
              id={`${action}-${admissionId ?? "new"}-reason`}
              label={label}
              required
              hint="Choose a standard note. Use Other only when the situation is unusual."
              error={errors.reason?.message}
            >
              {({ id, describedBy, invalid }) => (
                <div className="space-y-2">
                  {presets.length > 0 && (
                    <select
                      className={inputClass}
                      defaultValue=""
                      onChange={(event) => {
                        const value = event.target.value;
                        if (value === "__other__") {
                          setValue("reason", "", {
                            shouldDirty: true,
                            shouldValidate: true,
                          });
                          return;
                        }
                        if (value) {
                          setValue("reason", value, {
                            shouldDirty: true,
                            shouldValidate: true,
                          });
                        }
                      }}
                    >
                      <option value="">Select a standard note…</option>
                      {presets.map((item) => (
                        <option key={item} value={item}>
                          {item}
                        </option>
                      ))}
                      <option value="__other__">Other (type below)</option>
                    </select>
                  )}
                  <input
                    id={id}
                    className={inputClass}
                    aria-describedby={describedBy}
                    aria-invalid={invalid}
                    placeholder="Selected note appears here; type only for Other"
                    {...register("reason")}
                  />
                </div>
              )}
            </ErpFormField>
          );
        })()}
      </div>
      {prospect && action === "CREATE" && (
        <div className="rounded-xl border bg-muted/30 p-4 text-sm leading-6">
          <p className="font-medium text-foreground">
            Verified CRM data will seed this draft
          </p>
          <p className="mt-1 text-muted-foreground">
            {prospect.number} · {prospect.name}
          </p>
          <p className="mt-1 text-muted-foreground">
            Guardian: {prospect.guardian} · {prospect.mobile}
          </p>
          <p className="mt-2 text-xs text-muted-foreground">
            Student, guardian and contact details are inherited from the
            Prospect. Choose an eligible batch, then review fees before
            acceptance.
          </p>
        </div>
      )}
      <ErpFormStatus message={message} />
      <div className="flex flex-wrap items-center gap-3">
        <Button type="submit" disabled={pending || !isDirty} loading={pending}>
          {pending ? "Working…" : label}
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
