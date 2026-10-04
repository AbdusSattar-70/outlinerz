import { PGlite } from "@electric-sql/pglite";
import { readFile, readdir } from "node:fs/promises";
const db = new PGlite();
await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
create schema auth; create table auth.users(id uuid primary key,email text);
create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
grant usage on schema auth to anon,authenticated,service_role; grant execute on function auth.uid() to anon,authenticated,service_role;
create schema storage; create table storage.buckets(id text primary key,name text,public boolean);
create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text); alter table storage.objects enable row level security;
grant usage on schema storage to authenticated; grant select,insert,update,delete on storage.objects to authenticated;`);
await db.exec(
  "alter default privileges in schema public grant all on tables to anon,authenticated;",
);
const migrationDir = new URL("../../supabase/migrations/", import.meta.url);
const files = (await readdir(migrationDir))
  .filter((n) => n.endsWith(".sql"))
  .sort();
const sql = await readFile(new URL(files[0], migrationDir), "utf8");
for (const file of files)
  await db.exec(await readFile(new URL(file, migrationDir), "utf8"));
console.log("PASS: fresh baseline applies");
const q = async (s, p = []) => (await db.query(s, p)).rows;
let passed = 0;
async function assert(s, label) {
  if (!s) throw Error(label);
  passed++;
  console.log("PASS: " + label);
}
async function reject(fn, label) {
  let failed = false;
  try {
    await fn();
  } catch {
    failed = true;
  }
  await assert(failed, label);
}
const owner = "11111111-1111-4111-8111-111111111111",
  outsider = "22222222-2222-4222-8222-222222222222",
  teacher = "33333333-3333-4333-8333-333333333333";
await db.exec(
  `insert into auth.users values('${owner}','owner@example.test'),('${outsider}','outsider@example.test'),('${teacher}','teacher@example.test');`,
);
async function as(user, role = "authenticated") {
  await db.exec("reset role");
  await q("select set_config('request.jwt.claim.sub',$1,false)", [user]);
  await db.exec("set role " + role);
}
await as(owner);
const onboardingRequest = crypto.randomUUID();
const onboard = (
  await q("select public.onboard_organization($1,$2,$3,$4) result", [
    onboardingRequest,
    "First Institute",
    "first-institute",
    "Central",
  ])
)[0].result;
const onboardRetry = (
  await q("select public.onboard_organization($1,$2,$3,$4) result", [
    onboardingRequest,
    "First Institute",
    "first-institute",
    "Central",
  ])
)[0].result;
await assert(
  onboard.organization_id === onboardRetry.organization_id,
  "owner onboarding retry preserves one organization",
);
await assert(
  (
    await q(
      "select count(*)::int n from public.branches where organization_id=$1",
      [onboard.organization_id],
    )
  )[0].n === 1,
  "owner onboarding creates first branch atomically",
);
await assert(
  (
    await q(
      "select role from public.memberships where organization_id=$1 and user_id=$2",
      [onboard.organization_id, owner],
    )
  )[0].role === "OWNER",
  "founder receives only new organization ownership",
);
await reject(
  () =>
    q("select public.onboard_organization($1,$2,$3,$4)", [
      onboardingRequest,
      "Changed",
      "first-institute",
      "Central",
    ]),
  "onboarding request input changes rejected",
);
await reject(
  () =>
    q("select public.onboard_organization($1,$2,$3,$4)", [
      crypto.randomUUID(),
      "Second",
      "first-institute",
      "Other",
    ]),
  "existing slug cannot be taken over",
);
await as(outsider);
await assert(
  (
    await q("select * from public.memberships where organization_id=$1", [
      onboard.organization_id,
    ])
  ).length === 0,
  "organization picker cannot see outsider memberships",
);
await as(owner);
const org = (
  await q(
    "select public.create_organization('Alpha Tuition','alpha-tuition') id",
  )
)[0].id;
await reject(
  () => q("select public.set_member($1,$2,'TEACHER',true)", [org, owner]),
  "last owner protected",
);
const ins = async (table, cols, values) =>
  (
    await q(
      `insert into public.${table}(organization_id,${cols}) values($1,${values.map((_, i) => "$" + (i + 2)).join(",")}) returning id`,
      [org, ...values],
    )
  )[0].id;
const branch = await ins("branches", "name,code", ["Main", "MAIN"]);
const year = await ins("academic_years", "name,starts_on,ends_on", [
  "2026",
  "2026-01-01",
  "2026-12-31",
]);
const cl = await ins("class_levels", "name", ["8"]);
const subject = await ins("subjects", "name", ["Math"]);
const subject2 = await ins("subjects", "name", ["English"]);
const account = await ins("money_accounts", "name,kind", ["Counter", "CASH"]);
const bank = await ins("money_accounts", "name,kind", ["Bank", "BANK"]);
const person = await ins("people", "name,kind,user_id", [
  "Karim",
  "TEACHER",
  teacher,
]);
await q("select public.set_member($1,$2,'TEACHER',true)", [org, teacher]);
const req = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const courseData = {
  programme_name: "Math coaching",
  name: "Class 8 Math",
  code: "8M26",
  branch_id: branch,
  academic_year_id: year,
  class_level_id: cl,
  subject_ids: [subject],
  fee_amount: 1500,
  fee_frequency: "MONTHLY",
  effective_on: "2026-01-01",
  batch_name: "Evening",
  capacity: 2,
  teacher_id: person,
  intake_open: true,
  public_visible: true,
};
const course = (
  await q("select public.create_course($1,$2,$3) result", [
    org,
    req,
    courseData,
  ])
)[0].result;
const retry = (
  await q("select public.create_course($1,$2,$3) result", [
    org,
    req,
    courseData,
  ])
)[0].result;
await assert(
  course.offering_id === retry.offering_id,
  "course stable retry creates one offering",
);
await reject(
  () =>
    q("select public.create_course($1,$2,$3)", [
      org,
      req,
      { ...courseData, name: "Changed" },
    ]),
  "changed retry rejected",
);
await reject(
  () =>
    q("select public.create_course($1,$2,$3)", [
      org,
      crypto.randomUUID(),
      {
        ...courseData,
        programme_name: "No subjects",
        code: "EMPTY",
        subject_ids: null,
      },
    ]),
  "missing subject list rejected",
);
const failData = {
  ...courseData,
  programme_name: "Bad course",
  code: "BAD",
  name: "Bad course",
  subject_ids: [crypto.randomUUID()],
};
await reject(
  () =>
    q("select public.create_course($1,$2,$3)", [
      org,
      crypto.randomUUID(),
      failData,
    ]),
  "invalid course rolls back all parts",
);
await assert(
  (
    await q(
      "select count(*)::int n from public.programmes where name='Bad course'",
    )
  )[0].n === 0,
  "no orphan programme after failed course",
);
const studentData = {
  batch_id: course.batch_id,
  student_name: "Rahim",
  guardian_name: "Parent",
  guardian_phone: "01700000000",
  admitted_on: "2026-10-04",
};
const admission = (
  await q("select public.admit_student($1,$2,$3) result", [
    org,
    crypto.randomUUID(),
    studentData,
  ])
)[0].result;
const admission2 = (
  await q("select public.admit_student($1,$2,$3) result", [
    org,
    crypto.randomUUID(),
    { ...studentData, student_name: "Sibling" },
  ])
)[0].result;
await assert(
  admission.student_id !== admission2.student_id,
  "shared guardian phone does not merge siblings",
);
await reject(
  () =>
    q("select public.admit_student($1,$2,$3)", [
      org,
      crypto.randomUUID(),
      studentData,
    ]),
  "capacity limit enforced",
);
await assert(
  (await q("select count(*)::int n from public.students"))[0].n === 2,
  "failed full-batch admission creates no student",
);
await assert(
  (await q("select count(*)::int n from public.journals"))[0].n === 0,
  "admissions complete without accounting",
);
const payReq = crypto.randomUUID();
const payment = (
  await q("select public.collect_payment($1,$2,$3,$4,1000,$5,null) result", [
    org,
    payReq,
    admission.invoice_id,
    account,
    "2026-10-04",
  ])
)[0].result;
await q("select public.collect_payment($1,$2,$3,$4,1000,$5,null)", [
  org,
  payReq,
  admission.invoice_id,
  account,
  "2026-10-04",
]);
await assert(
  Number(payment.remaining_due) === 500,
  "partial collection calculates due",
);
await assert(
  (await q("select count(*)::int n from public.payments"))[0].n === 1,
  "payment retry does not duplicate receipt",
);
await reject(
  () =>
    q("select public.collect_payment($1,$2,$3,$4,600,$5,null)", [
      org,
      crypto.randomUUID(),
      admission.invoice_id,
      account,
      "2026-10-04",
    ]),
  "overpayment rejected",
);
const alloc = (
  await q("select id from public.payment_allocations where payment_id=$1", [
    payment.payment_id,
  ])
)[0].id;
await q("select public.refund_payment($1,$2,$3,$4,200,$5,$6)", [
  org,
  crypto.randomUUID(),
  alloc,
  account,
  "2026-10-04",
  "Test refund",
]);
await reject(
  () =>
    q("select public.refund_payment($1,$2,$3,$4,900,$5,$6)", [
      org,
      crypto.randomUUID(),
      alloc,
      account,
      "2026-10-04",
      "Too much",
    ]),
  "over-refund rejected",
);
await q("select public.credit_invoice($1,$2,$3,100,$4,$5)", [
  org,
  crypto.randomUUID(),
  admission.invoice_id,
  "DISCOUNT",
  "Approved",
]);
await reject(
  () =>
    q("select public.record_expense($1,$2,$3,$4,$5,$6,$7,null)", [
      org,
      crypto.randomUUID(),
      account,
      "NaN",
      "2026-10-04",
      "BAD",
      "Invalid",
    ]),
  "non-finite money rejected",
);
await q("select public.record_expense($1,$2,$3,100,$4,$5,$6,null)", [
  org,
  crypto.randomUUID(),
  account,
  "2026-10-04",
  "PRINTING",
  "Paper",
]);
await q("select public.transfer_money($1,$2,$3,$4,100,$5)", [
  org,
  crypto.randomUUID(),
  account,
  bank,
  "2026-10-04",
]);
await assert(
  Number(
    (
      await q(
        "select sum(signed_amount) n from public.money_movements where source_type='TRANSFER'",
      )
    )[0].n,
  ) === 0,
  "transfer has balanced operational legs",
);
const payable = (
  await q("select public.record_payable($1,$2,$3,500,$4,$5,null,$6) result", [
    org,
    crypto.randomUUID(),
    person,
    "2026-10-04",
    "Accepted work",
    "MANUAL",
  ])
)[0].result;
await q("select public.settle_payable($1,$2,$3,$4,100,$5)", [
  org,
  crypto.randomUUID(),
  payable.payable_id,
  account,
  "2026-10-04",
]);
await reject(
  () =>
    q("select public.settle_payable($1,$2,$3,$4,500,$5)", [
      org,
      crypto.randomUUID(),
      payable.payable_id,
      account,
      "2026-10-04",
    ]),
  "over-settlement rejected",
);
const adv = (
  await q("select public.give_advance($1,$2,$3,$4,100,$5,$6) result", [
    org,
    crypto.randomUUID(),
    person,
    account,
    "2026-10-04",
    "Staff advance",
  ])
)[0].result;
const cashBefore = Number(
  (await q("select sum(signed_amount) n from public.money_movements"))[0].n,
);
await q("select public.clear_advance($1,$2,$3,100,$4,$5,null)", [
  org,
  crypto.randomUUID(),
  adv.advance_id,
  "2026-10-04",
  payable.payable_id,
]);
await assert(
  Number(
    (await q("select sum(signed_amount) n from public.money_movements"))[0].n,
  ) === cashBefore,
  "advance offset creates no duplicate outflow",
);
await reject(
  () =>
    q("update public.payments set amount=1 where id=$1", [payment.payment_id]),
  "client cannot rewrite posted payment",
);
const purchase = await ins(
  "purchases",
  "description,amount,purchased_on,classification",
  ["Fans", 12000, "2026-10-04", "ASSET"],
);
const pur = (
  await q("select public.receive_purchase($1,$2,$3,$4) result", [
    org,
    crypto.randomUUID(),
    purchase,
    "2026-10-04",
  ])
)[0].result;
await assert(Boolean(pur.payable_id), "received purchase creates liability");
await ins("assets", "purchase_id,branch_id,code,name,cost,acquired_on", [
  purchase,
  branch,
  "FAN-1",
  "Fan",
  6000,
  "2026-10-04",
]);
await reject(
  () =>
    ins("assets", "purchase_id,branch_id,code,name,cost,acquired_on", [
      purchase,
      branch,
      "FAN-2",
      "Fan",
      7000,
      "2026-10-04",
    ]),
  "asset allocation cannot exceed purchase",
);
await reject(
  () => q("update public.purchases set amount=1 where id=$1", [purchase]),
  "received purchase immutable",
);
const topic = await ins("topics", "subject_id,class_level_id,chapter,title", [
  subject,
  cl,
  "Algebra",
  "1.1",
]);
const session = await ins(
  "sessions",
  "batch_id,subject_id,teacher_id,starts_at,ends_at",
  [
    course.batch_id,
    subject,
    person,
    "2026-10-04T11:00:00Z",
    "2026-10-04T12:00:00Z",
  ],
);
await reject(
  () =>
    ins("sessions", "batch_id,subject_id,teacher_id,starts_at,ends_at", [
      course.batch_id,
      subject2,
      person,
      "2026-10-04T13:00:00Z",
      "2026-10-04T14:00:00Z",
    ]),
  "session subject must be offered",
);
const assessment = await ins(
  "assessments",
  "batch_id,subject_id,kind,name,scheduled_on",
  [course.batch_id, subject, "WEEKLY", "Weekly 1", "2026-10-04"],
);
const item = await ins(
  "assessment_items",
  "assessment_id,topic_id,position,marks,question_snapshot",
  [assessment, topic, 1, 10, "Q1"],
);
const result = await ins("assessment_results", "assessment_id,enrollment_id", [
  assessment,
  admission.enrollment_id,
]);
await reject(
  () => ins("marks", "result_id,item_id,earned", [result, item, 11]),
  "marks cannot exceed item maximum",
);
await ins("marks", "result_id,item_id,earned", [result, item, 8]);
await reject(
  () =>
    q("update public.assessment_results set absent=true where id=$1", [result]),
  "marked result cannot be converted to absent",
);
await reject(
  () => q("update public.assessment_items set marks=7 where id=$1", [item]),
  "maximum cannot be reduced below recorded score",
);
await q("select public.set_module($1,'CRM',false)", [org]);
await reject(
  () => ins("prospects", "student_name,phone", ["Test", "017"]),
  "disabled module rejects direct client writes",
);
await q("select public.set_module($1,'CRM',true)", [org]);
await as(teacher);
await assert(
  (
    await q("select * from public.teacher_sessions($1,$2,$3)", [
      org,
      "2026-10-01T00:00:00Z",
      "2026-10-10T00:00:00Z",
    ])
  ).length === 1,
  "teacher reads assigned sessions",
);
await assert(
  (await q("select * from public.payments")).length === 0,
  "teacher cannot read finance",
);
await q("select public.complete_session($1,$2,$3,$4)", [
  org,
  crypto.randomUUID(),
  session,
  {
    attendance: [{ enrollment_id: admission.enrollment_id, status: "PRESENT" }],
    topics: [{ topic_id: topic, coverage_percent: 80 }],
    notes: "Covered 80%",
  },
]);
await assert(
  (
    await q("select * from public.teacher_sessions($1,$2,$3)", [
      org,
      "2026-10-01T00:00:00Z",
      "2026-10-10T00:00:00Z",
    ])
  )[0].status === "COMPLETED",
  "assigned teacher completes lesson without payroll setup",
);
await as(outsider);
const otherOrg = (
  await q("select public.create_organization('Beta Tuition','beta-tuition') id")
)[0].id;
await assert(
  (
    await q(
      "select has_table_privilege(current_user,'public.payments','UPDATE') allowed",
    )
  )[0].allowed === false,
  "implicit hosted financial update grants revoked",
);
await assert(
  (await q("select * from public.invoices")).length === 0,
  "other tenant sees no invoices",
);
await reject(
  () =>
    q("select public.collect_payment($1,$2,$3,$4,1,$5,null)", [
      org,
      crypto.randomUUID(),
      admission.invoice_id,
      account,
      "2026-10-04",
    ]),
  "cross-tenant RPC denied",
);
await reject(
  () =>
    q(
      "insert into public.batches(organization_id,offering_id,name,capacity) values($1,$2,$3,10)",
      [otherOrg, course.offering_id, "Illegal"],
    ),
  "same-tenant foreign keys enforced",
);
await as(owner, "anon");
await assert(
  (await q("select * from public.public_courses($1)", ["alpha-tuition"]))
    .length === 1,
  "anonymous reads only public course projection",
);
await reject(
  () => q("select * from public.students"),
  "anonymous private student access denied",
);
await as(owner);
await q(
  "insert into storage.objects(bucket_id,name) values('eduops-documents',$1)",
  [org + "/receipt.pdf"],
);
await as(outsider);
await assert(
  (await q("select * from storage.objects")).length === 0,
  "private document tenant isolation",
);
await reject(
  () =>
    q(
      "insert into storage.objects(bucket_id,name) values('eduops-documents',$1)",
      [org + "/forged.pdf"],
    ),
  "cross-tenant upload denied",
);
await as(owner);
await q("select public.set_module($1,'ACCOUNTING',true)", [org]);
const ca = await ins("accounting_accounts", "code,name,kind", [
  "1000",
  "Cash",
  "ASSET",
]);
const cr = await ins("accounting_accounts", "code,name,kind", [
  "4000",
  "Tuition",
  "INCOME",
]);
const event = (
  await q(
    "select id from public.outbox_events where event_type='money_movements.created' limit 1",
  )
)[0].id;
await reject(
  () =>
    q("select public.project_journal($1,$2,$3,$4,$5)", [
      org,
      event,
      "2026-10-04",
      "Test",
      [
        { account_id: ca, debit: 100, credit: 0 },
        { account_id: cr, debit: 0, credit: 100 },
      ],
    ]),
  "clients cannot call accounting worker",
);
await as("", "service_role");
await reject(
  () =>
    q("select public.project_journal($1,$2,$3,$4,$5)", [
      org,
      event,
      "2026-10-04",
      "Bad",
      [
        { account_id: ca, debit: 100, credit: 0 },
        { account_id: cr, debit: 0, credit: 99 },
      ],
    ]),
  "unbalanced journal rejected atomically",
);
const lines = [
  { account_id: ca, debit: 100, credit: 0 },
  { account_id: cr, debit: 0, credit: 100 },
];
const journal = (
  await q("select public.project_journal($1,$2,$3,$4,$5) id", [
    org,
    event,
    "2026-10-04",
    "Test",
    lines,
  ])
)[0].id;
await assert(
  (
    await q("select public.project_journal($1,$2,$3,$4,$5) id", [
      org,
      event,
      "2026-10-04",
      "Test",
      lines,
    ])
  )[0].id === journal,
  "accounting event replay idempotent",
);
await reject(
  () =>
    q("update public.journals set description=$1 where id=$2", [
      "Changed",
      journal,
    ]),
  "posted journals immutable even for service",
);
await as(owner);
await q("select public.set_accounting_period($1,$2,true)", [org, "2026-10-01"]);
await q("select public.record_expense($1,$2,$3,10,$4,$5,$6,null)", [
  org,
  crypto.randomUUID(),
  account,
  "2026-10-04",
  "PRINTING",
  "Late expense",
]);
await assert(
  true,
  "closed accounting month does not block operational expense",
);
const late = (
  await q(
    "select id from public.outbox_events where event_type='expenses.created' order by created_at desc limit 1",
  )
)[0].id;
await as("", "service_role");
await reject(
  () =>
    q("select public.project_journal($1,$2,$3,$4,$5)", [
      org,
      late,
      "2026-10-04",
      "Closed",
      lines,
    ]),
  "closed accounting month blocks projection",
);
await db.exec("reset role");
await assert(
  (await q("select count(*)::int n from public.audit_events"))[0].n > 0,
  "audit evidence recorded",
);
// The CRM presentation contract uses only the new tenant schema.
await as(owner);
const masterRequest = crypto.randomUUID();
const masterInput = {
  entity: "school",
  name: "Alpha School",
  isActive: true,
  isVerified: true,
  reason: "Verified school directory",
};
const school = (
  await q("select public.crm_master($1,$2,$3) result", [
    org,
    masterRequest,
    masterInput,
  ])
)[0].result;
await assert(
  (
    await q("select public.crm_master($1,$2,$3) result", [
      org,
      masterRequest,
      masterInput,
    ])
  )[0].result.id === school.id,
  "CRM master retry preserves one directory entry",
);
await reject(
  () =>
    q("select public.crm_master($1,$2,$3)", [
      org,
      masterRequest,
      { ...masterInput, name: "Changed" },
    ]),
  "CRM master changed retry rejected",
);
await q("select public.crm_master($1,$2,$3)", [
  org,
  crypto.randomUUID(),
  {
    entity: "school",
    id: school.id,
    name: "Alpha School Updated",
    isActive: false,
    isVerified: false,
    reason: "Temporarily inactive school",
  },
]);
await assert(
  (await q("select active from public.schools where id=$1", [school.id]))[0]
    .active === false,
  "CRM editor deactivates without deleting history",
);
await as(outsider);
await assert(
  (await q("select * from public.schools where organization_id=$1", [org]))
    .length === 0,
  "CRM directories do not leak across tenants",
);
await reject(
  () =>
    q("select public.crm_master($1,$2,$3)", [
      org,
      crypto.randomUUID(),
      masterInput,
    ]),
  "other tenant cannot mutate CRM master data",
);
await as(teacher);
await reject(
  () =>
    q("select public.crm_master($1,$2,$3)", [
      org,
      crypto.randomUUID(),
      masterInput,
    ]),
  "teacher cannot mutate CRM master data",
);
await as("", "anon");
const catalogue = (
  await q("select public.crm_public_catalogue($1) result", ["alpha-tuition"])
)[0].result;
await assert(
  catalogue.length === 1 && catalogue[0].current_open_seats === 0,
  "CRM public catalogue reports actual occupied capacity",
);
const publishedFee = catalogue[0].fee_plan;
await assert(
  publishedFee === null ||
    publishedFee.components[0].amount === Number(courseData.fee_amount),
  "CRM public catalogue exposes only an effective operational fee",
);
const options = (
  await q("select public.crm_public_options($1) result", ["alpha-tuition"])
)[0].result;
await assert(
  options.classes.some((x) => x.id === cl) &&
    !options.schools.some((x) => x.id === school.id),
  "anonymous options include only active public directory projection",
);
await reject(
  () => q("select * from public.schools"),
  "anonymous directory table access denied",
);
const interestRequest = crypto.randomUUID();
const interestPayload = {
  studentName: "Interested learner",
  guardianName: "Guardian",
  mobile: "01712345678",
  classId: cl,
  offeringId: course.offering_id,
  programIds: [],
  subjectIds: [subject],
  intent: "interest",
  consentToContact: false,
};
const intake = (
  await q("select public.crm_public_interest($1,$2,$3) result", [
    "alpha-tuition",
    interestRequest,
    interestPayload,
  ])
)[0].result;
await assert(
  (
    await q("select public.crm_public_interest($1,$2,$3) result", [
      "alpha-tuition",
      interestRequest,
      interestPayload,
    ])
  )[0].result.prospect_no === intake.prospect_no,
  "public interest stable retry creates one prospect",
);
await reject(
  () =>
    q("select public.crm_public_interest($1,$2,$3)", [
      "beta-tuition",
      crypto.randomUUID(),
      interestPayload,
    ]),
  "public interest rejects academic choices from another tenant",
);
await reject(
  () => q("select * from public.prospects"),
  "public applicants cannot read private prospects",
);
await as(owner);
const lead = (
  await q("select * from public.prospects where phone='01712345678'")
)[0];
await assert(
  lead.application_snapshot.class_label === "8" &&
    lead.application_snapshot.subject_labels[0] === "Math",
  "public preferences preserve verified catalogue labels separately",
);
await assert(
  lead.stage === "NEW",
  "public interest creates no admission and needs no digital consent",
);
await q("select public.crm_assign($1,$2,$3)", [org, lead.id, owner]);
await reject(
  () => q("select public.crm_assign($1,$2,$3)", [org, lead.id, outsider]),
  "cross-tenant CRM assignee rejected",
);
const followupRequest = crypto.randomUUID();
const followupInput = {
  prospect_id: lead.id,
  stage: "INTERESTED",
  followup_type: "CALL",
  note: "Guardian asked for counselling",
  next_follow_up_at: "2026-10-05T10:00:00Z",
};
await q("select public.crm_followup($1,$2,$3)", [
  org,
  followupRequest,
  followupInput,
]);
await q("select public.crm_followup($1,$2,$3)", [
  org,
  followupRequest,
  followupInput,
]);
await assert(
  (
    await q(
      "select count(*)::int n from public.followups where prospect_id=$1",
      [lead.id],
    )
  )[0].n === 2,
  "follow-up retry creates one history entry and one scheduled task",
);
const history = (
  await q(
    "select id from public.followups where prospect_id=$1 and completed_at is not null",
    [lead.id],
  )
)[0].id;
await reject(
  () =>
    q("update public.followups set note=$1 where id=$2", [
      "Rewritten",
      history,
    ]),
  "completed CRM follow-up history cannot be rewritten",
);
await reject(
  () =>
    q("select public.crm_followup($1,$2,$3)", [
      org,
      crypto.randomUUID(),
      { ...followupInput, stage: "LOST", lost_reason: "" },
    ]),
  "lost CRM stage requires a factual reason",
);
await assert(
  (
    await q(
      "select count(*)::int n from public.followups where prospect_id=$1",
      [lead.id],
    )
  )[0].n === 2,
  "failed follow-up rolls back history and stage atomically",
);
await reject(
  () =>
    q("select public.crm_followup($1,$2,$3)", [
      org,
      crypto.randomUUID(),
      { ...followupInput, stage: "ADMITTED" },
    ]),
  "CRM follow-up cannot manufacture an admission",
);
await q("select public.crm_followup($1,$2,$3)", [
  org,
  crypto.randomUUID(),
  { ...followupInput, stage: "CONTACTED" },
]);
await assert(
  (
    await q(
      "select count(*)::int n from public.followups where prospect_id=$1 and completed_at is null",
      [lead.id],
    )
  )[0].n === 1,
  "next follow-up resolves previous pending task without duplicate reminders",
);
await as("", "anon");
for (let n = 0; n < 2; n++)
  await q("select public.crm_public_interest($1,$2,$3)", [
    "alpha-tuition",
    crypto.randomUUID(),
    interestPayload,
  ]);
await reject(
  () =>
    q("select public.crm_public_interest($1,$2,$3)", [
      "alpha-tuition",
      crypto.randomUUID(),
      interestPayload,
    ]),
  "public intake phone rate limit enforced inside database",
);
await as(owner);
await q("select public.set_module($1,'CRM',false)", [org]);
await as("", "anon");
await reject(
  () =>
    q("select public.crm_public_interest($1,$2,$3)", [
      "alpha-tuition",
      crypto.randomUUID(),
      { ...interestPayload, mobile: "01700000000" },
    ]),
  "disabled CRM rejects anonymous intake",
);
await assert(
  (
    await q("select public.crm_public_catalogue($1) result", ["alpha-tuition"])
  )[0].result.length === 0,
  "disabled CRM hides public catalogue",
);
await as(owner);
await assert(
  (await q("select * from public.prospects where id=$1", [lead.id])).length ===
    1,
  "disabled CRM preserves authorized prospect history",
);
await assert(
  (await q("select * from public.schools where id=$1", [school.id])).length ===
    1,
  "disabled CRM preserves authorized directory history",
);
await q("select public.set_module($1,'CRM',true)", [org]);
await db.exec("reset role");

// Editorial settings are private to management; only public fields are projected.
const siteSettings = {
  nameEn: "Changed Academy",
  nameBn: "নতুন একাডেমি",
  logo: "/branding/logo.webp",
  mark: "/branding/mark.webp",
  heroImage: "/images/classroom.webp",
  learningImage: "/images/learning.webp",
  phone: "01234567890",
  email: "hello@example.test",
  addressEn: "Dhaka",
  addressBn: "ঢাকা",
  copy: { text_0: { en: "Edited headline", bn: "পরিবর্তিত শিরোনাম" } },
};
await as(owner);
const siteRequest = "abcdefab-1111-4111-8111-111111111111";
const saved = (
  await q("select public.crm_site_save($1,$2,0,$3) r", [
    org,
    siteRequest,
    siteSettings,
  ])
)[0].r;
await assert(
  saved.revision === 1,
  "CRM management saves first tenant configuration",
);
await assert(
  (
    await q("select public.crm_site_save($1,$2,0,$3) r", [
      org,
      siteRequest,
      siteSettings,
    ])
  )[0].r.revision === 1,
  "site save retry is idempotent",
);
await reject(
  () =>
    q("select public.crm_site_save($1,$2,0,$3)", [
      org,
      "abcdefab-2222-4222-8222-222222222222",
      siteSettings,
    ]),
  "stale site edits cannot overwrite another save",
);
await reject(
  () =>
    q("select public.crm_site_save($1,$2,null,$3)", [
      org,
      "abcdefab-3333-4333-8333-333333333333",
      siteSettings,
    ]),
  "missing revision cannot bypass conflict protection",
);
await reject(
  () =>
    q("select public.crm_site_save($1,$2,1,$3)", [
      org,
      "abcdefab-4444-4444-8444-444444444444",
      { ...siteSettings, logo: "javascript:alert(1)" },
    ]),
  "site assets reject unsafe URL schemes",
);
await assert(
  (await q("select name from public.organizations where id=$1", [org]))[0]
    .name === siteSettings.nameEn,
  "organization name and CRM identity update together",
);
await assert(
  (
    await q(
      "select * from public.audit_events where organization_id=$1 and table_name='crm_sites'",
      [org],
    )
  ).length === 1,
  "site edits retain audit evidence without duplicate retry events",
);
await as(outsider);
await assert(
  (await q("select * from public.crm_sites where organization_id=$1", [org]))
    .length === 0,
  "management settings cannot be read across tenants",
);
await reject(
  () =>
    q("select public.crm_site_save($1,$2,1,$3)", [
      org,
      "abcdefab-5555-4555-8555-555555555555",
      siteSettings,
    ]),
  "management settings cannot be changed across tenants",
);
await as(teacher);
await reject(
  () =>
    q("select public.crm_site_save($1,$2,1,$3)", [
      org,
      "abcdefab-6666-4666-8666-666666666666",
      siteSettings,
    ]),
  "teachers cannot change organization branding",
);
await as("", "anon");
await reject(
  () => q("select * from public.crm_sites"),
  "anonymous visitors cannot read private management table",
);
await db.exec("reset role");
const slug = (
  await q("select slug from public.organizations where id=$1", [org])
)[0].slug;
await as("", "anon");
const projection = (await q("select public.crm_site_public($1) r", [slug]))[0]
  .r;
await assert(
  projection.settings.nameBn === siteSettings.nameBn &&
    projection.settings.copy.text_0.en === "Edited headline" &&
    !("organization_id" in projection),
  "public site exposes configured branding and content without private identifiers",
);
await db.exec("reset role");

await as(owner);
const beforePublication = (
  await q(
    "select jsonb_build_object('name',name,'public_visible',public_visible,'intake_open',intake_open,'public_copy',public_copy) r from public.offerings where organization_id=$1 and id=$2",
    [org, course.offering_id],
  )
)[0].r;
const newPublication = {
  ...beforePublication,
  public_visible: true,
  intake_open: false,
  public_copy: {
    showcase_title: "New programme title",
    showcase_title_bn: "নতুন প্রোগ্রাম",
  },
};
const publicationRequest = "abcdefab-7777-4777-8777-777777777777";
const feeBefore = JSON.stringify(
  await q(
    "select amount,frequency from public.fee_terms where organization_id=$1 and offering_id=$2",
    [org, course.offering_id],
  ),
);
await q("select public.crm_site_offering($1,$2,$3,$4,$5)", [
  org,
  publicationRequest,
  course.offering_id,
  beforePublication,
  newPublication,
]);
await q("select public.crm_site_offering($1,$2,$3,$4,$5)", [
  org,
  publicationRequest,
  course.offering_id,
  beforePublication,
  newPublication,
]);
await assert(
  (
    await q(
      "select public_copy,intake_open from public.offerings where organization_id=$1 and id=$2",
      [org, course.offering_id],
    )
  )[0].public_copy.showcase_title === newPublication.public_copy.showcase_title,
  "publication editor updates bilingual programme copy with stable retries",
);
await assert(
  JSON.stringify(
    await q(
      "select amount,frequency from public.fee_terms where organization_id=$1 and offering_id=$2",
      [org, course.offering_id],
    ),
  ) === feeBefore,
  "publication settings preserve operational fees",
);
await reject(
  () =>
    q("select public.crm_site_offering($1,$2,$3,$4,$5)", [
      org,
      "abcdefab-8888-4888-8888-888888888888",
      course.offering_id,
      beforePublication,
      newPublication,
    ]),
  "publication edits reject stale content",
);
await as(outsider);
await reject(
  () =>
    q("select public.crm_site_offering($1,$2,$3,$4,$5)", [
      org,
      "abcdefab-9999-4999-8999-999999999999",
      course.offering_id,
      newPublication,
      newPublication,
    ]),
  "another tenant cannot publish an offering",
);
await db.exec("reset role");

const count = (
  await q(
    "select count(*)::int n from information_schema.tables where table_schema='public' and table_type='BASE TABLE'",
  )
)[0].n;

await reject(
  () => db.exec(sql),
  "fresh baseline rejects existing public schema",
);
await db.exec("rollback");
console.log(
  `Validated ${passed} assertions; ${count} public tables; Supabase Auth/Storage mocked, hosted acceptance pending.`,
);
await db.close();
