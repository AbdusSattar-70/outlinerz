-- Lean EduOps fresh baseline. New empty Supabase project only.
-- This is a new contract, not the old migrations concatenated.
begin;
do $$ begin
 if exists(select 1 from pg_catalog.pg_tables where schemaname='public') then
 raise exception 'Fresh baseline requires an empty public schema. Create a new project; do not apply to the legacy database.';
 end if;
end $$;
create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;
create table public.organizations (
 id uuid primary key default gen_random_uuid(), name text not null check(length(trim(name)) between 1 and 160),
 slug text not null unique check(slug ~ '^[a-z0-9][a-z0-9-]{2,62}$'),
 currency text not null default 'BDT' check(currency ~ '^[A-Z]{3}$'), timezone text not null default 'Asia/Dhaka',
 settings jsonb not null default '{}' check(jsonb_typeof(settings)='object'),
 created_at timestamptz not null default now()
);
create table public.memberships (
 organization_id uuid not null references public.organizations(id), user_id uuid not null references auth.users(id),
 role text not null check(role in ('OWNER','ADMIN','ACADEMIC','FINANCE','OPERATOR','TEACHER')),
 active boolean not null default true, created_at timestamptz not null default now(),
 primary key(organization_id,user_id)
);
create table public.organization_modules (
 organization_id uuid not null references public.organizations(id), module text not null check(module in ('CRM','ACADEMIC','FINANCE','BUSINESS','ACCOUNTING')),
 enabled boolean not null default true, primary key(organization_id,module)
);
create function app_private.has_role(p_org uuid, p_roles text[]) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.memberships m where m.organization_id=p_org and m.user_id=auth.uid() and m.active and m.role=any(p_roles));
$$;
create function app_private.require_role(p_org uuid, p_roles text[]) returns void
language plpgsql security definer set search_path = '' as $$
begin
 if not app_private.has_role(p_org,p_roles) then raise exception 'Access denied' using errcode='42501'; end if;
end $$;
create function app_private.require_module(p_org uuid, p_module text) returns void
language plpgsql security definer set search_path = '' as $$
begin
 if not exists(select 1 from public.organization_modules where organization_id=p_org and module=p_module and enabled) then
 raise exception 'Module is disabled: %',p_module; end if;
end $$;

create table public.branches (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 name text not null check(length(trim(name))>0),
 code text not null,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 unique(organization_id,code)
);

create table public.academic_years (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 name text not null,
 starts_on date not null,
 ends_on date not null,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 check(ends_on>=starts_on), unique(organization_id,name)
);

create table public.class_levels (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 name text not null,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 unique(organization_id,name)
);

create table public.class_groups (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 name text not null,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 unique(organization_id,name)
);

create table public.subjects (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 name text not null,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 unique(organization_id,name)
);

create table public.people (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 name text not null check(length(trim(name))>0),
 user_id uuid references auth.users(id),
 phone text,
 email text,
 kind text not null check(kind in ('TEACHER','STAFF','SUPPLIER','REFERRER')),
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 unique(organization_id,user_id)
);

create table public.programmes (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 name text not null check(length(trim(name))>0),
 description text,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 unique(organization_id,name)
);

create table public.offerings (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 programme_id uuid not null,
 branch_id uuid not null,
 academic_year_id uuid not null,
 class_level_id uuid not null,
 class_group_id uuid,
 name text not null,
 code text not null,
 intake_open boolean not null default false,
 public_visible boolean not null default false,
 active boolean not null default true,
 public_copy jsonb not null default '{}' check(jsonb_typeof(public_copy)='object'),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,programme_id) references public.programmes(organization_id,id),
 foreign key(organization_id,branch_id) references public.branches(organization_id,id),
 foreign key(organization_id,academic_year_id) references public.academic_years(organization_id,id),
 foreign key(organization_id,class_level_id) references public.class_levels(organization_id,id),
 foreign key(organization_id,class_group_id) references public.class_groups(organization_id,id),
 unique(organization_id,code)
);

create table public.offering_subjects (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 offering_id uuid not null,
 subject_id uuid not null,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,offering_id) references public.offerings(organization_id,id),
 foreign key(organization_id,subject_id) references public.subjects(organization_id,id),
 unique(organization_id,offering_id,subject_id)
);

create table public.fee_terms (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 offering_id uuid not null,
 amount numeric(14,2) not null check(amount>=0),
 frequency text not null check(frequency in ('MONTHLY','ONE_TIME')),
 effective_on date not null,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,offering_id) references public.offerings(organization_id,id)
);

create unique index one_current_fee on public.fee_terms(organization_id,offering_id) where active;
create table public.batches (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 offering_id uuid not null,
 name text not null,
 capacity integer not null check(capacity>0),
 teacher_id uuid,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,offering_id) references public.offerings(organization_id,id),
 foreign key(organization_id,teacher_id) references public.people(organization_id,id),
 unique(organization_id,offering_id,name), unique(organization_id,id,offering_id)
);

create table public.prospects (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 student_name text not null,
 guardian_name text,
 phone text not null,
 class_level_id uuid,
 offering_id uuid,
 source text not null default 'ORGANIC',
 referrer_id uuid,
 stage text not null default 'NEW' check(stage in ('NEW','CONTACTED','INTERESTED','LOST','ADMITTED')),
 lost_reason text,
 notes text,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,class_level_id) references public.class_levels(organization_id,id),
 foreign key(organization_id,offering_id) references public.offerings(organization_id,id),
 foreign key(organization_id,referrer_id) references public.people(organization_id,id),
 check(stage<>'LOST' or length(trim(lost_reason))>0)
);

create table public.followups (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 prospect_id uuid not null,
 assigned_user_id uuid not null,
 due_at timestamptz not null,
 note text,
 completed_at timestamptz,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,prospect_id) references public.prospects(organization_id,id),
 foreign key(organization_id,assigned_user_id) references public.memberships(organization_id,user_id)
);

create table public.students (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 student_number bigint not null check(student_number>0),
 name text not null check(length(trim(name))>0),
 date_of_birth date,
 school text,
 guardian_name text not null,
 guardian_phone text not null,
 address text,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 unique(organization_id,student_number)
);

create table public.enrollments (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 student_id uuid not null,
 offering_id uuid not null,
 batch_id uuid not null,
 prospect_id uuid,
 referrer_id uuid,
 admitted_on date not null,
 status text not null default 'ACTIVE' check(status in ('ACTIVE','WITHDRAWN','COMPLETED')),
 agreed_fee numeric(14,2) not null check(agreed_fee>=0),
 fee_frequency text not null check(fee_frequency in ('MONTHLY','ONE_TIME')),
 agreement_snapshot jsonb not null check(jsonb_typeof(agreement_snapshot)='object'),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,student_id) references public.students(organization_id,id),
 foreign key(organization_id,offering_id) references public.offerings(organization_id,id),
 foreign key(organization_id,prospect_id) references public.prospects(organization_id,id),
 foreign key(organization_id,referrer_id) references public.people(organization_id,id),
 foreign key(organization_id,batch_id,offering_id) references public.batches(organization_id,id,offering_id), unique(organization_id,id,student_id)
);

create unique index one_active_enrollment on public.enrollments(organization_id,student_id,offering_id) where status='ACTIVE';
create table public.routine_slots (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 batch_id uuid not null,
 subject_id uuid not null,
 teacher_id uuid not null,
 weekday smallint not null check(weekday between 0 and 6),
 starts_at time not null,
 ends_at time not null,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,batch_id) references public.batches(organization_id,id),
 foreign key(organization_id,subject_id) references public.subjects(organization_id,id),
 foreign key(organization_id,teacher_id) references public.people(organization_id,id),
 check(ends_at>starts_at)
);

create table public.topics (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 subject_id uuid not null,
 class_level_id uuid not null,
 chapter text not null,
 title text not null,
 weight numeric(8,2) not null default 1 check(weight>0),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,subject_id) references public.subjects(organization_id,id),
 foreign key(organization_id,class_level_id) references public.class_levels(organization_id,id)
);

create table public.study_plan_items (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 batch_id uuid not null,
 topic_id uuid not null,
 target_on date not null,
 teacher_id uuid,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,batch_id) references public.batches(organization_id,id),
 foreign key(organization_id,topic_id) references public.topics(organization_id,id),
 foreign key(organization_id,teacher_id) references public.people(organization_id,id),
 unique(organization_id,batch_id,topic_id)
);

create table public.sessions (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 batch_id uuid not null,
 subject_id uuid not null,
 teacher_id uuid not null,
 starts_at timestamptz not null,
 ends_at timestamptz not null,
 status text not null default 'PLANNED' check(status in ('PLANNED','COMPLETED','CANCELLED')),
 notes text,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,batch_id) references public.batches(organization_id,id),
 foreign key(organization_id,subject_id) references public.subjects(organization_id,id),
 foreign key(organization_id,teacher_id) references public.people(organization_id,id),
 check(ends_at>starts_at)
);

create table public.session_topics (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 session_id uuid not null,
 topic_id uuid not null,
 coverage_percent numeric(5,2) not null check(coverage_percent>0 and coverage_percent<=100),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,session_id) references public.sessions(organization_id,id),
 foreign key(organization_id,topic_id) references public.topics(organization_id,id),
 unique(organization_id,session_id,topic_id)
);

create table public.attendance (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 session_id uuid not null,
 enrollment_id uuid not null,
 status text not null check(status in ('PRESENT','ABSENT','LATE','EXCUSED')),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,session_id) references public.sessions(organization_id,id),
 foreign key(organization_id,enrollment_id) references public.enrollments(organization_id,id),
 unique(organization_id,session_id,enrollment_id)
);

create table public.homework (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 session_id uuid not null,
 instructions text not null,
 due_on date not null,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,session_id) references public.sessions(organization_id,id)
);

create table public.homework_reviews (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 homework_id uuid not null,
 enrollment_id uuid not null,
 status text not null check(status in ('DONE','PARTIAL','NOT_DONE')),
 comment text,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,homework_id) references public.homework(organization_id,id),
 foreign key(organization_id,enrollment_id) references public.enrollments(organization_id,id),
 unique(organization_id,homework_id,enrollment_id)
);

create table public.questions (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 topic_id uuid not null,
 kind text not null,
 difficulty text not null check(difficulty in ('EASY','MEDIUM','HARD')),
 marks numeric(8,2) not null check(marks>0),
 body text not null,
 answer text,
 reviewed boolean not null default false,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,topic_id) references public.topics(organization_id,id)
);

create table public.assessments (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 batch_id uuid not null,
 subject_id uuid not null,
 kind text not null check(kind in ('CLASS','WEEKLY','MONTHLY','MODEL')),
 name text not null,
 scheduled_on date not null,
 published boolean not null default false,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,batch_id) references public.batches(organization_id,id),
 foreign key(organization_id,subject_id) references public.subjects(organization_id,id)
);

create table public.assessment_items (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 assessment_id uuid not null,
 question_id uuid,
 topic_id uuid not null,
 position integer not null check(position>0),
 marks numeric(8,2) not null check(marks>0),
 question_snapshot text not null,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,assessment_id) references public.assessments(organization_id,id),
 foreign key(organization_id,question_id) references public.questions(organization_id,id),
 foreign key(organization_id,topic_id) references public.topics(organization_id,id),
 unique(organization_id,assessment_id,position)
);

create table public.assessment_results (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 assessment_id uuid not null,
 enrollment_id uuid not null,
 absent boolean not null default false,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,assessment_id) references public.assessments(organization_id,id),
 foreign key(organization_id,enrollment_id) references public.enrollments(organization_id,id),
 unique(organization_id,assessment_id,enrollment_id)
);

create table public.marks (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 result_id uuid not null,
 item_id uuid not null,
 earned numeric(8,2) not null check(earned>=0),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,result_id) references public.assessment_results(organization_id,id),
 foreign key(organization_id,item_id) references public.assessment_items(organization_id,id),
 unique(organization_id,result_id,item_id)
);

create table public.work_items (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 person_id uuid not null,
 session_id uuid,
 kind text not null check(kind in ('TEACHING','SCRIPT_CHECKING','QUESTION_SET','OTHER')),
 description text not null,
 due_on date,
 quantity numeric(10,2) not null default 1 check(quantity>0),
 status text not null default 'ASSIGNED' check(status in ('ASSIGNED','SUBMITTED','ACCEPTED','REJECTED')),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,person_id) references public.people(organization_id,id),
 foreign key(organization_id,session_id) references public.sessions(organization_id,id)
);

create table public.compensation_terms (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 person_id uuid not null,
 kind text not null check(kind in ('FIXED','HOURLY','PER_CLASS','PER_SCRIPT','PER_QUESTION_SET','REVENUE_SHARE')),
 rate numeric(14,2) not null check(rate>=0),
 effective_from date not null,
 effective_to date,
 hybrid boolean not null default false,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,person_id) references public.people(organization_id,id),
 check(effective_to is null or effective_to>=effective_from), check(kind<>'REVENUE_SHARE' or rate<=100)
);

create table public.money_accounts (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 branch_id uuid,
 name text not null,
 kind text not null check(kind in ('CASH','BANK','MFS')),
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,branch_id) references public.branches(organization_id,id),
 unique(organization_id,name)
);

create table public.invoices (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 student_id uuid not null,
 enrollment_id uuid not null,
 invoice_number bigint not null,
 billing_period date not null,
 due_on date not null,
 amount numeric(14,2) not null check(amount>=0),
 description text not null,
 fee_snapshot jsonb not null,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,student_id) references public.students(organization_id,id),
 foreign key(organization_id,enrollment_id,student_id) references public.enrollments(organization_id,id,student_id), unique(organization_id,invoice_number), unique(organization_id,enrollment_id,billing_period), unique(organization_id,id,student_id)
);

create table public.invoice_credits (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 invoice_id uuid not null,
 amount numeric(14,2) not null check(amount>0),
 kind text not null check(kind in ('DISCOUNT','SCHOLARSHIP','CANCELLATION')),
 reason text not null check(length(trim(reason))>0),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,invoice_id) references public.invoices(organization_id,id)
);

create table public.payments (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 student_id uuid not null,
 account_id uuid not null,
 receipt_number bigint not null,
 amount numeric(14,2) not null check(amount>0),
 paid_on date not null,
 reference text,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,student_id) references public.students(organization_id,id),
 foreign key(organization_id,account_id) references public.money_accounts(organization_id,id),
 unique(organization_id,receipt_number), unique(organization_id,id,student_id)
);

create table public.payment_allocations (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 payment_id uuid not null,
 invoice_id uuid not null,
 student_id uuid not null,
 amount numeric(14,2) not null check(amount>0),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,payment_id,student_id) references public.payments(organization_id,id,student_id), foreign key(organization_id,invoice_id,student_id) references public.invoices(organization_id,id,student_id), unique(organization_id,payment_id,invoice_id)
);

create table public.refunds (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 allocation_id uuid not null,
 account_id uuid not null,
 amount numeric(14,2) not null check(amount>0),
 paid_on date not null,
 reason text not null check(length(trim(reason))>0),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,allocation_id) references public.payment_allocations(organization_id,id),
 foreign key(organization_id,account_id) references public.money_accounts(organization_id,id)
);

create table public.purchases (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 supplier_id uuid,
 branch_id uuid,
 description text not null,
 supplier_invoice text,
 amount numeric(14,2) not null check(amount>0),
 purchased_on date not null,
 classification text not null check(classification in ('EXPENSE','ASSET')),
 status text not null default 'DRAFT' check(status in ('DRAFT','RECEIVED','CANCELLED')),
 received_on date,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,supplier_id) references public.people(organization_id,id),
 foreign key(organization_id,branch_id) references public.branches(organization_id,id),
 check((status='RECEIVED')=(received_on is not null))
);

create unique index unique_supplier_invoice on public.purchases(organization_id,supplier_id,lower(trim(supplier_invoice))) where supplier_invoice is not null;
create table public.payables (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 person_id uuid,
 purchase_id uuid,
 work_item_id uuid,
 component text not null,
 amount numeric(14,2) not null check(amount>0),
 earned_on date not null,
 description text not null,
 agreement_snapshot jsonb not null default '{}',
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,person_id) references public.people(organization_id,id),
 foreign key(organization_id,purchase_id) references public.purchases(organization_id,id),
 foreign key(organization_id,work_item_id) references public.work_items(organization_id,id),
 unique(organization_id,work_item_id,component), unique(organization_id,purchase_id)
);

create table public.settlements (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 payable_id uuid not null,
 account_id uuid not null,
 amount numeric(14,2) not null check(amount>0),
 paid_on date not null,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,payable_id) references public.payables(organization_id,id),
 foreign key(organization_id,account_id) references public.money_accounts(organization_id,id)
);

create table public.expenses (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 account_id uuid not null,
 category text not null,
 description text not null,
 amount numeric(14,2) not null check(amount>0),
 paid_on date not null,
 person_id uuid,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,account_id) references public.money_accounts(organization_id,id),
 foreign key(organization_id,person_id) references public.people(organization_id,id)
);

create table public.money_movements (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 account_id uuid not null,
 signed_amount numeric(14,2) not null check(signed_amount<>0),
 occurred_on date not null,
 source_type text not null check(source_type in ('PAYMENT','REFUND','EXPENSE','SETTLEMENT','TRANSFER','OPENING','ADVANCE','ADVANCE_RETURN','ASSET_SALE')),
 source_id uuid not null,
 description text not null,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,account_id) references public.money_accounts(organization_id,id),
 unique(organization_id,source_type,source_id,account_id)
);

create table public.staff_advances (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 person_id uuid not null,
 account_id uuid not null,
 amount numeric(14,2) not null check(amount>0),
 paid_on date not null,
 reason text not null,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,person_id) references public.people(organization_id,id),
 foreign key(organization_id,account_id) references public.money_accounts(organization_id,id)
);

create table public.advance_clearings (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 advance_id uuid not null,
 payable_id uuid,
 account_id uuid,
 amount numeric(14,2) not null check(amount>0),
 cleared_on date not null,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,advance_id) references public.staff_advances(organization_id,id),
 foreign key(organization_id,payable_id) references public.payables(organization_id,id),
 foreign key(organization_id,account_id) references public.money_accounts(organization_id,id),
 check((payable_id is null)<>(account_id is null))
);

create table public.assets (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 purchase_id uuid,
 branch_id uuid not null,
 assigned_person_id uuid,
 code text not null,
 name text not null,
 cost numeric(14,2) not null check(cost>=0),
 acquired_on date not null,
 condition text not null default 'GOOD' check(condition in ('GOOD','REPAIR','DAMAGED')),
 status text not null default 'ACTIVE' check(status in ('ACTIVE','DISPOSED')),
 disposed_on date,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,purchase_id) references public.purchases(organization_id,id),
 foreign key(organization_id,branch_id) references public.branches(organization_id,id),
 foreign key(organization_id,assigned_person_id) references public.people(organization_id,id),
 unique(organization_id,code), check((status='DISPOSED')=(disposed_on is not null))
);

create table public.asset_maintenance (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 asset_id uuid not null,
 expense_id uuid,
 performed_on date not null,
 description text not null,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,asset_id) references public.assets(organization_id,id),
 foreign key(organization_id,expense_id) references public.expenses(organization_id,id)
);

create table public.documents (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 object_path text not null,
 kind text not null,
 student_id uuid,
 purchase_id uuid,
 expense_id uuid,
 uploaded_by uuid not null references auth.users(id),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,student_id) references public.students(organization_id,id),
 foreign key(organization_id,purchase_id) references public.purchases(organization_id,id),
 foreign key(organization_id,expense_id) references public.expenses(organization_id,id),
 check(split_part(object_path,'/',1)=organization_id::text), unique(organization_id,object_path)
);

create table public.outbox_events (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 event_type text not null,
 source_id uuid not null,
 payload jsonb not null,
 occurred_at timestamptz not null default now(),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 unique(organization_id,event_type,source_id)
);

create table public.accounting_accounts (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 code text not null,
 name text not null,
 kind text not null check(kind in ('ASSET','LIABILITY','EQUITY','INCOME','EXPENSE')),
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 unique(organization_id,code)
);

create table public.journals (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 event_id uuid not null,
 projection_snapshot jsonb not null,
 posted_on date not null,
 description text not null,
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,event_id) references public.outbox_events(organization_id,id),
 unique(organization_id,event_id)
);

create table public.journal_lines (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id),
 journal_id uuid not null,
 account_id uuid not null,
 debit numeric(14,2) not null default 0 check(debit>=0),
 credit numeric(14,2) not null default 0 check(credit>=0),
 created_at timestamptz not null default now(),
 unique(organization_id,id),
 foreign key(organization_id,journal_id) references public.journals(organization_id,id),
 foreign key(organization_id,account_id) references public.accounting_accounts(organization_id,id),
 check((debit>0 and credit=0) or (credit>0 and debit=0))
);


create table app_private.command_results (
 organization_id uuid not null references public.organizations(id), request_id uuid not null,
 command text not null, payload jsonb not null, result jsonb, primary key(organization_id,request_id)
);
create table app_private.counters (
 organization_id uuid not null references public.organizations(id), kind text not null, value bigint not null,
 primary key(organization_id,kind)
);
create table public.audit_events (
 id bigint generated always as identity primary key, organization_id uuid not null references public.organizations(id),
 actor_id uuid, table_name text not null, row_id uuid, operation text not null,
 old_record jsonb, new_record jsonb, occurred_at timestamptz not null default now()
);
create function app_private.next_number(p_org uuid,p_kind text) returns bigint
language plpgsql security definer set search_path='' as $$
declare n bigint;
begin
 insert into app_private.counters values(p_org,p_kind,1)
 on conflict(organization_id,kind) do update set value=app_private.counters.value+1 returning value into n;
 return n;
end $$;
create function app_private.begin_command(p_org uuid,p_request uuid,p_command text,p_payload jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare c app_private.command_results;
begin
 if p_request is null then raise exception 'Stable request ID required'; end if;
 insert into app_private.command_results values(p_org,p_request,p_command,p_payload,null) on conflict do nothing;
 select * into c from app_private.command_results where organization_id=p_org and request_id=p_request for update;
 if c.command<>p_command or c.payload<>p_payload then raise exception 'Request ID reused with changed inputs'; end if;
 return c.result;
end $$;
create function app_private.end_command(p_org uuid,p_request uuid,p_result jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 update app_private.command_results set result=p_result where organization_id=p_org and request_id=p_request;
 return p_result;
end $$;
create function app_private.audit_row() returns trigger language plpgsql security definer set search_path='' as $$
declare r jsonb;
begin
 r:=case when TG_OP='DELETE' then to_jsonb(old) else to_jsonb(new) end;
 insert into public.audit_events(organization_id,actor_id,table_name,row_id,operation,old_record,new_record)
 values((r->>'organization_id')::uuid,auth.uid(),TG_TABLE_NAME,(r->>'id')::uuid,TG_OP,
 case when TG_OP<>'INSERT' then to_jsonb(old) end,case when TG_OP<>'DELETE' then to_jsonb(new) end);
 return case when TG_OP='DELETE' then old else new end;
end $$;
create function app_private.reject_mutation() returns trigger language plpgsql set search_path='' as $$
begin raise exception 'Immutable evidence; use correction transactions'; end $$;
create function app_private.emit_event() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.outbox_events(organization_id,event_type,source_id,payload)
 values(new.organization_id,TG_TABLE_NAME||'.created',new.id,to_jsonb(new));
 return new;
end $$;

alter table public.branches enable row level security;
create policy tenant_read on public.branches for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant select on public.branches to authenticated;

create policy tenant_insert on public.branches for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
create policy tenant_update on public.branches for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant insert,update on public.branches to authenticated;

create index branches_tenant_idx on public.branches(organization_id);
create trigger audit_changes after insert or update or delete on public.branches for each row execute function app_private.audit_row();
alter table public.academic_years enable row level security;
create policy tenant_read on public.academic_years for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant select on public.academic_years to authenticated;

create policy tenant_insert on public.academic_years for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
create policy tenant_update on public.academic_years for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant insert,update on public.academic_years to authenticated;

create index academic_years_tenant_idx on public.academic_years(organization_id);
create trigger audit_changes after insert or update or delete on public.academic_years for each row execute function app_private.audit_row();
alter table public.class_levels enable row level security;
create policy tenant_read on public.class_levels for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant select on public.class_levels to authenticated;

create policy tenant_insert on public.class_levels for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
create policy tenant_update on public.class_levels for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant insert,update on public.class_levels to authenticated;

create index class_levels_tenant_idx on public.class_levels(organization_id);
create trigger audit_changes after insert or update or delete on public.class_levels for each row execute function app_private.audit_row();
alter table public.class_groups enable row level security;
create policy tenant_read on public.class_groups for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant select on public.class_groups to authenticated;

create policy tenant_insert on public.class_groups for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
create policy tenant_update on public.class_groups for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant insert,update on public.class_groups to authenticated;

create index class_groups_tenant_idx on public.class_groups(organization_id);
create trigger audit_changes after insert or update or delete on public.class_groups for each row execute function app_private.audit_row();
alter table public.subjects enable row level security;
create policy tenant_read on public.subjects for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant select on public.subjects to authenticated;

create policy tenant_insert on public.subjects for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
create policy tenant_update on public.subjects for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant insert,update on public.subjects to authenticated;

create index subjects_tenant_idx on public.subjects(organization_id);
create trigger audit_changes after insert or update or delete on public.subjects for each row execute function app_private.audit_row();
alter table public.people enable row level security;
create policy tenant_read on public.people for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant select on public.people to authenticated;

create policy tenant_insert on public.people for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
create policy tenant_update on public.people for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant insert,update on public.people to authenticated;

create index people_tenant_idx on public.people(organization_id);
create trigger audit_changes after insert or update or delete on public.people for each row execute function app_private.audit_row();
alter table public.programmes enable row level security;
create policy tenant_read on public.programmes for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant select on public.programmes to authenticated;

create policy tenant_insert on public.programmes for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
create policy tenant_update on public.programmes for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN']::text[]));
grant insert,update on public.programmes to authenticated;

create index programmes_tenant_idx on public.programmes(organization_id);
create trigger audit_changes after insert or update or delete on public.programmes for each row execute function app_private.audit_row();
alter table public.offerings enable row level security;
create policy tenant_read on public.offerings for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.offerings to authenticated;

create policy tenant_insert on public.offerings for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.offerings for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.offerings to authenticated;

create index offerings_tenant_idx on public.offerings(organization_id);
create trigger audit_changes after insert or update or delete on public.offerings for each row execute function app_private.audit_row();
alter table public.offering_subjects enable row level security;
create policy tenant_read on public.offering_subjects for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.offering_subjects to authenticated;

create policy tenant_insert on public.offering_subjects for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.offering_subjects for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.offering_subjects to authenticated;

create index offering_subjects_tenant_idx on public.offering_subjects(organization_id);
create trigger audit_changes after insert or update or delete on public.offering_subjects for each row execute function app_private.audit_row();
alter table public.fee_terms enable row level security;
create policy tenant_read on public.fee_terms for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.fee_terms to authenticated;

create policy tenant_insert on public.fee_terms for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.fee_terms for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.fee_terms to authenticated;

create index fee_terms_tenant_idx on public.fee_terms(organization_id);
create trigger audit_changes after insert or update or delete on public.fee_terms for each row execute function app_private.audit_row();
alter table public.batches enable row level security;
create policy tenant_read on public.batches for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.batches to authenticated;

create policy tenant_insert on public.batches for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.batches for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.batches to authenticated;

create index batches_tenant_idx on public.batches(organization_id);
create trigger audit_changes after insert or update or delete on public.batches for each row execute function app_private.audit_row();
alter table public.prospects enable row level security;
create policy tenant_read on public.prospects for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.prospects to authenticated;

create policy tenant_insert on public.prospects for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','OPERATOR']::text[]));
create policy tenant_update on public.prospects for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','OPERATOR']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','OPERATOR']::text[]));
grant insert,update on public.prospects to authenticated;

create index prospects_tenant_idx on public.prospects(organization_id);
create trigger audit_changes after insert or update or delete on public.prospects for each row execute function app_private.audit_row();
alter table public.followups enable row level security;
create policy tenant_read on public.followups for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.followups to authenticated;

create policy tenant_insert on public.followups for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','OPERATOR']::text[]));
create policy tenant_update on public.followups for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','OPERATOR']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','OPERATOR']::text[]));
grant insert,update on public.followups to authenticated;

create index followups_tenant_idx on public.followups(organization_id);
create trigger audit_changes after insert or update or delete on public.followups for each row execute function app_private.audit_row();
alter table public.students enable row level security;
create policy tenant_read on public.students for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.students to authenticated;

create index students_tenant_idx on public.students(organization_id);
create trigger audit_changes after insert or update or delete on public.students for each row execute function app_private.audit_row();
alter table public.enrollments enable row level security;
create policy tenant_read on public.enrollments for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.enrollments to authenticated;

create index enrollments_tenant_idx on public.enrollments(organization_id);
create trigger audit_changes after insert or update or delete on public.enrollments for each row execute function app_private.audit_row();
alter table public.routine_slots enable row level security;
create policy tenant_read on public.routine_slots for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.routine_slots to authenticated;

create policy tenant_insert on public.routine_slots for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.routine_slots for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.routine_slots to authenticated;

create index routine_slots_tenant_idx on public.routine_slots(organization_id);
create trigger audit_changes after insert or update or delete on public.routine_slots for each row execute function app_private.audit_row();
alter table public.topics enable row level security;
create policy tenant_read on public.topics for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.topics to authenticated;

create policy tenant_insert on public.topics for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.topics for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.topics to authenticated;

create index topics_tenant_idx on public.topics(organization_id);
create trigger audit_changes after insert or update or delete on public.topics for each row execute function app_private.audit_row();
alter table public.study_plan_items enable row level security;
create policy tenant_read on public.study_plan_items for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.study_plan_items to authenticated;

create policy tenant_insert on public.study_plan_items for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.study_plan_items for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.study_plan_items to authenticated;

create index study_plan_items_tenant_idx on public.study_plan_items(organization_id);
create trigger audit_changes after insert or update or delete on public.study_plan_items for each row execute function app_private.audit_row();
alter table public.sessions enable row level security;
create policy tenant_read on public.sessions for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.sessions to authenticated;

create policy tenant_insert on public.sessions for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.sessions for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.sessions to authenticated;

create index sessions_tenant_idx on public.sessions(organization_id);
create trigger audit_changes after insert or update or delete on public.sessions for each row execute function app_private.audit_row();
alter table public.session_topics enable row level security;
create policy tenant_read on public.session_topics for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.session_topics to authenticated;

create policy tenant_insert on public.session_topics for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.session_topics for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.session_topics to authenticated;

create index session_topics_tenant_idx on public.session_topics(organization_id);
create trigger audit_changes after insert or update or delete on public.session_topics for each row execute function app_private.audit_row();
alter table public.attendance enable row level security;
create policy tenant_read on public.attendance for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.attendance to authenticated;

create policy tenant_insert on public.attendance for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.attendance for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.attendance to authenticated;

create index attendance_tenant_idx on public.attendance(organization_id);
create trigger audit_changes after insert or update or delete on public.attendance for each row execute function app_private.audit_row();
alter table public.homework enable row level security;
create policy tenant_read on public.homework for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.homework to authenticated;

create policy tenant_insert on public.homework for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.homework for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.homework to authenticated;

create index homework_tenant_idx on public.homework(organization_id);
create trigger audit_changes after insert or update or delete on public.homework for each row execute function app_private.audit_row();
alter table public.homework_reviews enable row level security;
create policy tenant_read on public.homework_reviews for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.homework_reviews to authenticated;

create policy tenant_insert on public.homework_reviews for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.homework_reviews for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.homework_reviews to authenticated;

create index homework_reviews_tenant_idx on public.homework_reviews(organization_id);
create trigger audit_changes after insert or update or delete on public.homework_reviews for each row execute function app_private.audit_row();
alter table public.questions enable row level security;
create policy tenant_read on public.questions for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.questions to authenticated;

create policy tenant_insert on public.questions for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.questions for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.questions to authenticated;

create index questions_tenant_idx on public.questions(organization_id);
create trigger audit_changes after insert or update or delete on public.questions for each row execute function app_private.audit_row();
alter table public.assessments enable row level security;
create policy tenant_read on public.assessments for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.assessments to authenticated;

create policy tenant_insert on public.assessments for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.assessments for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.assessments to authenticated;

create index assessments_tenant_idx on public.assessments(organization_id);
create trigger audit_changes after insert or update or delete on public.assessments for each row execute function app_private.audit_row();
alter table public.assessment_items enable row level security;
create policy tenant_read on public.assessment_items for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.assessment_items to authenticated;

create policy tenant_insert on public.assessment_items for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.assessment_items for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.assessment_items to authenticated;

create index assessment_items_tenant_idx on public.assessment_items(organization_id);
create trigger audit_changes after insert or update or delete on public.assessment_items for each row execute function app_private.audit_row();
alter table public.assessment_results enable row level security;
create policy tenant_read on public.assessment_results for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.assessment_results to authenticated;

create policy tenant_insert on public.assessment_results for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.assessment_results for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.assessment_results to authenticated;

create index assessment_results_tenant_idx on public.assessment_results(organization_id);
create trigger audit_changes after insert or update or delete on public.assessment_results for each row execute function app_private.audit_row();
alter table public.marks enable row level security;
create policy tenant_read on public.marks for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.marks to authenticated;

create policy tenant_insert on public.marks for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.marks for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.marks to authenticated;

create index marks_tenant_idx on public.marks(organization_id);
create trigger audit_changes after insert or update or delete on public.marks for each row execute function app_private.audit_row();
alter table public.work_items enable row level security;
create policy tenant_read on public.work_items for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']::text[]));
grant select on public.work_items to authenticated;

create policy tenant_insert on public.work_items for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
create policy tenant_update on public.work_items for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']::text[]));
grant insert,update on public.work_items to authenticated;

create index work_items_tenant_idx on public.work_items(organization_id);
create trigger audit_changes after insert or update or delete on public.work_items for each row execute function app_private.audit_row();
alter table public.compensation_terms enable row level security;
create policy tenant_read on public.compensation_terms for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.compensation_terms to authenticated;

create policy tenant_insert on public.compensation_terms for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
create policy tenant_update on public.compensation_terms for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant insert,update on public.compensation_terms to authenticated;

create index compensation_terms_tenant_idx on public.compensation_terms(organization_id);
create trigger audit_changes after insert or update or delete on public.compensation_terms for each row execute function app_private.audit_row();
alter table public.money_accounts enable row level security;
create policy tenant_read on public.money_accounts for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.money_accounts to authenticated;

create policy tenant_insert on public.money_accounts for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
create policy tenant_update on public.money_accounts for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant insert,update on public.money_accounts to authenticated;

create index money_accounts_tenant_idx on public.money_accounts(organization_id);
create trigger audit_changes after insert or update or delete on public.money_accounts for each row execute function app_private.audit_row();
alter table public.invoices enable row level security;
create policy tenant_read on public.invoices for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.invoices to authenticated;

create index invoices_tenant_idx on public.invoices(organization_id);
create trigger audit_changes after insert or update or delete on public.invoices for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.invoices for each row execute function app_private.reject_mutation();
create trigger operational_event after insert on public.invoices for each row execute function app_private.emit_event();
alter table public.invoice_credits enable row level security;
create policy tenant_read on public.invoice_credits for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.invoice_credits to authenticated;

create index invoice_credits_tenant_idx on public.invoice_credits(organization_id);
create trigger audit_changes after insert or update or delete on public.invoice_credits for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.invoice_credits for each row execute function app_private.reject_mutation();
create trigger operational_event after insert on public.invoice_credits for each row execute function app_private.emit_event();
alter table public.payments enable row level security;
create policy tenant_read on public.payments for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.payments to authenticated;

create index payments_tenant_idx on public.payments(organization_id);
create trigger audit_changes after insert or update or delete on public.payments for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.payments for each row execute function app_private.reject_mutation();
create trigger operational_event after insert on public.payments for each row execute function app_private.emit_event();
alter table public.payment_allocations enable row level security;
create policy tenant_read on public.payment_allocations for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.payment_allocations to authenticated;

create index payment_allocations_tenant_idx on public.payment_allocations(organization_id);
create trigger audit_changes after insert or update or delete on public.payment_allocations for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.payment_allocations for each row execute function app_private.reject_mutation();
alter table public.refunds enable row level security;
create policy tenant_read on public.refunds for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.refunds to authenticated;

create index refunds_tenant_idx on public.refunds(organization_id);
create trigger audit_changes after insert or update or delete on public.refunds for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.refunds for each row execute function app_private.reject_mutation();
create trigger operational_event after insert on public.refunds for each row execute function app_private.emit_event();
alter table public.purchases enable row level security;
create policy tenant_read on public.purchases for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.purchases to authenticated;

create policy tenant_insert on public.purchases for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
create policy tenant_update on public.purchases for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant insert,update on public.purchases to authenticated;

create index purchases_tenant_idx on public.purchases(organization_id);
create trigger audit_changes after insert or update or delete on public.purchases for each row execute function app_private.audit_row();
alter table public.payables enable row level security;
create policy tenant_read on public.payables for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.payables to authenticated;

create index payables_tenant_idx on public.payables(organization_id);
create trigger audit_changes after insert or update or delete on public.payables for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.payables for each row execute function app_private.reject_mutation();
create trigger operational_event after insert on public.payables for each row execute function app_private.emit_event();
alter table public.settlements enable row level security;
create policy tenant_read on public.settlements for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.settlements to authenticated;

create index settlements_tenant_idx on public.settlements(organization_id);
create trigger audit_changes after insert or update or delete on public.settlements for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.settlements for each row execute function app_private.reject_mutation();
create trigger operational_event after insert on public.settlements for each row execute function app_private.emit_event();
alter table public.expenses enable row level security;
create policy tenant_read on public.expenses for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.expenses to authenticated;

create index expenses_tenant_idx on public.expenses(organization_id);
create trigger audit_changes after insert or update or delete on public.expenses for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.expenses for each row execute function app_private.reject_mutation();
create trigger operational_event after insert on public.expenses for each row execute function app_private.emit_event();
alter table public.money_movements enable row level security;
create policy tenant_read on public.money_movements for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.money_movements to authenticated;

create index money_movements_tenant_idx on public.money_movements(organization_id);
create trigger audit_changes after insert or update or delete on public.money_movements for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.money_movements for each row execute function app_private.reject_mutation();
create trigger operational_event after insert on public.money_movements for each row execute function app_private.emit_event();
alter table public.staff_advances enable row level security;
create policy tenant_read on public.staff_advances for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.staff_advances to authenticated;

create index staff_advances_tenant_idx on public.staff_advances(organization_id);
create trigger audit_changes after insert or update or delete on public.staff_advances for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.staff_advances for each row execute function app_private.reject_mutation();
create trigger operational_event after insert on public.staff_advances for each row execute function app_private.emit_event();
alter table public.advance_clearings enable row level security;
create policy tenant_read on public.advance_clearings for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.advance_clearings to authenticated;

create index advance_clearings_tenant_idx on public.advance_clearings(organization_id);
create trigger audit_changes after insert or update or delete on public.advance_clearings for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.advance_clearings for each row execute function app_private.reject_mutation();
create trigger operational_event after insert on public.advance_clearings for each row execute function app_private.emit_event();
alter table public.assets enable row level security;
create policy tenant_read on public.assets for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.assets to authenticated;

create policy tenant_insert on public.assets for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
create policy tenant_update on public.assets for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant insert,update on public.assets to authenticated;

create index assets_tenant_idx on public.assets(organization_id);
create trigger audit_changes after insert or update or delete on public.assets for each row execute function app_private.audit_row();
alter table public.asset_maintenance enable row level security;
create policy tenant_read on public.asset_maintenance for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.asset_maintenance to authenticated;

create policy tenant_insert on public.asset_maintenance for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
create policy tenant_update on public.asset_maintenance for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant insert,update on public.asset_maintenance to authenticated;

create index asset_maintenance_tenant_idx on public.asset_maintenance(organization_id);
create trigger audit_changes after insert or update or delete on public.asset_maintenance for each row execute function app_private.audit_row();
alter table public.documents enable row level security;
create policy tenant_read on public.documents for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.documents to authenticated;

create policy tenant_insert on public.documents for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
create policy tenant_update on public.documents for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant insert,update on public.documents to authenticated;

create index documents_tenant_idx on public.documents(organization_id);
create trigger audit_changes after insert or update or delete on public.documents for each row execute function app_private.audit_row();
alter table public.outbox_events enable row level security;
create policy tenant_read on public.outbox_events for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.outbox_events to authenticated;

create index outbox_events_tenant_idx on public.outbox_events(organization_id);
create trigger audit_changes after insert or update or delete on public.outbox_events for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.outbox_events for each row execute function app_private.reject_mutation();
alter table public.accounting_accounts enable row level security;
create policy tenant_read on public.accounting_accounts for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.accounting_accounts to authenticated;

create policy tenant_insert on public.accounting_accounts for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
create policy tenant_update on public.accounting_accounts for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[])) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant insert,update on public.accounting_accounts to authenticated;

create index accounting_accounts_tenant_idx on public.accounting_accounts(organization_id);
create trigger audit_changes after insert or update or delete on public.accounting_accounts for each row execute function app_private.audit_row();
alter table public.journals enable row level security;
create policy tenant_read on public.journals for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.journals to authenticated;

create index journals_tenant_idx on public.journals(organization_id);
create trigger audit_changes after insert or update or delete on public.journals for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.journals for each row execute function app_private.reject_mutation();
alter table public.journal_lines enable row level security;
create policy tenant_read on public.journal_lines for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']::text[]));
grant select on public.journal_lines to authenticated;

create index journal_lines_tenant_idx on public.journal_lines(organization_id);
create trigger audit_changes after insert or update or delete on public.journal_lines for each row execute function app_private.audit_row();
create trigger immutable_evidence before update or delete on public.journal_lines for each row execute function app_private.reject_mutation();

alter table public.organizations enable row level security;
alter table public.memberships enable row level security;
alter table public.organization_modules enable row level security;
alter table public.audit_events enable row level security;
create policy org_read on public.organizations for select to authenticated using(app_private.has_role(id,array['OWNER','ADMIN','ACADEMIC','FINANCE','OPERATOR','TEACHER']));
create policy member_read on public.memberships for select to authenticated using(user_id=auth.uid() or app_private.has_role(organization_id,array['OWNER','ADMIN']));
create policy module_read on public.organization_modules for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','FINANCE','OPERATOR','TEACHER']));
create policy audit_read on public.audit_events for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']));
grant select on public.organizations,public.memberships,public.organization_modules,public.audit_events to authenticated;
create trigger audit_immutable before update or delete on public.audit_events for each row execute function app_private.reject_mutation();
-- Private helpers are needed by policies, never exposed in PostgREST schemas.
grant usage on schema app_private to authenticated;
revoke all on all functions in schema app_private from public,anon,authenticated;
grant execute on function app_private.has_role(uuid,text[]) to authenticated;
-- Organization creation is self-service; access applies only to the new organization.
create function public.create_organization(p_name text,p_slug text) returns uuid
language plpgsql security definer set search_path='' as $$
declare o uuid;
begin
 if auth.uid() is null then raise exception 'Login required' using errcode='42501'; end if;
 insert into public.organizations(name,slug) values(p_name,p_slug) returning id into o;
 insert into public.memberships(organization_id,user_id,role) values(o,auth.uid(),'OWNER');
 insert into public.organization_modules(organization_id,module,enabled)
 select o,m,m<>'ACCOUNTING' from unnest(array['CRM','ACADEMIC','FINANCE','BUSINESS','ACCOUNTING']) m;
 return o;
end $$;
create function public.set_member(p_org uuid,p_user uuid,p_role text,p_active boolean) returns void
language plpgsql security definer set search_path='' as $$
begin
 perform app_private.require_role(p_org,array['OWNER']);
 perform 1 from public.organizations where id=p_org for update;
 if exists(select 1 from public.memberships where organization_id=p_org and user_id=p_user and role='OWNER' and active)
 and (not p_active or p_role<>'OWNER')
 and (select count(*) from public.memberships where organization_id=p_org and role='OWNER' and active)=1
 then raise exception 'Last owner cannot be removed'; end if;
 insert into public.memberships(organization_id,user_id,role,active) values(p_org,p_user,p_role,p_active)
 on conflict(organization_id,user_id) do update set role=excluded.role,active=excluded.active;
end $$;
create function public.set_module(p_org uuid,p_module text,p_enabled boolean) returns void
language plpgsql security definer set search_path='' as $$
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN']);
 update public.organization_modules set enabled=p_enabled where organization_id=p_org and module=p_module;
 if not found then raise exception 'Unknown module'; end if;
end $$;

create function public.create_course(p_org uuid,p_request uuid,p_data jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; pr uuid; o uuid; b uuid; s text;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','ACADEMIC']);
 perform app_private.require_module(p_org,'ACADEMIC');
 r:=app_private.begin_command(p_org,p_request,'create_course',p_data); if r is not null then return r; end if;
 pr:=(p_data->>'programme_id')::uuid;
 if pr is null then
 insert into public.programmes(organization_id,name) values(p_org,p_data->>'programme_name') returning id into pr;
 end if;
 insert into public.offerings(organization_id,programme_id,branch_id,academic_year_id,class_level_id,class_group_id,name,code,intake_open,public_visible)
 values(p_org,pr,(p_data->>'branch_id')::uuid,(p_data->>'academic_year_id')::uuid,(p_data->>'class_level_id')::uuid,
 (p_data->>'class_group_id')::uuid,p_data->>'name',p_data->>'code',coalesce((p_data->>'intake_open')::boolean,false),coalesce((p_data->>'public_visible')::boolean,false)) returning id into o;
 if jsonb_typeof(p_data->'subject_ids') is distinct from 'array' or jsonb_array_length(p_data->'subject_ids')=0 then raise exception 'Select at least one subject'; end if;
 for s in select jsonb_array_elements_text(p_data->'subject_ids') loop
 insert into public.offering_subjects(organization_id,offering_id,subject_id) values(p_org,o,s::uuid);
 end loop;
 insert into public.fee_terms(organization_id,offering_id,amount,frequency,effective_on)
 values(p_org,o,(p_data->>'fee_amount')::numeric,p_data->>'fee_frequency',coalesce((p_data->>'effective_on')::date,current_date));
 if p_data->>'batch_name' is not null then
 insert into public.batches(organization_id,offering_id,name,capacity,teacher_id)
 values(p_org,o,p_data->>'batch_name',(p_data->>'capacity')::integer,(p_data->>'teacher_id')::uuid) returning id into b;
 end if;
 return app_private.end_command(p_org,p_request,jsonb_build_object('offering_id',o,'batch_id',b,'programme_id',pr));
end $$;

create function app_private.invoice_due(p_org uuid,p_invoice uuid) returns numeric
language sql stable security definer set search_path='' as $$
 select i.amount-coalesce((select sum(c.amount) from public.invoice_credits c where c.organization_id=p_org and c.invoice_id=i.id),0)
 -coalesce((select sum(a.amount) from public.payment_allocations a where a.organization_id=p_org and a.invoice_id=i.id),0)
 +coalesce((select sum(r.amount) from public.refunds r join public.payment_allocations a on a.organization_id=r.organization_id and a.id=r.allocation_id where r.organization_id=p_org and a.invoice_id=i.id),0)
 from public.invoices i where i.organization_id=p_org and i.id=p_invoice;
$$;
create function public.admit_student(p_org uuid,p_request uuid,p_data jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; b public.batches; o public.offerings; f public.fee_terms; st uuid; en uuid; inv uuid; pro uuid; dt date; amt numeric; num bigint;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','OPERATOR']);
 perform app_private.require_module(p_org,'ACADEMIC');
 r:=app_private.begin_command(p_org,p_request,'admit_student',p_data); if r is not null then return r; end if;
 select * into b from public.batches where organization_id=p_org and id=(p_data->>'batch_id')::uuid for update;
 if not found or not b.active then raise exception 'Active batch required'; end if;
 select * into o from public.offerings where organization_id=p_org and id=b.offering_id;
 if not o.active or not o.intake_open then raise exception 'Admission closed'; end if;
 if (select count(*) from public.enrollments where organization_id=p_org and batch_id=b.id and status='ACTIVE')>=b.capacity then raise exception 'Batch full'; end if;
 dt:=coalesce((p_data->>'admitted_on')::date,current_date);
 select * into f from public.fee_terms where organization_id=p_org and offering_id=b.offering_id and active and effective_on<=dt;
 if not found then raise exception 'Applicable fee terms required'; end if;
 amt:=f.amount; pro:=(p_data->>'prospect_id')::uuid;
 if pro is not null then
 perform 1 from public.prospects where organization_id=p_org and id=pro and stage<>'ADMITTED' for update;
 if not found then raise exception 'Prospect unavailable/already converted'; end if;
 end if;
 st:=(p_data->>'student_id')::uuid;
 if st is null then
 insert into public.students(organization_id,student_number,name,guardian_name,guardian_phone,date_of_birth,school,address)
 values(p_org,app_private.next_number(p_org,'STUDENT'),p_data->>'student_name',p_data->>'guardian_name',p_data->>'guardian_phone',
 (p_data->>'date_of_birth')::date,p_data->>'school',p_data->>'address') returning id into st;
 else
 perform 1 from public.students where organization_id=p_org and id=st and active;
 if not found then raise exception 'Existing active student required'; end if;
 end if;
 insert into public.enrollments(organization_id,student_id,offering_id,batch_id,prospect_id,referrer_id,admitted_on,agreed_fee,fee_frequency,agreement_snapshot)
 values(p_org,st,b.offering_id,b.id,pro,(p_data->>'referrer_id')::uuid,dt,amt,f.frequency,to_jsonb(f)) returning id into en;
 -- Explicit first invoice; no journal or consent prerequisite.
 insert into public.invoices(organization_id,student_id,enrollment_id,invoice_number,billing_period,due_on,amount,description,fee_snapshot)
 values(p_org,st,en,app_private.next_number(p_org,'INVOICE'),date_trunc('month',dt)::date,dt,amt,o.name,to_jsonb(f)) returning id into inv;
 if pro is not null then update public.prospects set stage='ADMITTED' where organization_id=p_org and id=pro; end if;
 return app_private.end_command(p_org,p_request,jsonb_build_object('student_id',st,'enrollment_id',en,'invoice_id',inv));
end $$;
create function public.issue_invoice(p_org uuid,p_request uuid,p_enrollment uuid,p_period date,p_due date) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; e public.enrollments; i uuid;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE','OPERATOR']);
 perform app_private.require_module(p_org,'FINANCE');
 r:=app_private.begin_command(p_org,p_request,'issue_invoice',jsonb_build_array(p_enrollment,p_period,p_due)); if r is not null then return r; end if;
 select * into e from public.enrollments where organization_id=p_org and id=p_enrollment and status='ACTIVE' for update;
 if not found or e.fee_frequency<>'MONTHLY' then raise exception 'Active monthly enrollment required'; end if;
 if p_period<>date_trunc('month',p_period)::date then raise exception 'Billing period must be first day of month'; end if;
 insert into public.invoices(organization_id,student_id,enrollment_id,invoice_number,billing_period,due_on,amount,description,fee_snapshot)
 values(p_org,e.student_id,e.id,app_private.next_number(p_org,'INVOICE'),p_period,p_due,e.agreed_fee,'Monthly tuition',e.agreement_snapshot) returning id into i;
 return app_private.end_command(p_org,p_request,jsonb_build_object('invoice_id',i));
end $$;
create function app_private.active_account(p_org uuid,p_account uuid) returns void
language plpgsql security definer set search_path='' as $$
begin
 perform 1 from public.money_accounts where organization_id=p_org and id=p_account and active for update;
 if not found then raise exception 'Active money account required'; end if;
end $$;
create function public.collect_payment(p_org uuid,p_request uuid,p_invoice uuid,p_account uuid,p_amount numeric,p_date date,p_reference text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; i public.invoices; pay uuid; n bigint;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE','OPERATOR']);
 perform app_private.require_module(p_org,'FINANCE');
 r:=app_private.begin_command(p_org,p_request,'collect_payment',jsonb_build_array(p_invoice,p_account,p_amount,p_date,p_reference)); if r is not null then return r; end if;
 select * into i from public.invoices where organization_id=p_org and id=p_invoice for update;
 if not found then raise exception 'Invoice not found'; end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) or p_amount>app_private.invoice_due(p_org,p_invoice) then raise exception 'Invalid amount or exceeds due'; end if;
 perform app_private.active_account(p_org,p_account);
 n:=app_private.next_number(p_org,'RECEIPT');
 insert into public.payments(organization_id,student_id,account_id,receipt_number,amount,paid_on,reference)
 values(p_org,i.student_id,p_account,n,p_amount,p_date,p_reference) returning id into pay;
 insert into public.payment_allocations(organization_id,payment_id,invoice_id,student_id,amount) values(p_org,pay,p_invoice,i.student_id,p_amount);
 insert into public.money_movements(organization_id,account_id,signed_amount,occurred_on,source_type,source_id,description)
 values(p_org,p_account,p_amount,p_date,'PAYMENT',pay,'Student collection');
 return app_private.end_command(p_org,p_request,jsonb_build_object('payment_id',pay,'receipt_number',n,'remaining_due',app_private.invoice_due(p_org,p_invoice)));
end $$;
create function public.credit_invoice(p_org uuid,p_request uuid,p_invoice uuid,p_amount numeric,p_kind text,p_reason text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; c uuid;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE']);
 perform app_private.require_module(p_org,'FINANCE');
 r:=app_private.begin_command(p_org,p_request,'credit_invoice',jsonb_build_array(p_invoice,p_amount,p_kind,p_reason)); if r is not null then return r; end if;
 perform 1 from public.invoices where organization_id=p_org and id=p_invoice for update;
 if not found then raise exception 'Invoice not found'; end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) or p_amount>app_private.invoice_due(p_org,p_invoice) then raise exception 'Credit exceeds outstanding due'; end if;
 insert into public.invoice_credits(organization_id,invoice_id,amount,kind,reason) values(p_org,p_invoice,p_amount,p_kind,p_reason) returning id into c;
 return app_private.end_command(p_org,p_request,jsonb_build_object('credit_id',c));
end $$;
create function public.refund_payment(p_org uuid,p_request uuid,p_allocation uuid,p_account uuid,p_amount numeric,p_date date,p_reason text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; a public.payment_allocations; re uuid;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE']);
 perform app_private.require_module(p_org,'FINANCE');
 r:=app_private.begin_command(p_org,p_request,'refund_payment',jsonb_build_array(p_allocation,p_account,p_amount,p_date,p_reason)); if r is not null then return r; end if;
 select * into a from public.payment_allocations where organization_id=p_org and id=p_allocation;
 if not found then raise exception 'Allocation not found'; end if;
 perform 1 from public.invoices where organization_id=p_org and id=a.invoice_id for update;
 perform 1 from public.payment_allocations where organization_id=p_org and id=a.id for update;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) or p_amount>a.amount-coalesce((select sum(amount) from public.refunds where organization_id=p_org and allocation_id=a.id),0) then raise exception 'Refund exceeds paid balance'; end if;
 perform app_private.active_account(p_org,p_account);
 insert into public.refunds(organization_id,allocation_id,account_id,amount,paid_on,reason) values(p_org,p_allocation,p_account,p_amount,p_date,p_reason) returning id into re;
 insert into public.money_movements(organization_id,account_id,signed_amount,occurred_on,source_type,source_id,description)
 values(p_org,p_account,-p_amount,p_date,'REFUND',re,p_reason);
 return app_private.end_command(p_org,p_request,jsonb_build_object('refund_id',re));
end $$;
create function public.record_expense(p_org uuid,p_request uuid,p_account uuid,p_amount numeric,p_date date,p_category text,p_description text,p_person uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; e uuid;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE']);
 perform app_private.require_module(p_org,'BUSINESS');
 r:=app_private.begin_command(p_org,p_request,'record_expense',jsonb_build_array(p_account,p_amount,p_date,p_category,p_description,p_person)); if r is not null then return r; end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) then raise exception 'Positive exact amount required'; end if;
 perform app_private.active_account(p_org,p_account);
 insert into public.expenses(organization_id,account_id,category,description,amount,paid_on,person_id)
 values(p_org,p_account,p_category,p_description,p_amount,p_date,p_person) returning id into e;
 insert into public.money_movements(organization_id,account_id,signed_amount,occurred_on,source_type,source_id,description)
 values(p_org,p_account,-p_amount,p_date,'EXPENSE',e,p_description);
 return app_private.end_command(p_org,p_request,jsonb_build_object('expense_id',e));
end $$;
create function public.transfer_money(p_org uuid,p_request uuid,p_from uuid,p_to uuid,p_amount numeric,p_date date) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; t uuid:=gen_random_uuid(); a uuid;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE']);
 perform app_private.require_module(p_org,'BUSINESS');
 r:=app_private.begin_command(p_org,p_request,'transfer_money',jsonb_build_array(p_from,p_to,p_amount,p_date)); if r is not null then return r; end if;
 if p_from=p_to or p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) then raise exception 'Distinct accounts and positive exact amount required'; end if;
 for a in select x from unnest(array[p_from,p_to]) x order by x loop perform app_private.active_account(p_org,a); end loop;
 insert into public.money_movements(organization_id,account_id,signed_amount,occurred_on,source_type,source_id,description)
 values(p_org,p_from,-p_amount,p_date,'TRANSFER',t,'Transfer out'),(p_org,p_to,p_amount,p_date,'TRANSFER',t,'Transfer in');
 return app_private.end_command(p_org,p_request,jsonb_build_object('transfer_id',t));
end $$;
create function public.record_payable(p_org uuid,p_request uuid,p_person uuid,p_amount numeric,p_date date,p_description text,p_work uuid default null,p_component text default 'MANUAL') returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; pay uuid; w public.work_items;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE']);
 perform app_private.require_module(p_org,'BUSINESS');
 r:=app_private.begin_command(p_org,p_request,'record_payable',jsonb_build_array(p_person,p_amount,p_date,p_description,p_work,p_component)); if r is not null then return r; end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) then raise exception 'Positive exact amount required'; end if;
 if p_work is not null then
 select * into w from public.work_items where organization_id=p_org and id=p_work for update;
 if not found or w.status<>'ACCEPTED' or w.person_id is distinct from p_person then raise exception 'Accepted work for this person required'; end if;
 end if;
 insert into public.payables(organization_id,person_id,work_item_id,component,amount,earned_on,description,agreement_snapshot)
 values(p_org,p_person,p_work,p_component,p_amount,p_date,p_description,coalesce(to_jsonb(w),'{}'::jsonb)) returning id into pay;
 return app_private.end_command(p_org,p_request,jsonb_build_object('payable_id',pay));
end $$;
create function app_private.payable_due(p_org uuid,p_payable uuid) returns numeric
language sql stable security definer set search_path='' as $$
 select p.amount-coalesce((select sum(s.amount) from public.settlements s where s.organization_id=p_org and s.payable_id=p.id),0)
 -coalesce((select sum(c.amount) from public.advance_clearings c where c.organization_id=p_org and c.payable_id=p.id),0)
 from public.payables p where p.organization_id=p_org and p.id=p_payable;
$$;
create function public.settle_payable(p_org uuid,p_request uuid,p_payable uuid,p_account uuid,p_amount numeric,p_date date) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; s uuid;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE']);
 perform app_private.require_module(p_org,'BUSINESS');
 r:=app_private.begin_command(p_org,p_request,'settle_payable',jsonb_build_array(p_payable,p_account,p_amount,p_date)); if r is not null then return r; end if;
 perform 1 from public.payables where organization_id=p_org and id=p_payable for update;
 if not found then raise exception 'Payable not found'; end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) or p_amount>app_private.payable_due(p_org,p_payable) then raise exception 'Settlement exceeds payable'; end if;
 perform app_private.active_account(p_org,p_account);
 insert into public.settlements(organization_id,payable_id,account_id,amount,paid_on) values(p_org,p_payable,p_account,p_amount,p_date) returning id into s;
 insert into public.money_movements(organization_id,account_id,signed_amount,occurred_on,source_type,source_id,description)
 values(p_org,p_account,-p_amount,p_date,'SETTLEMENT',s,'Payable settlement');
 return app_private.end_command(p_org,p_request,jsonb_build_object('settlement_id',s));
end $$;
-- New fresh-project public showcase; explicit safe columns only.
create function public.public_courses(p_slug text) returns table(offering_id uuid,name text,year_name text,branch_name text,intake_open boolean,monthly_or_one_time_fee numeric,frequency text)
language sql stable security definer set search_path='' as $$
 select o.id,o.name,y.name,b.name,o.intake_open,f.amount,f.frequency
 from public.offerings o join public.organizations n on n.id=o.organization_id
 join public.academic_years y on y.organization_id=o.organization_id and y.id=o.academic_year_id
 join public.branches b on b.organization_id=o.organization_id and b.id=o.branch_id
 left join public.fee_terms f on f.organization_id=o.organization_id and f.offering_id=o.id and f.active
 where n.slug=p_slug and o.public_visible and o.active;
$$;
-- Bootstrap new memberships via create_organization; no hard-coded academy/COA/demo seeds.
revoke all on all functions in schema public from public,anon,authenticated;
grant execute on function public.create_organization(text,text), public.set_member(uuid,uuid,text,boolean), public.set_module(uuid,text,boolean),
 public.create_course(uuid,uuid,jsonb),public.admit_student(uuid,uuid,jsonb),public.issue_invoice(uuid,uuid,uuid,date,date),
 public.collect_payment(uuid,uuid,uuid,uuid,numeric,date,text),public.credit_invoice(uuid,uuid,uuid,numeric,text,text),
 public.refund_payment(uuid,uuid,uuid,uuid,numeric,date,text),public.record_expense(uuid,uuid,uuid,numeric,date,text,text,uuid),
 public.transfer_money(uuid,uuid,uuid,uuid,numeric,date),public.record_payable(uuid,uuid,uuid,numeric,date,text,uuid,text),
 public.settle_payable(uuid,uuid,uuid,uuid,numeric,date) to authenticated;
grant execute on function public.public_courses(text) to anon,authenticated;
create function app_private.protect_identity() returns trigger language plpgsql set search_path='' as $$
begin
 if new.id is distinct from old.id or new.organization_id is distinct from old.organization_id or new.created_at is distinct from old.created_at then raise exception 'Identity and tenant are immutable'; end if;
 return new;
end $$;
create function app_private.validate_academic_row() returns trigger language plpgsql security definer set search_path='' as $$
declare batch uuid; sub uuid; other uuid; lim numeric; absent boolean;
begin
 if TG_TABLE_NAME in ('routine_slots','sessions') then
 select b.offering_id into other from public.batches b where b.organization_id=new.organization_id and b.id=new.batch_id;
 if not exists(select 1 from public.offering_subjects s where s.organization_id=new.organization_id and s.offering_id=other and s.subject_id=new.subject_id) then raise exception 'Subject not offered in batch'; end if;
 if not exists(select 1 from public.people p where p.organization_id=new.organization_id and p.id=new.teacher_id and p.kind='TEACHER' and p.active) then raise exception 'Active teacher required'; end if;
 elsif TG_TABLE_NAME='attendance' then
 select s.batch_id into batch from public.sessions s where s.organization_id=new.organization_id and s.id=new.session_id;
 select e.batch_id into other from public.enrollments e where e.organization_id=new.organization_id and e.id=new.enrollment_id;
 if batch is distinct from other then raise exception 'Attendance enrollment belongs to another batch'; end if;
 elsif TG_TABLE_NAME='session_topics' then
 select s.subject_id into sub from public.sessions s where s.organization_id=new.organization_id and s.id=new.session_id;
 select t.subject_id into other from public.topics t where t.organization_id=new.organization_id and t.id=new.topic_id;
 if sub is distinct from other then raise exception 'Topic belongs to another subject'; end if;
 elsif TG_TABLE_NAME='study_plan_items' then
 select b.offering_id into batch from public.batches b where b.organization_id=new.organization_id and b.id=new.batch_id;
 select t.subject_id into sub from public.topics t where t.organization_id=new.organization_id and t.id=new.topic_id;
 if not exists(select 1 from public.offering_subjects where organization_id=new.organization_id and offering_id=batch and subject_id=sub) then raise exception 'Plan topic subject not offered'; end if;
 elsif TG_TABLE_NAME='homework_reviews' then
 select s.batch_id into batch from public.homework h join public.sessions s on s.organization_id=h.organization_id and s.id=h.session_id where h.organization_id=new.organization_id and h.id=new.homework_id;
 select e.batch_id into other from public.enrollments e where e.organization_id=new.organization_id and e.id=new.enrollment_id;
 if batch is distinct from other then raise exception 'Homework enrollment belongs to another batch'; end if;
 elsif TG_TABLE_NAME='assessment_results' then
 select a.batch_id into batch from public.assessments a where a.organization_id=new.organization_id and a.id=new.assessment_id;
 select e.batch_id into other from public.enrollments e where e.organization_id=new.organization_id and e.id=new.enrollment_id;
 if batch is distinct from other then raise exception 'Assessment enrollment belongs to another batch'; end if;
 if new.absent and exists(select 1 from public.marks m where m.organization_id=new.organization_id and m.result_id=new.id) then raise exception 'Marked student cannot be absent'; end if;
 elsif TG_TABLE_NAME='assessment_items' then
 select a.subject_id into sub from public.assessments a where a.organization_id=new.organization_id and a.id=new.assessment_id;
 select t.subject_id into other from public.topics t where t.organization_id=new.organization_id and t.id=new.topic_id;
 if sub is distinct from other then raise exception 'Assessment topic subject mismatch'; end if;
 if new.question_id is not null and not exists(select 1 from public.questions q where q.organization_id=new.organization_id and q.id=new.question_id and q.topic_id=new.topic_id and q.reviewed) then raise exception 'Reviewed question for same topic required'; end if;
 if exists(select 1 from public.marks m where m.organization_id=new.organization_id and m.item_id=new.id and m.earned>new.marks) then raise exception 'Item maximum below existing marks'; end if;
 elsif TG_TABLE_NAME='marks' then
 select r.assessment_id,r.absent into batch,absent from public.assessment_results r where r.organization_id=new.organization_id and r.id=new.result_id for update;
 select i.assessment_id,i.marks into other,lim from public.assessment_items i where i.organization_id=new.organization_id and i.id=new.item_id for update;
 if batch is distinct from other or absent or new.earned>lim then raise exception 'Invalid assessment mark'; end if;
 end if;
 return new;
end $$;
create function app_private.protect_purchase() returns trigger language plpgsql set search_path='' as $$
begin
 if old.status<>'DRAFT' then raise exception 'Received/cancelled purchase evidence cannot be edited'; end if;
 -- Only receipt RPC can finalize; trigger also checks resulting payable via deferred check below.
 return new;
end $$;
create function app_private.protect_prospect_stage() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.stage='ADMITTED' and not exists(select 1 from public.enrollments where organization_id=new.organization_id and prospect_id=new.id) then raise exception 'Admission conversion required'; end if;
 if TG_OP='UPDATE' and old.stage='ADMITTED' and new.stage<>'ADMITTED' then raise exception 'Converted prospect history cannot be reopened'; end if;
 return new;
end $$;
create function public.opening_balance(p_org uuid,p_request uuid,p_account uuid,p_amount numeric,p_date date) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; source uuid:=gen_random_uuid();
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE']);
 r:=app_private.begin_command(p_org,p_request,'opening_balance',jsonb_build_array(p_account,p_amount,p_date)); if r is not null then return r; end if;
 perform app_private.active_account(p_org,p_account);
 if exists(select 1 from public.money_movements where organization_id=p_org and account_id=p_account) then raise exception 'Opening must precede account movements'; end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) then raise exception 'Positive exact opening required; zero needs no entry'; end if;
 insert into public.money_movements(organization_id,account_id,signed_amount,occurred_on,source_type,source_id,description)
 values(p_org,p_account,p_amount,p_date,'OPENING',source,'Opening balance');
 return app_private.end_command(p_org,p_request,jsonb_build_object('source_id',source));
end $$;
create function public.receive_purchase(p_org uuid,p_request uuid,p_purchase uuid,p_received date) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; p public.purchases; pay uuid;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE']);
 perform app_private.require_module(p_org,'BUSINESS');
 r:=app_private.begin_command(p_org,p_request,'receive_purchase',jsonb_build_array(p_purchase,p_received)); if r is not null then return r; end if;
 select * into p from public.purchases where organization_id=p_org and id=p_purchase for update;
 if not found or p.status<>'DRAFT' then raise exception 'Draft purchase required'; end if;
 if p_received is null or p_received<p.purchased_on then raise exception 'Valid receipt date required'; end if;
 update public.purchases set status='RECEIVED',received_on=p_received where organization_id=p_org and id=p_purchase;
 insert into public.payables(organization_id,person_id,purchase_id,component,amount,earned_on,description,agreement_snapshot)
 values(p_org,p.supplier_id,p.id,'PURCHASE',p.amount,p_received,p.description,to_jsonb(p)) returning id into pay;
 return app_private.end_command(p_org,p_request,jsonb_build_object('payable_id',pay));
end $$;
create function app_private.validate_asset() returns trigger language plpgsql security definer set search_path='' as $$
declare p public.purchases; total numeric;
begin
 if TG_OP='UPDATE' and (old.status='DISPOSED' or new.cost<>old.cost or new.purchase_id is distinct from old.purchase_id or new.acquired_on<>old.acquired_on) then raise exception 'Asset acquisition/disposed history immutable'; end if;
 if new.purchase_id is not null then
 select * into p from public.purchases where organization_id=new.organization_id and id=new.purchase_id for update;
 if not found or p.status<>'RECEIVED' or p.classification<>'ASSET' then raise exception 'Received asset purchase required'; end if;
 select coalesce(sum(cost),0) into total from public.assets where organization_id=new.organization_id and purchase_id=new.purchase_id and id<>new.id;
 if total+new.cost>p.amount then raise exception 'Asset cost exceeds purchase total'; end if;
 end if;
 return new;
end $$;
create function public.give_advance(p_org uuid,p_request uuid,p_person uuid,p_account uuid,p_amount numeric,p_date date,p_reason text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; a uuid;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE']);
 perform app_private.require_module(p_org,'BUSINESS');
 r:=app_private.begin_command(p_org,p_request,'give_advance',jsonb_build_array(p_person,p_account,p_amount,p_date,p_reason)); if r is not null then return r; end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) then raise exception 'Positive exact amount required'; end if;
 perform app_private.active_account(p_org,p_account);
 if not exists(select 1 from public.people where organization_id=p_org and id=p_person and active and kind in ('TEACHER','STAFF')) then raise exception 'Active staff/teacher required'; end if;
 insert into public.staff_advances(organization_id,person_id,account_id,amount,paid_on,reason) values(p_org,p_person,p_account,p_amount,p_date,p_reason) returning id into a;
 insert into public.money_movements(organization_id,account_id,signed_amount,occurred_on,source_type,source_id,description) values(p_org,p_account,-p_amount,p_date,'ADVANCE',a,p_reason);
 return app_private.end_command(p_org,p_request,jsonb_build_object('advance_id',a));
end $$;
create function public.clear_advance(p_org uuid,p_request uuid,p_advance uuid,p_amount numeric,p_date date,p_payable uuid default null,p_return_account uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; a public.staff_advances; person uuid; c uuid;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE']);
 perform app_private.require_module(p_org,'BUSINESS');
 r:=app_private.begin_command(p_org,p_request,'clear_advance',jsonb_build_array(p_advance,p_amount,p_date,p_payable,p_return_account)); if r is not null then return r; end if;
 if (p_payable is null)=(p_return_account is null) then raise exception 'Choose payable offset or cash return'; end if;
 if p_payable is not null then
 select person_id into person from public.payables where organization_id=p_org and id=p_payable for update;
 if not found then raise exception 'Payable not found'; end if;
 end if;
 select * into a from public.staff_advances where organization_id=p_org and id=p_advance for update;
 if not found then raise exception 'Advance not found'; end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) or p_amount>a.amount-coalesce((select sum(amount) from public.advance_clearings where organization_id=p_org and advance_id=p_advance),0) then raise exception 'Clearing exceeds advance'; end if;
 if p_payable is not null then
 if person is distinct from a.person_id or p_amount>app_private.payable_due(p_org,p_payable) then raise exception 'Payable balance/person mismatch'; end if;
 else perform app_private.active_account(p_org,p_return_account);
 end if;
 insert into public.advance_clearings(organization_id,advance_id,payable_id,account_id,amount,cleared_on)
 values(p_org,p_advance,p_payable,p_return_account,p_amount,p_date) returning id into c;
 if p_return_account is not null then
 insert into public.money_movements(organization_id,account_id,signed_amount,occurred_on,source_type,source_id,description)
 values(p_org,p_return_account,p_amount,p_date,'ADVANCE_RETURN',c,'Advance returned');
 end if;
 return app_private.end_command(p_org,p_request,jsonb_build_object('clearing_id',c));
end $$;
-- Teachers receive only assigned session context, never general finance/student registers.
create function public.teacher_sessions(p_org uuid,p_from timestamptz,p_to timestamptz) returns setof public.sessions
language plpgsql stable security definer set search_path='' as $$
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','ACADEMIC','TEACHER']);
 if p_to<=p_from or p_to-p_from>interval '31 days' then raise exception 'Select up to 31 days'; end if;
 return query select s.* from public.sessions s join public.people p on p.organization_id=s.organization_id and p.id=s.teacher_id
 where s.organization_id=p_org and s.starts_at>=p_from and s.starts_at<p_to
 and (p.user_id=auth.uid() or app_private.has_role(p_org,array['OWNER','ADMIN','ACADEMIC']));
end $$;
create function public.complete_session(p_org uuid,p_request uuid,p_session uuid,p_data jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; s public.sessions; x jsonb;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','ACADEMIC','TEACHER']);
 perform app_private.require_module(p_org,'ACADEMIC');
 r:=app_private.begin_command(p_org,p_request,'complete_session',jsonb_build_array(p_session,p_data)); if r is not null then return r; end if;
 select * into s from public.sessions where organization_id=p_org and id=p_session for update;
 if not found or s.status<>'PLANNED' then raise exception 'Planned session required'; end if;
 if not app_private.has_role(p_org,array['OWNER','ADMIN','ACADEMIC']) and not exists(select 1 from public.people where organization_id=p_org and id=s.teacher_id and user_id=auth.uid()) then raise exception 'Session is not assigned to you' using errcode='42501'; end if;
 if jsonb_typeof(p_data->'attendance') is distinct from 'array' or jsonb_typeof(p_data->'topics') is distinct from 'array' then raise exception 'Attendance/topics arrays required'; end if;
 for x in select jsonb_array_elements(p_data->'attendance') loop
 insert into public.attendance(organization_id,session_id,enrollment_id,status) values(p_org,s.id,(x->>'enrollment_id')::uuid,x->>'status')
 on conflict(organization_id,session_id,enrollment_id) do update set status=excluded.status;
 end loop;
 for x in select jsonb_array_elements(p_data->'topics') loop
 insert into public.session_topics(organization_id,session_id,topic_id,coverage_percent) values(p_org,s.id,(x->>'topic_id')::uuid,(x->>'coverage_percent')::numeric)
 on conflict(organization_id,session_id,topic_id) do update set coverage_percent=excluded.coverage_percent;
 end loop;
 if p_data->>'homework' is not null then insert into public.homework(organization_id,session_id,instructions,due_on) values(p_org,s.id,p_data->>'homework',(p_data->>'homework_due_on')::date); end if;
 update public.sessions set status='COMPLETED',notes=p_data->>'notes' where organization_id=p_org and id=s.id;
 return app_private.end_command(p_org,p_request,jsonb_build_object('session_id',s.id));
end $$;
create table public.accounting_periods (
 organization_id uuid not null references public.organizations(id), month date not null,
 closed boolean not null default false, primary key(organization_id,month), check(month=date_trunc('month',month)::date)
);
alter table public.accounting_periods enable row level security;
create policy accounting_period_read on public.accounting_periods for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']));
grant select on public.accounting_periods to authenticated;
create function public.set_accounting_period(p_org uuid,p_month date,p_closed boolean) returns void
language plpgsql security definer set search_path='' as $$
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','FINANCE']);
 perform app_private.require_module(p_org,'ACCOUNTING');
 perform 1 from public.organizations where id=p_org for update;
 insert into public.accounting_periods values(p_org,p_month,p_closed) on conflict(organization_id,month) do update set closed=excluded.closed;
end $$;
create function app_private.assert_balanced_journal() returns trigger language plpgsql security definer set search_path='' as $$
declare j uuid; o uuid; n bigint; delta numeric;
begin
 if TG_TABLE_NAME='journals' then j:=new.id; else j:=new.journal_id; end if; o:=new.organization_id;
 select count(*),coalesce(sum(debit-credit),0) into n,delta from public.journal_lines where organization_id=o and journal_id=j;
 if n<2 or delta<>0 then raise exception 'Journal must have at least two balanced lines'; end if;
 return null;
end $$;
create constraint trigger balanced_header after insert on public.journals deferrable initially deferred for each row execute function app_private.assert_balanced_journal();
create constraint trigger balanced_lines after insert on public.journal_lines deferrable initially deferred for each row execute function app_private.assert_balanced_journal();
create function public.project_journal(p_org uuid,p_event uuid,p_date date,p_description text,p_lines jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare j uuid; old_j public.journals; x jsonb; n integer; dr numeric; cr numeric;
begin
 -- Only trusted worker/service credentials are granted this entry point.
 perform app_private.require_module(p_org,'ACCOUNTING');
 perform 1 from public.organizations where id=p_org for update;
 if exists(select 1 from public.accounting_periods where organization_id=p_org and month=date_trunc('month',p_date)::date and closed) then raise exception 'Accounting period closed; source transaction is unchanged'; end if;
 perform 1 from public.outbox_events where organization_id=p_org and id=p_event for update;
 if not found then raise exception 'Tenant event required'; end if;
 select * into old_j from public.journals where organization_id=p_org and event_id=p_event;
 if found then
 if old_j.projection_snapshot is distinct from jsonb_build_array(p_date,p_description,p_lines) then raise exception 'Event projection inputs changed'; end if;
 return old_j.id;
 end if;
 if jsonb_typeof(p_lines) is distinct from 'array' or jsonb_array_length(p_lines)<2 then raise exception 'At least two lines required'; end if;
 insert into public.journals(organization_id,event_id,posted_on,description,projection_snapshot)
 values(p_org,p_event,p_date,p_description,jsonb_build_array(p_date,p_description,p_lines)) returning id into j;
 for x in select jsonb_array_elements(p_lines) loop
 dr:=coalesce((x->>'debit')::numeric,0); cr:=coalesce((x->>'credit')::numeric,0);
 if dr<>round(dr,2) or cr<>round(cr,2) then raise exception 'Exact currency precision required'; end if;
 if not exists(select 1 from public.accounting_accounts where organization_id=p_org and id=(x->>'account_id')::uuid and active) then raise exception 'Active tenant accounting account required'; end if;
 insert into public.journal_lines(organization_id,journal_id,account_id,debit,credit) values(p_org,j,(x->>'account_id')::uuid,dr,cr);
 end loop;
 select sum(debit-credit) into dr from public.journal_lines where organization_id=p_org and journal_id=j;
 if dr<>0 then raise exception 'Unbalanced projection'; end if;
 return j;
end $$;
-- Clients cannot directly finalize a purchase: a corresponding liability is required.
create function app_private.purchase_receipt_complete() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.status='RECEIVED' and not exists(select 1 from public.payables where organization_id=new.organization_id and purchase_id=new.id and amount=new.amount) then raise exception 'Receipt must create purchase payable atomically'; end if;
 return null;
end $$;
create constraint trigger purchase_receipt_evidence after insert or update on public.purchases deferrable initially deferred for each row execute function app_private.purchase_receipt_complete();
-- Do not allow historical academic references to be moved to a different batch/test.
create function app_private.protect_academic_reference() returns trigger language plpgsql set search_path='' as $$
begin
 if TG_TABLE_NAME='sessions' then
  if new.batch_id<>old.batch_id or new.subject_id<>old.subject_id or (old.status<>'PLANNED' and new.status<>old.status) then raise exception 'Historical session placement/status cannot change'; end if;
 elsif TG_TABLE_NAME='assessment_items' then
  if new.assessment_id<>old.assessment_id or new.topic_id<>old.topic_id then raise exception 'Assessment item placement immutable'; end if;
 elsif TG_TABLE_NAME='assessment_results' then
  if new.assessment_id<>old.assessment_id or new.enrollment_id<>old.enrollment_id then raise exception 'Assessment result placement immutable'; end if;
 end if;
 return new;
end $$;
create trigger protect_purchase before update on public.purchases for each row execute function app_private.protect_purchase();
create trigger asset_integrity before insert or update on public.assets for each row execute function app_private.validate_asset();
create trigger prospect_conversion before insert or update on public.prospects for each row execute function app_private.protect_prospect_stage();

create trigger tenant_identity before update on public.branches for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.academic_years for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.class_levels for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.class_groups for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.subjects for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.people for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.programmes for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.offerings for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.offering_subjects for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.fee_terms for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.batches for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.prospects for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.followups for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.students for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.enrollments for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.routine_slots for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.topics for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.study_plan_items for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.sessions for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.session_topics for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.attendance for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.homework for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.homework_reviews for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.questions for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.assessments for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.assessment_items for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.assessment_results for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.marks for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.work_items for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.compensation_terms for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.money_accounts for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.invoices for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.invoice_credits for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.payments for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.payment_allocations for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.refunds for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.purchases for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.payables for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.settlements for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.expenses for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.money_movements for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.staff_advances for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.advance_clearings for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.assets for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.asset_maintenance for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.documents for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.outbox_events for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.accounting_accounts for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.journals for each row execute function app_private.protect_identity();
create trigger tenant_identity before update on public.journal_lines for each row execute function app_private.protect_identity();
create trigger academic_integrity before insert or update on public.routine_slots for each row execute function app_private.validate_academic_row();
create trigger academic_integrity before insert or update on public.sessions for each row execute function app_private.validate_academic_row();
create trigger academic_integrity before insert or update on public.session_topics for each row execute function app_private.validate_academic_row();
create trigger academic_integrity before insert or update on public.study_plan_items for each row execute function app_private.validate_academic_row();
create trigger academic_integrity before insert or update on public.attendance for each row execute function app_private.validate_academic_row();
create trigger academic_integrity before insert or update on public.homework_reviews for each row execute function app_private.validate_academic_row();
create trigger academic_integrity before insert or update on public.assessment_results for each row execute function app_private.validate_academic_row();
create trigger academic_integrity before insert or update on public.assessment_items for each row execute function app_private.validate_academic_row();
create trigger academic_integrity before insert or update on public.marks for each row execute function app_private.validate_academic_row();
create trigger academic_reference before update on public.sessions for each row execute function app_private.protect_academic_reference();
create trigger academic_reference before update on public.assessment_items for each row execute function app_private.protect_academic_reference();
create trigger academic_reference before update on public.assessment_results for each row execute function app_private.protect_academic_reference();
-- Explicit final grants: no private command helpers or unapproved public RPCs.
revoke all on all functions in schema app_private from public,anon,authenticated;
grant execute on function app_private.has_role(uuid,text[]) to authenticated;
revoke all on function public.opening_balance(uuid,uuid,uuid,numeric,date),public.receive_purchase(uuid,uuid,uuid,date),
 public.give_advance(uuid,uuid,uuid,uuid,numeric,date,text), public.clear_advance(uuid,uuid,uuid,numeric,date,uuid,uuid),
 public.teacher_sessions(uuid,timestamptz,timestamptz),public.complete_session(uuid,uuid,uuid,jsonb),
 public.set_accounting_period(uuid,date,boolean),public.project_journal(uuid,uuid,date,text,jsonb) from public,anon,authenticated;
grant execute on function public.opening_balance(uuid,uuid,uuid,numeric,date),public.receive_purchase(uuid,uuid,uuid,date),
 public.give_advance(uuid,uuid,uuid,uuid,numeric,date,text), public.clear_advance(uuid,uuid,uuid,numeric,date,uuid,uuid),
 public.teacher_sessions(uuid,timestamptz,timestamptz),public.complete_session(uuid,uuid,uuid,jsonb),
 public.set_accounting_period(uuid,date,boolean) to authenticated;
grant execute on function public.project_journal(uuid,uuid,date,text,jsonb) to service_role;
-- Supabase's service role is server-only. It is never used by browser clients.
grant usage on schema public,app_private to service_role;
grant all on all tables in schema public,app_private to service_role;
grant usage,select on all sequences in schema public to service_role;
-- Private uploads must live under <organization UUID>/... in this one private bucket.
insert into storage.buckets(id,name,public) values('eduops-documents','eduops-documents',false);
create policy eduops_document_read on storage.objects for select to authenticated using(
 bucket_id='eduops-documents' and exists(select 1 from public.memberships m
 where m.organization_id::text=split_part(name,'/',1) and m.user_id=auth.uid() and m.active and m.role in ('OWNER','ADMIN','FINANCE'))
);
create policy eduops_document_insert on storage.objects for insert to authenticated with check(
 bucket_id='eduops-documents' and exists(select 1 from public.memberships m
 where m.organization_id::text=split_part(name,'/',1) and m.user_id=auth.uid() and m.active and m.role in ('OWNER','ADMIN','FINANCE'))
);
-- No overwrite/delete storage policies: retained financial documents are append-only.
-- Read history remains available when a module is disabled; new module writes stop.
create function app_private.module_enabled(p_org uuid,p_module text) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.organization_modules where organization_id=p_org and module=p_module and enabled);
$$;
revoke all on function app_private.module_enabled(uuid,text) from public,anon,authenticated;
grant execute on function app_private.module_enabled(uuid,text) to authenticated;
-- Immutable source evidence must match the operational movement, independent of accounting.
create function app_private.validate_money_source() returns trigger language plpgsql security definer set search_path='' as $$
declare amt numeric; acct uuid; dt date;
begin
 if new.source_type='PAYMENT' then select amount,account_id,paid_on into amt,acct,dt from public.payments where organization_id=new.organization_id and id=new.source_id;
 elsif new.source_type='REFUND' then select -amount,account_id,paid_on into amt,acct,dt from public.refunds where organization_id=new.organization_id and id=new.source_id;
 elsif new.source_type='EXPENSE' then select -amount,account_id,paid_on into amt,acct,dt from public.expenses where organization_id=new.organization_id and id=new.source_id;
 elsif new.source_type='SETTLEMENT' then select -amount,account_id,paid_on into amt,acct,dt from public.settlements where organization_id=new.organization_id and id=new.source_id;
 elsif new.source_type='ADVANCE' then select -amount,account_id,paid_on into amt,acct,dt from public.staff_advances where organization_id=new.organization_id and id=new.source_id;
 elsif new.source_type='ADVANCE_RETURN' then select amount,account_id,cleared_on into amt,acct,dt from public.advance_clearings where organization_id=new.organization_id and id=new.source_id and account_id is not null;
 elsif new.source_type='ASSET_SALE' then raise exception 'Asset sale command is not yet implemented';
 else return new;
 end if;
 if amt is distinct from new.signed_amount or acct is distinct from new.account_id or dt is distinct from new.occurred_on then raise exception 'Movement must match tenant source amount/account/date'; end if;
 return new;
end $$;
create trigger source_integrity before insert on public.money_movements for each row execute function app_private.validate_money_source();
create function app_private.assert_transfer_balanced() returns trigger language plpgsql security definer set search_path='' as $$
declare n bigint; delta numeric;
begin
 if new.source_type='TRANSFER' then
 select count(*),sum(signed_amount) into n,delta from public.money_movements where organization_id=new.organization_id and source_type='TRANSFER' and source_id=new.source_id;
 if n<>2 or delta<>0 then raise exception 'Transfer must have two balanced legs'; end if;
 end if;
 return null;
end $$;
create constraint trigger transfer_integrity after insert on public.money_movements deferrable initially deferred for each row execute function app_private.assert_transfer_balanced();
create function app_private.assert_payment_allocated() returns trigger language plpgsql security definer set search_path='' as $$
declare pid uuid; o uuid; expected numeric; actual numeric;
begin
 if TG_TABLE_NAME='payments' then pid:=new.id; else pid:=new.payment_id; end if; o:=new.organization_id;
 select amount into expected from public.payments where organization_id=o and id=pid;
 select coalesce(sum(amount),0) into actual from public.payment_allocations where organization_id=o and payment_id=pid;
 if expected is distinct from actual then raise exception 'Payment must be fully allocated in baseline'; end if;
 return null;
end $$;
create constraint trigger payment_full_allocation after insert on public.payments deferrable initially deferred for each row execute function app_private.assert_payment_allocated();
create constraint trigger allocation_total after insert on public.payment_allocations deferrable initially deferred for each row execute function app_private.assert_payment_allocated();
-- Narrow defaults explicitly: hosted Supabase may auto-grant newly created public tables.
revoke all on all tables in schema public from anon,authenticated;
revoke all on all sequences in schema public from anon,authenticated;
revoke all on all tables in schema app_private from public,anon,authenticated;
revoke all on function app_private.validate_money_source(),app_private.assert_transfer_balanced(),app_private.assert_payment_allocated() from public,anon,authenticated;
grant select on public.branches to authenticated;
grant insert,update on public.branches to authenticated;
grant select on public.academic_years to authenticated;
grant insert,update on public.academic_years to authenticated;
grant select on public.class_levels to authenticated;
grant insert,update on public.class_levels to authenticated;
grant select on public.class_groups to authenticated;
grant insert,update on public.class_groups to authenticated;
grant select on public.subjects to authenticated;
grant insert,update on public.subjects to authenticated;
grant select on public.people to authenticated;
grant insert,update on public.people to authenticated;
grant select on public.programmes to authenticated;
grant insert,update on public.programmes to authenticated;
grant select on public.offerings to authenticated;
grant insert,update on public.offerings to authenticated;
grant select on public.offering_subjects to authenticated;
grant insert,update on public.offering_subjects to authenticated;
grant select on public.fee_terms to authenticated;
grant insert,update on public.fee_terms to authenticated;
grant select on public.batches to authenticated;
grant insert,update on public.batches to authenticated;
grant select on public.prospects to authenticated;
grant insert,update on public.prospects to authenticated;
grant select on public.followups to authenticated;
grant insert,update on public.followups to authenticated;
grant select on public.students to authenticated;
grant select on public.enrollments to authenticated;
grant select on public.routine_slots to authenticated;
grant insert,update on public.routine_slots to authenticated;
grant select on public.topics to authenticated;
grant insert,update on public.topics to authenticated;
grant select on public.study_plan_items to authenticated;
grant insert,update on public.study_plan_items to authenticated;
grant select on public.sessions to authenticated;
grant insert,update on public.sessions to authenticated;
grant select on public.session_topics to authenticated;
grant insert,update on public.session_topics to authenticated;
grant select on public.attendance to authenticated;
grant insert,update on public.attendance to authenticated;
grant select on public.homework to authenticated;
grant insert,update on public.homework to authenticated;
grant select on public.homework_reviews to authenticated;
grant insert,update on public.homework_reviews to authenticated;
grant select on public.questions to authenticated;
grant insert,update on public.questions to authenticated;
grant select on public.assessments to authenticated;
grant insert,update on public.assessments to authenticated;
grant select on public.assessment_items to authenticated;
grant insert,update on public.assessment_items to authenticated;
grant select on public.assessment_results to authenticated;
grant insert,update on public.assessment_results to authenticated;
grant select on public.marks to authenticated;
grant insert,update on public.marks to authenticated;
grant select on public.work_items to authenticated;
grant insert,update on public.work_items to authenticated;
grant select on public.compensation_terms to authenticated;
grant insert,update on public.compensation_terms to authenticated;
grant select on public.money_accounts to authenticated;
grant insert,update on public.money_accounts to authenticated;
grant select on public.invoices to authenticated;
grant select on public.invoice_credits to authenticated;
grant select on public.payments to authenticated;
grant select on public.payment_allocations to authenticated;
grant select on public.refunds to authenticated;
grant select on public.purchases to authenticated;
grant insert,update on public.purchases to authenticated;
grant select on public.payables to authenticated;
grant select on public.settlements to authenticated;
grant select on public.expenses to authenticated;
grant select on public.money_movements to authenticated;
grant select on public.staff_advances to authenticated;
grant select on public.advance_clearings to authenticated;
grant select on public.assets to authenticated;
grant insert,update on public.assets to authenticated;
grant select on public.asset_maintenance to authenticated;
grant insert,update on public.asset_maintenance to authenticated;
grant select on public.documents to authenticated;
grant insert,update on public.documents to authenticated;
grant select on public.outbox_events to authenticated;
grant select on public.accounting_accounts to authenticated;
grant insert,update on public.accounting_accounts to authenticated;
grant select on public.journals to authenticated;
grant select on public.journal_lines to authenticated;
grant select on public.organizations,public.memberships,public.organization_modules,public.audit_events to authenticated;
grant select on public.accounting_periods to authenticated;
alter policy tenant_insert on public.offerings with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.offerings using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.offering_subjects with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.offering_subjects using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.fee_terms with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.fee_terms using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.batches with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.batches using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.routine_slots with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.routine_slots using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.topics with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.topics using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.study_plan_items with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.study_plan_items using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.sessions with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.sessions using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.session_topics with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.session_topics using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.attendance with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.attendance using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.homework with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.homework using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.homework_reviews with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.homework_reviews using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.questions with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.questions using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.assessments with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.assessments using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.assessment_items with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.assessment_items using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.assessment_results with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.assessment_results using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.marks with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.marks using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.work_items with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_update on public.work_items using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC']) and app_private.module_enabled(organization_id,'ACADEMIC'));
alter policy tenant_insert on public.prospects with check(app_private.has_role(organization_id,array['OWNER','ADMIN','OPERATOR']) and app_private.module_enabled(organization_id,'CRM'));
alter policy tenant_update on public.prospects using(app_private.has_role(organization_id,array['OWNER','ADMIN','OPERATOR']) and app_private.module_enabled(organization_id,'CRM')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','OPERATOR']) and app_private.module_enabled(organization_id,'CRM'));
alter policy tenant_insert on public.followups with check(app_private.has_role(organization_id,array['OWNER','ADMIN','OPERATOR']) and app_private.module_enabled(organization_id,'CRM'));
alter policy tenant_update on public.followups using(app_private.has_role(organization_id,array['OWNER','ADMIN','OPERATOR']) and app_private.module_enabled(organization_id,'CRM')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','OPERATOR']) and app_private.module_enabled(organization_id,'CRM'));
alter policy tenant_insert on public.purchases with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS'));
alter policy tenant_update on public.purchases using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS'));
alter policy tenant_insert on public.assets with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS'));
alter policy tenant_update on public.assets using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS'));
alter policy tenant_insert on public.asset_maintenance with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS'));
alter policy tenant_update on public.asset_maintenance using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS'));
alter policy tenant_insert on public.documents with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS'));
alter policy tenant_update on public.documents using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS'));
alter policy tenant_insert on public.compensation_terms with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS'));
alter policy tenant_update on public.compensation_terms using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'BUSINESS'));
alter policy tenant_insert on public.money_accounts with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'FINANCE'));
alter policy tenant_update on public.money_accounts using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'FINANCE')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'FINANCE'));
alter policy tenant_insert on public.accounting_accounts with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'ACCOUNTING'));
alter policy tenant_update on public.accounting_accounts using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'ACCOUNTING')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE']) and app_private.module_enabled(organization_id,'ACCOUNTING'));
alter policy tenant_read on public.students using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE','OPERATOR']));
alter policy tenant_read on public.enrollments using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE','OPERATOR']));
alter policy tenant_read on public.invoices using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE','OPERATOR']));
alter policy tenant_read on public.invoice_credits using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE','OPERATOR']));
alter policy tenant_read on public.payments using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE','OPERATOR']));
alter policy tenant_read on public.payment_allocations using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE','OPERATOR']));
alter policy tenant_read on public.refunds using(app_private.has_role(organization_id,array['OWNER','ADMIN','FINANCE','OPERATOR']));

alter table public.fee_terms add constraint fee_terms_amount_finite check(amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.enrollments add constraint enrollments_agreed_fee_finite check(agreed_fee not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.topics add constraint topics_weight_finite check(weight not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.session_topics add constraint session_topics_coverage_percent_finite check(coverage_percent not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.questions add constraint questions_marks_finite check(marks not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.assessment_items add constraint assessment_items_marks_finite check(marks not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.marks add constraint marks_earned_finite check(earned not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.work_items add constraint work_items_quantity_finite check(quantity not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.compensation_terms add constraint compensation_terms_rate_finite check(rate not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.invoices add constraint invoices_amount_finite check(amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.invoice_credits add constraint invoice_credits_amount_finite check(amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.payments add constraint payments_amount_finite check(amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.payment_allocations add constraint payment_allocations_amount_finite check(amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.refunds add constraint refunds_amount_finite check(amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.purchases add constraint purchases_amount_finite check(amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.payables add constraint payables_amount_finite check(amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.settlements add constraint settlements_amount_finite check(amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.expenses add constraint expenses_amount_finite check(amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.money_movements add constraint money_movements_signed_amount_finite check(signed_amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.staff_advances add constraint staff_advances_amount_finite check(amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.advance_clearings add constraint advance_clearings_amount_finite check(amount not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.assets add constraint assets_cost_finite check(cost not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.journal_lines add constraint journal_lines_debit_finite check(debit not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
alter table public.journal_lines add constraint journal_lines_credit_finite check(credit not in ('NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric));
commit;
