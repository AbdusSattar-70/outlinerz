import { CollectionForm } from "@/modules/finance/operations/collection-form";
import { AdmissionPlacementEditor } from "@/modules/admissions/components/placement-editor";
import { ExtraChargeForm } from "@/modules/admissions/components/extra-charge-form";
import Link from "next/link";
import { notFound } from "next/navigation";
import { z } from "zod";
import { PageHeader } from "@/components/erp/page-header";
import { StatusBadge } from "@/components/erp/status-badge";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { platformClient } from "@/modules/platform/rpc-client";
import {
  getAdmissionCase,
  getAdmissionWorkspace,
} from "@/modules/admissions/queries";
import { getAdmissionReferrals } from "@/modules/admissions/referrals";
import { AdmissionCommandForm } from "@/modules/admissions/components/command-form";
import { PhysicalConsentForm } from "@/modules/admissions/components/physical-consent-form";
import { ReferralForm } from "@/modules/admissions/components/referral-form";
import { AdmissionIdentityEditor } from "@/modules/admissions/components/identity-editor";
import { AdmissionDiscountForm } from "@/modules/admissions/components/discount-form";
import { CaseStepNavigation } from "@/modules/admissions/components/case-step-navigation";
import { FinalSubmissionReview } from "@/modules/admissions/components/final-submission-review";
const labels = {
  DIRECT_STAFF: "Direct admission",
  PROSPECT_CONVERSION: "Enquiry conversion",
  PUBLIC_APPLICATION: "Public application",
  EXISTING_STUDENT: "Existing student",
};
export default async function AdmissionCasePage({
  params,
}: {
  params: Promise<{ admissionId: string }>;
}) {
  const context = await requirePermission("admissions.view"),
    { admissionId } = await params;
  if (!z.string().uuid().safeParse(admissionId).success) notFound();
  const db = await platformClient();
  const [a, data, referrals, discountQ, checksQ] = await Promise.all([
    getAdmissionCase(admissionId),
    getAdmissionWorkspace(),
    getAdmissionReferrals(),
    db.rpc("admission_discount_options", { p_admission_id: admissionId }),
    db.rpc("admission_review_checks", { p_admission_id: admissionId }),
  ]);
  if (discountQ.error || checksQ.error)
    throw new Error(discountQ.error?.message ?? checksQ.error?.message);
  const discount = z
    .object({
      allowed: z.array(z.number()),
      selected: z.number(),
      reason: z.string().nullable(),
    })
    .parse(discountQ.data);
  const checks = z
    .object({ hasConsent: z.boolean(), identityRevision: z.number() })
    .parse(checksQ.data);
  const referral = referrals.choices.find((r) => r.admission_id === a.id),
    hasReferral = Boolean(referral),
    hasConsent = checks.hasConsent;
  const manage = context.permissions.includes("admissions.create"),
    canBill = context.permissions.includes("finance.billing.manage"),
    canPay = context.permissions.includes("finance.payments.post");
  const finished = [
      "BILLING_POSTED",
      "PENDING_PAYMENT",
      "ACTIVE_ENROLLMENT",
      "CLOSED_ENROLLMENT",
    ].includes(a.status),
    accepted = finished || a.status === "ACCEPTED",
    cancelled = ["CANCELLED", "CLOSED_ENROLLMENT"].includes(a.status);
  const total = a.components.reduce((n, c) => n + c.amount, 0);
  const steps = [
    {
      id: "verify",
      title: "Verify application and placement",
      complete: a.status !== "DRAFT",
      active: a.status === "DRAFT",
    },
    {
      id: "source",
      title: "Record Organic or referrer",
      complete: hasReferral,
      active: a.status === "READY" && !hasReferral,
    },
    {
      id: "consent",
      title: "Receive signed paper consent",
      complete: hasConsent,
      active: a.status !== "DRAFT" && hasReferral && !hasConsent,
    },
    {
      id: "submit",
      title: "Review fees and confirm admission",
      complete: finished,
      active:
        (a.status === "READY" && hasReferral && hasConsent) ||
        a.status === "ACCEPTED",
    },
    {
      id: "enroll",
      title: "Payment and enrollment",
      complete: a.status === "ACTIVE_ENROLLMENT",
      active: finished,
    },
  ];
  const history = (
    <p className="text-sm text-muted-foreground">
      This step is complete. The recorded application remains below; financial
      records retain their original amounts and audit history.
    </p>
  );
  const command = (
    action: "READY" | "RETURN_TO_DRAFT" | "BILL" | "ACTIVATE",
    label: string,
    description: string,
  ) => (
    <AdmissionCommandForm
      action={action}
      admissionId={a.id}
      data={data}
      label={label}
      description={description}
    />
  );
  const panels = {
    verify: (
      <div className="space-y-4">
        <h2 className="text-xl font-semibold">Verify application</h2>
        {manage && <AdmissionIdentityEditor admission={a} />}
        {manage && ["DRAFT", "READY"].includes(a.status) && (
          <AdmissionPlacementEditor
            admissionId={a.id}
            batchId={a.batchId}
            data={data}
          />
        )}
        <p className="text-sm text-muted-foreground">
          Confirm the actual student class, offering and batch. Public
          selections are preferences until staff verify them.
        </p>
        {a.status === "DRAFT" && manage
          ? command(
              "READY",
              "Details verified — continue",
              "Review the information above, correct anything necessary, then continue. This saves the draft; it does not confirm admission.",
            )
          : history}
      </div>
    ),
    source: (
      <div className="space-y-4">
        <h2 className="text-xl font-semibold">Admission source</h2>
        {a.status === "READY" && manage ? (
          <ReferralForm
            admissionId={a.id}
            people={referrals}
            choice={referral}
          />
        ) : (
          <p>
            {referral?.source === "ORGANIC"
              ? "Organic — no referrer"
              : "Verified referral recorded"}
          </p>
        )}
      </div>
    ),
    consent: (
      <div className="space-y-4">
        <h2 className="text-xl font-semibold">Signed consent</h2>
        <Link
          className="inline-block rounded-lg border px-4 py-2 text-sm"
          href={`/dashboard/admissions/${a.id}/print`}
        >
          Print two-page application and consent
        </Link>
        {a.status !== "DRAFT" && !hasConsent && manage ? (
          <PhysicalConsentForm admissionId={a.id} />
        ) : (
          <p className="text-sm">
            {hasConsent
              ? "Signed paper form received for the current application details. Keep the original in the student file."
              : "Complete verification and source first."}
          </p>
        )}
      </div>
    ),
    submit: (
      <div className="space-y-4">
        <h2 className="text-xl font-semibold">Fees and final review</h2>
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b text-left">
              <th className="py-2">Charge</th>
              <th>Frequency</th>
              <th className="text-right">BDT</th>
            </tr>
          </thead>
          <tbody>
            {a.components.map((c, i) => (
              <tr key={i} className="border-b">
                <td className="py-2">{c.name}</td>
                <td>{c.recurrence.replaceAll("_", " ")}</td>
                <td className="text-right">{c.amount.toFixed(2)}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {a.status === "READY" && manage && canBill ? (
          <>
            <ExtraChargeForm admissionId={a.id} charges={a.additionalCharges} />
            <AdmissionDiscountForm admissionId={a.id} {...discount} />
            <FinalSubmissionReview
              key={`${a.id}:${discount.selected}:${checks.identityRevision}`}
              admissionId={a.id}
              total={total}
              discountPercent={discount.selected}
              tuitionTotal={a.tuitionTotal}
            />
            {command(
              "RETURN_TO_DRAFT",
              "Go back to correct application",
              "Returns this case to Draft. Existing audit and signed records remain in history.",
            )}
          </>
        ) : a.status === "ACCEPTED" && manage ? (
          command(
            "BILL",
            "Recover missing initial invoice",
            "Complete billing for this previously accepted case. No payment is recorded.",
          )
        ) : (
          history
        )}
        {a.status === "READY" && !canBill && (
          <p>
            Billing management permission is needed to confirm admission and
            post the invoice.
          </p>
        )}
      </div>
    ),
    enroll: (
      <div className="space-y-4">
        <h2 className="text-xl font-semibold">Payment and enrollment</h2>
        {a.invoice && (
          <div className="rounded-xl bg-muted/40 p-4 text-sm">
            <p className="font-semibold">{a.invoice.number}</p>
            <p>
              Invoice: BDT {a.invoice.total.toFixed(2)} · Paid: BDT{" "}
              {a.invoice.paid.toFixed(2)} · Due: BDT {a.invoice.due.toFixed(2)}
            </p>
          </div>
        )}
        {a.invoice && a.invoice.due > 0 && canPay && (
          <CollectionForm admissionId={a.id} invoiceId={a.invoice.id} due={a.invoice.due} methods={data.paymentMethods} />
        )}
        {["BILLING_POSTED", "PENDING_PAYMENT"].includes(a.status) &&
          manage &&
          command(
            "ACTIVATE",
            "Activate enrollment",
            "Check batch capacity and the configured payment requirement. Unpaid fees stay due when credit enrollment is permitted.",
          )}
        {a.status === "ACTIVE_ENROLLMENT" && (
          <p className="rounded-xl border p-4 text-sm">
            Enrollment is active. Any outstanding invoice remains collectible.
          </p>
        )}
        {a.receipts.map((r) => (
          <Link
            key={r.number}
            className="block text-sm underline"
            href={`/dashboard/admissions/${a.id}/print?receipt=${encodeURIComponent(r.number)}`}
          >
            Print receipt {r.number} · BDT {r.amount.toFixed(2)}
          </Link>
        ))}
        <Link
          className="inline-block text-sm underline"
          href={`/dashboard/finance/billing?returnTo=${encodeURIComponent(`/dashboard/admissions/${a.id}`)}`}
        >
          Other financial adjustments — return to this case afterwards
        </Link>
      </div>
    ),
  };
  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow={labels[a.origin]}
        title={`${a.number} · ${a.name}`}
        description={`${a.offeringName} · ${a.batchName}${a.studentNo ? ` · ${a.studentNo}` : " · Student ID is issued at final submission"}`}
        actions={
          <div className="flex gap-2">
            <Link
              className="rounded-lg border px-4 py-2 text-sm"
              href="/dashboard/admissions"
            >
              Admission register
            </Link>
            <Link
              className="rounded-lg border px-4 py-2 text-sm"
              href={`/dashboard/admissions/${a.id}/print`}
            >
              Print form
            </Link>
            <StatusBadge value={a.status} />
          </div>
        }
      />
      {!cancelled ? (
        <CaseStepNavigation steps={steps} panels={panels} />
      ) : (
        <p className="rounded-xl border p-5">
          This admission is closed. Its application, enrollment history and
          financial balances are retained.
        </p>
      )}
      <details className="rounded-xl border p-5">
        <summary className="cursor-pointer font-semibold">
          Application record
        </summary>
        <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-2">
          {[
            ["Student", a.name],
            ["Guardian", a.guardian],
            ["Mobile", a.mobile],
            ["Address", a.guardianAddress ?? "—"],
            ["School", a.schoolName ?? "—"],
            ["Relationship", a.guardianRelationship ?? "—"],
            ["Programme", a.offeringName],
            ["Batch", a.batchName],
            [
              "Consent",
              hasConsent
                ? "Current signed original on file"
                : "Not recorded for current details",
            ],
          ].map(([label, value]) => (
            <div key={label}>
              <dt className="text-muted-foreground">{label}</dt>
              <dd className="font-medium">{value}</dd>
            </div>
          ))}
        </dl>
        {accepted && manage && (
          <div className="mt-4">
            <AdmissionIdentityEditor admission={a} />
          </div>
        )}
      </details>
    </div>
  );
}
