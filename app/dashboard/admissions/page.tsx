import Link from "next/link";
import { PageHeader } from "@/components/erp/page-header";
import { StatusBadge } from "@/components/erp/status-badge";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { getAdmissionWorkspace } from "@/modules/admissions/queries";
import { AdmissionCommandForm } from "@/modules/admissions/components/command-form";
import { StaffAdmissionIntakeForm } from "@/modules/admissions/components/staff-intake-form";
const caseGroups = {
  open: {
    label: "In progress",
    description:
      "Cases still requiring verification and academic enrollment.",
    matches: (status: string) =>
      !["ACTIVE_ENROLLMENT", "CANCELLED", "CLOSED_ENROLLMENT"].includes(status),
  },
  completed: {
    label: "Enrolled",
    description:
      "Admissions with an active academic enrollment.",
    matches: (status: string) => status === "ACTIVE_ENROLLMENT",
  },
  closed: {
    label: "Closed",
    description:
      "Cancelled, withdrawn and completed cases retained for history.",
    matches: (status: string) =>
      ["CANCELLED", "CLOSED_ENROLLMENT"].includes(status),
  },
} as const;

function nextCaseStep(status: string) {
  switch (status) {
    case "DRAFT":
      return "Verify application";
    case "READY":
      return "Confirm academic enrollment";
    case "ACCEPTED":
      return "Review record";
    case "BILLING_POSTED":
    case "PENDING_PAYMENT":
      return "Activate enrollment";
    default:
      return "View record";
  }
}

export default async function AdmissionsPage({
  searchParams,
}: {
  searchParams: Promise<{ prospect?: string; start?: string; view?: string }>;
}) {
  const context = await requirePermission("admissions.view");
  const {
    prospect: prospectParam,
    start: startParam,
    view: viewParam,
  } = await searchParams;
  const selectedView =
    viewParam === "completed" || viewParam === "closed" ? viewParam : "open";
  const data = await getAdmissionWorkspace();
  const visibleCases = data.cases.filter((item) =>
    caseGroups[selectedView].matches(item.status),
  );
  const manage = context.permissions.includes("admissions.create");
  const defaultProspectId =
    prospectParam && data.prospects.some((p) => p.id === prospectParam)
      ? prospectParam
      : undefined;
  const preselected = defaultProspectId
    ? data.prospects.find((p) => p.id === defaultProspectId)
    : undefined;
  const startMode =
    startParam === "staff" || startParam === "enquiry"
      ? startParam
      : defaultProspectId
        ? "enquiry"
        : null;
  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="Student Lifecycle"
        title="Admissions"
        description="Verify the application, record referral and paper consent, then accept. Billing and enrollment follow as separate steps."
      />
      <div className="flex flex-wrap gap-4 text-sm print:hidden">
        <Link href="/dashboard/crm/prospects" className="underline">
          Enquiries
        </Link>
        <Link href="/dashboard/academics/batches" className="underline">
          Batch setup
        </Link>
        <Link href="/dashboard/students" className="underline">
          Student register
        </Link>
      </div>
      {manage && (
        <section
          id="start-admission"
          className="space-y-4 rounded-2xl border bg-muted/10 p-5 sm:p-6"
        >
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-blue-700 dark:text-blue-300">
              Choose how to begin
            </p>
            <h2 className="mt-1 text-xl font-semibold">Start an admission</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              Pick a path below. The matching form opens on this page. Online
              entry creates an unconfirmed draft. A blank paper form must be
              entered by staff before a case exists.
            </p>
          </div>
          <div className="grid gap-3 md:grid-cols-3">
            <Link
              href="/dashboard/admissions?start=staff"
              className={`rounded-xl border bg-card p-4 transition hover:border-primary/60 ${
                startMode === "staff"
                  ? "border-primary ring-2 ring-primary/20"
                  : ""
              }`}
            >
              <p className="text-sm font-semibold">
                New applicant with staff assistance
              </p>
              <p className="mt-1 min-h-10 text-xs leading-5 text-muted-foreground">
                Enter the student and guardian details while they are with you.
                Creates the admission application and draft case directly; does
                not create a CRM Enquiry.
              </p>
              <span className="mt-3 inline-block text-sm font-medium text-primary underline">
                {startMode === "staff"
                  ? "Form open below"
                  : "Open staff intake form"}
              </span>
            </Link>
            <Link
              href={
                defaultProspectId
                  ? `/dashboard/admissions?start=enquiry&prospect=${defaultProspectId}`
                  : "/dashboard/admissions?start=enquiry"
              }
              className={`rounded-xl border bg-card p-4 transition hover:border-primary/60 ${
                startMode === "enquiry"
                  ? "border-primary ring-2 ring-primary/20"
                  : ""
              }`}
            >
              <p className="text-sm font-semibold">Already in Enquiries</p>
              <p className="mt-1 min-h-10 text-xs leading-5 text-muted-foreground">
                Continue a verified enquiry. Choose the intended offering and an
                available batch. Identity is inherited from the CRM record.
              </p>
              <span className="mt-3 inline-block text-sm font-medium text-primary underline">
                {startMode === "enquiry"
                  ? "Form open below"
                  : "Open enquiry conversion form"}
              </span>
            </Link>
            <Link
              href="/dashboard/admissions/application-form"
              className="rounded-xl border bg-card p-4 transition hover:border-primary/60"
            >
              <p className="text-sm font-semibold">Paper application</p>
              <p className="mt-1 min-h-10 text-xs leading-5 text-muted-foreground">
                Print a blank A4 form for the student and guardian to complete
                and sign in person.
              </p>
              <span className="mt-3 inline-block text-sm font-medium text-primary underline">
                Print blank application
              </span>
            </Link>
          </div>

          {startMode === "staff" && (
            <div
              id="new-applicant"
              className="scroll-mt-24 space-y-3 rounded-xl border border-primary/30 bg-card p-4 sm:p-5"
            >
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <p className="text-xs font-bold uppercase tracking-[0.16em] text-muted-foreground">
                    Staff intake
                  </p>
                  <h3 className="mt-1 text-lg font-semibold">
                    Enter a new applicant online
                  </h3>
                  <p className="mt-1 text-sm text-muted-foreground">
                    Complete the form below. On success you are taken to the
                    admission case workbench.
                  </p>
                </div>
                <Link
                  href="/dashboard/admissions"
                  className="rounded-lg border px-3 py-1.5 text-sm font-medium"
                >
                  Close form
                </Link>
              </div>
              <StaffAdmissionIntakeForm data={data} />
            </div>
          )}

          {startMode === "enquiry" && (
            <div
              id="from-prospect"
              className="scroll-mt-24 space-y-3 rounded-xl border border-primary/30 bg-card p-4 sm:p-5"
            >
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <p className="text-xs font-bold uppercase tracking-[0.16em] text-muted-foreground">
                    Enquiry conversion
                  </p>
                  <h3 className="mt-1 text-lg font-semibold">
                    Create a draft from an existing Enquiry
                  </h3>
                  <p className="mt-1 text-sm text-muted-foreground">
                    Select the Prospect, programme offering and batch. The case
                    opens after the draft is created.
                  </p>
                </div>
                <Link
                  href="/dashboard/admissions"
                  className="rounded-lg border px-3 py-1.5 text-sm font-medium"
                >
                  Close form
                </Link>
              </div>
              {preselected && (
                <p className="rounded-lg border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-950 dark:border-blue-900 dark:bg-blue-950/30 dark:text-blue-100">
                  Starting from{" "}
                  <strong>
                    {preselected.number} · {preselected.name}
                  </strong>
                  . Confirm the correct offering and batch before creating the
                  draft.
                </p>
              )}
              {!data.prospects.length && (
                <p className="rounded-lg border border-amber-300 bg-amber-50 px-4 py-3 text-sm text-amber-950 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-100">
                  No open enquiries are available. Use staff intake for a new
                  applicant, or continue work in CRM first.
                </p>
              )}
              <AdmissionCommandForm
                action="CREATE"
                data={data}
                defaultProspectId={defaultProspectId}
                label="Create admission draft"
                description="Student and guardian identity are inherited from the Prospect. The selected offering and batch are revalidated before the draft is created."
              />
            </div>
          )}

          {!startMode && (
            <p className="text-sm text-muted-foreground">
              Select a card above to open the matching form on this page.
            </p>
          )}
        </section>
      )}
      <section id="case-register" className="space-y-4">
        <div className="flex flex-wrap items-end justify-between gap-3">
          <div>
            <h2 className="text-xl font-semibold">Admission cases</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              Scan the register, then open one case to finish its next step.
            </p>
          </div>
          <p className="text-sm text-muted-foreground">
            {data.cases.length} total
          </p>
        </div>
        <nav aria-label="Admission case views" className="flex flex-wrap gap-2">
          {(Object.keys(caseGroups) as (keyof typeof caseGroups)[]).map(
            (key) => {
              const count = data.cases.filter((item) =>
                caseGroups[key].matches(item.status),
              ).length;
              return (
                <Link
                  key={key}
                  href={`/dashboard/admissions?view=${key}#case-register`}
                  aria-current={selectedView === key ? "page" : undefined}
                  className={`rounded-xl border px-4 py-2 text-sm font-medium transition hover:border-primary/60 ${selectedView === key ? "border-primary bg-primary/10 text-primary" : "bg-card"}`}
                >
                  {caseGroups[key].label}{" "}
                  <span className="ml-1 text-xs opacity-70">({count})</span>
                </Link>
              );
            },
          )}
        </nav>
        <p className="text-sm text-muted-foreground">
          {caseGroups[selectedView].description}
        </p>
        {visibleCases.length ? (
          <div className="overflow-x-auto rounded-2xl border bg-card">
            <table className="w-full min-w-[720px] text-left text-sm">
              <thead className="border-b bg-muted/40 text-xs uppercase tracking-wide text-muted-foreground">
                <tr>
                  <th scope="col" className="px-4 py-3 font-semibold">
                    Admission / Student
                  </th>
                  <th scope="col" className="px-4 py-3 font-semibold">
                    Programme and batch
                  </th>
                  <th scope="col" className="px-4 py-3 font-semibold">
                    Status
                  </th>
                  <th scope="col" className="px-4 py-3 font-semibold">
                    Next step
                  </th>
                  <th
                    scope="col"
                    className="px-4 py-3 text-right font-semibold"
                  >
                    Action
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {visibleCases.map((item) => {
                  const batch = data.batches.find(
                    (row) => row.id === item.batchId,
                  );
                  return (
                    <tr key={item.id} className="hover:bg-muted/30">
                      <td className="px-4 py-3">
                        <Link
                          href={`/dashboard/admissions/${item.id}`}
                          className="font-semibold text-foreground hover:underline"
                        >
                          {item.number} · {item.name}
                        </Link>
                        <span className="mt-1 block text-xs text-muted-foreground">
                          {item.studentNo ?? item.mobile}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <span className="block">
                          {batch?.offeringName ?? "Programme unavailable"}
                        </span>
                        <span className="block text-xs text-muted-foreground">
                          {batch?.name ?? "Batch unavailable"}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge value={item.status} />
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {nextCaseStep(item.status)}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <Link
                          href={`/dashboard/admissions/${item.id}`}
                          className="inline-flex min-h-9 items-center rounded-lg border px-3 font-medium hover:bg-muted"
                        >
                          {selectedView === "open" ? "Continue" : "Open"}
                        </Link>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="rounded-xl border border-dashed p-6 text-sm text-muted-foreground">
            {selectedView === "open"
              ? "No admissions need action. Start a new admission above."
              : selectedView === "completed"
                ? "No enrolled admissions yet."
                : "No closed admissions."}
          </p>
        )}
      </section>
    </div>
  );
}
