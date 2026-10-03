import Link from "next/link";
import { ArrowRight, CircleCheck, ExternalLink, LockKeyhole } from "lucide-react";
import { PageHeader } from "@/components/erp/page-header";
import { requirePermission } from "@/modules/platform/auth/erp-context";

type Step = {
  title: string;
  do: string;
  check: string;
  href: string;
  page: string;
  permission: string;
};

const setup: Step[] = [
  {
    title: "Set up the academy directory",
    do: "In Manage CRM, check the academic years, branch, classes and groups, subjects taught, programme definitions, schools and public form choices. Add missing entries and deactivate outdated choices instead of deleting historical data.",
    check: "The year, class, subject and programme you need can be selected in the ERP forms. More than one academic year may be active while preparing a future intake.",
    href: "/dashboard/crm/manage", page: "Manage CRM", permission: "system.master_data.manage",
  },
  {
    title: "Review the operating rules and staff access",
    do: "In Settings and Business Rules, review staff roles, admission activation, capacity, billing and compensation policies. Give a second authorized staff member approval permissions; requesters cannot approve their own financial actions.",
    check: "The intended operator and independent approver can each open their assigned workspaces.",
    href: "/dashboard/settings", page: "Settings", permission: "system.settings.view",
  },
  {
    title: "Create a programme offering",
    do: "Choose the academic year, branch, class or group and programme. Complete eligibility, subjects, public card content, application dates and requirements. A new offering begins as Draft.",
    check: "The offering is listed with the correct class, branch and year.",
    href: "/dashboard/academics/offerings", page: "Programme Offerings", permission: "academics.view",
  },
  {
    title: "Publish standard fees and open the website card",
    do: "Publish the offering’s Fee Plan with tuition, one-time charges, cycle and effective date. This activates the offering. Then use the offering's Website & application controls to make it visible and open applications when ready.",
    check: "The offering is Active, the Fee Plan is published, and its public card shows the correct fees and application state.",
    href: "/dashboard/finance/fee-plans", page: "Fee Plans", permission: "finance.view",
  },
  {
    title: "Create a batch with seats",
    do: "Use the batch register to review cohorts or create a batch under the active offering. Edit a batch name, code or capacity there; its offering, year, class and branch stay fixed. Timetable days and hours are managed in Academic Operations. Batch occupancy is checked again when enrollment activates.",
    check: "The batch appears in the register and becomes a placement choice with available seats.",
    href: "/dashboard/academics/batches", page: "Batches", permission: "academics.view",
  },
];

const admission: Step[] = [
  {
    title: "Choose the right intake path",
    do: "In Admissions, either enter a new applicant with the student/guardian, continue a Prospect already in CRM, or print a blank A4 form for the family. The new-applicant entry creates the Prospect and draft together. Applicants do not need an account or login.",
    check: "The case is linked to one Prospect. For paper applications, staff enter the verified details online after collecting the form.",
    href: "/dashboard/admissions", page: "Admissions", permission: "admissions.create",
  },
  {
    title: "Confirm programme and batch placement",
    do: "Choose an active Programme Offering and an available batch. The year, branch and class are shown with the offering. If an older Prospect has no class, choose its recorded offering or confirm an offering; the class is then completed from that choice.",
    check: "The case shows Draft, the intended batch and the effective published Fee Plan version. Full batches and mismatched classes are rejected again by the database.",
    href: "/dashboard/admissions", page: "Admissions", permission: "admissions.view",
  },
  {
    title: "Record the admission source",
    do: "Ask who referred the student. In the case's Admission source and referral section, select an existing person or staff member. If the person is missing, register their verified name, 11-digit mobile and relationship there. If no one referred the student, choose Organic. Save before accepting.",
    check: "The case has a saved Referred or Organic choice. Staff referrals feed teacher compensation; external rewards need later approval after tuition collection.",
    href: "/dashboard/admissions", page: "Admissions · Referral", permission: "admissions.view",
  },
  {
    title: "Print and receive signed consent",
    do: "Open Print Consent Form on the admission case. Explain the programme and pinned charges to the guardian, obtain the guardian signature and student acknowledgment when appropriate, then record the signed document in Signed consent evidence.",
    check: "The signed document can be opened from the case. A new case cannot be accepted until its signed consent receipt is recorded.",
    href: "/dashboard/admissions", page: "Admissions · Consent", permission: "admissions.view",
  },
  {
    title: "Review and accept",
    do: "Mark the draft Ready after checking identity, batch, referral choice, fees and consent. Then Accept Admission. If the Fee Plan changed, refresh standard fees and review the draft again before acceptance.",
    check: "The case shows Accepted and a permanent student identity. Acceptance does not mean tuition has been paid or enrollment is active.",
    href: "/dashboard/admissions", page: "Admissions · Review", permission: "admissions.view",
  },
  {
    title: "Post the initial invoice",
    do: "Use Post Initial Billing on the accepted case. The invoice includes the pinned first billing cycle and any one-time charges. Review its due date and total with the guardian.",
    check: "The case shows Billing Posted and an invoice. The invoice is a charge, not proof of payment.",
    href: "/dashboard/admissions", page: "Admissions · Billing", permission: "admissions.view",
  },
  {
    title: "Record money actually received",
    do: "If money is received, use Post Actual Payment on the case or Student Accounts in Billing & Adjustments. Enter only the amount received and choose the real payment method. Keep the permanent receipt; never post a payment for a promise to pay.",
    check: "A receipt and allocation appear, and the outstanding balance changes. Posting payment does not activate enrollment automatically.",
    href: "/dashboard/finance/billing", page: "Billing & Adjustments", permission: "finance.view",
  },
  {
    title: "Evaluate enrollment activation",
    do: "Return to the case and choose Evaluate Enrollment Activation. The pinned policy checks acceptance, initial billing, required payment and seat capacity. If Pending Payment remains, collect the required amount and run activation again.",
    check: "Active Enrollment appears on the case and the student is visible in the active Student register. Any permitted credit balance remains due.",
    href: "/dashboard/admissions", page: "Admissions · Activate", permission: "admissions.view",
  },
  {
    title: "Continue the student journey",
    do: "Open the Student register and batch. Record classes, attendance, homework and assessments in the academic workspaces. For future fee cycles, preview and post recurring billing, then record each actual payment separately.",
    check: "The student is assigned to the intended batch; teaching records and later invoices refer to that student.",
    href: "/dashboard/students", page: "Students", permission: "students.view",
  },
];

function StepList({ steps, permissions, start }: { steps: Step[]; permissions: string[]; start: number }) {
  return <ol className="space-y-3">
    {steps.map((step, index) => <li key={step.title} className="rounded-2xl border bg-card p-5 sm:p-6">
      <div className="flex items-start gap-4">
        <span aria-hidden="true" className="flex size-9 shrink-0 items-center justify-center rounded-full bg-primary/10 text-sm font-bold text-primary">{start + index}</span>
        <div className="min-w-0 flex-1">
          <h3 className="font-semibold">{step.title}</h3>
          <p className="mt-2 text-sm leading-6 text-foreground/85">{step.do}</p>
          <p className="mt-3 flex items-start gap-2 rounded-lg bg-muted/60 px-3 py-2 text-sm"><CircleCheck className="mt-0.5 size-4 shrink-0 text-primary" aria-hidden="true"/><span><strong>Check:</strong> {step.check}</span></p>
          {permissions.includes(step.permission)
            ? <Link href={step.href} className="mt-4 inline-flex min-h-10 items-center gap-2 text-sm font-semibold text-primary underline-offset-4 hover:underline">Open {step.page}<ArrowRight className="size-4" aria-hidden="true"/></Link>
            : <p className="mt-4 inline-flex items-center gap-2 text-xs text-muted-foreground"><LockKeyhole className="size-4" aria-hidden="true"/>Ask an authorized colleague to complete this step in {step.page}.</p>}
        </div>
      </div>
    </li>)}
  </ol>;
}

export default async function HelpPage() {
  const context = await requirePermission("dashboard.view");
  return <div className="space-y-8 pb-12">
    <PageHeader eyebrow="Getting Started" title="Help & Workflows" description="Follow the academy setup once, then use the admission walkthrough for each student. Links open the exact ERP workspaces used in the steps." />
    <nav aria-label="Help sections" className="flex flex-wrap gap-2 text-sm">
      {[["#setup","Start from zero"],["#student","Student admission"],["#example","Worked example"],["#after","After admission"],["#problems","If something blocks you"]].map(([href,label])=><a key={href} href={href} className="rounded-full border bg-card px-4 py-2 font-medium hover:bg-muted">{label}</a>)}
    </nav>
    <section className="rounded-2xl border border-primary/20 bg-primary/5 p-5 sm:p-6">
      <h2 className="text-lg font-semibold">A student is here right now</h2>
      <p className="mt-2 text-sm leading-6">Open <Link className="font-semibold underline" href="/dashboard/admissions">Admissions</Link> and choose one of three starts: enter a new applicant online with staff, continue a Prospect already in CRM, or print a blank form for a family to complete. Then verify placement, record referral or Organic, attach signed consent, accept, bill, record actual payment and evaluate activation.</p>
      <a className="mt-3 inline-flex items-center gap-2 text-sm font-semibold text-primary hover:underline" href="#student">Follow the admission steps <ArrowRight className="size-4" aria-hidden="true"/></a>
    </section>
    <section id="setup" className="scroll-mt-24 space-y-4"><div><p className="text-xs font-semibold uppercase tracking-widest text-primary">Before taking applications</p><h2 className="mt-1 text-2xl font-bold">Start from zero</h2><p className="mt-2 text-sm text-muted-foreground">Do these setup steps once per programme, year or branch as needed.</p></div><StepList steps={setup} permissions={context.permissions} start={1}/></section>
    <section id="student" className="scroll-mt-24 space-y-4"><div><p className="text-xs font-semibold uppercase tracking-widest text-primary">Repeat for each student</p><h2 className="mt-1 text-2xl font-bold">Walk-in or online student: start to finish</h2><p className="mt-2 text-sm text-muted-foreground">The applicant does not create an ERP account. Staff verify the application and perform the controlled admission steps.</p></div><StepList steps={admission} permissions={context.permissions} start={1}/></section>
    <section id="example" className="scroll-mt-24 rounded-2xl border bg-card p-5 sm:p-6"><h2 className="text-xl font-bold">Worked example</h2><p className="mt-2 text-sm text-muted-foreground">Illustrative names and amounts only; always use the published Fee Plan and real receipt.</p>
      <div className="mt-4 grid gap-3 md:grid-cols-2">
        <p className="rounded-xl bg-muted/60 p-4 text-sm leading-6"><strong>1. Enquiry and placement.</strong> A guardian brings student Ayesha, who wants the active Class 10 offering. Search Prospects, verify her record, select a Class 10 batch, and create Draft.</p>
        <p className="rounded-xl bg-muted/60 p-4 text-sm leading-6"><strong>2. Referral and consent.</strong> The guardian names neighbour Salma as the referrer. Search the referrer list. If absent, register Salma with verified name, mobile and relationship. Print the case, obtain the guardian signature and record the signed form.</p>
        <p className="rounded-xl bg-muted/60 p-4 text-sm leading-6"><strong>3. Accept and invoice.</strong> Mark Ready, Accept, then Post Initial Billing. For illustration, BDT 2,500 tuition plus BDT 100 one-time charge produces a BDT 2,600 invoice. The fee plan, not this example, determines actual charges.</p>
        <p className="rounded-xl bg-muted/60 p-4 text-sm leading-6"><strong>4. Payment and activation.</strong> If BDT 2,600 is actually received, post that amount and keep its receipt. Evaluate activation. If the academy policy permits credit enrollment, activation can also succeed with a balance still due; check the case result.</p>
      </div><p className="mt-4 rounded-lg border border-amber-300 bg-amber-50 p-3 text-sm text-amber-950 dark:bg-amber-950/20 dark:text-amber-100"><strong>Referral reward:</strong> Salma does not receive money at admission. After qualifying tuition is collected, an authorized operator requests the reward in Accounting & Settlements, a different staff member approves it, and finance records the actual payout. A referred teacher uses the teacher compensation run instead.</p>
    </section>
    <section id="after" className="scroll-mt-24 space-y-4"><h2 className="text-2xl font-bold">After admission</h2><div className="grid gap-3 md:grid-cols-2">
      <Further title="Monthly fees and receipts" body="Preview and post each recurring cycle, inspect the student account and record actual payments against invoices." href="/dashboard/finance/billing" label="Billing & Adjustments" allowed={context.permissions.includes("finance.view")}/>
      <Further title="Discounts, cancellations and refunds" body="Submit the relevant request, obtain an independent approval, then post the resulting credit or actual refund payout. Keep the original invoice and receipt history." href="/dashboard/finance/billing" label="Billing & Adjustments" allowed={context.permissions.includes("finance.view")}/>
      <Further title="Teacher and external referral compensation" body="Use monthly compensation for teacher earnings. External referral rewards, advances, payables, expenses and reconciliations live in accounting and need their own approval where shown." href="/dashboard/finance/accounting" label="Accounting & Settlements" allowed={context.permissions.includes("accounting.view")}/>
      <Further title="Teaching and follow-up" body="Use My Classes, Academic Operations and Assessments to record sessions, attendance, homework and learning results for enrolled students." href="/dashboard/academics/operations" label="Academic Operations" allowed={context.permissions.includes("academics.view")}/>
    </div></section>
    <section id="problems" className="scroll-mt-24 rounded-2xl border bg-card p-5 sm:p-6"><h2 className="text-xl font-bold">If something blocks you</h2><dl className="mt-4 space-y-4 text-sm leading-6">
      <div><dt className="font-semibold">An offering is Draft or missing on the website</dt><dd className="text-muted-foreground">Publish its effective Fee Plan, then review website visibility, application dates and accepting-applications controls. Check the organisation’s local date.</dd></div>
      <div><dt className="font-semibold">You cannot create an admission or choose a batch</dt><dd className="text-muted-foreground">Verify the Prospect is open, choose the intended active offering, and check that the batch belongs to it, has room and an effective published Fee Plan. A Prospect missing class data can be placed through the offering the applicant confirmed.</dd></div>
      <div><dt className="font-semibold">Accept Admission is rejected</dt><dd className="text-muted-foreground">Check the signed consent evidence, referral or Organic choice, identity, batch, and Fee Plan version. If terms changed, refresh fees and review again.</dd></div>
      <div><dt className="font-semibold">Payment is posted but the student is not active</dt><dd className="text-muted-foreground">Return to the admission case and run Evaluate Enrollment Activation. Read its status for a payment, policy or seat issue.</dd></div>
      <div><dt className="font-semibold">A button or workspace is unavailable</dt><dd className="text-muted-foreground">Your ERP role may lack that permission. Ask the administrator for the specific task; financial approval must be completed by another authorized person.</dd></div>
    </dl><p className="mt-5 text-xs text-muted-foreground">Keep the <Link href="/dashboard/governance/audit" className="underline">Audit Trail</Link> and approval history when correcting errors. The ERP keeps financial history rather than silently removing it.</p></section>
    <a href="/interest" target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-2 text-sm text-primary underline-offset-4 hover:underline">Open the public interest form <ExternalLink className="size-4" aria-hidden="true"/></a>
  </div>;
}
function Further({title,body,href,label,allowed}:{title:string;body:string;href:string;label:string;allowed:boolean}){
 return <article className="rounded-xl border bg-card p-5"><h3 className="font-semibold">{title}</h3><p className="mt-2 text-sm leading-6 text-muted-foreground">{body}</p>{allowed?<Link href={href} className="mt-3 inline-flex items-center gap-2 text-sm font-semibold text-primary hover:underline">Open {label}<ArrowRight className="size-4" aria-hidden="true"/></Link>:<p className="mt-3 text-xs text-muted-foreground">Ask an authorized colleague to open {label}.</p>}</article>;
}
