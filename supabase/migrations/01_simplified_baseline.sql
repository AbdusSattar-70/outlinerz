-- Fresh database only: Sohoj academic ERP in public, isolated branches, demo opt-in.
-- Financial stores and permissions are removed before this transaction commits.
set search_path=public,extensions;
-- Upstream 01_platform_identity_access.sql
-- Sohoj Academy fresh database baseline: platform identity access.
-- Install on an empty application schema. Each object is defined once.

create extension if not exists pgcrypto;

create type public.approval_status as enum ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');

create type public.enrollment_status as enum ('ACTIVE', 'COMPLETED', 'WITHDRAWN', 'CANCELLED');

create type public.offering_status as enum ('DRAFT', 'ACTIVE', 'RETIRED');

create type public.profile_status as enum ('ACTIVE', 'SUSPENDED', 'ARCHIVED');

create type public.prospect_status as enum ('NEW', 'CONTACTED', 'COUNSELLING', 'TRIAL_SCHEDULED', 'TRIAL_ATTENDED', 'REGISTERED', 'CONVERTED', 'FUTURE_FOLLOW_UP', 'LOST');

create type public.rule_status as enum ('DRAFT', 'ACTIVE', 'RETIRED');

create type public.staff_status as enum ('ACTIVE', 'ON_LEAVE', 'RESIGNED', 'TERMINATED', 'ARCHIVED');

create type public.student_status as enum ('ACTIVE', 'INACTIVE', 'WITHDRAWN', 'GRADUATED', 'ARCHIVED');

create sequence public.staff_no_seq start with 1;

create sequence public.prospect_no_seq start with 1;

create sequence public.student_no_seq start with 1;

create sequence public.admission_no_seq start with 1;

create sequence public.invoice_no_seq start with 1;

create sequence public.admission_receipt_no_seq start with 1;

create sequence public.refund_no_seq start with 1;

create sequence public.general_ledger_journal_no_seq start with 1;

create sequence public.vendor_no_seq start with 1;

create sequence public.finance_payable_no_seq start with 1;

create sequence public.finance_advance_no_seq start with 1;

create sequence public.finance_expense_no_seq start with 1;

create sequence public.teacher_compensation_run_no_seq start with 1;

CREATE OR REPLACE FUNCTION public.generate_staff_no()
 RETURNS text
 LANGUAGE sql
AS $function$
  select 'SA-STF-' || lpad(nextval('public.staff_no_seq')::text, 6, '0');
$function$
;

CREATE OR REPLACE FUNCTION public.generate_prospect_no()
 RETURNS text
 LANGUAGE sql
AS $function$
  select 'PR-' || lpad(nextval('public.prospect_no_seq')::text, 6, '0');
$function$
;

CREATE OR REPLACE FUNCTION public.generate_student_no()
 RETURNS text
 LANGUAGE sql
AS $function$
  select 'SA-' || lpad(nextval('public.student_no_seq')::text, 6, '0');
$function$
;

create table public.organizations (
  id uuid default gen_random_uuid() not null,
  code text not null,
  name text not null,
  timezone text default 'Asia/Dhaka'::text not null,
  currency_code text default 'BDT'::text not null,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  setup_completed_at timestamp with time zone,
  setup_completed_by uuid,
  setup_identity_confirmed_at timestamp with time zone
);

create table public.branches (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  address text,
  timezone text default 'Asia/Dhaka'::text not null,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.profiles (
  id uuid not null,
  display_name text not null,
  status profile_status default 'ACTIVE'::profile_status not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.system_roles (
  id uuid default gen_random_uuid() not null,
  code text not null,
  name text not null,
  description text,
  is_system boolean default true not null,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null
);

create table public.permissions (
  id uuid default gen_random_uuid() not null,
  code text not null,
  name text not null,
  description text,
  created_at timestamp with time zone default now() not null
);

create table public.role_permissions (
  role_id uuid not null,
  permission_id uuid not null,
  created_at timestamp with time zone default now() not null
);

create table public.user_role_assignments (
  id uuid default gen_random_uuid() not null,
  profile_id uuid not null,
  role_id uuid not null,
  branch_id uuid,
  effective_from date default CURRENT_DATE not null,
  effective_to date,
  is_active boolean default true not null,
  assigned_by uuid,
  created_at timestamp with time zone default now() not null
);

create table public.staff (
  id uuid default gen_random_uuid() not null,
  staff_no text default generate_staff_no() not null,
  profile_id uuid,
  branch_id uuid,
  full_name text not null,
  mobile text,
  alternate_mobile text,
  email text,
  address text,
  emergency_contact_name text,
  emergency_contact_mobile text,
  joined_on date,
  left_on date,
  status staff_status default 'ACTIVE'::staff_status not null,
  notes text,
  created_by uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.staff_roles (
  id uuid default gen_random_uuid() not null,
  code text not null,
  name text not null,
  is_teaching_role boolean default false not null,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null
);

create table public.staff_role_assignments (
  id uuid default gen_random_uuid() not null,
  staff_id uuid not null,
  staff_role_id uuid not null,
  branch_id uuid,
  effective_from date default CURRENT_DATE not null,
  effective_to date,
  is_primary boolean default false not null,
  assigned_by uuid,
  created_at timestamp with time zone default now() not null
);

create table public.audit_events (
  id uuid default gen_random_uuid() not null,
  correlation_id uuid default gen_random_uuid() not null,
  occurred_at timestamp with time zone default now() not null,
  actor_profile_id uuid,
  actor_staff_id uuid,
  actor_role_code text,
  branch_id uuid,
  entity_type text not null,
  entity_id text not null,
  action text not null,
  reason text,
  before_data jsonb,
  after_data jsonb,
  metadata jsonb default '{}'::jsonb not null
);

create table public.approval_requests (
  id uuid default gen_random_uuid() not null,
  correlation_id uuid default gen_random_uuid() not null,
  workflow_type text not null,
  entity_type text not null,
  entity_id text not null,
  requested_action text not null,
  payload_snapshot jsonb default '{}'::jsonb not null,
  request_note text,
  status approval_status default 'PENDING'::approval_status not null,
  requested_by uuid not null,
  requested_at timestamp with time zone default now() not null,
  decided_by uuid,
  decided_at timestamp with time zone,
  decision_note text,
  created_at timestamp with time zone default now() not null
);

create table public.business_rule_versions (
  id uuid default gen_random_uuid() not null,
  domain text not null,
  rule_key text not null,
  version integer not null,
  status rule_status default 'DRAFT'::rule_status not null,
  effective_from date default CURRENT_DATE not null,
  effective_to date,
  payload jsonb not null,
  change_reason text not null,
  created_by uuid,
  created_at timestamp with time zone default now() not null
);

create table public.staff_access_requests (
  id uuid default gen_random_uuid() not null,
  full_name text not null,
  email text not null,
  mobile text not null,
  requested_role text not null,
  purpose text not null,
  status text default 'PENDING'::text not null,
  assigned_role text,
  profile_id uuid,
  reviewed_by uuid,
  reviewed_at timestamp with time zone,
  invitation_sent_at timestamp with time zone,
  review_note text,
  created_at timestamp with time zone default now() not null
);

-- Upstream 02_academic_directory_offerings_fees.sql
-- Sohoj Academy fresh database baseline: academic directory offerings fees.
-- Install on an empty application schema. Each object is defined once.

create table public.academic_years (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  name text not null,
  starts_on date not null,
  ends_on date not null,
  is_active boolean default false not null,
  created_at timestamp with time zone default now() not null
);

create table public.classes (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  sort_order integer default 0 not null,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null
);

create table public.programs (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  description text,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null
);

create table public.subjects (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null
);

create table public.areas (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  name text not null,
  parent_id uuid,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null
);

create table public.schools (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  area_id uuid,
  name text not null,
  is_verified boolean default false not null,
  is_active boolean default true not null,
  created_by uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.lead_sources (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null
);

create table public.guardian_relationships (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null
);

create table public.academic_groups (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  is_active boolean default true not null
);

create table public.programme_offerings (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  branch_id uuid not null,
  academic_year_id uuid not null,
  class_id uuid not null,
  program_id uuid not null,
  group_id uuid,
  code text not null,
  name text not null,
  status offering_status default 'DRAFT'::offering_status not null,
  created_by uuid not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  showcase_title text,
  showcase_title_bn text,
  showcase_description text,
  showcase_description_bn text,
  showcase_eyebrow text,
  showcase_eyebrow_bn text,
  showcase_icon text,
  showcase_sort_order integer default 100 not null,
  is_website_visible boolean default false not null,
  is_accepting_applications boolean default false not null,
  applications_open_on date,
  applications_close_on date,
  public_schedule text,
  public_requirements text,
  admission_policy text,
  public_schedule_bn text,
  public_requirements_bn text,
  admission_policy_bn text,
  allowed_discount_percentages integer[] default '{}'::integer[] not null
);

create table public.fee_plan_versions (
  id uuid default gen_random_uuid() not null,
  offering_id uuid not null,
  version integer not null,
  status rule_status default 'DRAFT'::rule_status not null,
  billing_cycle text not null,
  due_day integer,
  currency_code text default 'BDT'::text not null,
  effective_from date not null,
  effective_to date,
  change_reason text not null,
  created_by uuid not null,
  created_at timestamp with time zone default now() not null
);

create table public.fee_plan_components (
  id uuid default gen_random_uuid() not null,
  fee_plan_version_id uuid not null,
  code text not null,
  name text not null,
  amount numeric(12,2) not null,
  charge_type text not null,
  recurrence text not null,
  sort_order integer default 0 not null
);

create table public.programme_offering_subjects (
  offering_id uuid not null,
  subject_id uuid not null,
  sort_order integer default 0 not null
);

-- Upstream 03_crm_admissions_student_lifecycle.sql
-- Sohoj Academy fresh database baseline: crm admissions student lifecycle.
-- Install on an empty application schema. Each object is defined once.

create table public.prospects (
  id uuid default gen_random_uuid() not null,
  prospect_no text default generate_prospect_no() not null,
  organization_id uuid not null,
  branch_id uuid,
  student_name text not null,
  student_name_bn text,
  guardian_name text not null,
  guardian_relationship_id uuid,
  guardian_relationship_snapshot text,
  mobile text not null,
  alternate_mobile text,
  current_class_id uuid,
  school_id uuid,
  school_name_snapshot text,
  area_id uuid,
  area_snapshot text,
  preferred_schedule text,
  preferred_days text[] default '{}'::text[] not null,
  trial_interest boolean default false not null,
  source_id uuid,
  referral_note text,
  notes text,
  consent_to_contact boolean default false not null,
  status prospect_status default 'NEW'::prospect_status not null,
  assigned_to_staff_id uuid,
  next_follow_up_at timestamp with time zone,
  lost_reason text,
  converted_student_id uuid,
  converted_at timestamp with time zone,
  submitted_via text default 'PUBLIC_WEB'::text not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  interested_offering_id uuid,
  submission_intent text default 'interest'::text not null,
  date_of_birth date,
  gender text,
  school_roll text,
  guardian_address text,
  application_snapshot jsonb,
  application_verified_at timestamp with time zone,
  application_verified_by uuid
);

create table public.prospect_program_interests (
  prospect_id uuid not null,
  program_id uuid not null,
  created_at timestamp with time zone default now() not null
);

create table public.prospect_subject_interests (
  prospect_id uuid not null,
  subject_id uuid not null,
  created_at timestamp with time zone default now() not null
);

create table public.prospect_followups (
  id uuid default gen_random_uuid() not null,
  prospect_id uuid not null,
  followup_type text not null,
  occurred_at timestamp with time zone default now() not null,
  outcome text,
  notes text not null,
  next_follow_up_at timestamp with time zone,
  recorded_by uuid not null,
  created_at timestamp with time zone default now() not null
);

create table public.students (
  id uuid default gen_random_uuid() not null,
  student_no text default generate_student_no() not null,
  organization_id uuid not null,
  branch_id uuid,
  full_name text not null,
  name_bn text,
  gender text,
  date_of_birth date,
  school_id uuid,
  school_name_snapshot text,
  school_roll text,
  status student_status default 'ACTIVE'::student_status not null,
  created_from_prospect_id uuid,
  created_by uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  merged_into_id uuid,
  academy_roll bigint generated always as identity not null
);

create table public.guardians (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  full_name text not null,
  mobile text not null,
  alternate_mobile text,
  email text,
  address text,
  created_by uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.student_guardians (
  id uuid default gen_random_uuid() not null,
  student_id uuid not null,
  guardian_id uuid not null,
  relationship_id uuid,
  relationship_snapshot text,
  is_primary boolean default false not null,
  created_at timestamp with time zone default now() not null
);

create table public.batches (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  branch_id uuid,
  academic_year_id uuid not null,
  class_id uuid not null,
  program_id uuid,
  code text not null,
  name text not null,
  capacity integer not null,
  is_active boolean default true not null,
  created_by uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  offering_id uuid,
  capacity_policy_version_id uuid
);

create table public.enrollments (
  id uuid default gen_random_uuid() not null,
  student_id uuid not null,
  organization_id uuid not null,
  branch_id uuid,
  academic_year_id uuid not null,
  class_id uuid not null,
  program_id uuid,
  batch_id uuid,
  admission_date date default CURRENT_DATE not null,
  status enrollment_status default 'ACTIVE'::enrollment_status not null,
  ended_on date,
  created_by uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.admission_cases (
  id uuid default gen_random_uuid() not null,
  admission_no text default ('ADM-'::text || lpad((nextval('admission_no_seq'::regclass))::text, 6, '0'::text)) not null,
  prospect_id uuid,
  batch_id uuid not null,
  fee_plan_version_id uuid not null,
  activation_policy_version_id uuid,
  capacity_policy_version_id uuid,
  student_id uuid,
  enrollment_id uuid,
  status text default 'DRAFT'::text not null,
  identity_snapshot jsonb not null,
  created_by uuid not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  existing_student boolean default false not null,
  consent_required boolean default true not null,
  origin text default 'PROSPECT_CONVERSION'::text not null,
  origin_prospect_id uuid,
  selected_discount_percent integer default 0 not null,
  discount_reason text,
  identity_revision integer default 1 not null,
  additional_charges jsonb default '[]'::jsonb not null
);

create table public.admission_command_keys (
  request_id uuid not null,
  actor_id uuid not null,
  payload jsonb not null,
  result jsonb not null,
  created_at timestamp with time zone default now() not null
);

create table public.student_merges (
  id uuid default gen_random_uuid() not null,
  source_id uuid not null,
  target_id uuid not null,
  source_snapshot jsonb not null,
  target_snapshot jsonb not null,
  created_at timestamp with time zone default now() not null,
  authorized_by uuid not null,
  authorization_reason text not null
);

create table public.enrollment_transfers (
  id uuid default gen_random_uuid() not null,
  student_id uuid not null,
  admission_id uuid not null,
  from_enrollment_id uuid not null,
  to_enrollment_id uuid not null,
  from_batch_id uuid not null,
  to_batch_id uuid not null,
  capacity_policy_version_id uuid not null,
  transferred_on date not null,
  created_at timestamp with time zone default now() not null,
  authorized_by uuid not null,
  authorization_reason text not null
);

create table public.staff_admission_intake_requests (
  request_id uuid not null,
  actor_id uuid not null,
  payload jsonb not null,
  prospect_id uuid,
  admission_id uuid not null,
  created_at timestamp with time zone default now() not null
);

create table public.admission_physical_consent_receipts (
  id uuid default gen_random_uuid() not null,
  request_id uuid not null,
  request_payload jsonb not null,
  admission_id uuid not null,
  version integer not null,
  guardian_signed_on date not null,
  student_signed boolean default false not null,
  physical_copy_reference text,
  received_by uuid not null,
  received_at timestamp with time zone default now() not null,
  reason text not null,
  identity_revision integer default 1 not null
);

-- Upstream 04_billing_payments_adjustments.sql
-- Sohoj Academy fresh database baseline: billing payments adjustments.
-- Install on an empty application schema. Each object is defined once.

create table public.payment_methods (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null
);

create table public.admission_invoices (
  id uuid default gen_random_uuid() not null,
  invoice_no text default ('INV-'::text || lpad((nextval('invoice_no_seq'::regclass))::text, 6, '0'::text)) not null,
  admission_id uuid not null,
  student_id uuid not null,
  fee_plan_version_id uuid not null,
  currency_code text not null,
  total numeric(12,2) not null,
  due_on date not null,
  issued_on date not null,
  posted_by uuid not null,
  posted_at timestamp with time zone default now() not null,
  invoice_kind text default 'INITIAL'::text not null,
  billing_period date not null
);

create table public.admission_invoice_lines (
  id uuid default gen_random_uuid() not null,
  invoice_id uuid not null,
  fee_component_id uuid,
  name text not null,
  charge_type text not null,
  amount numeric(12,2) not null
);

create table public.admission_payments (
  id uuid default gen_random_uuid() not null,
  student_id uuid not null,
  payment_method_id uuid not null,
  amount numeric(12,2) not null,
  currency_code text not null,
  external_reference text,
  receipt_no text default ('RCT-'::text || lpad((nextval('admission_receipt_no_seq'::regclass))::text, 6, '0'::text)) not null,
  posted_by uuid not null,
  posted_at timestamp with time zone default now() not null,
  reason text not null
);

create table public.admission_payment_allocations (
  payment_id uuid not null,
  invoice_id uuid not null,
  amount numeric(12,2) not null
);

create table public.billing_terms (
  id uuid default gen_random_uuid() not null,
  academic_year_id uuid not null,
  name text not null,
  starts_on date not null,
  ends_on date not null,
  due_on date not null,
  created_by uuid not null,
  created_at timestamp with time zone default now() not null
);

create table public.admission_discounts (
  id uuid default gen_random_uuid() not null,
  admission_id uuid not null,
  kind text not null,
  value numeric(12,2) not null,
  starts_on date not null,
  ends_on date not null,
  created_at timestamp with time zone default now() not null,
  authorized_by uuid,
  authorization_reason text,
  correlation_id uuid
);

create table public.invoice_credits (
  id uuid default gen_random_uuid() not null,
  invoice_id uuid not null,
  discount_id uuid,
  kind text not null,
  amount numeric(12,2) not null,
  created_at timestamp with time zone default now() not null,
  applied_by uuid
);

create table public.refund_authorizations (
  id uuid default gen_random_uuid() not null,
  payment_id uuid not null,
  invoice_id uuid not null,
  amount numeric(12,2) not null,
  created_at timestamp with time zone default now() not null,
  authorized_by uuid,
  authorization_reason text,
  correlation_id uuid
);

create table public.refund_payouts (
  id uuid default gen_random_uuid() not null,
  authorization_id uuid not null,
  refund_no text default ('RFN-'::text || lpad((nextval('refund_no_seq'::regclass))::text, 6, '0'::text)) not null,
  payment_method_id uuid not null,
  external_reference text,
  posted_by uuid not null,
  posted_at timestamp with time zone default now() not null,
  reason text not null
);

create table public.admission_cancellations (
  admission_id uuid not null,
  settlement text not null,
  cancelled_at timestamp with time zone default now() not null,
  cancelled_by uuid,
  cancellation_reason text,
  correlation_id uuid
);

create table public.billing_runs (
  id uuid not null,
  period date not null,
  term_id uuid,
  posted_by uuid not null,
  posted_at timestamp with time zone default now() not null,
  invoice_count integer not null,
  gross_total numeric(14,2) not null,
  reason text not null
);

-- Upstream 05_accounting_referrals_compensation.sql
-- Sohoj Academy fresh database baseline: accounting referrals compensation.
-- Install on an empty application schema. Each object is defined once.

create table public.finance_accounts (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  account_type text not null,
  account_subtype text not null,
  parent_id uuid,
  is_control_account boolean default false not null,
  is_active boolean default true not null,
  created_by uuid,
  created_at timestamp with time zone default now() not null
);

create table public.finance_cost_centres (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  branch_id uuid,
  program_id uuid,
  batch_id uuid,
  is_active boolean default true not null,
  created_by uuid,
  created_at timestamp with time zone default now() not null
);

create table public.general_ledger_journals (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  journal_no text default ('JRN-'::text || lpad((nextval('general_ledger_journal_no_seq'::regclass))::text, 8, '0'::text)) not null,
  journal_date date not null,
  journal_type text not null,
  source_type text not null,
  source_id text not null,
  description text not null,
  status text default 'POSTED'::text not null,
  posted_by uuid not null,
  posted_at timestamp with time zone default now() not null,
  created_at timestamp with time zone default now() not null
);

create table public.general_ledger_lines (
  id uuid default gen_random_uuid() not null,
  journal_id uuid not null,
  line_no integer not null,
  account_id uuid not null,
  debit numeric(14,2) default 0 not null,
  credit numeric(14,2) default 0 not null,
  memo text,
  cost_centre_id uuid,
  branch_id uuid,
  program_id uuid,
  batch_id uuid,
  created_at timestamp with time zone default now() not null
);

create table public.vendors (
  id uuid default gen_random_uuid() not null,
  vendor_no text default ('VEN-'::text || lpad((nextval('vendor_no_seq'::regclass))::text, 6, '0'::text)) not null,
  organization_id uuid not null,
  name text not null,
  mobile text,
  email text,
  address text,
  service_category text,
  is_active boolean default true not null,
  created_by uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.finance_payment_account_map (
  payment_method_id uuid not null,
  account_id uuid not null,
  created_at timestamp with time zone default now() not null
);

create table public.finance_fee_revenue_map (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  charge_type text not null,
  account_id uuid not null,
  created_at timestamp with time zone default now() not null
);

create table public.finance_payables (
  id uuid default gen_random_uuid() not null,
  payable_no text default ('PAY-'::text || lpad((nextval('finance_payable_no_seq'::regclass))::text, 6, '0'::text)) not null,
  organization_id uuid not null,
  payable_type text not null,
  staff_id uuid,
  vendor_id uuid,
  source_type text not null,
  source_id text not null,
  payable_account_id uuid not null,
  original_amount numeric(14,2) not null,
  due_on date,
  status text default 'OPEN'::text not null,
  created_by uuid not null,
  created_at timestamp with time zone default now() not null,
  referrer_id uuid
);

create table public.finance_payable_settlements (
  id uuid default gen_random_uuid() not null,
  payable_id uuid not null,
  amount numeric(14,2) not null,
  payment_account_id uuid,
  external_reference text,
  settled_by uuid not null,
  settled_at timestamp with time zone default now() not null,
  reason text not null,
  advance_id uuid
);

create table public.finance_advances (
  id uuid default gen_random_uuid() not null,
  advance_no text default ('ADV-'::text || lpad((nextval('finance_advance_no_seq'::regclass))::text, 6, '0'::text)) not null,
  organization_id uuid not null,
  beneficiary_type text not null,
  staff_id uuid,
  vendor_id uuid,
  project_reference text,
  purpose text not null,
  requested_amount numeric(14,2) not null,
  approved_amount numeric(14,2),
  expected_settlement_date date,
  requested_by uuid not null,
  status text default 'REQUESTED'::text not null,
  created_at timestamp with time zone default now() not null,
  authorized_by uuid,
  authorization_reason text
);

create table public.finance_advance_movements (
  id uuid default gen_random_uuid() not null,
  advance_id uuid not null,
  movement_type text not null,
  amount numeric(14,2) not null,
  source_type text,
  source_id text,
  payment_account_id uuid,
  created_by uuid not null,
  created_at timestamp with time zone default now() not null,
  reason text not null,
  payable_id uuid
);

create table public.finance_expense_categories (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  expense_account_id uuid not null,
  is_active boolean default true not null,
  created_by uuid,
  created_at timestamp with time zone default now() not null
);

create table public.finance_expenses (
  id uuid default gen_random_uuid() not null,
  expense_no text default ('EXP-'::text || lpad((nextval('finance_expense_no_seq'::regclass))::text, 6, '0'::text)) not null,
  organization_id uuid not null,
  expense_date date not null,
  category_id uuid not null,
  expense_account_id uuid not null,
  payment_mode text not null,
  payment_account_id uuid,
  payable_id uuid,
  vendor_id uuid,
  staff_id uuid,
  amount numeric(14,2) not null,
  description text not null,
  receipt_reference text,
  status text default 'DRAFT'::text not null,
  submitted_by uuid not null,
  posted_by uuid,
  posted_at timestamp with time zone,
  created_at timestamp with time zone default now() not null,
  authorized_by uuid,
  authorization_reason text
);

create table public.finance_expense_reconciliations (
  id uuid default gen_random_uuid() not null,
  expense_id uuid not null,
  matched_amount numeric(14,2) not null,
  statement_reference text not null,
  reconciled_by uuid not null,
  reconciled_at timestamp with time zone default now() not null,
  note text not null
);

create table public.finance_account_reconciliations (
  id uuid default gen_random_uuid() not null,
  account_id uuid not null,
  statement_date date not null,
  statement_reference text not null,
  statement_balance numeric(14,2) not null,
  ledger_balance numeric(14,2) not null,
  difference numeric(14,2) not null,
  status text not null,
  reconciled_by uuid,
  reconciled_at timestamp with time zone,
  note text not null
);

create table public.teacher_referrals (
  id uuid default gen_random_uuid() not null,
  admission_id uuid not null,
  teacher_id uuid not null,
  captured_by uuid not null,
  captured_at timestamp with time zone default now() not null,
  reason text not null
);

create table public.teacher_compensation_runs (
  id uuid default gen_random_uuid() not null,
  run_no text default ('CMP-'::text || lpad((nextval('teacher_compensation_run_no_seq'::regclass))::text, 6, '0'::text)) not null,
  organization_id uuid not null,
  period_start date not null,
  period_end date not null,
  policy_version_id uuid not null,
  status text default 'DRAFT'::text not null,
  total_amount numeric(14,2) default 0 not null,
  submitted_by uuid not null,
  approved_by uuid,
  approved_at timestamp with time zone,
  created_at timestamp with time zone default now() not null,
  authorized_by uuid,
  authorization_reason text
);

create table public.teacher_compensation_events (
  id uuid default gen_random_uuid() not null,
  event_key text not null,
  teacher_id uuid not null,
  admission_id uuid,
  event_type text not null,
  event_period date not null,
  amount numeric(14,2) not null,
  created_at timestamp with time zone default now() not null
);

create table public.teacher_compensation_adjustments (
  id uuid default gen_random_uuid() not null,
  teacher_id uuid not null,
  amount numeric(14,2) not null,
  adjustment_type text not null,
  effective_period date not null,
  reason text not null,
  status text default 'PENDING'::text not null,
  requested_by uuid not null,
  approved_by uuid,
  approved_at timestamp with time zone,
  created_at timestamp with time zone default now() not null,
  authorized_by uuid,
  authorization_reason text
);

create table public.teacher_compensation_lines (
  id uuid default gen_random_uuid() not null,
  run_id uuid not null,
  teacher_id uuid not null,
  line_type text not null,
  source_type text not null,
  source_id text not null,
  amount numeric(14,2) not null,
  calculation jsonb default '{}'::jsonb not null,
  created_at timestamp with time zone default now() not null,
  admission_id uuid
);

create table public.teacher_compensation_settlements (
  id uuid default gen_random_uuid() not null,
  run_id uuid not null,
  teacher_id uuid not null,
  payable_id uuid not null,
  gross_amount numeric(14,2) not null,
  advance_offset numeric(14,2) default 0 not null,
  cash_paid numeric(14,2) default 0 not null,
  payment_account_id uuid,
  external_reference text,
  settled_by uuid not null,
  settled_at timestamp with time zone default now() not null,
  reason text not null
);

create table public.teacher_compensation_claims (
  id uuid default gen_random_uuid() not null,
  teacher_id uuid not null,
  source_type text not null,
  source_id text not null,
  line_id uuid not null,
  run_id uuid not null,
  claimed_at timestamp with time zone default now() not null
);

create table public.referral_people (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  staff_id uuid,
  full_name text not null,
  mobile text,
  relationship_note text,
  contact_note text,
  created_by uuid,
  created_at timestamp with time zone default now() not null
);

create table public.admission_referrals (
  admission_id uuid not null,
  source text not null,
  referrer_id uuid,
  captured_by uuid not null,
  captured_at timestamp with time zone default now() not null,
  reason text not null
);

create table public.referral_bonus_awards (
  id uuid default gen_random_uuid() not null,
  admission_id uuid not null,
  referrer_id uuid not null,
  period_start date not null,
  net_collected numeric(14,2) not null,
  policy_version_id uuid not null,
  bonus_percent numeric(7,3) not null,
  amount numeric(14,2) not null,
  status text default 'PENDING'::text not null,
  payable_id uuid,
  requested_by uuid not null,
  reviewed_by uuid,
  created_at timestamp with time zone default now() not null,
  reviewed_at timestamp with time zone
);

-- Upstream 06_teacher_academic_records.sql
-- Sohoj Academy fresh database baseline: teacher academic records.
-- Install on an empty application schema. Each object is defined once.

create table public.staff_subject_assignments (
  id uuid default gen_random_uuid() not null,
  staff_id uuid not null,
  subject_id uuid not null,
  effective_from date default CURRENT_DATE not null,
  effective_to date,
  is_primary boolean default false not null,
  assigned_by uuid,
  created_at timestamp with time zone default now() not null
);

create table public.academic_rooms (
  id uuid default gen_random_uuid() not null,
  branch_id uuid not null,
  name text not null,
  capacity integer not null,
  created_by uuid not null,
  created_at timestamp with time zone default now() not null
);

create table public.curriculum_versions (
  id uuid default gen_random_uuid() not null,
  batch_id uuid not null,
  subject_id uuid not null,
  version integer not null,
  title text not null,
  units jsonb not null,
  reason text not null,
  published_by uuid not null,
  published_at timestamp with time zone default now() not null
);

create table public.academic_routines (
  id uuid default gen_random_uuid() not null,
  batch_id uuid not null,
  subject_id uuid not null,
  teacher_id uuid not null,
  room_id uuid not null,
  weekday integer not null,
  start_time time without time zone not null,
  end_time time without time zone not null,
  starts_on date not null,
  ends_on date not null,
  created_by uuid not null,
  created_at timestamp with time zone default now() not null,
  retired_at timestamp with time zone
);

create table public.class_sessions (
  id uuid default gen_random_uuid() not null,
  routine_id uuid,
  batch_id uuid not null,
  subject_id uuid not null,
  teacher_id uuid not null,
  room_id uuid not null,
  curriculum_version_id uuid,
  planned_scope text not null,
  session_date date not null,
  starts_at timestamp with time zone not null,
  ends_at timestamp with time zone not null,
  status text default 'SCHEDULED'::text not null,
  cancellation_reason text,
  cancelled_by uuid,
  cancelled_at timestamp with time zone,
  created_by uuid not null,
  created_at timestamp with time zone default now() not null
);

create table public.attendance_submissions (
  id uuid default gen_random_uuid() not null,
  session_id uuid not null,
  revision integer not null,
  entries jsonb not null,
  reason text not null,
  status text default 'DRAFT'::text not null,
  recorded_by uuid not null,
  created_at timestamp with time zone default now() not null,
  approval_id uuid,
  reviewer_id uuid,
  review_note text,
  reviewed_at timestamp with time zone
);

create table public.class_logs (
  id uuid default gen_random_uuid() not null,
  session_id uuid not null,
  revision integer not null,
  previous_log_id uuid,
  status text not null,
  unit_progress jsonb default '[]'::jsonb not null,
  class_summary text not null,
  unfinished_reason text default ''::text not null,
  homework text default ''::text not null,
  next_session_plan text default ''::text not null,
  reason text not null,
  authored_by uuid not null,
  created_at timestamp with time zone default now() not null,
  submitted_at timestamp with time zone,
  reviewer_id uuid,
  review_note text,
  reviewed_at timestamp with time zone
);

create table public.question_bank_items (
  id uuid default gen_random_uuid() not null,
  root_id uuid,
  revision integer default 1 not null,
  batch_id uuid not null,
  subject_id uuid not null,
  curriculum_version_id uuid,
  topic text not null,
  difficulty text not null,
  question_type text not null,
  prompt text not null,
  choices jsonb default '[]'::jsonb not null,
  answer_key text not null,
  explanation text,
  status text default 'DRAFT'::text not null,
  author_id uuid not null,
  reviewer_id uuid,
  review_note text,
  created_at timestamp with time zone default now() not null,
  submitted_at timestamp with time zone,
  reviewed_at timestamp with time zone
);

create table public.homework_checks (
  id uuid default gen_random_uuid() not null,
  class_log_id uuid not null,
  enrollment_id uuid not null,
  revision integer not null,
  status text not null,
  submitted_on date,
  feedback text default ''::text not null,
  recorded_by uuid not null,
  recorded_at timestamp with time zone default now() not null
);

create table public.academic_assessments (
  id uuid default gen_random_uuid() not null,
  batch_id uuid not null,
  subject_id uuid not null,
  title text not null,
  assessment_date date not null,
  max_marks numeric(8,2) not null,
  status text default 'DRAFT'::text not null,
  author_id uuid not null,
  created_at timestamp with time zone default now() not null,
  published_at timestamp with time zone
);

create table public.assessment_result_submissions (
  id uuid default gen_random_uuid() not null,
  assessment_id uuid not null,
  revision integer not null,
  entries jsonb not null,
  status text default 'DRAFT'::text not null,
  author_id uuid not null,
  reviewer_id uuid,
  review_note text,
  created_at timestamp with time zone default now() not null,
  submitted_at timestamp with time zone,
  reviewed_at timestamp with time zone
);

-- Upstream 07_constraints_indexes.sql
-- Sohoj Academy fresh database baseline: constraints indexes.
-- Install on an empty application schema. Each object is defined once.

alter table public.organizations add constraint organizations_pkey PRIMARY KEY (id);

alter table public.organizations add constraint organizations_code_key UNIQUE (code);

alter table public.branches add constraint branches_pkey PRIMARY KEY (id);

alter table public.branches add constraint branches_organization_id_code_key UNIQUE (organization_id, code);

alter table public.profiles add constraint profiles_pkey PRIMARY KEY (id);

alter table public.system_roles add constraint system_roles_pkey PRIMARY KEY (id);

alter table public.system_roles add constraint system_roles_code_key UNIQUE (code);

alter table public.permissions add constraint permissions_pkey PRIMARY KEY (id);

alter table public.permissions add constraint permissions_code_key UNIQUE (code);

alter table public.role_permissions add constraint role_permissions_pkey PRIMARY KEY (role_id, permission_id);

alter table public.user_role_assignments add constraint user_role_assignments_check CHECK (effective_to IS NULL OR effective_to >= effective_from);

alter table public.user_role_assignments add constraint user_role_assignments_pkey PRIMARY KEY (id);

alter table public.staff add constraint staff_check CHECK (left_on IS NULL OR joined_on IS NULL OR left_on >= joined_on);

alter table public.staff add constraint staff_pkey PRIMARY KEY (id);

alter table public.staff add constraint staff_staff_no_key UNIQUE (staff_no);

alter table public.staff add constraint staff_profile_id_key UNIQUE (profile_id);

alter table public.staff_roles add constraint staff_roles_pkey PRIMARY KEY (id);

alter table public.staff_roles add constraint staff_roles_code_key UNIQUE (code);

alter table public.staff_role_assignments add constraint staff_role_assignments_check CHECK (effective_to IS NULL OR effective_to >= effective_from);

alter table public.staff_role_assignments add constraint staff_role_assignments_pkey PRIMARY KEY (id);

alter table public.audit_events add constraint audit_events_pkey PRIMARY KEY (id);

alter table public.approval_requests add constraint approval_requests_check CHECK (status = 'PENDING'::approval_status AND decided_by IS NULL AND decided_at IS NULL OR status <> 'PENDING'::approval_status);

alter table public.approval_requests add constraint approval_requests_pkey PRIMARY KEY (id);

alter table public.business_rule_versions add constraint business_rule_versions_check CHECK (effective_to IS NULL OR effective_to >= effective_from);

alter table public.business_rule_versions add constraint business_rule_versions_pkey PRIMARY KEY (id);

alter table public.business_rule_versions add constraint business_rule_versions_domain_rule_key_version_key UNIQUE (domain, rule_key, version);

alter table public.academic_years add constraint academic_years_check CHECK (ends_on >= starts_on);

alter table public.academic_years add constraint academic_years_pkey PRIMARY KEY (id);

alter table public.academic_years add constraint academic_years_organization_id_name_key UNIQUE (organization_id, name);

alter table public.classes add constraint classes_pkey PRIMARY KEY (id);

alter table public.classes add constraint classes_organization_id_code_key UNIQUE (organization_id, code);

alter table public.programs add constraint programs_pkey PRIMARY KEY (id);

alter table public.programs add constraint programs_organization_id_code_key UNIQUE (organization_id, code);

alter table public.subjects add constraint subjects_pkey PRIMARY KEY (id);

alter table public.subjects add constraint subjects_organization_id_code_key UNIQUE (organization_id, code);

alter table public.areas add constraint areas_pkey PRIMARY KEY (id);

alter table public.schools add constraint schools_pkey PRIMARY KEY (id);

alter table public.lead_sources add constraint lead_sources_pkey PRIMARY KEY (id);

alter table public.lead_sources add constraint lead_sources_organization_id_code_key UNIQUE (organization_id, code);

alter table public.guardian_relationships add constraint guardian_relationships_pkey PRIMARY KEY (id);

alter table public.guardian_relationships add constraint guardian_relationships_organization_id_code_key UNIQUE (organization_id, code);

alter table public.payment_methods add constraint payment_methods_pkey PRIMARY KEY (id);

alter table public.payment_methods add constraint payment_methods_organization_id_code_key UNIQUE (organization_id, code);

alter table public.prospects add constraint prospects_pkey PRIMARY KEY (id);

alter table public.prospects add constraint prospects_prospect_no_key UNIQUE (prospect_no);

alter table public.prospect_program_interests add constraint prospect_program_interests_pkey PRIMARY KEY (prospect_id, program_id);

alter table public.prospect_subject_interests add constraint prospect_subject_interests_pkey PRIMARY KEY (prospect_id, subject_id);

alter table public.prospect_followups add constraint prospect_followups_pkey PRIMARY KEY (id);

alter table public.students add constraint students_pkey PRIMARY KEY (id);

alter table public.students add constraint students_student_no_key UNIQUE (student_no);

alter table public.students add constraint students_created_from_prospect_id_key UNIQUE (created_from_prospect_id);

alter table public.guardians add constraint guardians_pkey PRIMARY KEY (id);

alter table public.student_guardians add constraint student_guardians_pkey PRIMARY KEY (id);

alter table public.student_guardians add constraint student_guardians_student_id_guardian_id_key UNIQUE (student_id, guardian_id);

alter table public.batches add constraint batches_capacity_check CHECK (capacity > 0);

alter table public.batches add constraint batches_pkey PRIMARY KEY (id);

alter table public.batches add constraint batches_organization_id_academic_year_id_code_key UNIQUE (organization_id, academic_year_id, code);

alter table public.enrollments add constraint enrollments_check CHECK (ended_on IS NULL OR ended_on >= admission_date);

alter table public.enrollments add constraint enrollments_pkey PRIMARY KEY (id);

alter table public.staff_subject_assignments add constraint staff_subject_assignments_check CHECK (effective_to IS NULL OR effective_to >= effective_from);

alter table public.staff_subject_assignments add constraint staff_subject_assignments_pkey PRIMARY KEY (id);

alter table public.prospect_followups add constraint prospect_followup_type_check CHECK (followup_type = ANY (ARRAY['CALL'::text, 'WHATSAPP'::text, 'IN_PERSON'::text, 'COUNSELLING'::text, 'TRIAL'::text, 'OTHER'::text]));

alter table public.academic_groups add constraint academic_groups_pkey PRIMARY KEY (id);

alter table public.academic_groups add constraint academic_groups_organization_id_code_key UNIQUE (organization_id, code);

alter table public.programme_offerings add constraint programme_offerings_code_check CHECK (length(btrim(code)) >= 2 AND length(btrim(code)) <= 40);

alter table public.programme_offerings add constraint programme_offerings_name_check CHECK (length(btrim(name)) >= 2 AND length(btrim(name)) <= 160);

alter table public.programme_offerings add constraint programme_offerings_pkey PRIMARY KEY (id);

alter table public.programme_offerings add constraint programme_offerings_organization_id_academic_year_id_code_key UNIQUE (organization_id, academic_year_id, code);

alter table public.fee_plan_versions add constraint fee_plan_versions_version_check CHECK (version > 0);

alter table public.fee_plan_versions add constraint fee_plan_versions_billing_cycle_check CHECK (billing_cycle = ANY (ARRAY['ONE_TIME'::text, 'MONTHLY'::text, 'TERM'::text]));

alter table public.fee_plan_versions add constraint fee_plan_versions_due_day_check CHECK (due_day >= 1 AND due_day <= 28);

alter table public.fee_plan_versions add constraint fee_plan_versions_currency_code_check CHECK (currency_code ~ '^[A-Z]{3}$'::text);

alter table public.fee_plan_versions add constraint fee_plan_versions_change_reason_check CHECK (length(btrim(change_reason)) >= 5);

alter table public.fee_plan_versions add constraint fee_plan_versions_check CHECK (effective_to IS NULL OR effective_to >= effective_from);

alter table public.fee_plan_versions add constraint fee_plan_versions_check1 CHECK (billing_cycle = 'MONTHLY'::text AND due_day IS NOT NULL OR billing_cycle <> 'MONTHLY'::text AND due_day IS NULL);

alter table public.fee_plan_versions add constraint fee_plan_versions_pkey PRIMARY KEY (id);

alter table public.fee_plan_versions add constraint fee_plan_versions_offering_id_version_key UNIQUE (offering_id, version);

alter table public.fee_plan_components add constraint fee_plan_components_code_check CHECK (code ~ '^[A-Z][A-Z0-9_]{1,39}$'::text);

alter table public.fee_plan_components add constraint fee_plan_components_name_check CHECK (length(btrim(name)) >= 2 AND length(btrim(name)) <= 100);

alter table public.fee_plan_components add constraint fee_plan_components_amount_check CHECK (amount >= 0::numeric);

alter table public.fee_plan_components add constraint fee_plan_components_charge_type_check CHECK (charge_type = ANY (ARRAY['TUITION'::text, 'ADMISSION'::text, 'EXAM'::text, 'MATERIAL'::text, 'OTHER'::text]));

alter table public.fee_plan_components add constraint fee_plan_components_recurrence_check CHECK (recurrence = ANY (ARRAY['PER_CYCLE'::text, 'ONE_TIME'::text]));

alter table public.fee_plan_components add constraint fee_plan_components_pkey PRIMARY KEY (id);

alter table public.fee_plan_components add constraint fee_plan_components_fee_plan_version_id_code_key UNIQUE (fee_plan_version_id, code);

alter table public.admission_cases add constraint admission_cases_pkey PRIMARY KEY (id);

alter table public.admission_cases add constraint admission_cases_admission_no_key UNIQUE (admission_no);

alter table public.admission_cases add constraint admission_cases_enrollment_id_key UNIQUE (enrollment_id);

alter table public.admission_invoices add constraint admission_invoices_total_check CHECK (total >= 0::numeric);

alter table public.admission_invoices add constraint admission_invoices_pkey PRIMARY KEY (id);

alter table public.admission_invoices add constraint admission_invoices_invoice_no_key UNIQUE (invoice_no);

alter table public.admission_invoice_lines add constraint admission_invoice_lines_amount_check CHECK (amount >= 0::numeric);

alter table public.admission_invoice_lines add constraint admission_invoice_lines_pkey PRIMARY KEY (id);

alter table public.admission_invoice_lines add constraint admission_invoice_lines_invoice_id_fee_component_id_key UNIQUE (invoice_id, fee_component_id);

alter table public.admission_command_keys add constraint admission_command_keys_pkey PRIMARY KEY (request_id);

alter table public.admission_payments add constraint admission_payments_amount_check CHECK (amount > 0::numeric);

alter table public.admission_payments add constraint admission_payments_pkey PRIMARY KEY (id);

alter table public.admission_payments add constraint admission_payments_receipt_no_key UNIQUE (receipt_no);

alter table public.admission_payment_allocations add constraint admission_payment_allocations_amount_check CHECK (amount > 0::numeric);

alter table public.admission_payment_allocations add constraint admission_payment_allocations_pkey PRIMARY KEY (payment_id);

alter table public.admission_invoices add constraint admission_invoices_invoice_kind_check CHECK (invoice_kind = ANY (ARRAY['INITIAL'::text, 'RECURRING'::text]));

alter table public.billing_terms add constraint billing_terms_name_check CHECK (length(btrim(name)) >= 2);

alter table public.billing_terms add constraint billing_terms_check CHECK (ends_on >= starts_on);

alter table public.billing_terms add constraint billing_terms_check1 CHECK (due_on >= starts_on);

alter table public.billing_terms add constraint billing_terms_pkey PRIMARY KEY (id);

alter table public.billing_terms add constraint billing_terms_academic_year_id_starts_on_key UNIQUE (academic_year_id, starts_on);

alter table public.admission_discounts add constraint admission_discounts_kind_check CHECK (kind = ANY (ARRAY['PERCENT'::text, 'FIXED'::text]));

alter table public.admission_discounts add constraint admission_discounts_value_check CHECK (value > 0::numeric);

alter table public.admission_discounts add constraint admission_discounts_check CHECK (ends_on >= starts_on);

alter table public.admission_discounts add constraint admission_discounts_check1 CHECK (kind <> 'PERCENT'::text OR value <= 100::numeric);

alter table public.admission_discounts add constraint admission_discounts_pkey PRIMARY KEY (id);

alter table public.invoice_credits add constraint invoice_credits_kind_check CHECK (kind = ANY (ARRAY['DISCOUNT'::text, 'CANCELLATION'::text]));

alter table public.invoice_credits add constraint invoice_credits_amount_check CHECK (amount > 0::numeric);

alter table public.invoice_credits add constraint invoice_credits_pkey PRIMARY KEY (id);

alter table public.refund_authorizations add constraint refund_authorizations_amount_check CHECK (amount > 0::numeric);

alter table public.refund_authorizations add constraint refund_authorizations_pkey PRIMARY KEY (id);

alter table public.refund_payouts add constraint refund_payouts_pkey PRIMARY KEY (id);

alter table public.refund_payouts add constraint refund_payouts_authorization_id_key UNIQUE (authorization_id);

alter table public.refund_payouts add constraint refund_payouts_refund_no_key UNIQUE (refund_no);

alter table public.admission_cancellations add constraint admission_cancellations_settlement_check CHECK (settlement = ANY (ARRAY['KEEP_CHARGES'::text, 'CREDIT_ALL'::text]));

alter table public.admission_cancellations add constraint admission_cancellations_pkey PRIMARY KEY (admission_id);

alter table public.billing_runs add constraint billing_runs_pkey PRIMARY KEY (id);

alter table public.students add constraint no_self_merge CHECK (merged_into_id IS NULL OR merged_into_id <> id);

alter table public.student_merges add constraint student_merges_check CHECK (source_id <> target_id);

alter table public.student_merges add constraint student_merges_pkey PRIMARY KEY (id);

alter table public.student_merges add constraint student_merges_source_id_key UNIQUE (source_id);

alter table public.enrollment_transfers add constraint enrollment_transfers_pkey PRIMARY KEY (id);

alter table public.enrollment_transfers add constraint enrollment_transfers_from_enrollment_id_key UNIQUE (from_enrollment_id);

alter table public.enrollment_transfers add constraint enrollment_transfers_to_enrollment_id_key UNIQUE (to_enrollment_id);

alter table public.academic_rooms add constraint academic_rooms_name_check CHECK (length(btrim(name)) >= 2);

alter table public.academic_rooms add constraint academic_rooms_capacity_check CHECK (capacity > 0);

alter table public.academic_rooms add constraint academic_rooms_pkey PRIMARY KEY (id);

alter table public.academic_rooms add constraint academic_rooms_branch_id_name_key UNIQUE (branch_id, name);

alter table public.curriculum_versions add constraint curriculum_versions_pkey PRIMARY KEY (id);

alter table public.curriculum_versions add constraint curriculum_versions_batch_id_subject_id_version_key UNIQUE (batch_id, subject_id, version);

alter table public.academic_routines add constraint academic_routines_weekday_check CHECK (weekday >= 0 AND weekday <= 6);

alter table public.academic_routines add constraint academic_routines_check CHECK (end_time > start_time);

alter table public.academic_routines add constraint academic_routines_check1 CHECK (ends_on >= starts_on);

alter table public.academic_routines add constraint academic_routines_pkey PRIMARY KEY (id);

alter table public.class_sessions add constraint class_sessions_status_check CHECK (status = ANY (ARRAY['SCHEDULED'::text, 'CANCELLED'::text]));

alter table public.class_sessions add constraint class_sessions_check CHECK (ends_at > starts_at);

alter table public.class_sessions add constraint class_sessions_pkey PRIMARY KEY (id);

alter table public.class_sessions add constraint class_sessions_routine_id_session_date_key UNIQUE (routine_id, session_date);

alter table public.attendance_submissions add constraint attendance_submissions_status_check CHECK (status = ANY (ARRAY['DRAFT'::text, 'SUBMITTED'::text, 'APPROVED'::text, 'REJECTED'::text]));

alter table public.attendance_submissions add constraint attendance_submissions_pkey PRIMARY KEY (id);

alter table public.attendance_submissions add constraint attendance_submissions_approval_id_key UNIQUE (approval_id);

alter table public.attendance_submissions add constraint attendance_submissions_session_id_revision_key UNIQUE (session_id, revision);

alter table public.programme_offering_subjects add constraint programme_offering_subjects_pkey PRIMARY KEY (offering_id, subject_id);

alter table public.prospects add constraint prospects_submission_intent_check CHECK (submission_intent = ANY (ARRAY['interest'::text, 'admission'::text]));

alter table public.class_logs add constraint class_logs_revision_check CHECK (revision > 0);

alter table public.class_logs add constraint class_logs_check CHECK (status = 'DRAFT'::text AND submitted_at IS NULL OR status = 'SUBMITTED'::text AND submitted_at IS NOT NULL);

alter table public.class_logs add constraint class_logs_pkey PRIMARY KEY (id);

alter table public.class_logs add constraint class_logs_session_id_revision_key UNIQUE (session_id, revision);

alter table public.question_bank_items add constraint question_bank_items_revision_check CHECK (revision > 0);

alter table public.question_bank_items add constraint question_bank_items_topic_check CHECK (length(btrim(topic)) >= 2 AND length(btrim(topic)) <= 180);

alter table public.question_bank_items add constraint question_bank_items_difficulty_check CHECK (difficulty = ANY (ARRAY['FOUNDATION'::text, 'STANDARD'::text, 'ADVANCED'::text]));

alter table public.question_bank_items add constraint question_bank_items_question_type_check CHECK (question_type = ANY (ARRAY['MCQ'::text, 'SHORT_ANSWER'::text]));

alter table public.question_bank_items add constraint question_bank_items_prompt_check CHECK (length(btrim(prompt)) >= 10 AND length(btrim(prompt)) <= 3000);

alter table public.question_bank_items add constraint question_bank_items_answer_key_check CHECK (length(btrim(answer_key)) >= 1 AND length(btrim(answer_key)) <= 1500);

alter table public.question_bank_items add constraint question_bank_items_explanation_check CHECK (explanation IS NULL OR length(explanation) <= 3000);

alter table public.question_bank_items add constraint question_bank_items_status_check CHECK (status = ANY (ARRAY['DRAFT'::text, 'SUBMITTED'::text, 'APPROVED'::text, 'REJECTED'::text]));

alter table public.question_bank_items add constraint question_bank_items_check CHECK ((status = ANY (ARRAY['APPROVED'::text, 'REJECTED'::text])) = (reviewer_id IS NOT NULL));

alter table public.question_bank_items add constraint question_bank_items_pkey PRIMARY KEY (id);

alter table public.question_bank_items add constraint question_bank_items_root_id_revision_key UNIQUE (root_id, revision);

alter table public.homework_checks add constraint homework_checks_revision_check CHECK (revision > 0);

alter table public.homework_checks add constraint homework_checks_status_check CHECK (status = ANY (ARRAY['NOT_SUBMITTED'::text, 'NEEDS_WORK'::text, 'COMPLETE'::text]));

alter table public.homework_checks add constraint homework_checks_feedback_check CHECK (length(feedback) <= 1000);

alter table public.homework_checks add constraint homework_checks_pkey PRIMARY KEY (id);

alter table public.homework_checks add constraint homework_checks_class_log_id_enrollment_id_revision_key UNIQUE (class_log_id, enrollment_id, revision);

alter table public.academic_assessments add constraint academic_assessments_title_check CHECK (length(btrim(title)) >= 3 AND length(btrim(title)) <= 180);

alter table public.academic_assessments add constraint academic_assessments_max_marks_check CHECK (max_marks > 0::numeric AND max_marks <= 1000::numeric);

alter table public.academic_assessments add constraint academic_assessments_status_check CHECK (status = ANY (ARRAY['DRAFT'::text, 'PUBLISHED'::text, 'CANCELLED'::text]));

alter table public.academic_assessments add constraint academic_assessments_check CHECK ((status = 'DRAFT'::text) = (published_at IS NULL) OR status = 'CANCELLED'::text);

alter table public.academic_assessments add constraint academic_assessments_pkey PRIMARY KEY (id);

alter table public.assessment_result_submissions add constraint assessment_result_submissions_revision_check CHECK (revision > 0);

alter table public.assessment_result_submissions add constraint assessment_result_submissions_status_check CHECK (status = ANY (ARRAY['DRAFT'::text, 'SUBMITTED'::text, 'APPROVED'::text, 'REJECTED'::text]));

alter table public.assessment_result_submissions add constraint assessment_result_submissions_check CHECK ((status = ANY (ARRAY['APPROVED'::text, 'REJECTED'::text])) = (reviewer_id IS NOT NULL));

alter table public.assessment_result_submissions add constraint assessment_result_submissions_pkey PRIMARY KEY (id);

alter table public.assessment_result_submissions add constraint assessment_result_submissions_assessment_id_revision_key UNIQUE (assessment_id, revision);

alter table public.finance_accounts add constraint finance_accounts_account_type_check CHECK (account_type = ANY (ARRAY['ASSET'::text, 'LIABILITY'::text, 'EQUITY'::text, 'REVENUE'::text, 'CONTRA_REVENUE'::text, 'EXPENSE'::text]));

alter table public.finance_accounts add constraint finance_accounts_pkey PRIMARY KEY (id);

alter table public.finance_accounts add constraint finance_accounts_organization_id_code_key UNIQUE (organization_id, code);

alter table public.finance_cost_centres add constraint finance_cost_centres_pkey PRIMARY KEY (id);

alter table public.finance_cost_centres add constraint finance_cost_centres_organization_id_code_key UNIQUE (organization_id, code);

alter table public.general_ledger_journals add constraint general_ledger_journals_journal_type_check CHECK (journal_type = ANY (ARRAY['INVOICE'::text, 'INVOICE_CREDIT'::text, 'PAYMENT'::text, 'REFUND'::text, 'ADVANCE_PAYMENT'::text, 'ADVANCE_SETTLEMENT'::text, 'ADVANCE_REFUND'::text, 'EXPENSE'::text, 'PAYABLE_SETTLEMENT'::text, 'COMPENSATION_RUN'::text, 'COMPENSATION_SETTLEMENT'::text, 'MANUAL'::text]));

alter table public.general_ledger_journals add constraint general_ledger_journals_status_check CHECK (status = ANY (ARRAY['POSTED'::text, 'VOIDED'::text]));

alter table public.general_ledger_journals add constraint general_ledger_journals_pkey PRIMARY KEY (id);

alter table public.general_ledger_journals add constraint general_ledger_journals_journal_no_key UNIQUE (journal_no);

alter table public.general_ledger_journals add constraint general_ledger_journals_source_type_source_id_key UNIQUE (source_type, source_id);

alter table public.general_ledger_lines add constraint general_ledger_lines_debit_check CHECK (debit >= 0::numeric);

alter table public.general_ledger_lines add constraint general_ledger_lines_credit_check CHECK (credit >= 0::numeric);

alter table public.general_ledger_lines add constraint general_ledger_lines_check CHECK (debit = 0::numeric AND credit > 0::numeric OR credit = 0::numeric AND debit > 0::numeric);

alter table public.general_ledger_lines add constraint general_ledger_lines_pkey PRIMARY KEY (id);

alter table public.general_ledger_lines add constraint general_ledger_lines_journal_id_line_no_key UNIQUE (journal_id, line_no);

alter table public.vendors add constraint vendors_pkey PRIMARY KEY (id);

alter table public.vendors add constraint vendors_vendor_no_key UNIQUE (vendor_no);

alter table public.vendors add constraint vendors_organization_id_name_key UNIQUE (organization_id, name);

alter table public.finance_payment_account_map add constraint finance_payment_account_map_pkey PRIMARY KEY (payment_method_id);

alter table public.finance_fee_revenue_map add constraint finance_fee_revenue_map_pkey PRIMARY KEY (id);

alter table public.finance_fee_revenue_map add constraint finance_fee_revenue_map_organization_id_charge_type_key UNIQUE (organization_id, charge_type);

alter table public.finance_payables add constraint finance_payables_payable_type_check CHECK (payable_type = ANY (ARRAY['TEACHER_COMPENSATION'::text, 'VENDOR'::text, 'STAFF_REIMBURSEMENT'::text, 'OTHER'::text]));

alter table public.finance_payables add constraint finance_payables_original_amount_check CHECK (original_amount > 0::numeric);

alter table public.finance_payables add constraint finance_payables_status_check CHECK (status = ANY (ARRAY['OPEN'::text, 'PARTIALLY_SETTLED'::text, 'SETTLED'::text, 'VOIDED'::text]));

alter table public.finance_payables add constraint finance_payables_pkey PRIMARY KEY (id);

alter table public.finance_payables add constraint finance_payables_payable_no_key UNIQUE (payable_no);

alter table public.finance_payables add constraint finance_payables_source_type_source_id_key UNIQUE (source_type, source_id);

alter table public.finance_payable_settlements add constraint finance_payable_settlements_amount_check CHECK (amount > 0::numeric);

alter table public.finance_payable_settlements add constraint finance_payable_settlements_pkey PRIMARY KEY (id);

alter table public.finance_payable_settlements add constraint finance_payable_settlements_payable_id_id_key UNIQUE (payable_id, id);

alter table public.finance_advances add constraint finance_advances_beneficiary_type_check CHECK (beneficiary_type = ANY (ARRAY['STAFF'::text, 'VENDOR'::text, 'PROJECT'::text]));

alter table public.finance_advances add constraint finance_advances_requested_amount_check CHECK (requested_amount > 0::numeric);

alter table public.finance_advances add constraint finance_advances_status_check CHECK (status = ANY (ARRAY['REQUESTED'::text, 'APPROVED'::text, 'PAID'::text, 'PARTIALLY_SETTLED'::text, 'SETTLED'::text, 'REFUNDED'::text, 'OVERDUE'::text, 'REJECTED'::text]));

alter table public.finance_advances add constraint finance_advances_check CHECK (beneficiary_type = 'STAFF'::text AND staff_id IS NOT NULL AND vendor_id IS NULL OR beneficiary_type = 'VENDOR'::text AND vendor_id IS NOT NULL AND staff_id IS NULL OR beneficiary_type = 'PROJECT'::text AND staff_id IS NULL AND vendor_id IS NULL AND NULLIF(btrim(project_reference), ''::text) IS NOT NULL);

alter table public.finance_advances add constraint finance_advances_pkey PRIMARY KEY (id);

alter table public.finance_advances add constraint finance_advances_advance_no_key UNIQUE (advance_no);

alter table public.finance_advance_movements add constraint finance_advance_movements_movement_type_check CHECK (movement_type = ANY (ARRAY['PAYMENT'::text, 'SETTLEMENT'::text, 'REFUND'::text]));

alter table public.finance_advance_movements add constraint finance_advance_movements_amount_check CHECK (amount > 0::numeric);

alter table public.finance_advance_movements add constraint finance_advance_movements_pkey PRIMARY KEY (id);

alter table public.finance_advance_movements add constraint finance_advance_movements_source_type_source_id_key UNIQUE (source_type, source_id);

alter table public.finance_expense_categories add constraint finance_expense_categories_pkey PRIMARY KEY (id);

alter table public.finance_expense_categories add constraint finance_expense_categories_organization_id_code_key UNIQUE (organization_id, code);

alter table public.finance_expenses add constraint finance_expenses_payment_mode_check CHECK (payment_mode = ANY (ARRAY['PAID_NOW'::text, 'ON_ACCOUNT'::text]));

alter table public.finance_expenses add constraint finance_expenses_amount_check CHECK (amount > 0::numeric);

alter table public.finance_expenses add constraint finance_expenses_status_check CHECK (status = ANY (ARRAY['DRAFT'::text, 'PENDING_APPROVAL'::text, 'APPROVED'::text, 'REJECTED'::text, 'POSTED'::text, 'RECONCILED'::text]));

alter table public.finance_expenses add constraint finance_expenses_check CHECK (payment_mode = 'PAID_NOW'::text AND payment_account_id IS NOT NULL OR payment_mode = 'ON_ACCOUNT'::text AND payment_account_id IS NULL);

alter table public.finance_expenses add constraint finance_expenses_pkey PRIMARY KEY (id);

alter table public.finance_expenses add constraint finance_expenses_expense_no_key UNIQUE (expense_no);

alter table public.finance_expense_reconciliations add constraint finance_expense_reconciliations_matched_amount_check CHECK (matched_amount > 0::numeric);

alter table public.finance_expense_reconciliations add constraint finance_expense_reconciliations_pkey PRIMARY KEY (id);

alter table public.finance_expense_reconciliations add constraint finance_expense_reconciliations_expense_id_key UNIQUE (expense_id);

alter table public.finance_account_reconciliations add constraint finance_account_reconciliations_status_check CHECK (status = ANY (ARRAY['OPEN'::text, 'RECONCILED'::text]));

alter table public.finance_account_reconciliations add constraint finance_account_reconciliations_pkey PRIMARY KEY (id);

alter table public.finance_account_reconciliations add constraint finance_account_reconciliatio_account_id_statement_date_sta_key UNIQUE (account_id, statement_date, statement_reference);

alter table public.teacher_referrals add constraint teacher_referrals_pkey PRIMARY KEY (id);

alter table public.teacher_referrals add constraint teacher_referrals_admission_id_key UNIQUE (admission_id);

alter table public.teacher_compensation_runs add constraint teacher_compensation_runs_status_check CHECK (status = ANY (ARRAY['DRAFT'::text, 'PENDING_APPROVAL'::text, 'APPROVED'::text, 'SETTLED'::text, 'REJECTED'::text]));

alter table public.teacher_compensation_runs add constraint teacher_compensation_runs_total_amount_check CHECK (total_amount >= 0::numeric);

alter table public.teacher_compensation_runs add constraint teacher_compensation_runs_check CHECK (period_end >= period_start);

alter table public.teacher_compensation_runs add constraint teacher_compensation_runs_pkey PRIMARY KEY (id);

alter table public.teacher_compensation_runs add constraint teacher_compensation_runs_run_no_key UNIQUE (run_no);

alter table public.teacher_compensation_events add constraint teacher_compensation_events_event_type_check CHECK (event_type = ANY (ARRAY['ACQUISITION_BONUS'::text, 'RETENTION_3_MONTH'::text, 'RETENTION_6_MONTH'::text]));

alter table public.teacher_compensation_events add constraint teacher_compensation_events_amount_check CHECK (amount >= 0::numeric);

alter table public.teacher_compensation_events add constraint teacher_compensation_events_pkey PRIMARY KEY (id);

alter table public.teacher_compensation_events add constraint teacher_compensation_events_event_key_key UNIQUE (event_key);

alter table public.teacher_compensation_adjustments add constraint teacher_compensation_adjustments_amount_check CHECK (amount > 0::numeric);

alter table public.teacher_compensation_adjustments add constraint teacher_compensation_adjustments_adjustment_type_check CHECK (adjustment_type = ANY (ARRAY['GROWTH_BONUS'::text, 'ADJUSTMENT'::text]));

alter table public.teacher_compensation_adjustments add constraint teacher_compensation_adjustments_status_check CHECK (status = ANY (ARRAY['PENDING'::text, 'APPROVED'::text, 'REJECTED'::text]));

alter table public.teacher_compensation_adjustments add constraint teacher_compensation_adjustments_pkey PRIMARY KEY (id);

alter table public.teacher_compensation_lines add constraint teacher_compensation_lines_line_type_check CHECK (line_type = ANY (ARRAY['TEACHING_REMUNERATION'::text, 'ACQUISITION_BONUS'::text, 'RETENTION_3_MONTH'::text, 'RETENTION_6_MONTH'::text, 'GROWTH_BONUS'::text, 'ADJUSTMENT'::text]));

alter table public.teacher_compensation_lines add constraint teacher_compensation_lines_amount_check CHECK (amount > 0::numeric);

alter table public.teacher_compensation_lines add constraint teacher_compensation_lines_pkey PRIMARY KEY (id);

alter table public.teacher_compensation_lines add constraint teacher_compensation_lines_run_id_source_type_source_id_key UNIQUE (run_id, source_type, source_id);

alter table public.teacher_compensation_settlements add constraint teacher_compensation_settlements_gross_amount_check CHECK (gross_amount > 0::numeric);

alter table public.teacher_compensation_settlements add constraint teacher_compensation_settlements_advance_offset_check CHECK (advance_offset >= 0::numeric);

alter table public.teacher_compensation_settlements add constraint teacher_compensation_settlements_cash_paid_check CHECK (cash_paid >= 0::numeric);

alter table public.teacher_compensation_settlements add constraint teacher_compensation_settlements_check CHECK (cash_paid = 0::numeric OR payment_account_id IS NOT NULL);

alter table public.teacher_compensation_settlements add constraint teacher_compensation_settlements_pkey PRIMARY KEY (id);

alter table public.teacher_compensation_settlements add constraint teacher_compensation_settlements_payable_id_key UNIQUE (payable_id);

alter table public.teacher_compensation_settlements add constraint teacher_compensation_settlements_run_id_teacher_id_key UNIQUE (run_id, teacher_id);

alter table public.teacher_compensation_claims add constraint teacher_compensation_claims_pkey PRIMARY KEY (id);

alter table public.teacher_compensation_claims add constraint teacher_compensation_claims_line_id_key UNIQUE (line_id);

alter table public.teacher_compensation_claims add constraint teacher_compensation_claims_teacher_id_source_type_source_i_key UNIQUE (teacher_id, source_type, source_id);

alter table public.referral_people add constraint referral_people_full_name_check CHECK (length(btrim(full_name)) >= 2);

alter table public.referral_people add constraint referral_people_check CHECK (staff_id IS NOT NULL OR mobile ~ '^01[3-9][0-9]{8}$'::text);

alter table public.referral_people add constraint referral_people_pkey PRIMARY KEY (id);

alter table public.referral_people add constraint referral_people_staff_id_key UNIQUE (staff_id);

alter table public.referral_people add constraint referral_people_organization_id_mobile_key UNIQUE (organization_id, mobile);

alter table public.admission_referrals add constraint admission_referrals_source_check CHECK (source = ANY (ARRAY['ORGANIC'::text, 'REFERRED'::text]));

alter table public.admission_referrals add constraint admission_referrals_check CHECK (source = 'ORGANIC'::text AND referrer_id IS NULL OR source = 'REFERRED'::text AND referrer_id IS NOT NULL);

alter table public.admission_referrals add constraint admission_referrals_pkey PRIMARY KEY (admission_id);

alter table public.referral_bonus_awards add constraint referral_bonus_awards_net_collected_check CHECK (net_collected > 0::numeric);

alter table public.referral_bonus_awards add constraint referral_bonus_awards_bonus_percent_check CHECK (bonus_percent >= 0::numeric);

alter table public.referral_bonus_awards add constraint referral_bonus_awards_amount_check CHECK (amount > 0::numeric);

alter table public.referral_bonus_awards add constraint referral_bonus_awards_status_check CHECK (status = ANY (ARRAY['PENDING'::text, 'APPROVED'::text, 'REJECTED'::text]));

alter table public.referral_bonus_awards add constraint referral_bonus_awards_pkey PRIMARY KEY (id);

alter table public.referral_bonus_awards add constraint referral_bonus_awards_payable_id_key UNIQUE (payable_id);

alter table public.staff_admission_intake_requests add constraint staff_admission_intake_requests_pkey PRIMARY KEY (request_id);

alter table public.admission_physical_consent_receipts add constraint admission_physical_consent_receipts_version_check CHECK (version > 0);

alter table public.admission_physical_consent_receipts add constraint admission_physical_consent_receip_physical_copy_reference_check CHECK (physical_copy_reference IS NULL OR length(physical_copy_reference) <= 160);

alter table public.admission_physical_consent_receipts add constraint admission_physical_consent_receipts_reason_check CHECK (length(TRIM(BOTH FROM reason)) >= 5);

alter table public.admission_physical_consent_receipts add constraint admission_physical_consent_receipts_pkey PRIMARY KEY (id);

alter table public.admission_physical_consent_receipts add constraint admission_physical_consent_receipts_request_id_key UNIQUE (request_id);

alter table public.admission_physical_consent_receipts add constraint admission_physical_consent_receipts_admission_id_version_key UNIQUE (admission_id, version);

alter table public.admission_cases add constraint admission_identity_source CHECK (origin = 'DIRECT_STAFF'::text AND NOT existing_student AND origin_prospect_id IS NULL OR (origin = ANY (ARRAY['PROSPECT_CONVERSION'::text, 'PUBLIC_APPLICATION'::text])) AND NOT existing_student AND prospect_id IS NOT NULL AND origin_prospect_id = prospect_id OR origin = 'EXISTING_STUDENT'::text AND existing_student AND student_id IS NOT NULL AND origin_prospect_id IS NULL);

alter table public.class_logs add constraint class_logs_status_check CHECK (status = ANY (ARRAY['DRAFT'::text, 'SUBMITTED'::text, 'APPROVED'::text, 'REJECTED'::text]));

alter table public.class_logs add constraint class_logs_review_fields_check CHECK ((status = ANY (ARRAY['APPROVED'::text, 'REJECTED'::text])) AND reviewer_id IS NOT NULL AND reviewed_at IS NOT NULL OR (status = ANY (ARRAY['DRAFT'::text, 'SUBMITTED'::text])));

alter table public.programme_offerings add constraint valid_discount_percentages CHECK (allowed_discount_percentages <@ ARRAY[5, 10, 15, 20, 25, 30]);

alter table public.admission_cases add constraint admission_cases_selected_discount_percent_check CHECK (selected_discount_percent = ANY (ARRAY[0, 5, 10, 15, 20, 25, 30]));

alter table public.staff_access_requests add constraint staff_access_requests_requested_role_check CHECK (requested_role = ANY (ARRAY['ADMIN'::text, 'OPERATOR'::text, 'TEACHER'::text, 'ACCOUNTANT'::text]));

alter table public.staff_access_requests add constraint staff_access_requests_status_check CHECK (status = ANY (ARRAY['PENDING'::text, 'VERIFIED'::text, 'INVITED'::text, 'DECLINED'::text, 'INACTIVE'::text]));

alter table public.staff_access_requests add constraint staff_access_requests_assigned_role_check CHECK (assigned_role = ANY (ARRAY['ADMIN'::text, 'OPERATOR'::text, 'TEACHER'::text, 'ACCOUNTANT'::text]));

alter table public.staff_access_requests add constraint staff_access_requests_pkey PRIMARY KEY (id);

alter table public.admission_cases add constraint admission_cases_status_check CHECK (status = ANY (ARRAY['DRAFT'::text, 'READY'::text, 'ACCEPTED'::text, 'BILLING_POSTED'::text, 'PENDING_PAYMENT'::text, 'ACTIVE_ENROLLMENT'::text, 'CANCELLED'::text, 'CLOSED_ENROLLMENT'::text]));

alter table public.admission_discounts add constraint admission_discounts_authorization_actor_check CHECK (authorized_by IS NOT NULL);

alter table public.refund_authorizations add constraint refund_authorizations_authorization_actor_check CHECK (authorized_by IS NOT NULL);

alter table public.admission_cancellations add constraint admission_cancellations_authorization_actor_check CHECK (cancelled_by IS NOT NULL);

alter table public.branches add constraint branches_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.profiles add constraint profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table public.role_permissions add constraint role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES system_roles(id);

alter table public.role_permissions add constraint role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES permissions(id);

alter table public.user_role_assignments add constraint user_role_assignments_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id);

alter table public.user_role_assignments add constraint user_role_assignments_role_id_fkey FOREIGN KEY (role_id) REFERENCES system_roles(id);

alter table public.user_role_assignments add constraint user_role_assignments_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id);

alter table public.user_role_assignments add constraint user_role_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES profiles(id);

alter table public.staff add constraint staff_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id);

alter table public.staff add constraint staff_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id);

alter table public.staff add constraint staff_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.staff_role_assignments add constraint staff_role_assignments_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(id);

alter table public.staff_role_assignments add constraint staff_role_assignments_staff_role_id_fkey FOREIGN KEY (staff_role_id) REFERENCES staff_roles(id);

alter table public.staff_role_assignments add constraint staff_role_assignments_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id);

alter table public.staff_role_assignments add constraint staff_role_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES profiles(id);

alter table public.audit_events add constraint audit_events_actor_profile_id_fkey FOREIGN KEY (actor_profile_id) REFERENCES profiles(id);

alter table public.audit_events add constraint audit_events_actor_staff_id_fkey FOREIGN KEY (actor_staff_id) REFERENCES staff(id);

alter table public.audit_events add constraint audit_events_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id);

alter table public.approval_requests add constraint approval_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES profiles(id);

alter table public.approval_requests add constraint approval_requests_decided_by_fkey FOREIGN KEY (decided_by) REFERENCES profiles(id);

alter table public.business_rule_versions add constraint business_rule_versions_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.academic_years add constraint academic_years_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.classes add constraint classes_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.programs add constraint programs_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.subjects add constraint subjects_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.areas add constraint areas_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.areas add constraint areas_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES areas(id);

alter table public.schools add constraint schools_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.schools add constraint schools_area_id_fkey FOREIGN KEY (area_id) REFERENCES areas(id);

alter table public.schools add constraint schools_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.lead_sources add constraint lead_sources_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.guardian_relationships add constraint guardian_relationships_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.payment_methods add constraint payment_methods_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.prospects add constraint prospects_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.prospects add constraint prospects_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id);

alter table public.prospects add constraint prospects_guardian_relationship_id_fkey FOREIGN KEY (guardian_relationship_id) REFERENCES guardian_relationships(id);

alter table public.prospects add constraint prospects_current_class_id_fkey FOREIGN KEY (current_class_id) REFERENCES classes(id);

alter table public.prospects add constraint prospects_school_id_fkey FOREIGN KEY (school_id) REFERENCES schools(id);

alter table public.prospects add constraint prospects_area_id_fkey FOREIGN KEY (area_id) REFERENCES areas(id);

alter table public.prospects add constraint prospects_source_id_fkey FOREIGN KEY (source_id) REFERENCES lead_sources(id);

alter table public.prospects add constraint prospects_assigned_to_staff_id_fkey FOREIGN KEY (assigned_to_staff_id) REFERENCES staff(id);

alter table public.prospect_program_interests add constraint prospect_program_interests_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id);

alter table public.prospect_program_interests add constraint prospect_program_interests_program_id_fkey FOREIGN KEY (program_id) REFERENCES programs(id);

alter table public.prospect_subject_interests add constraint prospect_subject_interests_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id);

alter table public.prospect_subject_interests add constraint prospect_subject_interests_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES subjects(id);

alter table public.prospect_followups add constraint prospect_followups_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id);

alter table public.prospect_followups add constraint prospect_followups_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES profiles(id);

alter table public.students add constraint students_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.students add constraint students_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id);

alter table public.students add constraint students_school_id_fkey FOREIGN KEY (school_id) REFERENCES schools(id);

alter table public.students add constraint students_created_from_prospect_id_fkey FOREIGN KEY (created_from_prospect_id) REFERENCES prospects(id);

alter table public.students add constraint students_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.prospects add constraint prospects_converted_student_fkey FOREIGN KEY (converted_student_id) REFERENCES students(id);

alter table public.guardians add constraint guardians_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.guardians add constraint guardians_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.student_guardians add constraint student_guardians_student_id_fkey FOREIGN KEY (student_id) REFERENCES students(id);

alter table public.student_guardians add constraint student_guardians_guardian_id_fkey FOREIGN KEY (guardian_id) REFERENCES guardians(id);

alter table public.student_guardians add constraint student_guardians_relationship_id_fkey FOREIGN KEY (relationship_id) REFERENCES guardian_relationships(id);

alter table public.batches add constraint batches_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.batches add constraint batches_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id);

alter table public.batches add constraint batches_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES academic_years(id);

alter table public.batches add constraint batches_class_id_fkey FOREIGN KEY (class_id) REFERENCES classes(id);

alter table public.batches add constraint batches_program_id_fkey FOREIGN KEY (program_id) REFERENCES programs(id);

alter table public.batches add constraint batches_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.enrollments add constraint enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES students(id);

alter table public.enrollments add constraint enrollments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.enrollments add constraint enrollments_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id);

alter table public.enrollments add constraint enrollments_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES academic_years(id);

alter table public.enrollments add constraint enrollments_class_id_fkey FOREIGN KEY (class_id) REFERENCES classes(id);

alter table public.enrollments add constraint enrollments_program_id_fkey FOREIGN KEY (program_id) REFERENCES programs(id);

alter table public.enrollments add constraint enrollments_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES batches(id);

alter table public.enrollments add constraint enrollments_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.staff_subject_assignments add constraint staff_subject_assignments_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(id);

alter table public.staff_subject_assignments add constraint staff_subject_assignments_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES subjects(id);

alter table public.staff_subject_assignments add constraint staff_subject_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES profiles(id);

alter table public.academic_groups add constraint academic_groups_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.programme_offerings add constraint programme_offerings_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.programme_offerings add constraint programme_offerings_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id);

alter table public.programme_offerings add constraint programme_offerings_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES academic_years(id);

alter table public.programme_offerings add constraint programme_offerings_class_id_fkey FOREIGN KEY (class_id) REFERENCES classes(id);

alter table public.programme_offerings add constraint programme_offerings_program_id_fkey FOREIGN KEY (program_id) REFERENCES programs(id);

alter table public.programme_offerings add constraint programme_offerings_group_id_fkey FOREIGN KEY (group_id) REFERENCES academic_groups(id);

alter table public.programme_offerings add constraint programme_offerings_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.fee_plan_versions add constraint fee_plan_versions_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES programme_offerings(id);

alter table public.fee_plan_versions add constraint fee_plan_versions_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.fee_plan_components add constraint fee_plan_components_fee_plan_version_id_fkey FOREIGN KEY (fee_plan_version_id) REFERENCES fee_plan_versions(id);

alter table public.batches add constraint batches_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES programme_offerings(id);

alter table public.batches add constraint batches_capacity_policy_version_id_fkey FOREIGN KEY (capacity_policy_version_id) REFERENCES business_rule_versions(id);

alter table public.admission_cases add constraint admission_cases_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id);

alter table public.admission_cases add constraint admission_cases_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES batches(id);

alter table public.admission_cases add constraint admission_cases_fee_plan_version_id_fkey FOREIGN KEY (fee_plan_version_id) REFERENCES fee_plan_versions(id);

alter table public.admission_cases add constraint admission_cases_activation_policy_version_id_fkey FOREIGN KEY (activation_policy_version_id) REFERENCES business_rule_versions(id);

alter table public.admission_cases add constraint admission_cases_capacity_policy_version_id_fkey FOREIGN KEY (capacity_policy_version_id) REFERENCES business_rule_versions(id);

alter table public.admission_cases add constraint admission_cases_student_id_fkey FOREIGN KEY (student_id) REFERENCES students(id);

alter table public.admission_cases add constraint admission_cases_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES enrollments(id);

alter table public.admission_cases add constraint admission_cases_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.admission_invoices add constraint admission_invoices_admission_id_fkey FOREIGN KEY (admission_id) REFERENCES admission_cases(id);

alter table public.admission_invoices add constraint admission_invoices_student_id_fkey FOREIGN KEY (student_id) REFERENCES students(id);

alter table public.admission_invoices add constraint admission_invoices_fee_plan_version_id_fkey FOREIGN KEY (fee_plan_version_id) REFERENCES fee_plan_versions(id);

alter table public.admission_invoices add constraint admission_invoices_posted_by_fkey FOREIGN KEY (posted_by) REFERENCES profiles(id);

alter table public.admission_invoice_lines add constraint admission_invoice_lines_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES admission_invoices(id);

alter table public.admission_invoice_lines add constraint admission_invoice_lines_fee_component_id_fkey FOREIGN KEY (fee_component_id) REFERENCES fee_plan_components(id);

alter table public.admission_command_keys add constraint admission_command_keys_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES profiles(id);

alter table public.admission_payments add constraint admission_payments_student_id_fkey FOREIGN KEY (student_id) REFERENCES students(id);

alter table public.admission_payments add constraint admission_payments_payment_method_id_fkey FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id);

alter table public.admission_payments add constraint admission_payments_posted_by_fkey FOREIGN KEY (posted_by) REFERENCES profiles(id);

alter table public.admission_payment_allocations add constraint admission_payment_allocations_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES admission_payments(id);

alter table public.admission_payment_allocations add constraint admission_payment_allocations_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES admission_invoices(id);

alter table public.billing_terms add constraint billing_terms_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES academic_years(id);

alter table public.billing_terms add constraint billing_terms_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.admission_discounts add constraint admission_discounts_admission_id_fkey FOREIGN KEY (admission_id) REFERENCES admission_cases(id);

alter table public.invoice_credits add constraint invoice_credits_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES admission_invoices(id);

alter table public.invoice_credits add constraint invoice_credits_discount_id_fkey FOREIGN KEY (discount_id) REFERENCES admission_discounts(id);

alter table public.refund_authorizations add constraint refund_authorizations_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES admission_payments(id);

alter table public.refund_authorizations add constraint refund_authorizations_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES admission_invoices(id);

alter table public.refund_payouts add constraint refund_payouts_authorization_id_fkey FOREIGN KEY (authorization_id) REFERENCES refund_authorizations(id);

alter table public.refund_payouts add constraint refund_payouts_payment_method_id_fkey FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id);

alter table public.refund_payouts add constraint refund_payouts_posted_by_fkey FOREIGN KEY (posted_by) REFERENCES profiles(id);

alter table public.admission_cancellations add constraint admission_cancellations_admission_id_fkey FOREIGN KEY (admission_id) REFERENCES admission_cases(id);

alter table public.billing_runs add constraint billing_runs_term_id_fkey FOREIGN KEY (term_id) REFERENCES billing_terms(id);

alter table public.billing_runs add constraint billing_runs_posted_by_fkey FOREIGN KEY (posted_by) REFERENCES profiles(id);

alter table public.students add constraint students_merged_into_id_fkey FOREIGN KEY (merged_into_id) REFERENCES students(id);

alter table public.student_merges add constraint student_merges_source_id_fkey FOREIGN KEY (source_id) REFERENCES students(id);

alter table public.student_merges add constraint student_merges_target_id_fkey FOREIGN KEY (target_id) REFERENCES students(id);

alter table public.enrollment_transfers add constraint enrollment_transfers_student_id_fkey FOREIGN KEY (student_id) REFERENCES students(id);

alter table public.enrollment_transfers add constraint enrollment_transfers_admission_id_fkey FOREIGN KEY (admission_id) REFERENCES admission_cases(id);

alter table public.enrollment_transfers add constraint enrollment_transfers_from_enrollment_id_fkey FOREIGN KEY (from_enrollment_id) REFERENCES enrollments(id);

alter table public.enrollment_transfers add constraint enrollment_transfers_to_enrollment_id_fkey FOREIGN KEY (to_enrollment_id) REFERENCES enrollments(id);

alter table public.enrollment_transfers add constraint enrollment_transfers_from_batch_id_fkey FOREIGN KEY (from_batch_id) REFERENCES batches(id);

alter table public.enrollment_transfers add constraint enrollment_transfers_to_batch_id_fkey FOREIGN KEY (to_batch_id) REFERENCES batches(id);

alter table public.enrollment_transfers add constraint enrollment_transfers_capacity_policy_version_id_fkey FOREIGN KEY (capacity_policy_version_id) REFERENCES business_rule_versions(id);

alter table public.academic_rooms add constraint academic_rooms_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id);

alter table public.academic_rooms add constraint academic_rooms_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.curriculum_versions add constraint curriculum_versions_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES batches(id);

alter table public.curriculum_versions add constraint curriculum_versions_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES subjects(id);

alter table public.curriculum_versions add constraint curriculum_versions_published_by_fkey FOREIGN KEY (published_by) REFERENCES profiles(id);

alter table public.academic_routines add constraint academic_routines_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES batches(id);

alter table public.academic_routines add constraint academic_routines_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES subjects(id);

alter table public.academic_routines add constraint academic_routines_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES staff(id);

alter table public.academic_routines add constraint academic_routines_room_id_fkey FOREIGN KEY (room_id) REFERENCES academic_rooms(id);

alter table public.academic_routines add constraint academic_routines_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.class_sessions add constraint class_sessions_routine_id_fkey FOREIGN KEY (routine_id) REFERENCES academic_routines(id);

alter table public.class_sessions add constraint class_sessions_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES batches(id);

alter table public.class_sessions add constraint class_sessions_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES subjects(id);

alter table public.class_sessions add constraint class_sessions_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES staff(id);

alter table public.class_sessions add constraint class_sessions_room_id_fkey FOREIGN KEY (room_id) REFERENCES academic_rooms(id);

alter table public.class_sessions add constraint class_sessions_curriculum_version_id_fkey FOREIGN KEY (curriculum_version_id) REFERENCES curriculum_versions(id);

alter table public.class_sessions add constraint class_sessions_cancelled_by_fkey FOREIGN KEY (cancelled_by) REFERENCES profiles(id);

alter table public.class_sessions add constraint class_sessions_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.attendance_submissions add constraint attendance_submissions_session_id_fkey FOREIGN KEY (session_id) REFERENCES class_sessions(id);

alter table public.attendance_submissions add constraint attendance_submissions_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES profiles(id);

alter table public.attendance_submissions add constraint attendance_submissions_approval_id_fkey FOREIGN KEY (approval_id) REFERENCES approval_requests(id);

alter table public.programme_offering_subjects add constraint programme_offering_subjects_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES programme_offerings(id) ON DELETE CASCADE;

alter table public.programme_offering_subjects add constraint programme_offering_subjects_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES subjects(id);

alter table public.prospects add constraint prospects_interested_offering_id_fkey FOREIGN KEY (interested_offering_id) REFERENCES programme_offerings(id);

alter table public.class_logs add constraint class_logs_session_id_fkey FOREIGN KEY (session_id) REFERENCES class_sessions(id);

alter table public.class_logs add constraint class_logs_previous_log_id_fkey FOREIGN KEY (previous_log_id) REFERENCES class_logs(id);

alter table public.class_logs add constraint class_logs_authored_by_fkey FOREIGN KEY (authored_by) REFERENCES profiles(id);

alter table public.question_bank_items add constraint question_bank_items_root_id_fkey FOREIGN KEY (root_id) REFERENCES question_bank_items(id);

alter table public.question_bank_items add constraint question_bank_items_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES batches(id);

alter table public.question_bank_items add constraint question_bank_items_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES subjects(id);

alter table public.question_bank_items add constraint question_bank_items_curriculum_version_id_fkey FOREIGN KEY (curriculum_version_id) REFERENCES curriculum_versions(id);

alter table public.question_bank_items add constraint question_bank_items_author_id_fkey FOREIGN KEY (author_id) REFERENCES profiles(id);

alter table public.question_bank_items add constraint question_bank_items_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES profiles(id);

alter table public.homework_checks add constraint homework_checks_class_log_id_fkey FOREIGN KEY (class_log_id) REFERENCES class_logs(id);

alter table public.homework_checks add constraint homework_checks_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES enrollments(id);

alter table public.homework_checks add constraint homework_checks_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES profiles(id);

alter table public.academic_assessments add constraint academic_assessments_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES batches(id);

alter table public.academic_assessments add constraint academic_assessments_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES subjects(id);

alter table public.academic_assessments add constraint academic_assessments_author_id_fkey FOREIGN KEY (author_id) REFERENCES profiles(id);

alter table public.assessment_result_submissions add constraint assessment_result_submissions_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES academic_assessments(id);

alter table public.assessment_result_submissions add constraint assessment_result_submissions_author_id_fkey FOREIGN KEY (author_id) REFERENCES profiles(id);

alter table public.assessment_result_submissions add constraint assessment_result_submissions_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES profiles(id);

alter table public.finance_accounts add constraint finance_accounts_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.finance_accounts add constraint finance_accounts_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES finance_accounts(id);

alter table public.finance_accounts add constraint finance_accounts_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.finance_cost_centres add constraint finance_cost_centres_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.finance_cost_centres add constraint finance_cost_centres_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id);

alter table public.finance_cost_centres add constraint finance_cost_centres_program_id_fkey FOREIGN KEY (program_id) REFERENCES programs(id);

alter table public.finance_cost_centres add constraint finance_cost_centres_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES batches(id);

alter table public.finance_cost_centres add constraint finance_cost_centres_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.general_ledger_journals add constraint general_ledger_journals_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.general_ledger_journals add constraint general_ledger_journals_posted_by_fkey FOREIGN KEY (posted_by) REFERENCES profiles(id);

alter table public.general_ledger_lines add constraint general_ledger_lines_journal_id_fkey FOREIGN KEY (journal_id) REFERENCES general_ledger_journals(id);

alter table public.general_ledger_lines add constraint general_ledger_lines_account_id_fkey FOREIGN KEY (account_id) REFERENCES finance_accounts(id);

alter table public.general_ledger_lines add constraint general_ledger_lines_cost_centre_id_fkey FOREIGN KEY (cost_centre_id) REFERENCES finance_cost_centres(id);

alter table public.general_ledger_lines add constraint general_ledger_lines_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES branches(id);

alter table public.general_ledger_lines add constraint general_ledger_lines_program_id_fkey FOREIGN KEY (program_id) REFERENCES programs(id);

alter table public.general_ledger_lines add constraint general_ledger_lines_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES batches(id);

alter table public.vendors add constraint vendors_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.vendors add constraint vendors_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.finance_payment_account_map add constraint finance_payment_account_map_payment_method_id_fkey FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id);

alter table public.finance_payment_account_map add constraint finance_payment_account_map_account_id_fkey FOREIGN KEY (account_id) REFERENCES finance_accounts(id);

alter table public.finance_fee_revenue_map add constraint finance_fee_revenue_map_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.finance_fee_revenue_map add constraint finance_fee_revenue_map_account_id_fkey FOREIGN KEY (account_id) REFERENCES finance_accounts(id);

alter table public.finance_payables add constraint finance_payables_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.finance_payables add constraint finance_payables_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(id);

alter table public.finance_payables add constraint finance_payables_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES vendors(id);

alter table public.finance_payables add constraint finance_payables_payable_account_id_fkey FOREIGN KEY (payable_account_id) REFERENCES finance_accounts(id);

alter table public.finance_payables add constraint finance_payables_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.finance_payable_settlements add constraint finance_payable_settlements_payable_id_fkey FOREIGN KEY (payable_id) REFERENCES finance_payables(id);

alter table public.finance_payable_settlements add constraint finance_payable_settlements_payment_account_id_fkey FOREIGN KEY (payment_account_id) REFERENCES finance_accounts(id);

alter table public.finance_payable_settlements add constraint finance_payable_settlements_settled_by_fkey FOREIGN KEY (settled_by) REFERENCES profiles(id);

alter table public.finance_advances add constraint finance_advances_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.finance_advances add constraint finance_advances_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(id);

alter table public.finance_advances add constraint finance_advances_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES vendors(id);

alter table public.finance_advances add constraint finance_advances_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES profiles(id);

alter table public.finance_advance_movements add constraint finance_advance_movements_advance_id_fkey FOREIGN KEY (advance_id) REFERENCES finance_advances(id);

alter table public.finance_advance_movements add constraint finance_advance_movements_payment_account_id_fkey FOREIGN KEY (payment_account_id) REFERENCES finance_accounts(id);

alter table public.finance_advance_movements add constraint finance_advance_movements_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.finance_expense_categories add constraint finance_expense_categories_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.finance_expense_categories add constraint finance_expense_categories_expense_account_id_fkey FOREIGN KEY (expense_account_id) REFERENCES finance_accounts(id);

alter table public.finance_expense_categories add constraint finance_expense_categories_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.finance_expenses add constraint finance_expenses_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.finance_expenses add constraint finance_expenses_category_id_fkey FOREIGN KEY (category_id) REFERENCES finance_expense_categories(id);

alter table public.finance_expenses add constraint finance_expenses_expense_account_id_fkey FOREIGN KEY (expense_account_id) REFERENCES finance_accounts(id);

alter table public.finance_expenses add constraint finance_expenses_payment_account_id_fkey FOREIGN KEY (payment_account_id) REFERENCES finance_accounts(id);

alter table public.finance_expenses add constraint finance_expenses_payable_id_fkey FOREIGN KEY (payable_id) REFERENCES finance_payables(id);

alter table public.finance_expenses add constraint finance_expenses_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES vendors(id);

alter table public.finance_expenses add constraint finance_expenses_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(id);

alter table public.finance_expenses add constraint finance_expenses_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES profiles(id);

alter table public.finance_expenses add constraint finance_expenses_posted_by_fkey FOREIGN KEY (posted_by) REFERENCES profiles(id);

alter table public.finance_expense_reconciliations add constraint finance_expense_reconciliations_expense_id_fkey FOREIGN KEY (expense_id) REFERENCES finance_expenses(id);

alter table public.finance_expense_reconciliations add constraint finance_expense_reconciliations_reconciled_by_fkey FOREIGN KEY (reconciled_by) REFERENCES profiles(id);

alter table public.finance_account_reconciliations add constraint finance_account_reconciliations_account_id_fkey FOREIGN KEY (account_id) REFERENCES finance_accounts(id);

alter table public.finance_account_reconciliations add constraint finance_account_reconciliations_reconciled_by_fkey FOREIGN KEY (reconciled_by) REFERENCES profiles(id);

alter table public.teacher_referrals add constraint teacher_referrals_admission_id_fkey FOREIGN KEY (admission_id) REFERENCES admission_cases(id);

alter table public.teacher_referrals add constraint teacher_referrals_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES staff(id);

alter table public.teacher_referrals add constraint teacher_referrals_captured_by_fkey FOREIGN KEY (captured_by) REFERENCES profiles(id);

alter table public.teacher_compensation_runs add constraint teacher_compensation_runs_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.teacher_compensation_runs add constraint teacher_compensation_runs_policy_version_id_fkey FOREIGN KEY (policy_version_id) REFERENCES business_rule_versions(id);

alter table public.teacher_compensation_runs add constraint teacher_compensation_runs_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES profiles(id);

alter table public.teacher_compensation_runs add constraint teacher_compensation_runs_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES profiles(id);

alter table public.teacher_compensation_events add constraint teacher_compensation_events_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES staff(id);

alter table public.teacher_compensation_events add constraint teacher_compensation_events_admission_id_fkey FOREIGN KEY (admission_id) REFERENCES admission_cases(id);

alter table public.teacher_compensation_adjustments add constraint teacher_compensation_adjustments_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES staff(id);

alter table public.teacher_compensation_adjustments add constraint teacher_compensation_adjustments_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES profiles(id);

alter table public.teacher_compensation_adjustments add constraint teacher_compensation_adjustments_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES profiles(id);

alter table public.teacher_compensation_lines add constraint teacher_compensation_lines_run_id_fkey FOREIGN KEY (run_id) REFERENCES teacher_compensation_runs(id);

alter table public.teacher_compensation_lines add constraint teacher_compensation_lines_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES staff(id);

alter table public.teacher_compensation_settlements add constraint teacher_compensation_settlements_run_id_fkey FOREIGN KEY (run_id) REFERENCES teacher_compensation_runs(id);

alter table public.teacher_compensation_settlements add constraint teacher_compensation_settlements_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES staff(id);

alter table public.teacher_compensation_settlements add constraint teacher_compensation_settlements_payable_id_fkey FOREIGN KEY (payable_id) REFERENCES finance_payables(id);

alter table public.teacher_compensation_settlements add constraint teacher_compensation_settlements_payment_account_id_fkey FOREIGN KEY (payment_account_id) REFERENCES finance_accounts(id);

alter table public.teacher_compensation_settlements add constraint teacher_compensation_settlements_settled_by_fkey FOREIGN KEY (settled_by) REFERENCES profiles(id);

alter table public.teacher_compensation_lines add constraint teacher_compensation_lines_admission_id_fkey FOREIGN KEY (admission_id) REFERENCES admission_cases(id);

alter table public.teacher_compensation_claims add constraint teacher_compensation_claims_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES staff(id);

alter table public.teacher_compensation_claims add constraint teacher_compensation_claims_line_id_fkey FOREIGN KEY (line_id) REFERENCES teacher_compensation_lines(id);

alter table public.teacher_compensation_claims add constraint teacher_compensation_claims_run_id_fkey FOREIGN KEY (run_id) REFERENCES teacher_compensation_runs(id);

alter table public.finance_advance_movements add constraint finance_advance_movements_payable_id_fkey FOREIGN KEY (payable_id) REFERENCES finance_payables(id);

alter table public.finance_payable_settlements add constraint finance_payable_settlements_advance_id_fkey FOREIGN KEY (advance_id) REFERENCES finance_advances(id);

alter table public.referral_people add constraint referral_people_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);

alter table public.referral_people add constraint referral_people_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(id);

alter table public.referral_people add constraint referral_people_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id);

alter table public.admission_referrals add constraint admission_referrals_admission_id_fkey FOREIGN KEY (admission_id) REFERENCES admission_cases(id);

alter table public.admission_referrals add constraint admission_referrals_referrer_id_fkey FOREIGN KEY (referrer_id) REFERENCES referral_people(id);

alter table public.admission_referrals add constraint admission_referrals_captured_by_fkey FOREIGN KEY (captured_by) REFERENCES profiles(id);

alter table public.referral_bonus_awards add constraint referral_bonus_awards_admission_id_fkey FOREIGN KEY (admission_id) REFERENCES admission_cases(id);

alter table public.referral_bonus_awards add constraint referral_bonus_awards_referrer_id_fkey FOREIGN KEY (referrer_id) REFERENCES referral_people(id);

alter table public.referral_bonus_awards add constraint referral_bonus_awards_policy_version_id_fkey FOREIGN KEY (policy_version_id) REFERENCES business_rule_versions(id);

alter table public.referral_bonus_awards add constraint referral_bonus_awards_payable_id_fkey FOREIGN KEY (payable_id) REFERENCES finance_payables(id);

alter table public.referral_bonus_awards add constraint referral_bonus_awards_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES profiles(id);

alter table public.referral_bonus_awards add constraint referral_bonus_awards_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES profiles(id);

alter table public.finance_payables add constraint finance_payables_referrer_id_fkey FOREIGN KEY (referrer_id) REFERENCES referral_people(id);

alter table public.staff_admission_intake_requests add constraint staff_admission_intake_requests_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES profiles(id);

alter table public.staff_admission_intake_requests add constraint staff_admission_intake_requests_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id);

alter table public.staff_admission_intake_requests add constraint staff_admission_intake_requests_admission_id_fkey FOREIGN KEY (admission_id) REFERENCES admission_cases(id);

alter table public.admission_physical_consent_receipts add constraint admission_physical_consent_receipts_admission_id_fkey FOREIGN KEY (admission_id) REFERENCES admission_cases(id);

alter table public.admission_physical_consent_receipts add constraint admission_physical_consent_receipts_received_by_fkey FOREIGN KEY (received_by) REFERENCES profiles(id);

alter table public.admission_cases add constraint admission_cases_origin_prospect_id_fkey FOREIGN KEY (origin_prospect_id) REFERENCES prospects(id);

alter table public.class_logs add constraint class_logs_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES profiles(id);

alter table public.admission_discounts add constraint admission_discounts_authorized_by_fkey FOREIGN KEY (authorized_by) REFERENCES profiles(id);

alter table public.invoice_credits add constraint invoice_credits_applied_by_fkey FOREIGN KEY (applied_by) REFERENCES profiles(id);

alter table public.refund_authorizations add constraint refund_authorizations_authorized_by_fkey FOREIGN KEY (authorized_by) REFERENCES profiles(id);

alter table public.admission_cancellations add constraint admission_cancellations_cancelled_by_fkey FOREIGN KEY (cancelled_by) REFERENCES profiles(id);

alter table public.finance_advances add constraint finance_advances_authorized_by_fkey FOREIGN KEY (authorized_by) REFERENCES profiles(id);

alter table public.finance_expenses add constraint finance_expenses_authorized_by_fkey FOREIGN KEY (authorized_by) REFERENCES profiles(id);

alter table public.teacher_compensation_runs add constraint teacher_compensation_runs_authorized_by_fkey FOREIGN KEY (authorized_by) REFERENCES profiles(id);

alter table public.teacher_compensation_adjustments add constraint teacher_compensation_adjustments_authorized_by_fkey FOREIGN KEY (authorized_by) REFERENCES profiles(id);

alter table public.attendance_submissions add constraint attendance_submissions_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES profiles(id);

alter table public.prospects add constraint prospects_application_verified_by_fkey FOREIGN KEY (application_verified_by) REFERENCES profiles(id);

alter table public.organizations add constraint organizations_setup_completed_by_fkey FOREIGN KEY (setup_completed_by) REFERENCES profiles(id);

alter table public.staff_access_requests add constraint staff_access_requests_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id);

alter table public.staff_access_requests add constraint staff_access_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES profiles(id);

alter table public.student_merges add constraint student_merges_authorized_by_fkey FOREIGN KEY (authorized_by) REFERENCES public.profiles(id);

alter table public.enrollment_transfers add constraint enrollment_transfers_authorized_by_fkey FOREIGN KEY (authorized_by) REFERENCES public.profiles(id);

CREATE UNIQUE INDEX one_active_business_rule ON public.business_rule_versions USING btree (domain, rule_key) WHERE (status = 'ACTIVE'::rule_status);

CREATE UNIQUE INDEX programme_offering_context_uniq ON public.programme_offerings USING btree (academic_year_id, branch_id, class_id, program_id, COALESCE(group_id, '00000000-0000-0000-0000-000000000000'::uuid));

CREATE INDEX audit_events_correlation_idx ON public.audit_events USING btree (correlation_id);

CREATE INDEX admission_student_history ON public.admission_cases USING btree (student_id, created_at);

CREATE INDEX general_ledger_lines_account_idx ON public.general_ledger_lines USING btree (account_id, journal_id);

CREATE INDEX finance_advances_status_idx ON public.finance_advances USING btree (organization_id, status, expected_settlement_date);

CREATE INDEX admission_cases_origin_idx ON public.admission_cases USING btree (origin, created_at DESC);

CREATE UNIQUE INDEX assessment_one_pending ON public.assessment_result_submissions USING btree (assessment_id) WHERE (status = 'SUBMITTED'::text);

CREATE INDEX schools_search_idx ON public.schools USING btree (lower(name));

CREATE INDEX attendance_reviewed_idx ON public.attendance_submissions USING btree (session_id, status, revision DESC);

CREATE UNIQUE INDEX fee_plan_one_active_per_offering ON public.fee_plan_versions USING btree (offering_id) WHERE (status = 'ACTIVE'::rule_status);

CREATE UNIQUE INDEX invoice_credit_cancellation_unique ON public.invoice_credits USING btree (invoice_id) WHERE (kind = 'CANCELLATION'::text);

CREATE UNIQUE INDEX staff_primary_open_role_uniq ON public.staff_role_assignments USING btree (staff_id) WHERE (is_primary AND (effective_to IS NULL));

CREATE UNIQUE INDEX staff_access_open_email ON public.staff_access_requests USING btree (lower(email)) WHERE (status = ANY (ARRAY['PENDING'::text, 'VERIFIED'::text, 'INVITED'::text]));

CREATE UNIQUE INDEX admission_open_prospect ON public.admission_cases USING btree (prospect_id) WHERE (status <> 'CANCELLED'::text);

CREATE INDEX sessions_schedule ON public.class_sessions USING btree (starts_at, ends_at) WHERE (status = 'SCHEDULED'::text);

CREATE INDEX guardians_mobile_idx ON public.guardians USING btree (regexp_replace(mobile, '\D'::text, ''::text, 'g'::text));

CREATE UNIQUE INDEX student_academy_roll_unique ON public.students USING btree (academy_roll);

CREATE INDEX academic_assessments_scope ON public.academic_assessments USING btree (batch_id, subject_id, assessment_date DESC);

CREATE INDEX prospects_status_idx ON public.prospects USING btree (status, created_at DESC);

CREATE INDEX admission_physical_consent_case_idx ON public.admission_physical_consent_receipts USING btree (admission_id, version DESC);

CREATE UNIQUE INDEX assessment_one_draft ON public.assessment_result_submissions USING btree (assessment_id) WHERE (status = 'DRAFT'::text);

CREATE UNIQUE INDEX question_bank_one_draft ON public.question_bank_items USING btree (COALESCE(root_id, id)) WHERE (status = 'DRAFT'::text);

CREATE UNIQUE INDEX one_pending_attendance ON public.attendance_submissions USING btree (session_id) WHERE (status = 'SUBMITTED'::text);

CREATE UNIQUE INDEX admission_invoice_period ON public.admission_invoices USING btree (admission_id, billing_period);

CREATE UNIQUE INDEX one_primary_guardian_per_student ON public.student_guardians USING btree (student_id) WHERE is_primary;

CREATE UNIQUE INDEX admission_payment_external_reference ON public.admission_payments USING btree (payment_method_id, external_reference) WHERE (external_reference IS NOT NULL);

CREATE INDEX finance_payables_open_idx ON public.finance_payables USING btree (organization_id, status, due_on);

CREATE INDEX finance_expenses_status_idx ON public.finance_expenses USING btree (organization_id, status, expense_date DESC);

CREATE INDEX programme_offerings_website_visible_idx ON public.programme_offerings USING btree (showcase_sort_order, created_at) WHERE ((is_website_visible = true) AND (status = 'ACTIVE'::offering_status));

CREATE INDEX prospects_interested_offering_idx ON public.prospects USING btree (interested_offering_id) WHERE (interested_offering_id IS NOT NULL);

CREATE UNIQUE INDEX invoice_credit_discount_unique ON public.invoice_credits USING btree (invoice_id, discount_id) WHERE ((kind = 'DISCOUNT'::text) AND (discount_id IS NOT NULL));

CREATE INDEX prospects_followup_idx ON public.prospects USING btree (next_follow_up_at) WHERE (next_follow_up_at IS NOT NULL);

CREATE INDEX students_merged_into ON public.students USING btree (merged_into_id) WHERE (merged_into_id IS NOT NULL);

CREATE INDEX general_ledger_journals_date_idx ON public.general_ledger_journals USING btree (organization_id, journal_date DESC);

CREATE UNIQUE INDEX referral_bonus_one_live_award ON public.referral_bonus_awards USING btree (admission_id) WHERE (status = ANY (ARRAY['PENDING'::text, 'APPROVED'::text]));

CREATE INDEX homework_checks_history ON public.homework_checks USING btree (class_log_id, enrollment_id, revision DESC);

CREATE UNIQUE INDEX staff_subject_open_assignment_uniq ON public.staff_subject_assignments USING btree (staff_id, subject_id) WHERE (effective_to IS NULL);

CREATE UNIQUE INDEX class_logs_one_pending_per_session ON public.class_logs USING btree (session_id) WHERE (status = 'SUBMITTED'::text);

CREATE INDEX finance_accounts_type_idx ON public.finance_accounts USING btree (organization_id, account_type, is_active);

CREATE INDEX admission_cases_consent_gate_idx ON public.admission_cases USING btree (consent_required, status);

CREATE UNIQUE INDEX areas_name_parent_uniq ON public.areas USING btree (organization_id, lower(name), COALESCE(parent_id, '00000000-0000-0000-0000-000000000000'::uuid));

CREATE UNIQUE INDEX admission_one_initial_invoice ON public.admission_invoices USING btree (admission_id) WHERE (invoice_kind = 'INITIAL'::text);

CREATE UNIQUE INDEX one_class_log_draft_per_session ON public.class_logs USING btree (session_id) WHERE (status = 'DRAFT'::text);

CREATE INDEX approval_requests_pending_idx ON public.approval_requests USING btree (status, requested_at) WHERE (status = 'PENDING'::approval_status);

CREATE INDEX question_bank_scope_idx ON public.question_bank_items USING btree (batch_id, subject_id, created_at DESC);

CREATE INDEX class_logs_session_history ON public.class_logs USING btree (session_id, revision DESC);

CREATE UNIQUE INDEX user_role_open_assignment_uniq ON public.user_role_assignments USING btree (profile_id, role_id, COALESCE(branch_id, '00000000-0000-0000-0000-000000000000'::uuid)) WHERE (is_active AND (effective_to IS NULL));

CREATE INDEX audit_events_entity_idx ON public.audit_events USING btree (entity_type, entity_id, occurred_at DESC);

CREATE UNIQUE INDEX one_active_enrollment_per_student_year ON public.enrollments USING btree (student_id, academic_year_id) WHERE (status = 'ACTIVE'::enrollment_status);

CREATE INDEX prospects_mobile_idx ON public.prospects USING btree (regexp_replace(mobile, '\D'::text, ''::text, 'g'::text));

CREATE UNIQUE INDEX refund_external_reference ON public.refund_payouts USING btree (payment_method_id, external_reference) WHERE (external_reference IS NOT NULL);

-- Upstream 08_platform_crm_setup_workflows.sql
-- Sohoj Academy fresh database baseline: platform crm setup workflows.
-- Install on an empty application schema. Each object is defined once.

create view public.current_fee_plans with (security_invoker=true) as
 SELECT DISTINCT ON (offering_id) id,
    offering_id,
    version,
    status,
    billing_cycle,
    due_day,
    currency_code,
    effective_from,
    effective_to,
    change_reason,
    created_by,
    created_at
   FROM fee_plan_versions fp
  WHERE status = ANY (ARRAY['ACTIVE'::rule_status, 'RETIRED'::rule_status, 'DRAFT'::rule_status])
  ORDER BY offering_id, (
        CASE
            WHEN status = 'ACTIVE'::rule_status THEN 0
            ELSE 1
        END), effective_from DESC, created_at DESC, version DESC;

create view public.current_fee_plan_components with (security_invoker=true) as
 SELECT c.id,
    c.fee_plan_version_id,
    c.code,
    c.name,
    c.amount,
    c.charge_type,
    c.recurrence,
    c.sort_order
   FROM fee_plan_components c
     JOIN current_fee_plans fp ON fp.id = c.fee_plan_version_id;

create view public.current_operating_rules with (security_invoker=true) as
 SELECT DISTINCT ON (domain, rule_key) id,
    domain,
    rule_key,
    status,
    payload
   FROM business_rule_versions r
  WHERE status = ANY (ARRAY['ACTIVE'::rule_status, 'RETIRED'::rule_status, 'DRAFT'::rule_status])
  ORDER BY domain, rule_key, (
        CASE
            WHEN status = 'ACTIVE'::rule_status THEN 0
            ELSE 1
        END), version DESC;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  insert into public.profiles(id, display_name)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(split_part(coalesce(new.email,''), '@', 1), ''),
      'User'
    )
  )
  on conflict (id) do nothing;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.has_permission(p_permission_code text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.user_role_assignments ura
    join public.system_roles sr on sr.id = ura.role_id
    join public.role_permissions rp on rp.role_id = sr.id
    join public.permissions p on p.id = rp.permission_id
    join public.profiles pr on pr.id = ura.profile_id
    where ura.profile_id = auth.uid()
      and ura.is_active
      and (ura.effective_to is null or ura.effective_to >= current_date)
      and ura.effective_from <= current_date
      and sr.is_active
      and pr.status = 'ACTIVE'
      and p.code = p_permission_code
  );
$function$;

CREATE OR REPLACE FUNCTION public.my_erp_context()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object(
    'profile_id', p.id,
    'display_name', p.display_name,
    'status', p.status,
    'staff_id', s.id,
    'staff_no', s.staff_no,
    'staff_name', s.full_name,
    'roles', coalesce((
      select jsonb_agg(distinct sr.code order by sr.code)
      from public.user_role_assignments ura
      join public.system_roles sr on sr.id = ura.role_id
      where ura.profile_id = p.id
        and ura.is_active
        and ura.effective_from <= current_date
        and (ura.effective_to is null or ura.effective_to >= current_date)
        and sr.is_active
    ), '[]'::jsonb),
    'permissions', coalesce((
      select jsonb_agg(distinct pe.code order by pe.code)
      from public.user_role_assignments ura
      join public.system_roles sr on sr.id = ura.role_id
      join public.role_permissions rp on rp.role_id = sr.id
      join public.permissions pe on pe.id = rp.permission_id
      where ura.profile_id = p.id
        and ura.is_active
        and ura.effective_from <= current_date
        and (ura.effective_to is null or ura.effective_to >= current_date)
        and sr.is_active
    ), '[]'::jsonb)
  )
  from public.profiles p
  left join public.staff s on s.profile_id = p.id
  where p.id = auth.uid();
$function$;

CREATE OR REPLACE FUNCTION public.bootstrap_admin(p_email text, p_full_name text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_user auth.users;
  v_profile public.profiles;
  v_role public.system_roles;
  v_staff public.staff;
  v_staff_role public.staff_roles;
  v_branch public.branches;
begin
  select * into v_user
  from auth.users
  where lower(email) = lower(btrim(p_email))
  order by created_at asc
  limit 1;

  if v_user.id is null then
    raise exception 'Auth user not found for email %', p_email;
  end if;

  insert into public.profiles(id, display_name, status)
  values (
    v_user.id,
    coalesce(
      nullif(btrim(p_full_name), ''),
      nullif(v_user.raw_user_meta_data ->> 'full_name', ''),
      split_part(v_user.email, '@', 1)
    ),
    'ACTIVE'
  )
  on conflict (id) do update
  set
    display_name = excluded.display_name,
    status = 'ACTIVE',
    updated_at = now()
  returning * into v_profile;

  select * into v_role
  from public.system_roles
  where code = 'ADMIN';

  select * into v_staff_role
  from public.staff_roles
  where code = 'ADMINISTRATION';

  select * into v_branch
  from public.branches
  where code = 'MAIN'
  order by created_at asc
  limit 1;

  select * into v_staff
  from public.staff
  where profile_id = v_profile.id;

  if v_staff.id is null then
    insert into public.staff(
      profile_id,
      branch_id,
      full_name,
      email,
      joined_on,
      status
    )
    values (
      v_profile.id,
      v_branch.id,
      v_profile.display_name,
      v_user.email,
      current_date,
      'ACTIVE'
    )
    returning * into v_staff;
  end if;

  insert into public.user_role_assignments(
    profile_id,
    role_id,
    branch_id,
    is_active
  )
  values (
    v_profile.id,
    v_role.id,
    null,
    true
  )
  on conflict do nothing;

  insert into public.staff_role_assignments(
    staff_id,
    staff_role_id,
    branch_id,
    effective_from,
    is_primary
  )
  select
    v_staff.id,
    v_staff_role.id,
    v_branch.id,
    current_date,
    true
  where not exists (
    select 1
    from public.staff_role_assignments sra
    where sra.staff_id = v_staff.id
      and sra.staff_role_id = v_staff_role.id
      and sra.effective_to is null
  );

  return jsonb_build_object(
    'profile_id', v_profile.id,
    'staff_id', v_staff.id,
    'staff_no', v_staff.staff_no,
    'role', 'ADMIN'
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.enforce_approval_decision()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if old.status <> 'PENDING' and new.status is distinct from old.status then
    raise exception 'A decided approval request cannot be decided again.';
  end if;

  if new.status = 'APPROVED' and old.requested_by = new.decided_by then
    raise exception 'Maker-checker violation: requester cannot approve their own request.';
  end if;

  if new.status in ('APPROVED','REJECTED','CANCELLED') then
    if new.decided_by is null then
      raise exception 'Decision actor is required.';
    end if;
    if new.decided_at is null then
      new.decided_at := now();
    end if;
  end if;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.protect_active_business_rule()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if tg_op = 'DELETE' then
    raise exception 'Business rule versions are never deleted.';
  end if;

  if old.status = 'ACTIVE' and (
    new.domain is distinct from old.domain
    or new.rule_key is distinct from old.rule_key
    or new.version is distinct from old.version
    or new.payload is distinct from old.payload
    or new.effective_from is distinct from old.effective_from
  ) then
    raise exception 'Active business rule content is immutable. Retire it and create a new version.';
  end if;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.submit_public_interest(p_payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 org public.organizations; branch public.branches; applicant public.prospects;
 mobile_value text; snapshot jsonb; item jsonb; correlation uuid:=gen_random_uuid();
begin
 if jsonb_typeof(p_payload) is distinct from 'object' or octet_length(p_payload::text)>16000 then
  raise exception 'Enter a valid application.';
 end if;
 if length(btrim(coalesce(p_payload->>'student_name',''))) not between 2 and 160
 or length(btrim(coalesce(p_payload->>'guardian_name',''))) not between 2 and 160 then
  raise exception 'Student and guardian names are required.';
 end if;
 mobile_value:=regexp_replace(coalesce(p_payload->>'mobile',''),'\D','','g');
 if mobile_value !~ '^01[3-9][0-9]{8}$' then raise exception 'A valid mobile number is required.'; end if;
 if coalesce((p_payload->>'consent_to_contact')::boolean,false) is not true then
  raise exception 'Consent to contact is required.';
 end if;
 select * into org from public.organizations where is_active limit 1;
 if org.id is null then raise exception 'The public is not accepting applications yet.'; end if;
 select * into branch from public.branches where organization_id=org.id and is_active order by created_at limit 1;
 perform pg_advisory_xact_lock(hashtextextended(mobile_value,3));
 if exists(select 1 from public.prospects p where p.mobile=mobile_value
   and lower(p.student_name)=lower(btrim(p_payload->>'student_name'))
   and p.created_at>now()-interval '2 minutes') then
  raise exception 'A similar interest request was submitted recently. Please wait before submitting again.';
 end if;
 -- Preserve submitted IDs and text. Labels are captured for review, never FK links.
 snapshot:=p_payload||jsonb_build_object('verification','UNVERIFIED',
   'class_label',(select name from public.classes where id::text=p_payload->>'class_id' and organization_id=org.id),
   'offering_label',(select name from public.programme_offerings where id::text=p_payload->>'offering_id' and organization_id=org.id),
   'program_labels',coalesce((select jsonb_agg(name) from public.programs where organization_id=org.id
     and coalesce(p_payload->'program_ids','[]'::jsonb) ? id::text),'[]'::jsonb),
   'subject_labels',coalesce((select jsonb_agg(name) from public.subjects where organization_id=org.id
     and coalesce(p_payload->'subject_ids','[]'::jsonb) ? id::text),'[]'::jsonb));
 insert into public.prospects(organization_id,branch_id,student_name,student_name_bn,
  guardian_name,guardian_relationship_snapshot,mobile,alternate_mobile,
  school_name_snapshot,area_snapshot,guardian_address,referral_note,notes,
  consent_to_contact,submitted_via,submission_intent,application_snapshot)
 values(org.id,branch.id,btrim(p_payload->>'student_name'),nullif(btrim(p_payload->>'student_name_bn'),''),
  btrim(p_payload->>'guardian_name'),nullif(btrim(p_payload->>'guardian_relationship'),''),
  mobile_value,nullif(btrim(p_payload->>'alternate_mobile'),''),
  coalesce(nullif(btrim(p_payload->>'school_name_snapshot'),''),
   (select name from public.schools where id::text=p_payload->>'school_id' and organization_id=org.id)),
  nullif(btrim(p_payload->>'area'),''),nullif(btrim(p_payload->>'guardian_address'),''),
  nullif(btrim(p_payload->>'referral_note'),''),nullif(btrim(p_payload->>'notes'),''),
  true,'PUBLIC_WEB',case when p_payload->>'intent'='admission' then 'admission' else 'interest' end,snapshot) returning * into applicant;
 insert into public.audit_events(correlation_id,entity_type,entity_id,action,metadata)
 values(correlation,'PROSPECT',applicant.id::text,'RECEIVE_UNVERIFIED_APPLICATION',
  jsonb_build_object('intent',p_payload->>'intent','verification','UNVERIFIED'));
 return jsonb_build_object('prospect_no',applicant.prospect_no,'prospect_id',applicant.id);
end $function$;

CREATE OR REPLACE FUNCTION public.create_staff_member(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_staff public.staff;
  v_role public.staff_roles;
  v_branch public.branches;
  v_subject_id uuid;
  v_subjects jsonb;
  v_mobile text;
  v_joined_on date;
  v_correlation_id uuid := gen_random_uuid();
  v_actor_role text;
begin
  if v_actor is null or not public.has_permission('staff.manage') then
    raise exception 'You are not authorized to create Staff identities.';
  end if;

  if p_input is null or jsonb_typeof(p_input) <> 'object' then
    raise exception 'Staff request must be a JSON object.';
  end if;

  if nullif(btrim(coalesce(p_input->>'full_name','')), '') is null then
    raise exception 'Full name is required.';
  end if;

  select * into v_role
  from public.staff_roles
  where code=upper(btrim(coalesce(p_input->>'staff_role_code','')))
    and is_active;

  if v_role.id is null then
    raise exception 'Select a valid Staff role.';
  end if;

  if nullif(p_input->>'branch_id','') is not null then
    begin
      select * into v_branch
      from public.branches
      where id=(p_input->>'branch_id')::uuid
        and is_active;
    exception when others then
      raise exception 'Selected branch is invalid.';
    end;
  else
    select * into v_branch
    from public.branches
    where id=academy_private.current_branch_id() and is_active
    order by created_at asc
    limit 1;
  end if;

  if v_branch.id is null then
    raise exception 'An active branch is required.';
  end if;

  begin
    v_joined_on := coalesce(
      nullif(p_input->>'joined_on','')::date,
      current_date
    );
  exception when others then
    raise exception 'Joining date is invalid.';
  end;

  v_mobile := nullif(btrim(coalesce(p_input->>'mobile','')), '');

  if v_mobile is not null and exists (
    select 1
    from public.staff s
    where regexp_replace(coalesce(s.mobile,''), '\D', '', 'g')
        = regexp_replace(v_mobile, '\D', '', 'g')
      and s.status in ('ACTIVE','ON_LEAVE')
  ) then
    raise exception 'Another active Staff identity already uses this mobile number.';
  end if;

  insert into public.staff(
    branch_id,
    full_name,
    mobile,
    alternate_mobile,
    email,
    address,
    emergency_contact_name,
    emergency_contact_mobile,
    joined_on,
    status,
    notes,
    created_by
  )
  values(
    v_branch.id,
    btrim(p_input->>'full_name'),
    v_mobile,
    nullif(btrim(coalesce(p_input->>'alternate_mobile','')), ''),
    nullif(lower(btrim(coalesce(p_input->>'email',''))), ''),
    nullif(btrim(coalesce(p_input->>'address','')), ''),
    nullif(btrim(coalesce(p_input->>'emergency_contact_name','')), ''),
    nullif(btrim(coalesce(p_input->>'emergency_contact_mobile','')), ''),
    v_joined_on,
    'ACTIVE',
    nullif(btrim(coalesce(p_input->>'notes','')), ''),
    v_actor
  )
  returning * into v_staff;

  insert into public.staff_role_assignments(
    staff_id,
    staff_role_id,
    branch_id,
    effective_from,
    is_primary,
    assigned_by
  )
  values(
    v_staff.id,
    v_role.id,
    v_branch.id,
    v_joined_on,
    true,
    v_actor
  );

  v_subjects := coalesce(p_input->'subject_ids','[]'::jsonb);

  if jsonb_typeof(v_subjects) <> 'array' then
    raise exception 'Teaching subject selection must be an array.';
  end if;

  if not v_role.is_teaching_role
     and jsonb_array_length(v_subjects) > 0 then
    raise exception 'Teaching subjects can only be selected for a teaching Staff role.';
  end if;

  for v_subject_id in
    select value::text::uuid
    from jsonb_array_elements_text(v_subjects)
  loop
    if not exists (
      select 1 from public.subjects
      where id=v_subject_id and is_active
    ) then
      raise exception 'One selected subject is not available.';
    end if;

    insert into public.staff_subject_assignments(
      staff_id,
      subject_id,
      effective_from,
      assigned_by
    )
    values(
      v_staff.id,
      v_subject_id,
      v_joined_on,
      v_actor
    );
  end loop;

  select sr.code into v_actor_role
  from public.user_role_assignments ura
  join public.system_roles sr on sr.id=ura.role_id
  where ura.profile_id=v_actor
    and ura.is_active
    and ura.effective_from<=current_date
    and (ura.effective_to is null or ura.effective_to>=current_date)
  order by case when sr.code='ADMIN' then 0 else 1 end, sr.code
  limit 1;

  insert into public.audit_events(
    correlation_id,
    actor_profile_id,
    actor_staff_id,
    actor_role_code,
    branch_id,
    entity_type,
    entity_id,
    action,
    after_data,
    metadata
  )
  values(
    v_correlation_id,
    v_actor,
    (select id from public.staff where profile_id=v_actor limit 1),
    v_actor_role,
    v_branch.id,
    'STAFF',
    v_staff.id::text,
    'CREATE',
    jsonb_build_object(
      'staff_no',v_staff.staff_no,
      'full_name',v_staff.full_name,
      'staff_role_code',v_role.code,
      'joined_on',v_staff.joined_on,
      'status',v_staff.status
    ),
    jsonb_build_object(
      'workflow','CREATE_STAFF_MEMBER',
      'subject_count',jsonb_array_length(v_subjects)
    )
  );

  return jsonb_build_object(
    'staff_id',v_staff.id,
    'staff_no',v_staff.staff_no,
    'correlation_id',v_correlation_id
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.is_valid_prospect_transition(p_from prospect_status, p_to prospect_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select
    p_from = p_to
    or (p_from='NEW' and p_to in ('CONTACTED','COUNSELLING','FUTURE_FOLLOW_UP','LOST'))
    or (p_from='CONTACTED' and p_to in ('COUNSELLING','TRIAL_SCHEDULED','FUTURE_FOLLOW_UP','LOST'))
    or (p_from='COUNSELLING' and p_to in ('TRIAL_SCHEDULED','REGISTERED','FUTURE_FOLLOW_UP','LOST'))
    or (p_from='TRIAL_SCHEDULED' and p_to in ('TRIAL_ATTENDED','FUTURE_FOLLOW_UP','LOST'))
    or (p_from='TRIAL_ATTENDED' and p_to in ('COUNSELLING','REGISTERED','FUTURE_FOLLOW_UP','LOST'))
    or (p_from='REGISTERED' and p_to='LOST')
    or (p_from='FUTURE_FOLLOW_UP' and p_to in ('CONTACTED','COUNSELLING','TRIAL_SCHEDULED','LOST'))
    or (p_from='LOST' and p_to='FUTURE_FOLLOW_UP');
$function$;

CREATE OR REPLACE FUNCTION public.record_prospect_followup(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_prospect public.prospects;
  v_followup public.prospect_followups;
  v_followup_type text;
  v_new_status public.prospect_status;
  v_next_follow_up_at timestamptz;
  v_notes text;
  v_outcome text;
  v_lost_reason text;
  v_correlation_id uuid := gen_random_uuid();
  v_actor_role text;
  v_before jsonb;
begin
  if v_actor is null or not public.has_permission('crm.followups.manage') then
    raise exception 'You are not authorized to record CRM follow-ups.';
  end if;

  begin
    select * into v_prospect
    from public.prospects
    where id=(p_input->>'prospect_id')::uuid
    for update;
  exception when others then
    raise exception 'Prospect identity is invalid.';
  end;

  if v_prospect.id is null then
    raise exception 'Prospect was not found.';
  end if;

  if v_prospect.status='CONVERTED' then
    raise exception 'Converted prospects are read-only in CRM. Continue from the Student record.';
  end if;

  v_followup_type := upper(btrim(coalesce(p_input->>'followup_type','')));
  if v_followup_type not in ('CALL','WHATSAPP','IN_PERSON','COUNSELLING','TRIAL','OTHER') then
    raise exception 'Select a valid follow-up type.';
  end if;

  v_notes := nullif(btrim(coalesce(p_input->>'notes','')), '');
  if v_notes is null then
    raise exception 'Follow-up notes are required.';
  end if;

  v_outcome := nullif(btrim(coalesce(p_input->>'outcome','')), '');
  v_lost_reason := nullif(btrim(coalesce(p_input->>'lost_reason','')), '');

  begin
    v_new_status := coalesce(
      nullif(p_input->>'new_status','')::public.prospect_status,
      v_prospect.status
    );
    v_next_follow_up_at := nullif(p_input->>'next_follow_up_at','')::timestamptz;
  exception when others then
    raise exception 'Follow-up status or next follow-up date is invalid.';
  end;

  if not public.is_valid_prospect_transition(v_prospect.status,v_new_status) then
    raise exception 'Prospect status cannot move from % to % through a follow-up.', v_prospect.status, v_new_status;
  end if;

  if v_new_status='LOST' and v_lost_reason is null then
    raise exception 'Lost reason is required when a prospect is marked LOST.';
  end if;

  if v_new_status='FUTURE_FOLLOW_UP' and v_next_follow_up_at is null then
    raise exception 'Next follow-up date is required for FUTURE FOLLOW UP.';
  end if;

  v_before := to_jsonb(v_prospect);

  insert into public.prospect_followups(
    prospect_id,
    followup_type,
    occurred_at,
    outcome,
    notes,
    next_follow_up_at,
    recorded_by
  )
  values(
    v_prospect.id,
    v_followup_type,
    now(),
    v_outcome,
    v_notes,
    v_next_follow_up_at,
    v_actor
  )
  returning * into v_followup;

  update public.prospects
  set
    status=v_new_status,
    next_follow_up_at=v_next_follow_up_at,
    lost_reason=case
      when v_new_status='LOST' then v_lost_reason
      when v_prospect.status='LOST' and v_new_status<>'LOST' then null
      else lost_reason
    end,
    updated_at=now()
  where id=v_prospect.id
  returning * into v_prospect;

  select sr.code into v_actor_role
  from public.user_role_assignments ura
  join public.system_roles sr on sr.id=ura.role_id
  where ura.profile_id=v_actor
    and ura.is_active
    and ura.effective_from<=current_date
    and (ura.effective_to is null or ura.effective_to>=current_date)
  order by case when sr.code='ADMIN' then 0 else 1 end, sr.code
  limit 1;

  insert into public.audit_events(
    correlation_id,
    actor_profile_id,
    actor_staff_id,
    actor_role_code,
    branch_id,
    entity_type,
    entity_id,
    action,
    reason,
    before_data,
    after_data,
    metadata
  )
  values(
    v_correlation_id,
    v_actor,
    (select id from public.staff where profile_id=v_actor limit 1),
    v_actor_role,
    v_prospect.branch_id,
    'PROSPECT',
    v_prospect.id::text,
    'RECORD_FOLLOW_UP',
    v_notes,
    v_before,
    to_jsonb(v_prospect),
    jsonb_build_object(
      'workflow','PROSPECT_FOLLOW_UP',
      'followup_id',v_followup.id,
      'followup_type',v_followup.followup_type,
      'outcome',v_followup.outcome
    )
  );

  return jsonb_build_object(
    'prospect_id',v_prospect.id,
    'prospect_no',v_prospect.prospect_no,
    'followup_id',v_followup.id,
    'status',v_prospect.status,
    'correlation_id',v_correlation_id
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.publish_business_rule_version(p_domain text, p_rule_key text, p_payload jsonb, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare previous public.business_rule_versions; saved public.business_rule_versions; next_version integer; trace uuid:=gen_random_uuid();
begin
 if auth.uid() is null or not public.has_permission('system.settings.manage') then raise exception 'Settings management permission required.'; end if;
 if (p_domain,p_rule_key) not in (('academics','batch_capacity_policy'),('admissions','activation_policy'),('teacher_compensation','default_policy')) then raise exception 'Choose a supported operating rule.'; end if;
 if length(btrim(coalesce(p_reason,''))) not between 5 and 500 or not public.validate_business_rule_payload(p_domain,p_rule_key,p_payload) then raise exception 'Check the operating values and change reason.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_domain||'.'||p_rule_key,0));
 select * into previous from public.business_rule_versions where domain=p_domain and rule_key=p_rule_key and status='ACTIVE' for update;
 if previous.id is not null and previous.payload=p_payload then return jsonb_build_object('id',previous.id,'version',previous.version); end if;
 select coalesce(max(version),0)+1 into next_version from public.business_rule_versions where domain=p_domain and rule_key=p_rule_key;
 update public.business_rule_versions set status='RETIRED',effective_to=current_date where id=previous.id;
 insert into public.business_rule_versions(domain,rule_key,version,status,effective_from,payload,change_reason,created_by)
 values(p_domain,p_rule_key,next_version,'ACTIVE',current_date,p_payload,btrim(p_reason),auth.uid()) returning * into saved;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(trace,auth.uid(),'BUSINESS_RULE',p_domain||'.'||p_rule_key,case when previous.id is null then 'CREATE_SETTINGS' else 'SAVE_SETTINGS' end,p_reason,to_jsonb(previous),to_jsonb(saved));
 return jsonb_build_object('id',saved.id,'version',saved.version,'correlation_id',trace);
end $function$;

CREATE OR REPLACE FUNCTION public.set_role_permissions(p_role_code text, p_permission_codes text[], p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_role public.system_roles;
  v_before jsonb;
  v_after jsonb;
  v_correlation_id uuid := gen_random_uuid();
begin
  if v_actor is null or not public.has_permission('system.roles.manage') then
    raise exception 'You are not authorized to manage role permissions.';
  end if;

  select * into v_role
  from public.system_roles
  where code=upper(btrim(p_role_code))
    and is_active
  for update;

  if v_role.id is null then
    raise exception 'Role was not found.';
  end if;

  if v_role.code='ADMIN' then
    raise exception 'The bootstrap ADMIN role is protected. Create or edit operational roles instead.';
  end if;

  if nullif(btrim(coalesce(p_reason,'')), '') is null then
    raise exception 'A change reason is required.';
  end if;

  if exists (
    select unnest(coalesce(p_permission_codes,'{}'::text[]))
    except
    select code from public.permissions
  ) then
    raise exception 'One or more permission codes are invalid.';
  end if;

  select coalesce(jsonb_agg(p.code order by p.code),'[]'::jsonb)
    into v_before
  from public.role_permissions rp
  join public.permissions p on p.id=rp.permission_id
  where rp.role_id=v_role.id;

  delete from public.role_permissions where role_id=v_role.id;

  insert into public.role_permissions(role_id,permission_id)
  select v_role.id,p.id
  from public.permissions p
  where p.code=any(coalesce(p_permission_codes,'{}'::text[]));

  select coalesce(jsonb_agg(p.code order by p.code),'[]'::jsonb)
    into v_after
  from public.role_permissions rp
  join public.permissions p on p.id=rp.permission_id
  where rp.role_id=v_role.id;

  insert into public.audit_events(
    correlation_id,
    actor_profile_id,
    actor_staff_id,
    entity_type,
    entity_id,
    action,
    reason,
    before_data,
    after_data
  )
  values(
    v_correlation_id,
    v_actor,
    (select id from public.staff where profile_id=v_actor limit 1),
    'SYSTEM_ROLE',
    v_role.id::text,
    'SET_PERMISSIONS',
    btrim(p_reason),
    jsonb_build_object('permissions',v_before),
    jsonb_build_object('permissions',v_after)
  );

  return jsonb_build_object(
    'role_code',v_role.code,
    'permissions',v_after,
    'correlation_id',v_correlation_id
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.validate_business_rule_payload(p_domain text, p_rule_key text, p_payload jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
declare
  v_pool numeric;
  v_pool_max numeric;
  v_acquisition numeric;
  v_retention_3 numeric;
  v_retention_6 numeric;
  v_capacity numeric;
  v_payment_requirement text;
  v_minimum_payment numeric;
begin
  if p_payload is null or jsonb_typeof(p_payload)<>'object' then return false; end if;

  if p_domain='academics' and p_rule_key='batch_capacity_policy' then
    if jsonb_typeof(p_payload->'max_students')<>'number' then return false; end if;
    v_capacity:=(p_payload->>'max_students')::numeric;
    return v_capacity=trunc(v_capacity) and v_capacity between 1 and 500;
  end if;

  if p_domain='teacher_compensation' and p_rule_key='default_policy' then
    if jsonb_typeof(p_payload->'teaching_pool_percent')<>'number'
       or jsonb_typeof(p_payload->'teaching_pool_review_max_percent')<>'number'
       or jsonb_typeof(p_payload->'acquisition_bonus_percent')<>'number'
       or jsonb_typeof(p_payload->'retention_3_month_percent')<>'number'
       or jsonb_typeof(p_payload->'retention_6_month_percent')<>'number' then
      return false;
    end if;
    v_pool:=(p_payload->>'teaching_pool_percent')::numeric;
    v_pool_max:=(p_payload->>'teaching_pool_review_max_percent')::numeric;
    v_acquisition:=(p_payload->>'acquisition_bonus_percent')::numeric;
    v_retention_3:=(p_payload->>'retention_3_month_percent')::numeric;
    v_retention_6:=(p_payload->>'retention_6_month_percent')::numeric;
    if coalesce(p_payload->>'teaching_allocation_method','APPROVED_SESSION_WEIGHT')
       not in('APPROVED_SESSION_WEIGHT') then
      return false;
    end if;
    return v_pool between 0 and 100
      and v_pool_max between 0 and 100
      and v_pool<=v_pool_max
      and v_acquisition between 0 and 100
      and v_retention_3 between 0 and 100
      and v_retention_6 between 0 and 100;
  end if;

  if p_domain='admissions' and p_rule_key='activation_policy' then
    if jsonb_typeof(p_payload->'requires_admission_acceptance')<>'boolean'
       or jsonb_typeof(p_payload->'requires_initial_billing_posted')<>'boolean'
       or jsonb_typeof(p_payload->'allow_credit_enrollment')<>'boolean'
       or jsonb_typeof(p_payload->'count_student_active_only_when_enrollment_active')<>'boolean'
       or jsonb_typeof(p_payload->'minimum_payment_percent')<>'number'
       or jsonb_typeof(p_payload->'payment_requirement')<>'string' then return false; end if;
    v_payment_requirement:=p_payload->>'payment_requirement';
    v_minimum_payment:=(p_payload->>'minimum_payment_percent')::numeric;
    if v_payment_requirement not in('NONE','MINIMUM_PERCENT','FULL') then return false; end if;
    if v_minimum_payment<0 or v_minimum_payment>100 then return false; end if;
    if v_payment_requirement='NONE' and v_minimum_payment<>0 then return false; end if;
    if v_payment_requirement='MINIMUM_PERCENT' and (v_minimum_payment<=0 or v_minimum_payment>=100) then return false; end if;
    if v_payment_requirement='FULL' and v_minimum_payment<>100 then return false; end if;
    return true;
  end if;

  return false;
exception when others then
  return false;
end;
$function$;

CREATE OR REPLACE FUNCTION public.set_user_operational_roles(p_profile_id uuid, p_role_codes text[], p_reason text, p_branch_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_profile public.profiles;
  v_branch public.branches;
  v_before jsonb;
  v_after jsonb;
  v_correlation_id uuid := gen_random_uuid();
begin
  if v_actor is null or not public.has_permission('system.users.manage') then
    raise exception 'You are not authorized to manage user access.';
  end if;

  if nullif(btrim(coalesce(p_reason,'')), '') is null then
    raise exception 'A change reason is required.';
  end if;

  select * into v_profile
  from public.profiles
  where id=p_profile_id
    and status='ACTIVE'
  for update;

  if v_profile.id is null then
    raise exception 'Active user profile was not found.';
  end if;

  if p_branch_id is not null then
    select * into v_branch
    from public.branches
    where id=p_branch_id and is_active;

    if v_branch.id is null then
      raise exception 'Selected branch is not available.';
    end if;
  end if;

  if 'ADMIN'=any(coalesce(p_role_codes,'{}'::text[])) then
    raise exception 'ADMIN assignment is protected and cannot be changed through the operational access editor.';
  end if;

  if exists (
    select unnest(coalesce(p_role_codes,'{}'::text[]))
    except
    select code
    from public.system_roles
    where code<>'ADMIN' and is_active
  ) then
    raise exception 'One or more operational role codes are invalid.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'role_code',r.code,
        'branch_id',ura.branch_id,
        'effective_from',ura.effective_from
      )
      order by r.code
    ),
    '[]'::jsonb
  )
  into v_before
  from public.user_role_assignments ura
  join public.system_roles r on r.id=ura.role_id
  where ura.profile_id=p_profile_id
    and r.code<>'ADMIN'
    and ura.is_active
    and ura.effective_to is null
    and ura.branch_id is not distinct from p_branch_id;

  update public.user_role_assignments ura
  set
    is_active=false,
    effective_to=current_date
  from public.system_roles r
  where ura.role_id=r.id
    and ura.profile_id=p_profile_id
    and r.code<>'ADMIN'
    and ura.is_active
    and ura.effective_to is null
    and ura.branch_id is not distinct from p_branch_id
    and not (r.code=any(coalesce(p_role_codes,'{}'::text[])));

  insert into public.user_role_assignments(
    profile_id,
    role_id,
    branch_id,
    effective_from,
    is_active,
    assigned_by
  )
  select
    p_profile_id,
    r.id,
    p_branch_id,
    current_date,
    true,
    v_actor
  from public.system_roles r
  where r.code=any(coalesce(p_role_codes,'{}'::text[]))
    and r.code<>'ADMIN'
    and r.is_active
    and not exists (
      select 1
      from public.user_role_assignments existing
      where existing.profile_id=p_profile_id
        and existing.role_id=r.id
        and existing.branch_id is not distinct from p_branch_id
        and existing.is_active
        and existing.effective_to is null
    );

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'role_code',r.code,
        'branch_id',ura.branch_id,
        'effective_from',ura.effective_from
      )
      order by r.code
    ),
    '[]'::jsonb
  )
  into v_after
  from public.user_role_assignments ura
  join public.system_roles r on r.id=ura.role_id
  where ura.profile_id=p_profile_id
    and r.code<>'ADMIN'
    and ura.is_active
    and ura.effective_to is null
    and ura.branch_id is not distinct from p_branch_id;

  if v_before=v_after then
    raise exception 'The proposed access assignment is identical to the current assignment.';
  end if;

  insert into public.audit_events(
    correlation_id,
    actor_profile_id,
    actor_staff_id,
    branch_id,
    entity_type,
    entity_id,
    action,
    reason,
    before_data,
    after_data,
    metadata
  )
  values(
    v_correlation_id,
    v_actor,
    (select id from public.staff where profile_id=v_actor limit 1),
    p_branch_id,
    'USER_ACCESS',
    p_profile_id::text,
    'SET_OPERATIONAL_ROLES',
    btrim(p_reason),
    jsonb_build_object('roles',v_before),
    jsonb_build_object('roles',v_after),
    jsonb_build_object('scope_branch_id',p_branch_id)
  );

  return jsonb_build_object(
    'profile_id',p_profile_id,
    'branch_id',p_branch_id,
    'roles',v_after,
    'correlation_id',v_correlation_id
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.guard_fee_plan_history()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_table_name='fee_plan_components' then
    if tg_op='DELETE' then return old; end if;
    return new;
  end if;
  if tg_op='DELETE' then raise exception 'Fee Plans cannot be deleted.'; end if;
  if old.id is distinct from new.id or old.offering_id is distinct from new.offering_id
     or old.version is distinct from new.version or old.created_by is distinct from new.created_by then
    raise exception 'Fee Plan identity fields cannot be changed.';
  end if;
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.manage_crm_master_record(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_org uuid;
  v_entity text := lower(btrim(coalesce(p_input->>'entity', '')));
  v_reason text := btrim(coalesce(p_input->>'reason', ''));
  v_id uuid := nullif(p_input->>'id', '')::uuid;
  v_correlation uuid := gen_random_uuid();
  v_before jsonb;
  v_after jsonb;
  v_action text;
  v_code text;
  v_name text;
  v_is_active boolean;
  v_sort integer;
  v_starts date;
  v_ends date;
  v_description text;
  v_area_id uuid;
  v_verified boolean;
begin
  if v_actor is null or not public.has_permission('system.master_data.manage') then
    raise exception 'You are not authorized to manage CRM master data.';
  end if;
  if length(v_reason) < 5 then
    raise exception 'A change reason of at least five characters is required.';
  end if;

  select id into v_org from public.organizations where is_active limit 1;
  if v_org is null then
    raise exception 'Organization is not available.';
  end if;

  v_name := nullif(btrim(coalesce(p_input->>'name', '')), '');
  v_code := nullif(upper(btrim(coalesce(p_input->>'code', ''))), '');
  v_is_active := coalesce((p_input->>'is_active')::boolean, true);
  v_sort := coalesce((p_input->>'sort_order')::integer, 0);
  v_description := nullif(btrim(coalesce(p_input->>'description', '')), '');
  v_starts := nullif(p_input->>'starts_on', '')::date;
  v_ends := nullif(p_input->>'ends_on', '')::date;
  v_area_id := nullif(p_input->>'area_id', '')::uuid;
  v_verified := coalesce((p_input->>'is_verified')::boolean, false);

  if v_entity = 'academic_year' then
    if v_name is null or length(v_name) < 2 then
      raise exception 'Academic year name is required.';
    end if;
    if v_starts is null or v_ends is null or v_ends < v_starts then
      raise exception 'Academic year needs a valid start and end date.';
    end if;
    if v_id is null then
      insert into public.academic_years (organization_id, name, starts_on, ends_on, is_active)
      values (v_org, v_name, v_starts, v_ends, v_is_active)
      returning to_jsonb(academic_years.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(y.*) into v_before from public.academic_years y where y.id = v_id and y.organization_id = v_org for update;
      if v_before is null then raise exception 'Academic year not found.'; end if;
      update public.academic_years
      set name = v_name, starts_on = v_starts, ends_on = v_ends, is_active = v_is_active
      where id = v_id
      returning to_jsonb(academic_years.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'class' then
    if v_code is null or length(v_code) < 1 then raise exception 'Class code is required.'; end if;
    if v_name is null or length(v_name) < 1 then raise exception 'Class name is required.'; end if;
    if v_id is null then
      insert into public.classes (organization_id, code, name, sort_order, is_active)
      values (v_org, v_code, v_name, v_sort, v_is_active)
      returning to_jsonb(classes.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(c.*) into v_before from public.classes c where c.id = v_id and c.organization_id = v_org for update;
      if v_before is null then raise exception 'Class not found.'; end if;
      update public.classes
      set code = v_code, name = v_name, sort_order = v_sort, is_active = v_is_active
      where id = v_id
      returning to_jsonb(classes.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'group' then
    if v_code is null or length(v_code) < 1 then raise exception 'Group code is required.'; end if;
    if v_name is null or length(v_name) < 1 then raise exception 'Group name is required.'; end if;
    if v_id is null then
      insert into public.academic_groups (organization_id, code, name, is_active)
      values (v_org, v_code, v_name, v_is_active)
      returning to_jsonb(academic_groups.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(g.*) into v_before from public.academic_groups g where g.id = v_id and g.organization_id = v_org for update;
      if v_before is null then raise exception 'Group not found.'; end if;
      update public.academic_groups
      set code = v_code, name = v_name, is_active = v_is_active
      where id = v_id
      returning to_jsonb(academic_groups.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'subject' then
    if v_code is null or length(v_code) < 1 then raise exception 'Subject code is required.'; end if;
    if v_name is null or length(v_name) < 1 then raise exception 'Subject name is required.'; end if;
    if v_id is null then
      insert into public.subjects (organization_id, code, name, is_active)
      values (v_org, v_code, v_name, v_is_active)
      returning to_jsonb(subjects.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(s.*) into v_before from public.subjects s where s.id = v_id and s.organization_id = v_org for update;
      if v_before is null then raise exception 'Subject not found.'; end if;
      update public.subjects
      set code = v_code, name = v_name, is_active = v_is_active
      where id = v_id
      returning to_jsonb(subjects.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'program' then
    if v_code is null or length(v_code) < 1 then raise exception 'Programme code is required.'; end if;
    if v_name is null or length(v_name) < 1 then raise exception 'Programme name is required.'; end if;
    if v_id is null then
      insert into public.programs (organization_id, code, name, description, is_active)
      values (v_org, v_code, v_name, v_description, v_is_active)
      returning to_jsonb(programs.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(p.*) into v_before from public.programs p where p.id = v_id and p.organization_id = v_org for update;
      if v_before is null then raise exception 'Programme not found.'; end if;
      update public.programs
      set code = v_code, name = v_name, description = v_description, is_active = v_is_active
      where id = v_id
      returning to_jsonb(programs.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'school' then
    if v_name is null or length(v_name) < 2 then raise exception 'School name is required.'; end if;
    if v_area_id is not null and not exists (
      select 1 from public.areas a where a.id = v_area_id and a.organization_id = v_org
    ) then
      raise exception 'Selected area is not available.';
    end if;
    if v_id is null then
      insert into public.schools (organization_id, area_id, name, is_verified, is_active, created_by)
      values (v_org, v_area_id, v_name, v_verified, v_is_active, v_actor)
      returning to_jsonb(schools.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(s.*) into v_before from public.schools s where s.id = v_id and s.organization_id = v_org for update;
      if v_before is null then raise exception 'School not found.'; end if;
      update public.schools
      set area_id = v_area_id, name = v_name, is_verified = v_verified, is_active = v_is_active, updated_at = now()
      where id = v_id
      returning to_jsonb(schools.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'lead_source' then
    if v_code is null or length(v_code) < 1 then raise exception 'Lead source code is required.'; end if;
    if v_name is null or length(v_name) < 1 then raise exception 'Lead source name is required.'; end if;
    if v_id is null then
      insert into public.lead_sources (organization_id, code, name, is_active)
      values (v_org, v_code, v_name, v_is_active)
      returning to_jsonb(lead_sources.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(l.*) into v_before from public.lead_sources l where l.id = v_id and l.organization_id = v_org for update;
      if v_before is null then raise exception 'Lead source not found.'; end if;
      update public.lead_sources
      set code = v_code, name = v_name, is_active = v_is_active
      where id = v_id
      returning to_jsonb(lead_sources.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'guardian_relationship' then
    if v_code is null or length(v_code) < 1 then raise exception 'Relationship code is required.'; end if;
    if v_name is null or length(v_name) < 1 then raise exception 'Relationship name is required.'; end if;
    if v_id is null then
      insert into public.guardian_relationships (organization_id, code, name, is_active)
      values (v_org, v_code, v_name, v_is_active)
      returning to_jsonb(guardian_relationships.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(r.*) into v_before from public.guardian_relationships r where r.id = v_id and r.organization_id = v_org for update;
      if v_before is null then raise exception 'Relationship not found.'; end if;
      update public.guardian_relationships
      set code = v_code, name = v_name, is_active = v_is_active
      where id = v_id
      returning to_jsonb(guardian_relationships.*) into v_after;
      v_action := 'UPDATE';
    end if;

  else
    raise exception 'Unsupported master-data entity.';
  end if;

  insert into public.audit_events (
    correlation_id, actor_profile_id, actor_staff_id, branch_id,
    entity_type, entity_id, action, reason, before_data, after_data, metadata
  ) values (
    v_correlation,
    v_actor,
    (select id from public.staff where profile_id = v_actor limit 1),
    null,
    upper(v_entity),
    v_id::text,
    v_action,
    v_reason,
    v_before,
    v_after,
    jsonb_build_object('source', 'manage_crm', 'entity', v_entity)
  );

  return jsonb_build_object(
    'id', v_id,
    'entity', v_entity,
    'action', v_action,
    'correlation_id', v_correlation
  );
exception
  when unique_violation then
    raise exception 'A record with the same code or name already exists.';
end;
$function$;

CREATE OR REPLACE FUNCTION public.update_programme_offering_public_controls(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_correlation uuid := gen_random_uuid();
  v_offering_id uuid;
  v_reason text;
  v_row public.programme_offerings%rowtype;
  v_before jsonb;
  v_title text;
  v_title_bn text;
  v_desc text;
  v_desc_bn text;
  v_eyebrow text;
  v_eyebrow_bn text;
  v_icon text;
  v_sort integer;
  v_visible boolean;
  v_accepting boolean;
  v_open date;
  v_close date;
  v_subjects jsonb;
  v_subject_id uuid;
  v_idx integer := 0;
begin
  if v_actor is null then
    raise exception 'Authentication required.';
  end if;
  if not public.has_permission('academics.manage') then
    raise exception 'You are not authorized to curate programme public controls.';
  end if;

  v_offering_id := nullif(p_input->>'offering_id', '')::uuid;
  v_reason := nullif(trim(coalesce(p_input->>'reason', '')), '');
  v_title := nullif(trim(coalesce(p_input->>'showcase_title', '')), '');
  v_title_bn := nullif(trim(coalesce(p_input->>'showcase_title_bn', '')), '');
  v_desc := nullif(trim(coalesce(p_input->>'showcase_description', '')), '');
  v_desc_bn := nullif(trim(coalesce(p_input->>'showcase_description_bn', '')), '');
  v_eyebrow := nullif(trim(coalesce(p_input->>'showcase_eyebrow', '')), '');
  v_eyebrow_bn := nullif(trim(coalesce(p_input->>'showcase_eyebrow_bn', '')), '');
  v_icon := nullif(trim(coalesce(p_input->>'showcase_icon', '')), '');
  v_sort := coalesce((p_input->>'showcase_sort_order')::integer, 100);
  v_visible := coalesce((p_input->>'is_website_visible')::boolean, false);
  v_accepting := coalesce((p_input->>'is_accepting_applications')::boolean, false);
  v_open := nullif(p_input->>'applications_open_on', '')::date;
  v_close := nullif(p_input->>'applications_close_on', '')::date;
  v_subjects := coalesce(p_input->'subject_ids', '[]'::jsonb);

  if v_offering_id is null then
    raise exception 'Offering is required.';
  end if;
  if v_reason is null or length(v_reason) < 5 then
    raise exception 'A short reason (at least 5 characters) is required for the audit trail.';
  end if;
  if v_sort < 0 or v_sort > 9999 then
    raise exception 'Sort order must be between 0 and 9999.';
  end if;
  if v_icon is not null and v_icon not in (
    'clipboard-check', 'graduation-cap', 'users-round',
    'book-open-check', 'line-chart', 'shield-check'
  ) then
    raise exception 'Unsupported showcase icon.';
  end if;
  if v_open is not null and v_close is not null and v_close < v_open then
    raise exception 'Applications close date must be on or after the open date.';
  end if;

  select * into v_row from public.programme_offerings where id = v_offering_id for update;
  if not found then
    raise exception 'Programme offering not found.';
  end if;

  if v_visible and v_row.status <> 'ACTIVE' then
    raise exception 'Only ACTIVE offerings (with a published Fee Plan) can be shown on the website.';
  end if;
  if v_visible and v_title is null then
    raise exception 'Showcase title (English) is required when website visibility is enabled.';
  end if;
  if v_visible and v_desc is null then
    raise exception 'Showcase description (English) is required when website visibility is enabled.';
  end if;
  if v_accepting and v_row.status = 'RETIRED' then
    raise exception 'Retired offerings cannot accept new applications.';
  end if;

  v_before := to_jsonb(v_row);

  update public.programme_offerings set
    showcase_title = v_title,
    showcase_title_bn = v_title_bn,
    showcase_description = v_desc,
    showcase_description_bn = v_desc_bn,
    showcase_eyebrow = v_eyebrow,
    showcase_eyebrow_bn = v_eyebrow_bn,
    showcase_icon = v_icon,
    showcase_sort_order = v_sort,
    is_website_visible = v_visible,
    is_accepting_applications = v_accepting,
    applications_open_on = v_open,
    applications_close_on = v_close,
    public_schedule = case when p_input ? 'public_schedule' then nullif(btrim(p_input->>'public_schedule'), '') else public_schedule end,
    public_requirements = case when p_input ? 'public_requirements' then nullif(btrim(p_input->>'public_requirements'), '') else public_requirements end,
    admission_policy = case when p_input ? 'admission_policy' then nullif(btrim(p_input->>'admission_policy'), '') else admission_policy end,
    public_schedule_bn = case when p_input ? 'public_schedule_bn' then nullif(btrim(p_input->>'public_schedule_bn'), '') else public_schedule_bn end,
    public_requirements_bn = case when p_input ? 'public_requirements_bn' then nullif(btrim(p_input->>'public_requirements_bn'), '') else public_requirements_bn end,
    admission_policy_bn = case when p_input ? 'admission_policy_bn' then nullif(btrim(p_input->>'admission_policy_bn'), '') else admission_policy_bn end,
    updated_at = now()
  where id = v_offering_id
  returning * into v_row;

  delete from public.programme_offering_subjects where offering_id = v_offering_id;
  if jsonb_typeof(v_subjects) = 'array' then
    for v_idx in 0 .. greatest(jsonb_array_length(v_subjects) - 1, -1) loop
      v_subject_id := nullif(v_subjects->>v_idx, '')::uuid;
      if v_subject_id is null then
        continue;
      end if;
      if not exists (
        select 1 from public.subjects s
        where s.id = v_subject_id and s.is_active
      ) then
        raise exception 'One selected subject is not available.';
      end if;
      insert into public.programme_offering_subjects (offering_id, subject_id, sort_order)
      values (v_offering_id, v_subject_id, v_idx);
    end loop;
  end if;

  insert into public.audit_events (
    correlation_id, actor_profile_id, actor_staff_id, branch_id,
    entity_type, entity_id, action, reason, before_data, after_data, metadata
  ) values (
    v_correlation,
    v_actor,
    (select id from public.staff where profile_id = v_actor limit 1),
    v_row.branch_id,
    'PROGRAMME_OFFERING',
    v_row.id::text,
    'UPDATE_PUBLIC_CONTROLS',
    v_reason,
    v_before,
    to_jsonb(v_row),
    jsonb_build_object(
      'is_website_visible', v_visible,
      'is_accepting_applications', v_accepting,
      'showcase_sort_order', v_sort,
      'subject_count', coalesce(jsonb_array_length(v_subjects), 0)
    )
  );

  return jsonb_build_object(
    'offering_id', v_row.id,
    'is_website_visible', v_row.is_website_visible,
    'is_accepting_applications', v_row.is_accepting_applications,
    'correlation_id', v_correlation
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.list_public_programme_offerings()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(jsonb_agg(to_jsonb(x) order by x.showcase_sort_order, x.created_at), '[]'::jsonb)
  from (
    select o.id, o.code, o.name, o.class_id, o.program_id, o.group_id,
      o.branch_id, o.academic_year_id, ay.name as academic_year_name,
      b.name as branch_name, c.name as class_name, ag.name as group_name,
      o.showcase_title, o.showcase_title_bn, o.showcase_description,
      o.showcase_description_bn, o.showcase_eyebrow, o.showcase_eyebrow_bn,
      o.showcase_icon, o.showcase_sort_order,
      o.public_schedule, o.public_schedule_bn, o.public_requirements,
      o.public_requirements_bn, o.admission_policy, o.admission_policy_bn,
      (select count(*)::integer from public.batches bb where bb.offering_id=o.id and bb.is_active) as active_batch_count,
      (select coalesce(sum(bb.capacity),0)::integer from public.batches bb where bb.offering_id=o.id and bb.is_active) as current_total_seats,
      (select coalesce(sum(greatest(bb.capacity-(select count(*) from public.enrollments e where e.batch_id=bb.id and e.status='ACTIVE'),0)),0)::integer
       from public.batches bb where bb.offering_id=o.id and bb.is_active) as current_open_seats,
      (o.is_accepting_applications
        and (o.applications_open_on is null or o.applications_open_on <= local_day.today)
        and (o.applications_close_on is null or o.applications_close_on >= local_day.today)
      ) as is_accepting_applications,
      case when not o.is_accepting_applications then 'CLOSED'
        when o.applications_open_on > local_day.today then 'UPCOMING'
        when o.applications_close_on < local_day.today then 'CLOSED'
        else 'OPEN' end as application_state,
      o.applications_open_on, o.applications_close_on, o.created_at,
      (select coalesce(jsonb_agg(jsonb_build_object('id', s.id, 'code', s.code, 'name', s.name)
        order by pos.sort_order), '[]'::jsonb)
       from public.programme_offering_subjects pos
       join public.subjects s on s.id = pos.subject_id
       where pos.offering_id = o.id and s.is_active) as subjects,
      (select jsonb_build_object('billing_cycle', fp.billing_cycle,
        'currency_code', fp.currency_code,
        'components', coalesce((select jsonb_agg(jsonb_build_object(
          'code', fc.code, 'name', fc.name, 'amount', fc.amount,
          'charge_type', fc.charge_type, 'recurrence', fc.recurrence)
          order by fc.sort_order) from public.fee_plan_components fc
          where fc.fee_plan_version_id = fp.id), '[]'::jsonb))
       from public.fee_plan_versions fp
       where fp.offering_id = o.id and fp.status = 'ACTIVE' limit 1) as fee_plan
    from public.programme_offerings o
    join public.organizations org on org.id = o.organization_id
    join public.academic_years ay on ay.id = o.academic_year_id
    join public.branches b on b.id = o.branch_id
    join public.classes c on c.id = o.class_id
    left join public.academic_groups ag on ag.id = o.group_id
    cross join lateral (select timezone(org.timezone, now())::date as today) local_day
    where o.is_website_visible and o.status = 'ACTIVE'
    order by o.showcase_sort_order, o.created_at limit 24
  ) x;
$function$;

CREATE OR REPLACE FUNCTION public.link_staff_profile_by_email(p_email text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_email text := lower(nullif(btrim(coalesce(p_email, '')), ''));
  v_user_id uuid;
  v_staff_ids uuid[];
begin
  if v_email is null then
    return null;
  end if;

  select u.id into v_user_id
  from auth.users u
  where lower(u.email) = v_email
    and u.email_confirmed_at is not null
  order by u.created_at asc
  limit 1;

  if v_user_id is null
     or not exists (select 1 from public.profiles where id = v_user_id)
     or exists (select 1 from public.staff where profile_id = v_user_id) then
    return null;
  end if;

  select array_agg(s.id) into v_staff_ids
  from public.staff s
  where s.profile_id is null
    and lower(s.email) = v_email
    and s.status in ('ACTIVE', 'ON_LEAVE');

  if coalesce(array_length(v_staff_ids, 1), 0) <> 1 then
    return null;
  end if;

  update public.staff
  set profile_id = v_user_id
  where id = v_staff_ids[1]
    and profile_id is null;

  insert into public.audit_events(entity_type, entity_id, action, reason, metadata)
  values (
    'STAFF',
    v_staff_ids[1]::text,
    'LINK_PROFILE',
    'Linked to Auth profile by confirmed email match.',
    jsonb_build_object('profile_id', v_user_id, 'email', v_email)
  );

  return v_staff_ids[1];
end;
$function$;

CREATE OR REPLACE FUNCTION public.staff_link_profile_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  perform public.link_staff_profile_by_email(new.email);
  return null;
end;
$function$;

CREATE OR REPLACE FUNCTION public.auth_user_link_staff_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.email_confirmed_at is not null then
    perform public.link_staff_profile_by_email(new.email);
  end if;
  return null;
end;
$function$;

CREATE OR REPLACE FUNCTION public.admin_review_queue()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with queue as (
    select
      a.id,
      'ATTENDANCE'::text as review_type,
      a.id::text as entity_id,
      ('Attendance · ' || b.name || ' · ' || s.name) as title,
      coalesce(st.full_name, p.display_name) as teacher_name,
      st.staff_no as teacher_staff_no,
      b.name as batch_name,
      s.name as subject_name,
      coalesce(ar.requested_at, a.created_at) as submitted_at,
      a.revision,
      '/dashboard/academics/sessions/' || cs.id::text as href
    from public.attendance_submissions a
    left join public.approval_requests ar
      on ar.id = a.approval_id
    join public.class_sessions cs on cs.id = a.session_id
    join public.batches b on b.id = cs.batch_id
    join public.subjects s on s.id = cs.subject_id
    join public.profiles p on p.id = a.recorded_by
    left join public.staff st on st.profile_id = a.recorded_by
    where a.status = 'SUBMITTED'
      and public.has_permission('academics.attendance.approve')

    union all

    select
      l.id,
      'CLASS_LOG'::text as review_type,
      l.id::text as entity_id,
      ('Class log · ' || b.name || ' · ' || s.name) as title,
      coalesce(st.full_name, p.display_name) as teacher_name,
      st.staff_no as teacher_staff_no,
      b.name as batch_name,
      s.name as subject_name,
      l.submitted_at as submitted_at,
      l.revision,
      '/dashboard/academics/sessions/' || cs.id::text as href
    from public.class_logs l
    join public.class_sessions cs on cs.id = l.session_id
    join public.batches b on b.id = cs.batch_id
    join public.subjects s on s.id = cs.subject_id
    join public.profiles p on p.id = l.authored_by
    left join public.staff st on st.profile_id = l.authored_by
    where l.status = 'SUBMITTED'
      and public.has_permission('academics.attendance.approve')

    union all

    select
      r.id,
      'ASSESSMENT_RESULTS'::text as review_type,
      r.id::text as entity_id,
      ('Assessment results · ' || a.title) as title,
      coalesce(st.full_name, p.display_name) as teacher_name,
      st.staff_no as teacher_staff_no,
      b.name as batch_name,
      s.name as subject_name,
      coalesce(r.submitted_at, r.created_at) as submitted_at,
      r.revision,
      '/dashboard/academics/assessments?assessment=' || a.id::text as href
    from public.assessment_result_submissions r
    join public.academic_assessments a on a.id = r.assessment_id
    join public.batches b on b.id = a.batch_id
    join public.subjects s on s.id = a.subject_id
    join public.profiles p on p.id = r.author_id
    left join public.staff st on st.profile_id = r.author_id
    where r.status = 'SUBMITTED'
      and public.has_permission('academics.assessments.approve')

    union all

    select
      q.id,
      'QUESTION'::text as review_type,
      q.id::text as entity_id,
      ('Question · ' || q.topic) as title,
      coalesce(st.full_name, p.display_name) as teacher_name,
      st.staff_no as teacher_staff_no,
      b.name as batch_name,
      s.name as subject_name,
      coalesce(q.submitted_at, q.created_at) as submitted_at,
      q.revision,
      '/dashboard/academics/questions?item=' || q.id::text as href
    from public.question_bank_items q
    join public.batches b on b.id = q.batch_id
    join public.subjects s on s.id = q.subject_id
    join public.profiles p on p.id = q.author_id
    left join public.staff st on st.profile_id = q.author_id
    where q.status = 'SUBMITTED'
      and public.has_permission('academics.assessments.approve')
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'reviewType', review_type,
        'entityId', entity_id,
        'title', title,
        'teacherName', teacher_name,
        'teacherStaffNo', teacher_staff_no,
        'batchName', batch_name,
        'subjectName', subject_name,
        'submittedAt', submitted_at,
        'revision', revision,
        'href', href
      )
      order by submitted_at asc, review_type, entity_id
    ),
    '[]'::jsonb
  )
  from queue;
$function$;

CREATE OR REPLACE FUNCTION public.save_fee_plan(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_offering public.programme_offerings;
  v_previous public.fee_plan_versions;
  v_current public.fee_plan_versions;
  v_components jsonb := p_input->'components';
  v_component jsonb;
  v_today date;
  v_reason text := btrim(coalesce(p_input->>'reason',''));
  v_cycle text := p_input->>'billing_cycle';
  v_due_day integer;
  v_correlation uuid := gen_random_uuid();
  v_prior_components jsonb;
  v_next_version integer;
begin
  if v_actor is null or not public.has_permission('finance.billing.manage') then
    raise exception 'You are not authorized to edit Fee Plans.';
  end if;
  if length(v_reason) < 5 then
    raise exception 'Explain the fee change in at least five characters.';
  end if;
  if v_cycle not in ('MONTHLY','TERM','ONE_TIME') then
    raise exception 'Choose a valid billing cycle.';
  end if;
  v_due_day := nullif(p_input->>'due_day','')::integer;
  if (v_cycle = 'MONTHLY' and (v_due_day is null or v_due_day not between 1 and 28))
     or (v_cycle <> 'MONTHLY' and v_due_day is not null) then
    raise exception 'Monthly plans require a due day from 1 to 28; other plans have no monthly due day.';
  end if;
  if jsonb_typeof(v_components) is distinct from 'array' then
    raise exception 'Fee components must be a list.';
  end if;
  if jsonb_array_length(v_components) not between 1 and 30 then
    raise exception 'Enter between one and thirty fee components.';
  end if;
  if not exists (
    select 1 from jsonb_array_elements(v_components) c
    where c->>'charge_type' = 'TUITION'
      and c->>'recurrence' = 'PER_CYCLE'
      and (c->>'amount')::numeric > 0
  ) then
    raise exception 'Enter a positive recurring Tuition charge.';
  end if;
  if exists (
    select 1 from jsonb_array_elements(v_components) c
    where (c->>'amount')::numeric < 0
      or (c->>'charge_type' = 'TUITION' and (c->>'amount')::numeric <= 0)
  ) then
    raise exception 'Fee amounts cannot be negative; Tuition must be positive.';
  end if;

  -- Lock the offering to serialize simultaneous saves and version assignment.
  select * into v_offering
  from public.programme_offerings
  where id = (p_input->>'offering_id')::uuid and status <> 'RETIRED'
  for update;
  if v_offering.id is null then raise exception 'Offering is not available.'; end if;

  select (now() at time zone timezone)::date into v_today
  from public.organizations where id = v_offering.organization_id;
  if (p_input->>'effective_from')::date is distinct from v_today then
    raise exception 'Changes to current charges take effect today in the public timezone.';
  end if;

  select * into v_previous
  from public.fee_plan_versions
  where offering_id = v_offering.id and status = 'ACTIVE'
  for update;
  select coalesce(max(version), 0) + 1 into v_next_version
  from public.fee_plan_versions where offering_id = v_offering.id;

  if v_previous.id is not null then
    select coalesce(jsonb_agg(to_jsonb(c) order by c.sort_order), '[]'::jsonb)
      into v_prior_components
    from public.fee_plan_components c
    where c.fee_plan_version_id = v_previous.id;

    update public.fee_plan_versions
    set status = 'RETIRED',
        effective_to = greatest(v_previous.effective_from, v_today)
    where id = v_previous.id;
  end if;

  insert into public.fee_plan_versions (
    offering_id, version, status, billing_cycle, due_day, currency_code,
    effective_from, effective_to, change_reason, created_by
  ) values (
    v_offering.id, v_next_version, 'DRAFT', v_cycle, v_due_day,
    (select currency_code from public.organizations where id = v_offering.organization_id),
    v_today, null, v_reason, v_actor
  ) returning * into v_current;

  for v_component in select value from jsonb_array_elements(v_components)
  loop
    insert into public.fee_plan_components (
      fee_plan_version_id, code, name, amount, charge_type, recurrence, sort_order
    ) values (
      v_current.id, upper(btrim(v_component->>'code')),
      btrim(v_component->>'name'), (v_component->>'amount')::numeric,
      v_component->>'charge_type', v_component->>'recurrence',
      coalesce((v_component->>'sort_order')::integer, 0)
    );
  end loop;

  -- Finalize only after all components have been inserted. Published-plan guards
  -- must never be bypassed or weakened to permit later component mutation.
  update public.fee_plan_versions set status = 'ACTIVE'
  where id = v_current.id
  returning * into v_current;

  update public.programme_offerings set status = 'ACTIVE'
  where id = v_offering.id;

  insert into public.audit_events (
    correlation_id, actor_profile_id, actor_staff_id, branch_id,
    entity_type, entity_id, action, reason, before_data, after_data, metadata
  ) values (
    v_correlation, v_actor,
    (select id from public.staff where profile_id = v_actor limit 1),
    v_offering.branch_id, 'FEE_PLAN', v_current.id::text,
    case when v_previous.id is null then 'CREATE' else 'SAVE' end,
    v_reason,
    case when v_previous.id is null then null else jsonb_build_object(
      'plan', to_jsonb(v_previous), 'components', v_prior_components
    ) end,
    jsonb_build_object(
      'plan', to_jsonb(v_current), 'components', v_components
    ),
    jsonb_build_object('offering_id', v_offering.id, 'current_state', true)
  );

  return jsonb_build_object('fee_plan_id', v_current.id, 'correlation_id', v_correlation);
end;
$function$;

CREATE OR REPLACE FUNCTION public.save_offering_discount_policy(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare o public.programme_offerings; choices integer[]; before_data jsonb;
begin
 if auth.uid() is null or not public.has_permission('finance.billing.manage') then raise exception 'Billing management permission required.'; end if;
 select array_agg(distinct value::integer order by value::integer) into choices
 from jsonb_array_elements_text(coalesce(p_input->'percentages','[]'::jsonb));
 choices:=coalesce(choices,'{}');
 if not choices <@ array[5,10,15,20,25,30] then raise exception 'Choose discounts from 5 to 30 in steps of five.'; end if;
 select * into o from public.programme_offerings where id=(p_input->>'offering_id')::uuid for update;
 if o.id is null then raise exception 'Offering not found.'; end if;
 before_data:=to_jsonb(o);
 update public.programme_offerings set allowed_discount_percentages=choices where id=o.id;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),'OFFERING',o.id::text,'SAVE_DISCOUNT_POLICY','Updated permitted admission discounts',before_data,
 jsonb_build_object('allowed_discount_percentages',choices));
 return jsonb_build_object('id',o.id);
end $function$;

CREATE OR REPLACE FUNCTION public.academy_setup_status()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare o public.organizations; steps jsonb; ready boolean;
begin
 if auth.uid() is null or not public.has_permission('dashboard.view') then raise exception 'ERP access required.'; end if;
 select * into o from public.organizations where is_active limit 1;
 steps:=jsonb_build_array(
 jsonb_build_object('id','public','title','Academy and campus','href','/dashboard/setup','done',o.id is not null and o.setup_identity_confirmed_at is not null and exists(select 1 from public.branches where organization_id=o.id and is_active)),
 jsonb_build_object('id','directory','title','Academic years, classes, subjects and programmes','href','/dashboard/crm/manage','done',
 exists(select 1 from public.academic_years where organization_id=o.id and is_active) and
 exists(select 1 from public.classes where organization_id=o.id and is_active) and
 exists(select 1 from public.subjects where organization_id=o.id and is_active) and
 exists(select 1 from public.programs where organization_id=o.id and is_active)),
 jsonb_build_object('id','rules','title','Capacity and enrollment rules','href','/dashboard/governance/rules','done',
 exists(select 1 from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE') and
 exists(select 1 from public.business_rule_versions where domain='admissions' and rule_key='activation_policy' and status='ACTIVE')),
 jsonb_build_object('id','offering','title','Programme offering','href','/dashboard/academics/offerings','done',exists(select 1 from public.programme_offerings where organization_id=o.id and status<>'RETIRED')),
 jsonb_build_object('id','fees','title','Standard fees and permitted discounts','href','/dashboard/finance/fee-plans','done',exists(select 1 from public.programme_offerings off join public.fee_plan_versions f on f.offering_id=off.id where off.organization_id=o.id and off.status='ACTIVE' and f.status='ACTIVE' and f.effective_from<=timezone(o.timezone,now())::date)),
 jsonb_build_object('id','batches','title','At least one admission-ready batch','href','/dashboard/academics/batches','done',exists(select 1 from public.batches b join public.programme_offerings off on off.id=b.offering_id join public.fee_plan_versions f on f.offering_id=off.id where off.organization_id=o.id and off.status='ACTIVE' and b.is_active and f.status='ACTIVE' and f.effective_from<=timezone(o.timezone,now())::date)));
 select bool_and((value->>'done')::boolean) into ready from jsonb_array_elements(steps);
 return jsonb_build_object('completed',o.setup_completed_at is not null,'ready',coalesce(ready,false),'steps',steps,'academyName',o.name);
end $function$;

CREATE OR REPLACE FUNCTION public.complete_academy_setup()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null or not public.has_permission('system.settings.manage') then raise exception 'Academy setup permission required.'; end if;
 perform pg_advisory_xact_lock(871604);
 if not (public.academy_setup_status()->>'ready')::boolean then raise exception 'Finish all prerequisite settings before opening operations.'; end if;
 update public.organizations set setup_completed_at=now(),setup_completed_by=auth.uid() where is_active;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason) values(auth.uid(),'ACADEMY',(select id::text from public.organizations where is_active),'COMPLETE_SETUP','Reviewed public configuration before opening operations');
 return public.academy_setup_status();
end $function$;

CREATE OR REPLACE FUNCTION public.record_lifecycle_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare target_table text; permission text; status_column text; active_value text; inactive_value text;
 before_data jsonb; after_data jsonb; target uuid:=(p_input->>'id')::uuid; enabled boolean:=(p_input->>'active')::boolean;
begin
 case p_input->>'entity'
 when 'batch' then target_table:='batches';permission:='academics.manage';status_column:='is_active';
 when 'offering' then target_table:='programme_offerings';permission:='academics.manage';status_column:='status';active_value:='ACTIVE';inactive_value:='RETIRED';
 when 'student' then target_table:='students';permission:='students.manage';status_column:='status';active_value:='ACTIVE';inactive_value:='INACTIVE';
 when 'staff' then target_table:='staff';permission:='staff.manage';status_column:='status';active_value:='ACTIVE';inactive_value:='ARCHIVED';
 when 'referrer' then target_table:='referral_people';permission:='admissions.create';status_column:='is_active';
 else raise exception 'This record requires its dedicated correction workflow.';
 end case;
 if auth.uid() is null or not public.has_permission(permission) then raise exception 'Record management permission required.'; end if;
 if enabled is null or length(btrim(coalesce(p_input->>'reason','')))<5 then raise exception 'Select a state and provide a reason.'; end if;
 execute format('select to_jsonb(t) from public.%I t where id=$1 for update',target_table) into before_data using target;
 if before_data is null then raise exception 'Record not found.'; end if;
 if target_table='staff' and before_data->>'profile_id'=auth.uid()::text and not enabled then raise exception 'You cannot deactivate your own staff record.'; end if;
 if target_table='students' and enabled and not exists(select 1 from public.enrollments where student_id=target and status='ACTIVE') then raise exception 'Activate an enrollment before activating this student.'; end if;
 if target_table='students' and not enabled and exists(select 1 from public.enrollments where student_id=target and status='ACTIVE') then raise exception 'Withdraw or close the active enrollment first; its history and balances remain intact.'; end if;
 if status_column='is_active' then
 execute format('update public.%I set is_active=$2 where id=$1 returning to_jsonb(%I.*)',target_table,target_table) into after_data using target,enabled;
 else
 execute format('update public.%I set status=%L where id=$1 returning to_jsonb(%I.*)',target_table,case when enabled then active_value else inactive_value end,target_table) into after_data using target;
 end if;
 if target_table='programme_offerings' and not enabled then update public.programme_offerings set is_website_visible=false,is_accepting_applications=false where id=target; end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),upper(p_input->>'entity'),target::text,case when enabled then 'REACTIVATE' else 'MARK_INACTIVE' end,p_input->>'reason',before_data,after_data);
 return jsonb_build_object('id',target);
end $function$;

CREATE OR REPLACE FUNCTION public.request_staff_access(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare email_value text:=lower(btrim(coalesce(p_input->>'email',''))); count_recent integer;
begin
 if octet_length(p_input::text)>3000 or length(btrim(coalesce(p_input->>'full_name',''))) not between 2 and 160
 or email_value !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' or length(email_value)>254
 or coalesce(p_input->>'mobile','') !~ '^01[3-9][0-9]{8}$'
 or p_input->>'requested_role' not in('ADMIN','OPERATOR','TEACHER','ACCOUNTANT')
 or length(btrim(coalesce(p_input->>'purpose',''))) not between 5 and 500 then raise exception 'Enter valid contact details, role and purpose.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(email_value,5));
 if (select count(*) from public.staff_access_requests where email=email_value and created_at>now()-interval '1 hour')>=3 then
  return jsonb_build_object('received',true);
 end if;
 insert into public.staff_access_requests(full_name,email,mobile,requested_role,purpose)
 values(btrim(p_input->>'full_name'),email_value,p_input->>'mobile',p_input->>'requested_role',btrim(p_input->>'purpose'))
 on conflict do nothing;
 -- Identical response prevents disclosure of existing staff addresses.
 return jsonb_build_object('received',true);
end $function$;

CREATE OR REPLACE FUNCTION public.review_staff_access(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.staff_access_requests; role_value text:=p_input->>'assigned_role'; user_id uuid;
begin
 if auth.uid() is null or not public.has_permission('system.users.manage') then raise exception 'User management permission required.'; end if;
 if not exists(select 1 from public.user_role_assignments a join public.system_roles ro on ro.id=a.role_id
 where a.profile_id=auth.uid() and a.is_active and ro.code='ADMIN' and ro.is_active and a.effective_from<=current_date and (a.effective_to is null or a.effective_to>=current_date)) then raise exception 'Super admin verification required.'; end if;
 select * into r from public.staff_access_requests where id=(p_input->>'id')::uuid for update;
 if r.id is null then raise exception 'Request not found.'; end if;
 if p_input->>'action'='DECLINE' then
  if r.status not in('PENDING','VERIFIED') then raise exception 'Only pending requests can be declined.'; end if;
  update public.staff_access_requests set status='DECLINED',reviewed_by=auth.uid(),reviewed_at=now(),review_note=p_input->>'reason' where id=r.id;
 elsif p_input->>'action'='VERIFY' then
  if role_value not in('ADMIN','OPERATOR','TEACHER','ACCOUNTANT') then raise exception 'Choose a role.'; end if;
  if r.status not in('PENDING','VERIFIED') then raise exception 'Only pending requests can be verified.'; end if;
  update public.staff_access_requests set status='VERIFIED',assigned_role=role_value,reviewed_by=auth.uid(),reviewed_at=now(),review_note=p_input->>'reason' where id=r.id;
 elsif p_input->>'action'='COMPLETE_INVITATION' then
  if r.status not in('VERIFIED','INVITED') then raise exception 'Verify the request before inviting.'; end if;
  -- Identity is resolved from the verified request email, never an arbitrary caller ID.
  select id into user_id from auth.users where lower(email)=r.email;
  if user_id is null then raise exception 'Supabase invitation has not created the user yet.'; end if;
  insert into public.profiles(id,display_name) values(user_id,r.full_name) on conflict(id) do nothing;
  insert into public.staff(profile_id,full_name,email,mobile,created_by)
   values(user_id,r.full_name,r.email,r.mobile,auth.uid()) on conflict(profile_id) do nothing;
  if not exists(select 1 from public.system_roles where code=r.assigned_role and is_active) then raise exception 'Assigned role is unavailable.'; end if;
  insert into public.user_role_assignments(profile_id,role_id,assigned_by)
   select user_id,id,auth.uid() from public.system_roles where code=r.assigned_role and is_active
   on conflict do nothing;
  insert into public.staff_role_assignments(staff_id,staff_role_id,is_primary,assigned_by)
   select s.id,role.id,true,auth.uid() from public.staff s join public.staff_roles role on role.code=r.assigned_role and role.is_active
   where s.profile_id=user_id and not exists(select 1 from public.staff_role_assignments old where old.staff_id=s.id and old.is_primary and old.effective_to is null);
  update public.staff_access_requests set status='INVITED',profile_id=user_id,invitation_sent_at=now() where id=r.id;
 else raise exception 'Unsupported staff verification action.';
 end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason)
 values(auth.uid(),'STAFF_ACCESS_REQUEST',r.id::text,p_input->>'action',coalesce(p_input->>'reason','Verified staff invitation'));
 return jsonb_build_object('id',r.id);
end $function$;

CREATE OR REPLACE FUNCTION public.edit_staff_record(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s public.staff; before_data jsonb;
begin
 if auth.uid() is null or not public.has_permission('staff.manage') then raise exception 'Staff management permission required.'; end if;
 if length(btrim(coalesce(p_input->>'full_name',''))) not between 2 and 160 or length(btrim(coalesce(p_input->>'reason','')))<5 then raise exception 'Staff name and correction reason required.'; end if;
 select * into s from public.staff where id=(p_input->>'id')::uuid for update;
 if s.id is null then raise exception 'Staff not found.'; end if;
 before_data:=to_jsonb(s);
 update public.staff set full_name=btrim(p_input->>'full_name'),mobile=nullif(btrim(p_input->>'mobile'),''),
  address=case when p_input ? 'address' then nullif(btrim(p_input->>'address'),'') else address end,notes=case when p_input ? 'notes' then nullif(btrim(p_input->>'notes'),'') else notes end where id=s.id;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),'STAFF',s.id::text,'CORRECT_DETAILS',p_input->>'reason',before_data,p_input);
 return jsonb_build_object('id',s.id);
end $function$;

CREATE OR REPLACE FUNCTION public.prevent_permanent_record_delete()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin raise exception 'Do not delete this record. Use edit, inactive, withdrawal or a recorded financial correction.'; end $function$;

CREATE OR REPLACE FUNCTION public.save_academy_identity(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare org public.organizations; before_data jsonb;
begin
 if auth.uid() is null or not public.has_permission('system.settings.manage') then raise exception 'Academy setup permission required.'; end if;
 if length(btrim(coalesce(p_input->>'name',''))) not between 2 and 160 then raise exception 'Enter an public name.'; end if;
 if length(btrim(coalesce(p_input->>'branch_name',''))) not between 2 and 160 then raise exception 'Enter the campus name.'; end if;
 select * into org from public.organizations where is_active for update;
 before_data:=to_jsonb(org);
 update public.organizations set name=btrim(p_input->>'name'),setup_identity_confirmed_at=now() where id=org.id;
 update public.branches set name=btrim(p_input->>'branch_name') where organization_id=org.id and code='MAIN';
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),'ACADEMY',org.id::text,'CONFIRM_IDENTITY','Confirmed public name and campus',before_data,p_input);
 return jsonb_build_object('id',org.id);
end $function$;

CREATE OR REPLACE FUNCTION public.create_admission_directory_choice(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare org uuid; result jsonb; name_value text:=btrim(coalesce(p_input->>'name',''));
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if length(name_value) not between 2 and 160 then raise exception 'Enter a name of 2 to 160 characters.'; end if;
 select id into org from public.organizations where is_active;
 perform pg_advisory_xact_lock(hashtextextended(lower(name_value),6));
 if p_input->>'entity'='school' then
  select jsonb_build_object('id',id,'name',name) into result from public.schools where organization_id=org and lower(name)=lower(name_value) and is_active limit 1;
  if result is null then insert into public.schools(organization_id,name,is_verified,is_active) values(org,name_value,true,true) returning jsonb_build_object('id',id,'name',name) into result; end if;
 elsif p_input->>'entity'='relationship' then
  select jsonb_build_object('id',id,'name',name) into result from public.guardian_relationships where organization_id=org and lower(name)=lower(name_value) and is_active limit 1;
  if result is null then insert into public.guardian_relationships(organization_id,code,name,is_active) values(org,'REL_'||replace(gen_random_uuid()::text,'-',''),name_value,true) returning jsonb_build_object('id',id,'name',name) into result; end if;
 else raise exception 'Only school and guardian relationship can be created during admission.';
 end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,after_data)
 values(auth.uid(),upper(p_input->>'entity'),result->>'id','SELECT_OR_CREATE_FOR_ADMISSION','Verified missing directory option during admission',result);
 return result;
end $function$;

CREATE OR REPLACE FUNCTION public.capture_audit_actor()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare person public.staff; name text; roles text; trace text;
begin
 if new.actor_profile_id is null and exists(select 1 from public.profiles where id=auth.uid()) then new.actor_profile_id:=auth.uid(); end if;
 if new.actor_profile_id is not null then
  select * into person from public.staff where profile_id=new.actor_profile_id;
  new.actor_staff_id:=coalesce(new.actor_staff_id,person.id);
  select display_name into name from public.profiles where id=new.actor_profile_id;
  select string_agg(distinct r.code,', ' order by r.code) into roles from public.user_role_assignments a join public.system_roles r on r.id=a.role_id
   where a.profile_id=new.actor_profile_id and a.is_active and r.is_active and a.effective_from<=current_date and (a.effective_to is null or a.effective_to>=current_date);
  new.actor_role_code:=coalesce(new.actor_role_code,roles,'AUTHENTICATED');
  new.metadata:=new.metadata||jsonb_build_object('actor_name',coalesce(person.full_name,name),'actor_staff_no',person.staff_no,'actor_roles',new.actor_role_code);
 end if;
 trace:=nullif(current_setting('sohoj.workflow_trace',true),'');
 if trace is not null then new.correlation_id:=trace::uuid; end if;
 return new;
end $function$;

CREATE OR REPLACE FUNCTION public.audit_event_list(p_correlation uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null or not public.has_permission('audit.view') then raise exception 'Audit permission required.'; end if;
 return coalesce((select jsonb_agg(row_data order by occurred_at desc,id desc) from (
 select e.id,e.occurred_at,to_jsonb(e)||jsonb_build_object(
 'actor_name',coalesce(e.metadata->>'actor_name',s.full_name,p.display_name),
 'actor_staff_no',coalesce(e.metadata->>'actor_staff_no',s.staff_no),
 'actor_role_code',coalesce(e.actor_role_code,(select string_agg(distinct r.code,', ' order by r.code) from public.user_role_assignments a join public.system_roles r on r.id=a.role_id where a.profile_id=e.actor_profile_id and a.effective_from<=e.occurred_at::date and (a.effective_to is null or a.effective_to>=e.occurred_at::date))),
 'identity_snapshot',e.metadata ? 'actor_name') as row_data
 from public.audit_events e left join public.profiles p on p.id=e.actor_profile_id
 left join public.staff s on s.id=e.actor_staff_id or (e.actor_staff_id is null and s.profile_id=e.actor_profile_id)
 where p_correlation is null or e.correlation_id=p_correlation order by e.occurred_at desc,e.id desc limit 250
 ) rows),'[]'::jsonb);
end $function$;

CREATE OR REPLACE FUNCTION public.prospect_assignment_options()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null or not public.has_permission('crm.prospects.view') then raise exception 'CRM access required.'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',full_name||' · '||staff_no) order by full_name) from public.staff where status in('ACTIVE','ON_LEAVE')),'[]'::jsonb);
end $function$;

CREATE OR REPLACE FUNCTION public.assign_prospect_staff(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare p public.prospects; chosen uuid:=nullif(p_input->>'staff_id','')::uuid;
begin
 if auth.uid() is null or not public.has_permission('crm.prospects.manage') then raise exception 'CRM management permission required.'; end if;
 if length(btrim(coalesce(p_input->>'reason',''))) not between 5 and 500 then raise exception 'Assignment reason required.'; end if;
 if chosen is not null and not exists(select 1 from public.staff where id=chosen and status in('ACTIVE','ON_LEAVE')) then raise exception 'Choose an active staff member.'; end if;
 select * into p from public.prospects where id=(p_input->>'prospect_id')::uuid for update;
 if p.id is null then raise exception 'Prospect not found.'; end if;
 if chosen is not distinct from p.assigned_to_staff_id then return jsonb_build_object('id',p.id); end if;
 update public.prospects set assigned_to_staff_id=chosen where id=p.id;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),'PROSPECT',p.id::text,'ASSIGN_FOLLOWUP_STAFF',p_input->>'reason',jsonb_build_object('staff_id',p.assigned_to_staff_id),jsonb_build_object('staff_id',chosen));
 return jsonb_build_object('id',p.id);
end $function$;

CREATE OR REPLACE FUNCTION public.create_programme_offering(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_org uuid;
  v_row public.programme_offerings;
  v_reason text := btrim(coalesce(p_input->>'reason',''));
  v_correlation uuid := gen_random_uuid();
begin
 p_input:=p_input||jsonb_build_object('name',coalesce(nullif(btrim(p_input->>'name'),''),(select name from public.programs where id=(p_input->>'program_id')::uuid)));
  if v_actor is null or not public.has_permission('academics.manage') then
    raise exception 'You are not authorized to manage Programme Offerings.';
  end if;
  if length(v_reason)<5 then raise exception 'A change reason of at least five characters is required.'; end if;
  select id into v_org from public.organizations where is_active;
  if v_org is null or not exists (
    select 1 from public.branches b
    join public.academic_years y on y.id=(p_input->>'academic_year_id')::uuid
    join public.classes c on c.id=(p_input->>'class_id')::uuid
    join public.programs p on p.id=(p_input->>'program_id')::uuid
    where b.id=(p_input->>'branch_id')::uuid and b.is_active
      and b.organization_id=v_org and y.organization_id=v_org
      and c.organization_id=v_org and c.is_active
      and p.organization_id=v_org and p.is_active
      and (nullif(p_input->>'group_id','') is null or exists (
        select 1 from public.academic_groups g
        where g.id=(p_input->>'group_id')::uuid
          and g.organization_id=v_org and g.is_active))
  ) then
    raise exception 'Offering context must use active master data from the same organization.';
  end if;
  insert into public.programme_offerings(
    organization_id,branch_id,academic_year_id,class_id,program_id,
    group_id,code,name,created_by
  ) values (
    v_org,(p_input->>'branch_id')::uuid,(p_input->>'academic_year_id')::uuid,
    (p_input->>'class_id')::uuid,(p_input->>'program_id')::uuid,
    nullif(p_input->>'group_id','')::uuid,
    upper(btrim(p_input->>'code')),btrim(p_input->>'name'),v_actor
  ) returning * into v_row;
  insert into public.audit_events(correlation_id,actor_profile_id,actor_staff_id,
    branch_id,entity_type,entity_id,action,reason,after_data)
  values (v_correlation,v_actor,(select id from public.staff where profile_id=v_actor limit 1),
    v_row.branch_id,'PROGRAMME_OFFERING',v_row.id::text,'CREATE',v_reason,to_jsonb(v_row));
  return jsonb_build_object('offering_id',v_row.id,'correlation_id',v_correlation);
end;
$function$;

CREATE OR REPLACE FUNCTION public.update_programme_offering(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid:=auth.uid();
  v_request uuid:=nullif(p_input->>'request_id','')::uuid;
  v_reason text:=btrim(coalesce(p_input->>'reason',''));
  v_org uuid;
  v_row public.programme_offerings;
  v_before jsonb;
  v_result jsonb;
  v_branch uuid:=(p_input->>'branch_id')::uuid;
  v_year uuid:=(p_input->>'academic_year_id')::uuid;
  v_class uuid:=(p_input->>'class_id')::uuid;
  v_program uuid:=(p_input->>'program_id')::uuid;
  v_group uuid:=nullif(p_input->>'group_id','')::uuid;
  v_code text:=upper(btrim(coalesce(p_input->>'code','')));
  v_name text:=btrim(coalesce(p_input->>'name',''));
  v_existing public.admission_command_keys;
begin
 p_input:=p_input||jsonb_build_object('name',coalesce(nullif(btrim(p_input->>'name'),''),(select name from public.programs where id=(p_input->>'program_id')::uuid)));
  if v_actor is null or not public.has_permission('academics.manage') then raise exception 'You are not authorized to manage Programme Offerings.'; end if;
  if v_request is null then raise exception 'A request identity is required.'; end if;
  if length(v_reason)<5 then raise exception 'A change reason of at least five characters is required.'; end if;
  if length(v_code)<2 or length(v_code)>40 or v_code !~ '^[A-Z0-9_-]+$' then raise exception 'Use a valid offering code with letters, numbers, underscores or hyphens.'; end if;
  if length(v_name)<2 or length(v_name)>160 then raise exception 'Enter a recognizable offering name.'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_request::text,0));
  select * into v_existing from public.admission_command_keys where request_id=v_request;
  if found then
    if v_existing.actor_id<>v_actor or v_existing.payload<>p_input then raise exception 'Request identity was already used for different input.'; end if;
    return v_existing.result;
  end if;
  select id into v_org from public.organizations where is_active limit 1;
  select * into v_row from public.programme_offerings where id=(p_input->>'offering_id')::uuid and organization_id=v_org for update;
  if v_row.id is null then raise exception 'Programme Offering not found.'; end if;
  
  v_before:=to_jsonb(v_row);
  if v_row.status in('ACTIVE','RETIRED') and (
    v_branch is distinct from v_row.branch_id or v_year is distinct from v_row.academic_year_id
    or v_class is distinct from v_row.class_id or v_program is distinct from v_row.program_id
    or v_group is distinct from v_row.group_id
  ) then raise exception 'Academic context cannot change after activation. Create a new offering for a new year, class, branch or programme.'; end if;
  if v_row.status='DRAFT' and exists(select 1 from public.batches where offering_id=v_row.id) and (
    v_branch is distinct from v_row.branch_id or v_year is distinct from v_row.academic_year_id
    or v_class is distinct from v_row.class_id or v_program is distinct from v_row.program_id
    or v_group is distinct from v_row.group_id
  ) then raise exception 'Academic context cannot change after batches reference this offering.'; end if;
  if v_row.status='DRAFT' and not exists (
    select 1 from public.branches b join public.academic_years y on y.id=v_year
    join public.classes c on c.id=v_class join public.programs p on p.id=v_program
    where b.id=v_branch and b.is_active and b.organization_id=v_org and y.organization_id=v_org
      and c.organization_id=v_org and c.is_active and p.organization_id=v_org and p.is_active
      and (v_group is null or exists(select 1 from public.academic_groups g where g.id=v_group and g.organization_id=v_org and g.is_active))
  ) then raise exception 'Offering context must use active master data from the same organization.'; end if;
  update public.programme_offerings set
    branch_id=case when status='DRAFT' then v_branch else branch_id end,
    academic_year_id=case when status='DRAFT' then v_year else academic_year_id end,
    class_id=case when status='DRAFT' then v_class else class_id end,
    program_id=case when status='DRAFT' then v_program else program_id end,
    group_id=case when status='DRAFT' then v_group else group_id end,
    code=v_code,name=v_name
  where id=v_row.id returning * into v_row;
  v_result:=jsonb_build_object('offering_id',v_row.id,'correlation_id',v_request);
  insert into public.audit_events(correlation_id,actor_profile_id,actor_staff_id,branch_id,entity_type,entity_id,action,reason,before_data,after_data,metadata)
  values(v_request,v_actor,(select id from public.staff where profile_id=v_actor limit 1),v_row.branch_id,'PROGRAMME_OFFERING',v_row.id::text,'UPDATE',v_reason,v_before,to_jsonb(v_row),jsonb_build_object('request_id',v_request,'status',v_row.status));
  insert into public.admission_command_keys(request_id,actor_id,payload,result) values(v_request,v_actor,p_input,v_result);
  return v_result;
end
$function$;

-- Upstream 09_admission_billing_workflows.sql
-- Sohoj Academy fresh database baseline: admission billing workflows.
-- Install on an empty application schema. Each object is defined once.

CREATE OR REPLACE FUNCTION public.invoice_balance(p_invoice_id uuid)
 RETURNS TABLE(gross numeric, credits numeric, paid numeric, refunded numeric, net numeric, due numeric, credit_balance numeric, reserved_refunds numeric)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with x as (
 select i.total as g,
 coalesce((select sum(amount) from public.invoice_credits where invoice_id=i.id),0) c,
 coalesce((select sum(amount) from public.admission_payment_allocations where invoice_id=i.id),0) p,
 coalesce((select sum(r.amount) from public.refund_authorizations r join public.refund_payouts rp on rp.authorization_id=r.id where r.invoice_id=i.id),0) f,
 coalesce((select sum(r.amount) from public.refund_authorizations r where r.invoice_id=i.id and not exists(select 1 from public.refund_payouts rp where rp.authorization_id=r.id)),0) reserved
 from public.admission_invoices i where i.id=p_invoice_id)
 select g,c,p,f,g-c,greatest(g-c-p+f,0),greatest(p-f-(g-c),0),reserved from x;
$function$;

CREATE OR REPLACE FUNCTION public.enforce_batch_policy()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
  v_max integer;
begin
  select (payload->>'max_students')::integer
    into v_max
  from public.business_rule_versions
  where domain='academics'
    and rule_key='batch_capacity_policy'
    and status='ACTIVE'
  order by version desc
  limit 1;

  if v_max is null or v_max < 1 then
    raise exception 'Active batch capacity policy is missing or invalid.';
  end if;

  if new.capacity > v_max then
    raise exception 'Batch capacity exceeds the active public policy maximum of %.', v_max;
  end if;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.enforce_enrollment_batch_integrity()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
  v_batch public.batches;
  v_occupied integer;
begin
  if new.status <> 'ACTIVE' or new.batch_id is null then
    return new;
  end if;

  select * into v_batch
  from public.batches
  where id = new.batch_id
    and is_active
  for update;

  if v_batch.id is null then
    raise exception 'Selected batch is not available.';
  end if;

  if new.organization_id <> v_batch.organization_id
     or new.academic_year_id <> v_batch.academic_year_id
     or new.class_id <> v_batch.class_id
     or new.program_id is distinct from v_batch.program_id then
    raise exception 'Enrollment does not match the selected batch academic context.';
  end if;

  select count(*)::integer into v_occupied
  from public.enrollments e
  where e.batch_id = new.batch_id
    and e.status = 'ACTIVE'
    and e.id <> new.id;

  if v_occupied >= v_batch.capacity then
    raise exception 'Selected batch is full (%/%).', v_occupied, v_batch.capacity;
  end if;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.protect_admission_invoice()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$ begin raise exception 'Posted billing history is immutable; use a compensating adjustment workflow.'; end; $function$;

CREATE OR REPLACE FUNCTION public.admission_payment_satisfied(p_admission_id uuid)
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select bal.paid-bal.refunded>=case
 when not (r.payload->>'allow_credit_enrollment')::boolean or r.payload->>'payment_requirement'='FULL' then bal.net
 when r.payload->>'payment_requirement'='MINIMUM_PERCENT' then round(bal.net*(r.payload->>'minimum_payment_percent')::numeric/100,2)
 else 0 end
 from public.admission_cases a join public.admission_invoices i on i.admission_id=a.id and i.invoice_kind='INITIAL'
 join public.business_rule_versions r on r.id=a.activation_policy_version_id
 cross join lateral public.invoice_balance(i.id) bal where a.id=p_admission_id;
$function$;

CREATE OR REPLACE FUNCTION public.post_admission_payment(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 v_actor uuid:=auth.uid(); v_request uuid:=(p_input->>'request_id')::uuid;
 v_key public.admission_command_keys; v_case public.admission_cases; v_invoice public.admission_invoices;
 v_payment public.admission_payments; v_amount numeric:=(p_input->>'amount')::numeric;
 v_paid numeric; v_result jsonb; v_reason text:=btrim(coalesce(p_input->>'reason',''));
begin
 if v_actor is null or not public.has_permission('finance.payments.post') then raise exception 'Payment posting permission required.'; end if;
 if v_request is null or v_amount is null or v_amount<=0 or v_amount<>round(v_amount,2) or length(v_reason)<5 then raise exception 'Valid amount, request identity and reason are required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(v_request::text,0));
 select * into v_key from public.admission_command_keys where request_id=v_request;
 if found then
   if v_key.actor_id<>v_actor or v_key.payload<>p_input then raise exception 'Request identity was already used for different input.'; end if;
   return v_key.result;
 end if;
 select * into v_case from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
 if not found or v_case.status not in ('BILLING_POSTED','PENDING_PAYMENT','ACTIVE_ENROLLMENT','CANCELLED') then raise exception 'Post initial billing before collecting payment.'; end if;
 select * into v_invoice from public.admission_invoices where admission_id=v_case.id and (case when nullif(p_input->>'invoice_id','') is null then invoice_kind='INITIAL' else id=(p_input->>'invoice_id')::uuid end) for update;
 select due into v_paid from public.invoice_balance(v_invoice.id);
 if v_invoice.id is null or v_amount>v_paid then raise exception 'Payment exceeds the outstanding invoice balance.'; end if;
 if not exists(select 1 from public.payment_methods where id=(p_input->>'payment_method_id')::uuid and is_active) then raise exception 'Choose an active payment method.'; end if;
 insert into public.admission_payments(student_id,payment_method_id,amount,currency_code,external_reference,posted_by,reason)
 values(v_case.student_id,(p_input->>'payment_method_id')::uuid,v_amount,v_invoice.currency_code,nullif(btrim(p_input->>'external_reference'),''),v_actor,v_reason) returning * into v_payment;
 insert into public.admission_payment_allocations(payment_id,invoice_id,amount) values(v_payment.id,v_invoice.id,v_amount);
 v_result:=jsonb_build_object('id',v_case.id,'status',v_case.status,'receipt_no',v_payment.receipt_no);
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,after_data,metadata)
 values(v_request,v_actor,'PAYMENT',v_payment.id::text,'POST',v_reason,to_jsonb(v_payment),jsonb_build_object('invoice_id',v_invoice.id,'admission_id',v_case.id));
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(v_request,v_actor,p_input,v_result);
 return v_result;
end; $function$;

CREATE OR REPLACE FUNCTION public.admission_workspace()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_view boolean:=public.has_permission('admissions.view'); v_result jsonb;
begin
 if auth.uid() is null or not (v_view or public.has_permission('academics.view')) then raise exception 'Workspace access denied.'; end if;
 select jsonb_build_object(
  'offerings',coalesce((select jsonb_agg(jsonb_build_object('id',o.id,'name',o.name,'code',o.code,
      'classId',o.class_id,'className',c.name,'yearName',ay.name,'branchName',br.name))
    from public.programme_offerings o join public.classes c on c.id=o.class_id
    join public.academic_years ay on ay.id=o.academic_year_id left join public.branches br on br.id=o.branch_id
    join public.organizations org on org.id=o.organization_id
    where o.status='ACTIVE' and exists(select 1 from public.fee_plan_versions f
      where f.offering_id=o.id and f.status='ACTIVE'
        and f.effective_from<=timezone(org.timezone,now())::date)),'[]'::jsonb),
  'capacityLimit',(select (payload->>'max_students')::integer from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE'),
  'batches',coalesce((select jsonb_agg(jsonb_build_object(
    'id',b.id,'name',b.name,'code',b.code,'offeringId',b.offering_id,
    'offeringName',o.name,'classId',b.class_id,'className',c.name,
    'yearName',y.name,'branchName',br.name,'capacity',b.capacity,
    'isActive',b.is_active,
    'occupied',(select count(*) from public.enrollments e where e.batch_id=b.id and e.status='ACTIVE')
  ) order by y.starts_on desc,o.name,b.name)
    from public.batches b
    join public.programme_offerings o on o.id=b.offering_id
    join public.classes c on c.id=b.class_id
    join public.academic_years y on y.id=b.academic_year_id
    left join public.branches br on br.id=b.branch_id
  ),'[]'::jsonb),
  'prospects',case when v_view then coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.student_name,'number',p.prospect_no,'classId',p.current_class_id,'interestedOfferingId',p.interested_offering_id,'guardian',p.guardian_name,'mobile',p.mobile)) from public.prospects p where p.status not in ('CONVERTED','LOST') and not exists(select 1 from public.admission_cases a where a.prospect_id=p.id and a.status<>'CANCELLED')),'[]'::jsonb) else '[]'::jsonb end,
  'cases',case when v_view then coalesce((select jsonb_agg(x order by x->>'createdAt' desc) from (
    select jsonb_build_object('id',a.id,'number',a.admission_no,'status',a.status,'createdAt',a.created_at,
      'existingStudent',a.existing_student,'batchId',a.batch_id,'studentNo',s.student_no,'studentId',s.id,'name',a.identity_snapshot->>'student_name','nameBn',a.identity_snapshot->>'student_name_bn',
      'gender',a.identity_snapshot->>'gender','dateOfBirth',a.identity_snapshot->>'date_of_birth',
      'schoolName',a.identity_snapshot->>'school_name','schoolRoll',a.identity_snapshot->>'school_roll',
      'guardianAddress',a.identity_snapshot->>'guardian_address','alternateMobile',a.identity_snapshot->>'alternate_mobile',
      'guardianRelationship',a.identity_snapshot->>'guardian_relationship',
      'guardian',a.identity_snapshot->>'guardian_name','mobile',a.identity_snapshot->>'mobile',
      'feeVersion',f.version,'feePlanId',f.id,'policyVersion',r.version,'paymentRequirement',r.payload->>'payment_requirement',
      'components',coalesce((select jsonb_agg(jsonb_build_object('name',fc.name,'amount',fc.amount,'recurrence',fc.recurrence)) from public.fee_plan_components fc where fc.fee_plan_version_id=f.id),'[]'::jsonb),
      'invoice',case when i.id is null then null else jsonb_build_object('number',i.invoice_no,'total',i.total,'dueOn',i.due_on,'paid',bal.paid,'credits',bal.credits,'net',bal.net,'refunded',bal.refunded,'due',bal.due,'credit',bal.credit_balance) end,
      'receipts',coalesce((select jsonb_agg(jsonb_build_object('number',p.receipt_no,'amount',pa.amount,'postedAt',p.posted_at,'method',pm.name,'refunded',coalesce((select sum(ra.amount) from public.refund_authorizations ra join public.refund_payouts rp on rp.authorization_id=ra.id where ra.payment_id=p.id),0))) from public.admission_payment_allocations pa join public.admission_payments p on p.id=pa.payment_id join public.payment_methods pm on pm.id=p.payment_method_id where pa.invoice_id=i.id),'[]'::jsonb)
    ) as x
    from public.admission_cases a left join public.fee_plan_versions f on f.id=a.fee_plan_version_id
    left join public.students s on s.id=a.student_id left join public.business_rule_versions r on r.id=a.activation_policy_version_id
    left join public.admission_invoices i on i.admission_id=a.id and i.invoice_kind='INITIAL'
    left join lateral public.invoice_balance(i.id) bal on true
  ) rows),'[]'::jsonb) else '[]'::jsonb end,
  'paymentMethods',case when public.has_permission('finance.payments.post') then coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name)) from public.payment_methods where is_active),'[]'::jsonb) else '[]'::jsonb end
 ) into v_result;
 return v_result;
end; $function$;

CREATE OR REPLACE FUNCTION public.apply_invoice_discounts(p_invoice_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  i public.admission_invoices;
  d public.admission_discounts;
  tuition numeric;
  credit numeric;
begin
  select * into i
  from public.admission_invoices
  where id=p_invoice_id;

  select coalesce(sum(amount),0)
  into tuition
  from public.admission_invoice_lines
  where invoice_id=i.id
    and charge_type='TUITION';

  for d in
    select *
    from public.admission_discounts
    where admission_id=i.admission_id
      and i.billing_period between starts_on and ends_on
  loop
    credit:=least(
      tuition,
      case
        when d.kind='PERCENT' then round(tuition*d.value/100,2)
        else d.value
      end
    );

    if credit>0 then
      insert into public.invoice_credits(invoice_id, discount_id, kind, amount, applied_by)
      values(i.id, d.id, 'DISCOUNT', credit, d.authorized_by)
      on conflict (invoice_id, discount_id)
        where kind='DISCOUNT' and discount_id is not null
      do nothing;
    end if;
  end loop;
end;
$function$;

CREATE OR REPLACE FUNCTION public.billing_preview(p_period date, p_term_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare period_date date:=p_period; term public.billing_terms; rows jsonb; total numeric;
begin
 if auth.uid() is null or not public.has_permission('finance.billing.manage') then raise exception 'Billing management permission required.'; end if;
 if p_term_id is not null then
  select * into term from public.billing_terms where id=p_term_id;
  if term.id is null then raise exception 'Term not found.'; end if;
  period_date:=term.starts_on;
 elsif period_date is null or period_date<>date_trunc('month',period_date)::date then raise exception 'Select the first day of a billing month.';
 end if;
 select coalesce(jsonb_agg(x order by x->>'admissionId'),'[]'::jsonb) into rows from (
 select jsonb_build_object('admissionId',a.id,'name',s.full_name,'number',a.admission_no,'feePlanId',f.id,
 'gross',charges.gross,'discount',least(charges.tuition,coalesce(case when d.kind='PERCENT' then round(charges.tuition*d.value/100,2) else d.value end,0)),
 'dueOn',case when p_term_id is not null then term.due_on else period_date+f.due_day-1 end) x
 from public.admission_cases a join public.students s on s.id=a.student_id
 join public.enrollments e on e.id=a.enrollment_id and e.status='ACTIVE'
 join public.batches b on b.id=a.batch_id join public.academic_years y on y.id=b.academic_year_id
 left join public.fee_plan_versions f on f.id=a.fee_plan_version_id
 join public.admission_invoices initial on initial.admission_id=a.id and initial.invoice_kind='INITIAL'
 cross join lateral (select coalesce(sum(amount),0) gross,coalesce(sum(amount) filter(where charge_type='TUITION'),0) tuition from public.fee_plan_components where fee_plan_version_id=f.id and recurrence='PER_CYCLE') charges
 left join public.admission_discounts d on d.admission_id=a.id and period_date between d.starts_on and d.ends_on
 where a.status='ACTIVE_ENROLLMENT' and period_date between y.starts_on and y.ends_on
 and ((p_term_id is null and f.billing_cycle='MONTHLY' and period_date>initial.billing_period)
   or (p_term_id is not null and f.billing_cycle='TERM' and b.academic_year_id=term.academic_year_id and term.starts_on>initial.issued_on))
 and not exists(select 1 from public.admission_invoices i where i.admission_id=a.id and i.billing_period=period_date)
 ) q;
 select coalesce(sum((x->>'gross')::numeric-(x->>'discount')::numeric),0) into total from jsonb_array_elements(rows) x;
 return jsonb_build_object('period',period_date,'termId',p_term_id,'rows',rows,'netTotal',total,'token',md5(rows::text||period_date::text||coalesce(p_term_id::text,'')));
end; $function$;

CREATE OR REPLACE FUNCTION public.student_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 actor uuid:=auth.uid();req uuid:=(p_input->>'request_id')::uuid;action text:=p_input->>'action';reason text:=btrim(coalesce(p_input->>'reason',''));
 key public.admission_command_keys;s public.students;target public.students;a public.admission_cases;b public.batches;dest public.batches;
 fee public.fee_plan_versions;guardian record;policy public.business_rule_versions;e public.enrollments;
 sid uuid:=(p_input->>'student_id')::uuid;tid uuid:=(p_input->>'target_id')::uuid;eid uuid;aid uuid;today date;result jsonb;snapshot jsonb;
begin
 if actor is null or not public.has_permission('students.view') then raise exception 'Student access required.'; end if;
 if req is null or length(reason) not between 5 and 500 then raise exception 'Request identity and a reason of 5–500 characters required.'; end if;
 if action='CREATE_EXISTING' then
  if not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 elsif action in('TRANSFER','MERGE') then
  if not public.has_permission('students.manage') then raise exception 'Student management permission required.'; end if;
 else raise exception 'Unsupported student action.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into key from public.admission_command_keys where request_id=req;
 if found then
  if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity already used.'; end if;
  return key.result;
 end if;
 if action='TRANSFER' then
  aid:=(p_input->>'admission_id')::uuid;
  select * into a from public.admission_cases where id=aid for update;
  if a.id is null or a.student_id is distinct from sid then raise exception 'Admission does not belong to this student.'; end if;
 end if;
 perform 1 from public.students where id in(sid,tid) order by id for update;
 select * into s from public.students where id=sid;
 if s.id is null or s.merged_into_id is not null or s.status='ARCHIVED' then raise exception 'Use an existing canonical student.'; end if;
 select timezone(timezone,now())::date into today from public.organizations where id=s.organization_id;
  if action='CREATE_EXISTING' then
   select * into b from public.batches where id=(p_input->>'batch_id')::uuid and is_active for update;
   if b.id is null or b.organization_id<>s.organization_id or not exists(select 1 from public.programme_offerings where id=b.offering_id and status='ACTIVE') then raise exception 'Select an active offering-linked batch in this organization.';end if;
   if exists(select 1 from public.enrollments where student_id=s.id and academic_year_id=b.academic_year_id and status='ACTIVE')
    or exists(select 1 from public.admission_cases ac join public.batches ba on ba.id=ac.batch_id where ac.student_id=s.id and ba.academic_year_id=b.academic_year_id and ac.status<>'CANCELLED') then
    raise exception 'An open admission or active enrollment already exists for this academic year. Use transfer or finish cancellation first.';end if;
   select * into policy from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE';
   if policy.id is null then raise exception 'Capacity policy missing.';end if;
   if (select count(*) from public.enrollments where batch_id=b.id and status='ACTIVE')>=least(b.capacity,(policy.payload->>'max_students')::integer) then raise exception 'Selected batch is full.';end if;
   select * into fee from public.fee_plan_versions where offering_id=b.offering_id and status='ACTIVE' and effective_from<=today;
   if fee.id is null then raise exception 'An effective Fee Plan is required.';end if;
   select g.full_name,g.mobile,sg.relationship_snapshot into guardian from public.student_guardians sg join public.guardians g on g.id=sg.guardian_id where sg.student_id=s.id and sg.is_primary;
   if guardian.full_name is null then raise exception 'A primary guardian is required.';end if;
   insert into public.admission_cases(batch_id,fee_plan_version_id,student_id,existing_student,identity_snapshot,created_by)
   values(b.id,fee.id,s.id,true,jsonb_build_object('student_name',s.full_name,'guardian_name',guardian.full_name,'mobile',guardian.mobile,'guardian_relationship',coalesce(guardian.relationship_snapshot,'Guardian'),'school_id',s.school_id,'school_name',s.school_name_snapshot),actor) returning id into aid;
   result:=jsonb_build_object('id',aid,'message','Enrollment draft created using the existing Student ID. Review and accept it in Admissions.');
  elsif action='TRANSFER' then
   if a.status<>'ACTIVE_ENROLLMENT' then raise exception 'Only an active enrollment can transfer.';end if;
   select * into e from public.enrollments where id=a.enrollment_id and status='ACTIVE';
   if e.id is null then raise exception 'Active enrollment not found.';end if;
   eid:=(p_input->>'batch_id')::uuid;
   perform 1 from public.batches where id in(a.batch_id,eid) order by id for update;
   select * into b from public.batches where id=a.batch_id;
   select * into dest from public.batches where id=eid and is_active;
   if dest.id is null or dest.id=b.id or dest.offering_id is distinct from b.offering_id or dest.organization_id<>b.organization_id then raise exception 'Transfer requires a different active batch in the same offering. Fee terms remain unchanged.';end if;
   select * into policy from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE';
   if policy.id is null then raise exception 'Capacity policy missing.';end if;
   if (select count(*) from public.enrollments where batch_id=dest.id and status='ACTIVE')>=least(dest.capacity,(policy.payload->>'max_students')::integer) then raise exception 'Destination batch is full under the current capacity policy.';end if;
    update public.enrollments set status='WITHDRAWN',ended_on=today where id=e.id;
    insert into public.enrollments(student_id,organization_id,branch_id,academic_year_id,class_id,program_id,batch_id,admission_date,status,created_by)
    values(s.id,dest.organization_id,dest.branch_id,dest.academic_year_id,dest.class_id,dest.program_id,dest.id,today,'ACTIVE',actor) returning id into eid;
    insert into public.enrollment_transfers(student_id,admission_id,from_enrollment_id,to_enrollment_id,from_batch_id,to_batch_id,authorized_by,authorization_reason,capacity_policy_version_id,transferred_on)
    values(s.id,a.id,e.id,eid,b.id,dest.id,actor,reason,policy.id,today);
    update public.admission_cases set batch_id=dest.id,enrollment_id=eid,capacity_policy_version_id=policy.id where id=a.id;
   result:=jsonb_build_object('id',a.id,'message','Batch transfer completed; financial history preserved.');
  elsif action='MERGE' then
   select * into target from public.students where id=tid;
   if target.id is null or target.id=s.id or target.organization_id<>s.organization_id or target.merged_into_id is not null or target.status='ARCHIVED' then raise exception 'Select a different canonical student in this organization.';end if;
   if exists(select 1 from public.students where merged_into_id=s.id) then raise exception 'A canonical identity with linked duplicates cannot be merged again.';end if;
   if exists(select 1 from public.enrollments where student_id=s.id and status='ACTIVE') or exists(select 1 from public.admission_cases where student_id=s.id and status<>'CANCELLED') then raise exception 'Resolve the duplicate identity’s open admissions and enrollments before merging.';end if;
   if lower(btrim(s.full_name))<>lower(btrim(target.full_name)) and not exists(
    select 1 from public.student_guardians x join public.guardians gx on gx.id=x.guardian_id cross join public.student_guardians y join public.guardians gy on gy.id=y.guardian_id
    where x.student_id=s.id and y.student_id=target.id and gx.mobile=gy.mobile) then raise exception 'No matching name or guardian mobile. Verify the identities before requesting a merge.';end if;
   if p_input->>'confirmed_same_person' is distinct from 'true' then raise exception 'Confirm these identities belong to the same student.'; end if;
    insert into public.student_merges(source_id,target_id,authorized_by,authorization_reason,source_snapshot,target_snapshot) values(s.id,target.id,actor,reason,to_jsonb(s),to_jsonb(target));
    update public.students set merged_into_id=target.id,status='ARCHIVED' where id=s.id;
    -- History and guardian links retain their original IDs and appear in the canonical profile.
   result:=jsonb_build_object('id',target.id,'message','Duplicate archived; original records and financial history preserved.');
  end if;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,metadata)
 values(req,actor,'STUDENT',s.id::text,action,reason,to_jsonb(s),result,p_input);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);
 return result;
end;
$function$;

CREATE OR REPLACE FUNCTION public.student_profile_workspace(p_student_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s public.students;canonical uuid;ids uuid[];can_finance boolean:=public.has_permission('finance.view');result jsonb;
begin
 if auth.uid() is null or not public.has_permission('students.view') then raise exception 'Student access required.';end if;
 select * into s from public.students where id=p_student_id;
 if s.id is null then return null;end if;
 canonical:=coalesce(s.merged_into_id,s.id);
 select array_agg(id) into ids from public.students where id=canonical or merged_into_id=canonical;
 select jsonb_build_object(
 'student',jsonb_build_object('id',s.id,'number',s.student_no,'name',s.full_name,'nameBn',s.name_bn,'status',s.status,'birthDate',s.date_of_birth,'school',coalesce((select name from public.schools where id=s.school_id),s.school_name_snapshot),'createdAt',s.created_at,'canonicalId',canonical,'canonicalNumber',(select student_no from public.students where id=canonical)),
 'identities',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',full_name,'number',student_no)) from public.students where id=any(ids)),'[]'::jsonb),
 'guardians',coalesce((select jsonb_agg(jsonb_build_object('id',sg.id,'studentId',sg.student_id,'name',g.full_name,'mobile',g.mobile,'alternateMobile',g.alternate_mobile,'relationship',sg.relationship_snapshot,'primary',sg.is_primary)) from public.student_guardians sg join public.guardians g on g.id=sg.guardian_id where sg.student_id=any(ids)),'[]'::jsonb),
 'enrollments',coalesce((select jsonb_agg(jsonb_build_object('id',e.id,'studentId',e.student_id,'year',y.name,'class',c.name,'batch',b.name,'status',e.status,'startsOn',e.admission_date,'endsOn',e.ended_on) order by e.created_at desc) from public.enrollments e join public.academic_years y on y.id=e.academic_year_id join public.classes c on c.id=e.class_id left join public.batches b on b.id=e.batch_id where e.student_id=any(ids)),'[]'::jsonb),
 'admissions',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'number',a.admission_no,'studentId',a.student_id,'batchId',a.batch_id,'offeringId',b.offering_id,'batch',b.name,'status',a.status,'createdAt',a.created_at,'feeVersion',f.version) order by a.created_at desc) from public.admission_cases a join public.batches b on b.id=a.batch_id left join public.fee_plan_versions f on f.id=a.fee_plan_version_id where a.student_id=any(ids)),'[]'::jsonb),
 'batches',coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'name',b.name,'offeringId',b.offering_id,'offering',o.name,'year',y.name,'class',c.name,'capacity',least(b.capacity,(select (payload->>'max_students')::integer from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE')),'occupied',(select count(*) from public.enrollments where batch_id=b.id and status='ACTIVE'))) from public.batches b join public.programme_offerings o on o.id=b.offering_id join public.academic_years y on y.id=b.academic_year_id join public.classes c on c.id=b.class_id where b.organization_id=s.organization_id and b.is_active and o.status='ACTIVE'),'[]'::jsonb),
 'invoices',case when can_finance then coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'studentId',i.student_id,'number',i.invoice_no,'period',i.billing_period,'gross',bal.gross,'credits',bal.credits,'paid',bal.paid,'refunded',bal.refunded,'due',bal.due,'credit',bal.credit_balance) order by i.posted_at desc) from public.admission_invoices i cross join lateral public.invoice_balance(i.id) bal where i.student_id=any(ids)),'[]'::jsonb) else '[]'::jsonb end,
 'financeVisible',can_finance,
 'transfers',coalesce((select jsonb_agg(jsonb_build_object('id',t.id,'fromBatch',b.name,'toBatch',d.name,'date',t.transferred_on,'authorizedBy',t.authorized_by) order by t.created_at desc) from public.enrollment_transfers t join public.batches b on b.id=t.from_batch_id join public.batches d on d.id=t.to_batch_id where t.student_id=any(ids)),'[]'::jsonb),
 'candidates',case when public.has_permission('students.manage') then coalesce((select jsonb_agg(jsonb_build_object('id',t.id,'name',t.full_name,'number',t.student_no,'status',t.status,'birthDate',t.date_of_birth,'school',t.school_name_snapshot,'mobile',(select g.mobile from public.student_guardians sg join public.guardians g on g.id=sg.guardian_id where sg.student_id=t.id and sg.is_primary))) from public.students t where t.id<>s.id and t.organization_id=s.organization_id and t.merged_into_id is null and t.status<>'ARCHIVED' and (lower(btrim(t.full_name))=lower(btrim(s.full_name)) or exists(select 1 from public.student_guardians x join public.guardians gx on gx.id=x.guardian_id cross join public.student_guardians z join public.guardians gz on gz.id=z.guardian_id where x.student_id=s.id and z.student_id=t.id and gx.mobile=gz.mobile))),'[]'::jsonb) else '[]'::jsonb end
 ) into result;
 return result;
end;
$function$;

CREATE OR REPLACE FUNCTION public.require_admission_referral_choice()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
 if new.status='ACCEPTED' and old.status is distinct from new.status and
    not exists(select 1 from public.admission_referrals r where r.admission_id=new.id) then
   raise exception 'Record a referrer or select Organic before accepting this admission.';
 end if;
 return new;
end $function$;

CREATE OR REPLACE FUNCTION public.teacher_referral_matches_admission()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
 if not exists(select 1 from public.admission_referrals ar
   join public.referral_people rp on rp.id=ar.referrer_id
   where ar.admission_id=new.admission_id and ar.source='REFERRED' and rp.staff_id=new.teacher_id) then
  raise exception 'Teacher referral must match the verified admission referral.';
 end if;
 return new;
end $function$;

CREATE OR REPLACE FUNCTION public.batch_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 actor uuid:=auth.uid(); req uuid:=nullif(p_input->>'request_id','')::uuid;
 action text:=p_input->>'action'; reason text:=btrim(coalesce(p_input->>'reason',''));
 key public.admission_command_keys; org uuid; batch public.batches;
 offering public.programme_offerings; policy public.business_rule_versions;
 v_requested_capacity integer; occupied integer; before_data jsonb; result jsonb;
begin
 if actor is null or not public.has_permission('academics.manage') then
  raise exception 'Batch management permission required.';
 end if;
 if req is null or length(reason)<5 then raise exception 'Request identity and a reason of at least five characters are required.'; end if;
 if action not in('CREATE_BATCH','EDIT_BATCH') then raise exception 'Unsupported batch action.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into key from public.admission_command_keys where request_id=req;
 if found then
  if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity was already used for different input.'; end if;
  return key.result;
 end if;
 select id into org from public.organizations where is_active limit 1;
 select * into policy from public.business_rule_versions where domain='academics'
   and rule_key='batch_capacity_policy' and status='ACTIVE' order by version desc limit 1;
 if org is null or policy.id is null then raise exception 'Organization or active capacity policy is unavailable.'; end if;
 v_requested_capacity:=nullif(p_input->>'capacity','')::integer;
 if v_requested_capacity is null or v_requested_capacity<1 or v_requested_capacity>(policy.payload->>'max_students')::integer then
   raise exception 'Batch capacity must be between 1 and the active policy maximum (%).',policy.payload->>'max_students';
 end if;
 if length(btrim(coalesce(p_input->>'name','')))<2 or length(btrim(coalesce(p_input->>'code','')))<2 then
   raise exception 'Enter a batch code and a recognizable batch name.';
 end if;
 if action='CREATE_BATCH' then
  select * into offering from public.programme_offerings
   where id=(p_input->>'offering_id')::uuid and organization_id=org and status='ACTIVE' for update;
  if offering.id is null then raise exception 'Choose an active offering with a published Fee Plan.'; end if;
  insert into public.batches(organization_id,branch_id,academic_year_id,class_id,program_id,
   code,name,capacity,created_by,offering_id,capacity_policy_version_id)
  values(org,offering.branch_id,offering.academic_year_id,offering.class_id,offering.program_id,
   upper(btrim(p_input->>'code')),btrim(p_input->>'name'),v_requested_capacity,actor,offering.id,policy.id)
  returning * into batch;
  result:=jsonb_build_object('id',batch.id,'status','CREATED');
 else
  select * into batch from public.batches where id=(p_input->>'batch_id')::uuid
    and organization_id=org and offering_id is not null for update;
  if batch.id is null then raise exception 'Batch not found.'; end if;
  before_data:=to_jsonb(batch);
  select count(*) into occupied from public.enrollments where batch_id=batch.id and status='ACTIVE';
  if v_requested_capacity<occupied then raise exception 'Capacity cannot be lower than the % students already enrolled.',occupied; end if;
  update public.batches b set code=upper(btrim(p_input->>'code')),
    name=btrim(p_input->>'name'),capacity=v_requested_capacity,
    capacity_policy_version_id=policy.id,updated_at=now()
  where b.id=batch.id returning b.* into batch;
  result:=jsonb_build_object('id',batch.id,'status','UPDATED');
 end if;
 insert into public.audit_events(correlation_id,actor_profile_id,actor_staff_id,
   entity_type,entity_id,action,reason,before_data,after_data,metadata)
 values(req,actor,(select id from public.staff where profile_id=actor limit 1),
   'BATCH',batch.id::text,action,reason,
   before_data,
   to_jsonb(batch),jsonb_build_object('module','batch_register','offering_id',batch.offering_id));
 insert into public.admission_command_keys(request_id,actor_id,payload,result)
 values(req,actor,p_input,result);
 return result;
end $function$;

CREATE OR REPLACE FUNCTION public.sync_admission_student_details()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.student_id is not null and old.student_id is null then
    update public.students set
      name_bn=nullif(new.identity_snapshot->>'student_name_bn',''),
      gender=nullif(new.identity_snapshot->>'gender',''),
      date_of_birth=nullif(new.identity_snapshot->>'date_of_birth','')::date,
      school_roll=nullif(new.identity_snapshot->>'school_roll','')
    where id=new.student_id;
    update public.guardians g set
      alternate_mobile=coalesce(g.alternate_mobile,nullif(new.identity_snapshot->>'alternate_mobile','')),
      address=coalesce(g.address,nullif(new.identity_snapshot->>'guardian_address',''))
    from public.student_guardians sg where sg.student_id=new.student_id and sg.guardian_id=g.id;
  end if;
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.record_physical_admission_consent(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.admission_cases; r public.admission_physical_consent_receipts;
 req uuid:=(p_input->>'request_id')::uuid; signing date:=(p_input->>'guardian_signed_on')::date; today date;
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if req is null or signing is null or length(btrim(coalesce(p_input->>'reason','')))<5 then raise exception 'Signing date and staff note are required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into r from public.admission_physical_consent_receipts where request_id=req;
 if found then
  if r.received_by<>auth.uid() or r.request_payload<>p_input then raise exception 'Request identity already used.'; end if;
  return jsonb_build_object('id',r.id);
 end if;
 select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
 if a.id is null or a.status in('DRAFT','CANCELLED') then raise exception 'Verify the application before receiving paper consent.'; end if;
 if not exists(select 1 from public.admission_referrals where admission_id=a.id) then raise exception 'Record Organic or a verified referrer first.'; end if;
 select timezone(o.timezone,now())::date into today from public.batches b join public.organizations o on o.id=b.organization_id where b.id=a.batch_id;
 if signing>today then raise exception 'Signing date cannot be in the future.'; end if;
 if exists(select 1 from public.admission_physical_consent_receipts where admission_id=a.id and identity_revision=a.identity_revision) then raise exception 'Consent for these details is already recorded.'; end if;
 insert into public.admission_physical_consent_receipts(request_id,request_payload,admission_id,version,guardian_signed_on,student_signed,physical_copy_reference,received_by,reason,identity_revision)
 values(req,p_input,a.id,(select coalesce(max(version),0)+1 from public.admission_physical_consent_receipts where admission_id=a.id),signing,coalesce((p_input->>'student_signed')::boolean,false),nullif(btrim(p_input->>'physical_copy_reference'),''),auth.uid(),p_input->>'reason',a.identity_revision) returning * into r;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,after_data)
 values(auth.uid(),'ADMISSION_CONSENT',r.id::text,'RECEIVE_PAPER_FORM',p_input->>'reason',to_jsonb(r));
 return jsonb_build_object('id',r.id);
end $function$;

CREATE OR REPLACE FUNCTION public.require_admission_workflow_evidence()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.status is distinct from old.status
    and new.status in ('BILLING_POSTED','PENDING_PAYMENT','ACTIVE_ENROLLMENT') then
    if not exists(select 1 from public.admission_referrals r where r.admission_id=new.id) then
      raise exception 'Record the admission source before continuing to billing or enrollment.';
    end if;
    if not exists(select 1 from public.admission_physical_consent_receipts p where p.admission_id=new.id and p.identity_revision=new.identity_revision) then
      raise exception 'Record the signed paper consent before continuing to billing or enrollment.';
    end if;
  end if;
  return new;
end
$function$;

CREATE OR REPLACE FUNCTION public.admission_offering_options()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case
    when auth.uid() is null or not public.has_permission('admissions.view')
      then '[]'::jsonb
    else coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',o.id,'name',o.name,'code',o.code,
        'classId',o.class_id,'className',c.name,
        'yearName',ay.name,'branchName',br.name,
        'feeReady',exists(
          select 1 from public.fee_plan_versions f
          where f.offering_id=o.id and f.status='ACTIVE'
            and f.effective_from <= timezone(org.timezone,now())::date
        )
      ) order by ay.starts_on desc,o.name)
      from public.programme_offerings o
      join public.classes c on c.id=o.class_id
      join public.academic_years ay on ay.id=o.academic_year_id
      join public.organizations org on org.id=o.organization_id
      left join public.branches br on br.id=o.branch_id
      where o.status='ACTIVE'
    ),'[]'::jsonb)
  end;
$function$;

CREATE OR REPLACE FUNCTION public.admission_discount_options(p_admission_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare result jsonb;
begin
 if auth.uid() is null or not public.has_permission('admissions.view') then raise exception 'Admission view permission required.'; end if;
 select jsonb_build_object('allowed',o.allowed_discount_percentages,'selected',a.selected_discount_percent,'reason',a.discount_reason)
 into result from public.admission_cases a join public.batches b on b.id=a.batch_id
 join public.programme_offerings o on o.id=b.offering_id where a.id=p_admission_id;
 return result;
end $function$;

CREATE OR REPLACE FUNCTION public.edit_admission_identity(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.admission_cases; identity jsonb:=p_input->'identity'; guardian_id uuid; before_data jsonb;
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission management permission required.'; end if;
 if jsonb_typeof(identity) is distinct from 'object' or octet_length(identity::text)>5000
 or length(btrim(coalesce(p_input->>'reason','')))<5
 or length(btrim(coalesce(identity->>'student_name',''))) not between 2 and 160
 or length(btrim(coalesce(identity->>'guardian_name',''))) not between 2 and 160
 or coalesce(identity->>'mobile','') !~ '^01[3-9][0-9]{8}$'
 or length(btrim(coalesce(identity->>'guardian_address',''))) not between 5 and 300 then raise exception 'Enter verified student, guardian, contact and address details.'; end if;
 select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
 if a.id is null or a.status='CANCELLED' then raise exception 'Choose an open admission case.'; end if;
 if a.existing_student and a.student_id is null then raise exception 'Existing student identity is unavailable.'; end if;
 before_data:=a.identity_snapshot;
 identity:=jsonb_build_object('student_name',btrim(identity->>'student_name'),'student_name_bn',nullif(btrim(identity->>'student_name_bn'),''),
 'guardian_name',btrim(identity->>'guardian_name'),'mobile',identity->>'mobile','alternate_mobile',nullif(identity->>'alternate_mobile',''),
 'guardian_address',btrim(identity->>'guardian_address'),'guardian_relationship',btrim(identity->>'guardian_relationship'),
 'date_of_birth',nullif(identity->>'date_of_birth','')::date,'gender',nullif(identity->>'gender',''),
 'school_name',btrim(identity->>'school_name'),'school_roll',btrim(identity->>'school_roll'));
 if a.student_id is not null then
  if not public.has_permission('students.manage') then raise exception 'Student correction permission required.'; end if;
  update public.students set full_name=identity->>'student_name',school_name_snapshot=identity->>'school_name' where id=a.student_id;
  -- Do not change a shared guardian identity. Link to an existing matching guardian
  -- or create the corrected guardian; keep the old guardian record intact.
  select g.id into guardian_id from public.guardians g join public.students s on s.organization_id=g.organization_id
   where s.id=a.student_id and g.mobile=identity->>'mobile' and lower(g.full_name)=lower(identity->>'guardian_name') order by g.created_at limit 1;
  if guardian_id is null then
   insert into public.guardians(organization_id,full_name,mobile,created_by)
    select organization_id,identity->>'guardian_name',identity->>'mobile',auth.uid() from public.students where id=a.student_id returning id into guardian_id;
  end if;
  update public.student_guardians set is_primary=false where student_id=a.student_id and is_primary;
  insert into public.student_guardians(student_id,guardian_id,relationship_snapshot,is_primary)
  values(a.student_id,guardian_id,identity->>'guardian_relationship',true)
  on conflict(student_id,guardian_id) do update set is_primary=true,relationship_snapshot=excluded.relationship_snapshot;
 end if;
 update public.admission_cases set identity_snapshot=identity_snapshot||identity,
  identity_revision=identity_revision+1,
  status=case when status in('DRAFT','READY') then 'DRAFT' else status end where id=a.id;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),'ADMISSION',a.id::text,'CORRECT_IDENTITY',p_input->>'reason',before_data,identity);
 return jsonb_build_object('id',a.id);
end $function$;

CREATE OR REPLACE FUNCTION public.admission_review_checks(p_admission_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null or not public.has_permission('admissions.view') then raise exception 'Admission view permission required.'; end if;
 return (select jsonb_build_object('hasConsent',exists(select 1 from public.admission_physical_consent_receipts r where r.admission_id=a.id and r.identity_revision=a.identity_revision),'identityRevision',a.identity_revision) from public.admission_cases a where a.id=p_admission_id);
end $function$;

CREATE OR REPLACE FUNCTION public.create_staff_admission_intake(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid := auth.uid();
  req uuid := nullif(p_input->>'request_id','')::uuid;
  reason text := btrim(coalesce(p_input->>'reason',''));
  existing public.staff_admission_intake_requests;
  offering public.programme_offerings;
  batch public.batches;
  fee public.fee_plan_versions;
  organization public.organizations;
  admission public.admission_cases;
  open_seats integer;
  local_today date; extras jsonb;
  student_name text := btrim(coalesce(p_input->>'student_name',''));
  guardian_name text := btrim(coalesce(p_input->>'guardian_name',''));
  mobile text := regexp_replace(coalesce(p_input->>'mobile',''), '\\D', '', 'g');
  alternate_mobile text := nullif(regexp_replace(coalesce(p_input->>'alternate_mobile',''), '\\D', '', 'g'), '');
  birth_date date := nullif(p_input->>'date_of_birth','')::date;
  gender_value text := nullif(btrim(coalesce(p_input->>'gender','')), '');
  school_name text := nullif(btrim(coalesce(p_input->>'school_name','')), '');
  school_roll text := nullif(btrim(coalesce(p_input->>'school_roll','')), '');
  guardian_address text := btrim(coalesce(p_input->>'guardian_address',''));
  guardian_relationship text := nullif(btrim(coalesce(p_input->>'guardian_relationship','')), '');
  intake_note text := nullif(btrim(coalesce(p_input->>'referral_note','')), '');
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if octet_length(p_input::text)>10000 then raise exception 'Application is too long.'; end if;
 if not exists(select 1 from public.organizations where setup_completed_at is not null and is_active) then raise exception 'Complete public setup before starting admissions.'; end if;
  if actor is null or not public.has_permission('admissions.create') then
    raise exception 'Admission permission required.';
  end if;

  if req is null or length(reason) < 5 or length(reason) > 500 then
    raise exception 'Request identity and an audit reason of 5 to 500 characters are required.';
  end if;

  if length(student_name) < 2 or length(student_name) > 160
    or length(guardian_name) < 2 or length(guardian_name) > 160
    or mobile !~ '^01[3-9][0-9]{8}$'
    or length(guardian_address) < 5
    or coalesce((p_input->>'consent_to_contact')::boolean, false) is not true then
    raise exception 'Enter the student, guardian, valid mobile, address, and confirm permission to contact.';
  end if;

  if gender_value is not null
    and gender_value not in ('Female','Male','Other','Prefer not to say') then
    raise exception 'Choose a valid gender option or leave it blank.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(req::text, 0));

  select *
  into existing
  from public.staff_admission_intake_requests
  where request_id = req;

  if found then
    if existing.actor_id <> actor or existing.payload <> p_input then
      raise exception 'Request identity was already used for different intake details.';
    end if;

    select *
    into admission
    from public.admission_cases
    where id = existing.admission_id;

    return jsonb_build_object(
      'admission_id', existing.admission_id,
      'admission_no', admission.admission_no
    );
  end if;

  select *
  into offering
  from public.programme_offerings
  where id = nullif(p_input->>'offering_id','')::uuid
    and status = 'ACTIVE'
  for share;

  if offering.id is null then
    raise exception 'Choose an active programme offering.';
  end if;

  select *
  into batch
  from public.batches
  where id = nullif(p_input->>'batch_id','')::uuid
    and is_active
  for update;

  if batch.id is null or batch.offering_id is distinct from offering.id then
    raise exception 'Choose an active batch belonging to the selected programme offering.';
  end if;

  select *
  into organization
  from public.organizations
  where id = offering.organization_id;

  if organization.id is null then
    raise exception 'The selected programme organization is unavailable.';
  end if;

  local_today := timezone(organization.timezone, now())::date;

  select *
  into fee
  from public.fee_plan_versions
  where offering_id = offering.id
    and status = 'ACTIVE'
    and effective_from <= local_today
  order by effective_from desc, version desc
  limit 1;

  if fee.id is null then
    raise exception 'Publish an effective Fee Plan for this offering before starting admission.';
  end if;

  select count(*)
  into open_seats
  from public.enrollments
  where batch_id = batch.id
    and status = 'ACTIVE';

  if open_seats >= least(
    batch.capacity,
    coalesce(
      (
        select (payload->>'max_students')::integer
        from public.business_rule_versions
        where domain = 'academics'
          and rule_key = 'batch_capacity_policy'
          and status = 'ACTIVE'
        order by version desc
        limit 1
      ),
      batch.capacity
    )
  ) then
    raise exception 'The selected batch is full. Choose another available batch.';
  end if;

  if exists (
    select 1
    from public.admission_cases a
    where a.origin = 'DIRECT_STAFF'
      and lower(a.identity_snapshot->>'student_name') = lower(student_name)
      and regexp_replace(a.identity_snapshot->>'mobile', '\\D', '', 'g') = mobile
      and a.status <> 'CANCELLED'
  ) then
    raise exception 'A matching direct admission draft already exists. Open Admissions and continue that case.';
  end if;

  insert into public.admission_cases (
    prospect_id,
    origin,
    origin_prospect_id,
    batch_id,
    fee_plan_version_id,
    existing_student,
    identity_snapshot,
    created_by
  )
  values (
    null,
    'DIRECT_STAFF',
    null,
    batch.id,
    fee.id,
    false,
    jsonb_build_object(
      'student_name', student_name,
      'student_name_bn', nullif(btrim(coalesce(p_input->>'student_name_bn','')), ''),
      'date_of_birth', birth_date,
      'gender', gender_value,
      'school_name', school_name,
      'school_roll', school_roll,
      'guardian_name', guardian_name,
      'guardian_relationship', guardian_relationship,
      'mobile', mobile,
      'alternate_mobile', alternate_mobile,
      'guardian_address', guardian_address,
      'intake_note', intake_note,
      'consent_to_contact', true
    ),
    actor
  )
  returning *
  into admission;

  insert into public.audit_events(
    correlation_id,
    actor_profile_id,
    actor_staff_id,
    entity_type,
    entity_id,
    action,
    reason,
    before_data,
    after_data,
    metadata
  )
  values (
    req,
    actor,
    (select s.id from public.staff s where s.profile_id = actor limit 1),
    'ADMISSION',
    admission.id::text,
    'CREATE_DIRECT_STAFF_ADMISSION',
    reason,
    null,
    to_jsonb(admission),
    jsonb_build_object(
      'origin', 'DIRECT_STAFF',
      'offering_id', offering.id,
      'batch_id', batch.id
    )
  );

  insert into public.staff_admission_intake_requests(
    request_id,
    actor_id,
    payload,
    prospect_id,
    admission_id
  )
  values (
    req,
    actor,
    p_input,
    null,
    admission.id
  );

  extras:=jsonb_build_object('father_name',left(p_input->>'father_name',160),'mother_name',left(p_input->>'mother_name',160),
 'birth_registration',left(p_input->>'birth_registration',40),'permanent_address',left(p_input->>'permanent_address',300),
 'emergency_contact',left(p_input->>'emergency_contact',160),'emergency_mobile',left(p_input->>'emergency_mobile',30),
 'previous_result',left(p_input->>'previous_result',200),'learning_needs',left(p_input->>'learning_needs',500));
 update public.admission_cases set identity_snapshot=identity_snapshot||jsonb_strip_nulls(extras)
 where id=admission.id;

  return jsonb_build_object(
    'admission_id', admission.id,
    'admission_no', admission.admission_no
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.admission_directory_options()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null then raise exception 'Sign in required.'; end if;
 if not public.has_permission('admissions.view') then return jsonb_build_object('schools','[]'::jsonb,'relationships','[]'::jsonb); end if;
 return jsonb_build_object('schools',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.schools where is_active),'[]'::jsonb),
 'relationships',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.guardian_relationships where is_active),'[]'::jsonb));
end $function$;

CREATE OR REPLACE FUNCTION public.save_admission_extra_charge(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.admission_cases; req uuid:=(p_input->>'request_id')::uuid; k public.admission_command_keys;
 charge jsonb; result jsonb; amount numeric:=(p_input->>'amount')::numeric;
begin
 if auth.uid() is null or not public.has_permission('admissions.create') or not public.has_permission('finance.billing.manage') then raise exception 'Admission and billing permissions required.'; end if;
 if req is null then raise exception 'Request identity required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into k from public.admission_command_keys where request_id=req;
 if found then if k.actor_id<>auth.uid() or k.payload<>p_input then raise exception 'Request identity already used.'; end if; return k.result; end if;
 select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
 if a.id is null or a.status not in('DRAFT','READY') then raise exception 'Additional charges must be agreed before final submission.'; end if;
 if length(btrim(coalesce(p_input->>'name',''))) not between 2 and 100 or amount is null or amount<=0 or amount<>round(amount,2) or amount>99999999
 or coalesce(p_input->>'charge_type','') not in('ADMISSION','EXAM','MATERIAL','OTHER') then raise exception 'Enter a valid one-time fee and amount.'; end if;
 if jsonb_array_length(a.additional_charges)>=10 then raise exception 'No more than ten additional charges per admission.'; end if;
 charge:=jsonb_build_object('id',req,'name',btrim(p_input->>'name'),'charge_type',p_input->>'charge_type','amount',amount,'is_active',true);
 update public.admission_cases set additional_charges=additional_charges||jsonb_build_array(charge) where id=a.id;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(req,auth.uid(),'ADMISSION',a.id::text,'ADD_ONE_TIME_CHARGE','One-time charge agreed with guardian before final submission',a.additional_charges,charge);
 result:=jsonb_build_object('id',a.id);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,auth.uid(),p_input,result);
 return result;
end $function$;

CREATE OR REPLACE FUNCTION public.deactivate_admission_extra_charge(p_admission_id uuid, p_charge_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.admission_cases; charges jsonb;
begin
 if auth.uid() is null or not public.has_permission('admissions.create') or not public.has_permission('finance.billing.manage') then raise exception 'Admission and billing permissions required.'; end if;
 select * into a from public.admission_cases where id=p_admission_id for update;
 if a.id is null or a.status not in('DRAFT','READY') then raise exception 'Posted charges require a recorded financial correction.'; end if;
 select coalesce(jsonb_agg(case when value->>'id'=p_charge_id::text then value||'{"is_active":false}'::jsonb else value end order by ord),'[]') into charges from jsonb_array_elements(a.additional_charges) with ordinality items(value,ord);
 update public.admission_cases set additional_charges=charges where id=a.id;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),'ADMISSION',a.id::text,'DEACTIVATE_DRAFT_CHARGE','Corrected draft charges before submission',a.additional_charges,charges);
end $function$;

CREATE OR REPLACE FUNCTION public.admission_case_detail(p_admission_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  result jsonb; charges jsonb; extras jsonb;
begin
  if auth.uid() is null or not public.has_permission('admissions.view') then
    raise exception 'Admission workspace access denied.';
  end if;

  select jsonb_build_object(
    'id', a.id,
    'number', a.admission_no,
    'status', a.status,
    'createdAt', a.created_at,
    'existingStudent', a.existing_student,
    'origin', a.origin,
    'originProspectId', a.origin_prospect_id,
    'batchId', a.batch_id,
    'batchName', b.name,
    'batchCode', b.code,
    'batchCapacity', b.capacity,
    'batchOccupied', (
      select count(*)
      from public.enrollments e
      where e.batch_id = b.id
        and e.status = 'ACTIVE'
    ),
    'offeringId', o.id,
    'offeringName', o.name,
    'className', cl.name,
    'yearName', ay.name,
    'branchName', br.name,
    'studentNo', s.student_no,
    'studentId', s.id,
    'name', a.identity_snapshot->>'student_name',
    'nameBn', a.identity_snapshot->>'student_name_bn',
    'gender', a.identity_snapshot->>'gender',
    'dateOfBirth', a.identity_snapshot->>'date_of_birth',
    'schoolName', a.identity_snapshot->>'school_name',
    'schoolRoll', a.identity_snapshot->>'school_roll',
    'guardianAddress', a.identity_snapshot->>'guardian_address',
    'alternateMobile', a.identity_snapshot->>'alternate_mobile',
    'guardianRelationship', a.identity_snapshot->>'guardian_relationship',
    'guardian', a.identity_snapshot->>'guardian_name',
    'mobile', a.identity_snapshot->>'mobile',
    'feeVersion', f.version,
    'feePlanId', f.id,
    'policyVersion', r.version,
    'paymentRequirement', r.payload->>'payment_requirement',
    'components', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'name', fc.name,
          'amount', fc.amount,
          'recurrence', fc.recurrence
        )
        order by fc.sort_order, fc.id
      )
      from public.fee_plan_components fc
      where fc.fee_plan_version_id = f.id
    ), '[]'::jsonb),
    'invoice', case
      when i.id is null then null
      else jsonb_build_object(
        'number', i.invoice_no,
        'total', i.total,
        'dueOn', i.due_on,
        'paid', bal.paid,
        'credits', bal.credits,
        'net', bal.net,
        'refunded', bal.refunded,
        'due', bal.due,
        'credit', bal.credit_balance
      )
    end,
    'receipts', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'number', p.receipt_no,
          'amount', pa.amount,
          'postedAt', p.posted_at,
          'method', pm.name,
          'refunded', coalesce((
            select sum(ra.amount)
            from public.refund_authorizations ra
            join public.refund_payouts rp
              on rp.authorization_id = ra.id
            where ra.payment_id = p.id
          ), 0)
        )
        order by p.posted_at, p.receipt_no
      )
      from public.admission_payment_allocations pa
      join public.admission_payments p
        on p.id = pa.payment_id
      join public.payment_methods pm
        on pm.id = p.payment_method_id
      where pa.invoice_id = i.id
    ), '[]'::jsonb)
  )
  into result
  from public.admission_cases a
  join public.fee_plan_versions f
    on f.id = a.fee_plan_version_id
  join public.batches b
    on b.id = a.batch_id
  join public.programme_offerings o
    on o.id = b.offering_id
  join public.classes cl
    on cl.id = b.class_id
  join public.academic_years ay
    on ay.id = b.academic_year_id
  left join public.branches br
    on br.id = b.branch_id
  left join public.students s
    on s.id = a.student_id
  left join public.business_rule_versions r
    on r.id = a.activation_policy_version_id
  left join public.admission_invoices i
    on i.admission_id = a.id
   and i.invoice_kind = 'INITIAL'
  left join lateral public.invoice_balance(i.id) bal
    on true
  where a.id = p_admission_id;

  if result is null then
    raise exception 'Admission Case not found.';
  end if;

  result:=result||(select jsonb_build_object('academyRoll',s.academy_roll::text,'discountPercent',a.selected_discount_percent,'discountReason',a.discount_reason,'additionalDetails',
 jsonb_build_object('father_name',a.identity_snapshot->>'father_name','mother_name',a.identity_snapshot->>'mother_name',
 'birth_registration',a.identity_snapshot->>'birth_registration','permanent_address',a.identity_snapshot->>'permanent_address',
 'emergency_contact',a.identity_snapshot->>'emergency_contact','emergency_mobile',a.identity_snapshot->>'emergency_mobile',
 'previous_result',a.identity_snapshot->>'previous_result','learning_needs',a.identity_snapshot->>'learning_needs'))
 from public.admission_cases a left join public.students s on s.id=a.student_id where a.id=p_admission_id);

 select additional_charges into charges from public.admission_cases where id=p_admission_id;
 select coalesce(jsonb_agg(jsonb_build_object('name',value->>'name','amount',(value->>'amount')::numeric,'recurrence','ONE_TIME')),'[]') into extras from jsonb_array_elements(charges) where (value->>'is_active')::boolean;
 return result||jsonb_build_object('tuitionTotal',(select coalesce(sum(c.amount),0) from public.fee_plan_components c join public.admission_cases a on a.fee_plan_version_id=c.fee_plan_version_id where a.id=p_admission_id and c.charge_type='TUITION'),'additionalCharges',charges,'components',(result->'components')||extras);
end;
$function$;

CREATE OR REPLACE FUNCTION public.correct_admission_placement(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.admission_cases; b public.batches; f public.fee_plan_versions; today date;
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if length(btrim(coalesce(p_input->>'reason',''))) not between 5 and 500 then raise exception 'Correction reason required.'; end if;
 select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
 if a.id is null or a.status not in('DRAFT','READY') then raise exception 'Only an unconfirmed draft can change placement. Use enrollment transfer after admission.'; end if;
 select * into b from public.batches where id=(p_input->>'batch_id')::uuid and is_active for update;
 if b.id is null or b.offering_id is distinct from (p_input->>'offering_id')::uuid or not exists(select 1 from public.programme_offerings where id=b.offering_id and status='ACTIVE') then raise exception 'Choose an active offering and its batch.'; end if;
 if b.organization_id is distinct from (select organization_id from public.batches where id=a.batch_id) then raise exception 'Placement must remain in the same public.'; end if;
 if (select count(*) from public.enrollments where batch_id=b.id and status='ACTIVE')>=b.capacity then raise exception 'Selected batch is full.'; end if;
 select timezone(timezone,now())::date into today from public.organizations where id=b.organization_id;
 select * into f from public.fee_plan_versions where offering_id=b.offering_id and status='ACTIVE' and effective_from<=today order by effective_from desc,version desc limit 1;
 if f.id is null then raise exception 'Save an effective Fee Plan for this offering first.'; end if;
 if a.batch_id=b.id and a.fee_plan_version_id=f.id then return jsonb_build_object('id',a.id); end if;
 update public.admission_cases set batch_id=b.id,fee_plan_version_id=f.id,status='DRAFT',identity_revision=identity_revision+1,
 selected_discount_percent=0,discount_reason=null,
 additional_charges=coalesce((select jsonb_agg(x||jsonb_build_object('is_active',false)) from jsonb_array_elements(a.additional_charges) x),'[]'::jsonb)
 where id=a.id;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),'ADMISSION',a.id::text,'CORRECT_PLACEMENT',p_input->>'reason',to_jsonb(a),jsonb_build_object('batch_id',b.id,'fee_plan_id',f.id));
 return jsonb_build_object('id',a.id);
end $function$;

CREATE OR REPLACE FUNCTION public.admission_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
<<command>>
declare previous_trace text:=current_setting('sohoj.workflow_trace',true); a public.admission_cases; o public.programme_offerings; req uuid:=nullif(p_input->>'request_id','')::uuid;
 k public.admission_command_keys; result jsonb; pct integer; today date; end_date date;
begin
 if nullif(previous_trace,'') is null then perform set_config('sohoj.workflow_trace',coalesce(p_input->>'request_id',gen_random_uuid()::text),true); end if;
 if p_input->>'action' in('CREATE','READY','ACCEPT','BILL','FINALIZE') and not exists(select 1 from public.organizations where is_active and setup_completed_at is not null) then raise exception 'Complete public setup before processing admissions.'; end if;
 if p_input->>'action' in('ACCEPT','BILL') and not public.has_permission('finance.billing.manage') then raise exception 'Billing management permission required.'; end if;
 if p_input->>'action'='ACCEPT' and not (public.admission_review_checks((p_input->>'admission_id')::uuid)->>'hasConsent')::boolean then raise exception 'Receive signed consent for the current details.'; end if;
 if p_input->>'action' not in('SAVE_DISCOUNT','FINALIZE','RETURN_TO_DRAFT') then
  result:=public.execute_admission_stage(p_input);
  perform set_config('sohoj.workflow_trace',coalesce(previous_trace,''),true);
  return result;
 end if;
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if req is null or length(btrim(coalesce(p_input->>'reason','')))<5 then raise exception 'A request identity and note are required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into k from public.admission_command_keys where request_id=req;
 if found then
  if k.actor_id<>auth.uid() or k.payload<>p_input then raise exception 'Request identity already used.'; end if;
  return k.result;
 end if;
 select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
 if a.id is null or a.status not in('DRAFT','READY') then raise exception 'Only an unsubmitted draft can be changed or finalized.'; end if;
 select off.* into o from public.batches b join public.programme_offerings off on off.id=b.offering_id where b.id=a.batch_id for share of off;
 if p_input->>'action'='SAVE_DISCOUNT' then
  if not public.has_permission('finance.billing.manage') then raise exception 'Billing management permission required.'; end if;
  pct:=coalesce((p_input->>'discount_percent')::integer,0);
  if pct<>0 and not pct=any(o.allowed_discount_percentages) then raise exception 'This discount is not allowed for the offering.'; end if;
  if pct<>0 and coalesce(p_input->>'discount_reason','') not in('FINANCIAL_HARDSHIP','SIBLING','MERIT','LAUNCH_OFFER','STAFF_FAMILY','OTHER') then raise exception 'Select a discount reason.'; end if;
  update public.admission_cases set selected_discount_percent=pct,
   discount_reason=case when pct=0 then null else p_input->>'discount_reason' end where id=a.id;
 elsif p_input->>'action'='RETURN_TO_DRAFT' then
  update public.admission_cases set status='DRAFT' where id=a.id;
 else
  if a.status<>'READY' then raise exception 'Review and verify the draft before final submission.'; end if;
  if not public.has_permission('finance.billing.manage') then raise exception 'Admission final submission requires billing permission.'; end if;
  if a.selected_discount_percent<>0 and not a.selected_discount_percent=any(o.allowed_discount_percentages) then raise exception 'The discount policy changed. Review the chosen discount.'; end if;
  if not exists(select 1 from public.admission_physical_consent_receipts r where r.admission_id=a.id and r.identity_revision=a.identity_revision) then raise exception 'Record signed paper consent for the current details before final submission.'; end if;
  -- Accept and invoice atomically. Failure rolls back student issuance as well.
  result:=public.execute_admission_stage(jsonb_build_object('action','ACCEPT','request_id',gen_random_uuid(),
   'admission_id',a.id,'reason',p_input->>'reason'));
  if a.selected_discount_percent>0 then
   select timezone(org.timezone,now())::date into today from public.organizations org where org.id=o.organization_id;
   select greatest(ends_on,today) into end_date from public.academic_years where id=o.academic_year_id;
   perform public.finance_command(jsonb_build_object('action','APPLY_DISCOUNT','request_id',gen_random_uuid(),
    'admission_id',a.id,'kind','PERCENT','value',a.selected_discount_percent,
    'starts_on',date_trunc('month',today)::date,'ends_on',end_date,
    'reason','Admission discount: '||a.discount_reason));
  end if;
  result:=public.execute_admission_stage(jsonb_build_object('action','BILL','request_id',gen_random_uuid(),
   'admission_id',a.id,'reason','Initial invoice posted with final admission submission'));
 end if;
 select jsonb_build_object('id',id,'status',status) into result from public.admission_cases where id=a.id;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(req,auth.uid(),'ADMISSION',a.id::text,p_input->>'action',p_input->>'reason',to_jsonb(a),result);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,auth.uid(),p_input,result);
 perform set_config('sohoj.workflow_trace',coalesce(previous_trace,''),true);
 return result;
end
$function$;

CREATE OR REPLACE FUNCTION public.close_student_enrollment(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare e public.enrollments; today date; mode text:=p_input->>'mode'; before_data jsonb;
begin
 if auth.uid() is null or not public.has_permission('students.manage') then raise exception 'Student management permission required.'; end if;
 if mode not in('WITHDRAWN','COMPLETED') or mode is null or length(btrim(coalesce(p_input->>'reason',''))) not between 5 and 500 then raise exception 'Choose withdrawal or completion and record the reason.'; end if;
 -- Match admission command lock order to keep financial and enrollment mutations consistent.
 perform 1 from public.admission_cases where enrollment_id=(p_input->>'enrollment_id')::uuid for update;
 select * into e from public.enrollments where id=(p_input->>'enrollment_id')::uuid and student_id=(p_input->>'student_id')::uuid for update;
 if e.id is null then raise exception 'Enrollment not found for this student.'; end if;
 if e.status<>'ACTIVE' then return jsonb_build_object('id',e.id,'message','Enrollment is already closed.'); end if;
 select timezone(timezone,now())::date into today from public.organizations where id=e.organization_id;
 if today<e.admission_date then raise exception 'Enrollment start is in the future. Cancel the admission instead.'; end if;
 before_data:=to_jsonb(e);
 update public.enrollments set status=mode::public.enrollment_status,ended_on=today where id=e.id;
 update public.admission_cases set status='CLOSED_ENROLLMENT' where enrollment_id=e.id and status='ACTIVE_ENROLLMENT';
 if not exists(select 1 from public.enrollments where student_id=e.student_id and status='ACTIVE') then update public.students set status='INACTIVE' where id=e.student_id; end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),'ENROLLMENT',e.id::text,mode,p_input->>'reason',before_data,jsonb_build_object('status',mode,'ended_on',today,'student_id',e.student_id));
 return jsonb_build_object('id',e.id,'message','Enrollment closed. Future recurring billing stops; existing invoices, payments and due balances remain.');
end $function$;

CREATE OR REPLACE FUNCTION public.create_prospect_admission(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare chosen uuid; changed uuid; p public.prospects; o public.programme_offerings; k public.admission_command_keys;
 req uuid:=nullif(p_input->>'request_id','')::uuid; result jsonb;
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if req is null or p_input->>'action' is distinct from 'CREATE' or length(btrim(coalesce(p_input->>'reason','')))<5 then
  raise exception 'A valid request and verification note are required.';
 end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into k from public.admission_command_keys where request_id=req;
 if found then
  if k.actor_id<>auth.uid() or k.payload<>p_input then raise exception 'Request identity already used.'; end if;
  return k.result;
 end if;
 select * into p from public.prospects where id=(p_input->>'prospect_id')::uuid for update;
 select * into o from public.programme_offerings where id=(p_input->>'offering_id')::uuid and status='ACTIVE';
 if p.id is null or p.status in('CONVERTED','LOST') or o.id is null or p.organization_id<>o.organization_id
 or not exists(select 1 from public.batches where id=(p_input->>'batch_id')::uuid and offering_id=o.id and is_active) then
  raise exception 'Choose an open enquiry, active offering and its batch.';
 end if;
 if (p.current_class_id is not null and p.current_class_id<>o.class_id)
   or (p.interested_offering_id is not null and p.interested_offering_id<>o.id) then
  if coalesce((p_input->>'confirm_placement_correction')::boolean,false) is not true then
   raise exception 'Confirm the corrected placement.';
  end if;
 end if;
 update public.prospects set current_class_id=o.class_id,interested_offering_id=o.id,
  application_verified_at=now(),application_verified_by=auth.uid() where id=p.id;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(req,auth.uid(),'PROSPECT',p.id::text,'VERIFY_ADMISSION_PLACEMENT',p_input->>'reason',to_jsonb(p),
   jsonb_build_object('class_id',o.class_id,'offering_id',o.id));
 if not exists(select 1 from public.organizations where id=o.organization_id and setup_completed_at is not null and is_active) then raise exception 'Complete public setup before starting admissions.'; end if;
 result:=public.admission_command(p_input);
 update public.admission_cases set identity_snapshot=identity_snapshot||jsonb_strip_nulls(jsonb_build_object(
 'guardian_address',coalesce(p.guardian_address,p.application_snapshot->>'guardian_address'),
 'alternate_mobile',p.alternate_mobile,'student_name_bn',p.student_name_bn,
 'date_of_birth',coalesce(p.date_of_birth::text,p.application_snapshot->>'date_of_birth'),
 'gender',coalesce(p.gender,p.application_snapshot->>'gender'),
 'school_roll',coalesce(p.school_roll,p.application_snapshot->>'school_roll'),
 'father_name',p.application_snapshot->>'father_name','mother_name',p.application_snapshot->>'mother_name',
 'emergency_contact',p.application_snapshot->>'emergency_contact','emergency_mobile',p.application_snapshot->>'emergency_mobile',
 'learning_needs',p.application_snapshot->>'learning_needs'))
 where id=(result->>'id')::uuid;

 select id into chosen from public.staff where profile_id=auth.uid() and status in('ACTIVE','ON_LEAVE');
 if chosen is not null then
 update public.prospects set assigned_to_staff_id=chosen where id=(p_input->>'prospect_id')::uuid and assigned_to_staff_id is null returning id into changed;
 if changed is not null then
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,after_data)
 values((p_input->>'request_id')::uuid,auth.uid(),'PROSPECT',changed::text,'ASSIGN_FOLLOWUP_STAFF','Staff handled verified admission conversion',jsonb_build_object('staff_id',chosen));
 end if; end if;

 return result;
end
$function$;

CREATE OR REPLACE FUNCTION public.execute_admission_stage(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 v_actor uuid:=auth.uid(); v_action text:=p_input->>'action';
 v_request uuid:=(p_input->>'request_id')::uuid; v_key public.admission_command_keys;
 v_reason text:=btrim(coalesce(p_input->>'reason','')); v_case public.admission_cases;
 v_before jsonb; v_result jsonb; v_batch public.batches; v_offering public.programme_offerings;
 v_prospect public.prospects; v_fee public.fee_plan_versions;
 v_policy public.business_rule_versions; v_capacity public.business_rule_versions;
 v_guardian uuid; v_student uuid; v_enrollment uuid; v_invoice uuid;
 v_today date; v_total numeric; v_occupied integer;
begin
 if v_actor is null then raise exception 'Sign in to continue.'; end if;
 if v_action='CREATE_BATCH' then
   if not public.has_permission('academics.manage') then raise exception 'Batch management permission required.'; end if;
 elsif not public.has_permission('admissions.create') then raise exception 'Admission permission required.';
 end if;
 if v_request is null or length(v_reason)<5 then raise exception 'Request identity and a reason of at least five characters are required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(v_request::text,0));
 select * into v_key from public.admission_command_keys where request_id=v_request;
 if found then
   if v_key.actor_id<>v_actor or v_key.payload<>p_input then raise exception 'Request identity was already used for different input.'; end if;
   return v_key.result;
 end if;
 if v_action='CREATE_BATCH' then
   select * into v_offering from public.programme_offerings where id=(p_input->>'offering_id')::uuid and status='ACTIVE' for update;
   if not found then raise exception 'Choose an active offering with a published Fee Plan.'; end if;
   select * into v_capacity from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE';
   if v_capacity.id is null then raise exception 'Capacity policy is missing.'; end if;
   if coalesce((p_input->>'capacity')::integer,0)<1
      or (p_input->>'capacity')::integer>(v_capacity.payload->>'max_students')::integer then
     raise exception 'Batch capacity must be between 1 and the active policy maximum (%).',v_capacity.payload->>'max_students';
   end if;
   if length(btrim(coalesce(p_input->>'name','')))<2 or length(btrim(coalesce(p_input->>'code','')))<2 then raise exception 'Batch name and code are required.'; end if;
   insert into public.batches(organization_id,branch_id,academic_year_id,class_id,program_id,code,name,capacity,created_by,offering_id,capacity_policy_version_id)
   values(v_offering.organization_id,v_offering.branch_id,v_offering.academic_year_id,v_offering.class_id,v_offering.program_id,
     upper(btrim(p_input->>'code')),btrim(p_input->>'name'),(p_input->>'capacity')::integer,v_actor,v_offering.id,v_capacity.id) returning * into v_batch;
   v_result:=jsonb_build_object('id',v_batch.id,'status','CREATED');
 elsif v_action='CREATE' then
   select * into v_prospect from public.prospects where id=(p_input->>'prospect_id')::uuid for update;
   if v_prospect.id is null or v_prospect.status in ('CONVERTED','LOST') then raise exception 'Choose an unconverted, open Prospect.'; end if;
   if exists(select 1 from public.admission_cases where prospect_id=v_prospect.id and status<>'CANCELLED') then raise exception 'This Prospect already has an Admission Case. Open the existing case.'; end if;
   select * into v_batch from public.batches where id=(p_input->>'batch_id')::uuid and is_active for update;
   select * into v_offering from public.programme_offerings where id=v_batch.offering_id and status='ACTIVE';
   if v_offering.id is null or v_prospect.organization_id<>v_offering.organization_id
     or v_batch.offering_id is distinct from nullif(p_input->>'offering_id','')::uuid
     or (v_prospect.current_class_id is not null and v_prospect.current_class_id is distinct from v_offering.class_id)
     or (v_prospect.current_class_id is null and v_prospect.interested_offering_id is not null
         and v_prospect.interested_offering_id is distinct from v_offering.id) then
     raise exception 'Choose an active offering and a batch that match this Prospect.';
   end if;
   if v_prospect.current_class_id is null then
     update public.prospects set current_class_id=v_offering.class_id where id=v_prospect.id;
     v_prospect.current_class_id:=v_offering.class_id;
     insert into public.audit_events(correlation_id,actor_profile_id,actor_staff_id,
       entity_type,entity_id,action,reason,before_data,after_data,metadata)
     values(v_request,v_actor,(select id from public.staff where profile_id=v_actor limit 1),
       'PROSPECT',v_prospect.id::text,'ASSIGN_CLASS_FROM_OFFERING',v_reason,
       jsonb_build_object('current_class_id',null,'interested_offering_id',v_prospect.interested_offering_id),
       jsonb_build_object('current_class_id',v_offering.class_id,'interested_offering_id',v_prospect.interested_offering_id),
       jsonb_build_object('offering_id',v_offering.id,'batch_id',v_batch.id));
   end if;
   if (select count(*) from public.enrollments where batch_id=v_batch.id and status='ACTIVE')>=v_batch.capacity then raise exception 'Selected batch is full.'; end if;
   select (now() at time zone timezone)::date into v_today from public.organizations where id=v_offering.organization_id;
   select * into v_fee from public.fee_plan_versions where offering_id=v_offering.id and status='ACTIVE' and effective_from<=v_today;
   if v_fee.id is null then raise exception 'No effective published Fee Plan is available.'; end if;
   insert into public.admission_cases(prospect_id,batch_id,fee_plan_version_id,identity_snapshot,created_by)
   values(v_prospect.id,v_batch.id,v_fee.id,jsonb_build_object('student_name',v_prospect.student_name,'guardian_name',v_prospect.guardian_name,
     'mobile',v_prospect.mobile,'guardian_relationship',coalesce(v_prospect.guardian_relationship_snapshot,'Guardian'),
     'school_id',v_prospect.school_id,'school_name',v_prospect.school_name_snapshot,
     'student_name_bn',v_prospect.student_name_bn,'gender',v_prospect.gender,
     'date_of_birth',v_prospect.date_of_birth,'school_roll',v_prospect.school_roll,
     'alternate_mobile',v_prospect.alternate_mobile,
     'guardian_address',coalesce(v_prospect.guardian_address,
       v_prospect.application_snapshot->>'guardian_address'),
     'guardian_relationship',coalesce(v_prospect.guardian_relationship_snapshot,'Guardian')),v_actor) returning * into v_case;
   v_result:=jsonb_build_object('id',v_case.id,'status',v_case.status);
 else
   select * into v_case from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
   if not found then raise exception 'Admission Case not found.'; end if;
   v_before:=to_jsonb(v_case);
   if v_case.student_id is not null then
     perform 1 from public.students where id=v_case.student_id for update;
     if exists(select 1 from public.students where id=v_case.student_id and (merged_into_id is not null or status='ARCHIVED')) then raise exception 'Use the canonical, non-archived Student identity.';end if;
   end if;
   select * into v_batch from public.batches where id=v_case.batch_id and is_active for update;
   if v_batch.id is null then raise exception 'Batch is no longer active.'; end if;
   select * into v_fee from public.fee_plan_versions where id=v_case.fee_plan_version_id for share;
   select (now() at time zone timezone)::date into v_today from public.organizations where id=v_batch.organization_id;
   if v_action='EDIT_DRAFT' and v_case.status in ('DRAFT','READY') then
     if v_case.existing_student then raise exception 'Existing Student identity is read-only in enrollment drafts.';end if;
     if length(btrim(coalesce(p_input->>'student_name','')))<2 or length(btrim(coalesce(p_input->>'guardian_name','')))<2
       or coalesce(p_input->>'mobile','') !~ '^01[3-9][0-9]{8}$' then raise exception 'Valid student, guardian and Bangladesh mobile details are required.'; end if;
     update public.admission_cases set identity_snapshot=identity_snapshot||jsonb_build_object('student_name',btrim(p_input->>'student_name'),'guardian_name',btrim(p_input->>'guardian_name'),'mobile',p_input->>'mobile'),status='DRAFT' where id=v_case.id;
   elsif v_action='READY' and v_case.status='DRAFT' then
     if length(btrim(coalesce(v_case.identity_snapshot->>'student_name','')))<2 or length(btrim(coalesce(v_case.identity_snapshot->>'guardian_name','')))<2
       or coalesce(v_case.identity_snapshot->>'mobile','') !~ '^01[3-9][0-9]{8}$' then raise exception 'Valid student, guardian and Bangladesh mobile details are required. Correct the Prospect before starting admission.'; end if;
     if v_fee.status<>'ACTIVE' then raise exception 'The selected Fee Plan has changed. Refresh fees before review.'; end if;
     update public.admission_cases set status='READY' where id=v_case.id;
   elsif v_action='REFRESH_FEES' and v_case.status in ('DRAFT','READY') then
     select * into v_fee from public.fee_plan_versions where offering_id=v_batch.offering_id and status='ACTIVE' and effective_from<=v_today;
     if v_fee.id is null then raise exception 'No active Fee Plan.'; end if;
     update public.admission_cases set fee_plan_version_id=v_fee.id,status='DRAFT' where id=v_case.id;
   elsif v_action='ACCEPT' and v_case.status='READY' then
     select * into v_prospect from public.prospects where id=v_case.prospect_id for update;
     if not v_case.existing_student and v_prospect.status in ('CONVERTED','LOST') then raise exception 'Prospect is no longer eligible for admission.'; end if;
     if v_fee.status<>'ACTIVE' then raise exception 'Fee Plan changed. Refresh and review before acceptance.'; end if;

      if v_case.consent_required
        and not exists (select 1 from public.admission_physical_consent_receipts r where r.admission_id = v_case.id and r.identity_revision=v_case.identity_revision)
      then
        raise exception 'A recorded signed consent receipt is required before acceptance.';
      end if;
     select * into v_policy from public.business_rule_versions where domain='admissions' and rule_key='activation_policy' and status='ACTIVE';
     if v_policy.id is null or not public.validate_business_rule_payload('admissions','activation_policy',v_policy.payload) then raise exception 'A valid activation policy is required.'; end if;
     if v_case.existing_student then
       if exists(select 1 from public.enrollments where student_id=v_case.student_id and academic_year_id=v_batch.academic_year_id and status='ACTIVE') then raise exception 'Student already has an active enrollment in this academic year.';end if;
       update public.admission_cases set activation_policy_version_id=v_policy.id,status='ACCEPTED' where id=v_case.id;
     else
     perform pg_advisory_xact_lock(hashtextextended(v_case.identity_snapshot->>'mobile',1));
     if exists(select 1 from public.students s join public.student_guardians sg on sg.student_id=s.id join public.guardians g on g.id=sg.guardian_id
       where s.organization_id=v_batch.organization_id and lower(s.full_name)=lower(v_case.identity_snapshot->>'student_name') and g.mobile=v_case.identity_snapshot->>'mobile') then
       raise exception 'Possible existing student with this name and guardian mobile. Review the existing identity before continuing.';
     end if;
     select id into v_guardian from public.guardians where organization_id=v_batch.organization_id and mobile=v_case.identity_snapshot->>'mobile'
       and lower(full_name)=lower(v_case.identity_snapshot->>'guardian_name') order by created_at limit 1;
     if v_guardian is null then
       insert into public.guardians(organization_id,full_name,mobile,created_by) values(v_batch.organization_id,v_case.identity_snapshot->>'guardian_name',v_case.identity_snapshot->>'mobile',v_actor) returning id into v_guardian;
     end if;
     insert into public.students(organization_id,branch_id,full_name,school_id,school_name_snapshot,status,created_from_prospect_id,created_by)
     values(v_batch.organization_id,v_batch.branch_id,v_case.identity_snapshot->>'student_name',(v_case.identity_snapshot->>'school_id')::uuid,
       v_case.identity_snapshot->>'school_name','INACTIVE',v_case.prospect_id,v_actor) returning id into v_student;
     insert into public.student_guardians(student_id,guardian_id,relationship_snapshot,is_primary) values(v_student,v_guardian,v_case.identity_snapshot->>'guardian_relationship',true);
     update public.admission_cases set student_id=v_student,activation_policy_version_id=v_policy.id,status='ACCEPTED' where id=v_case.id;
     update public.prospects set status='CONVERTED',converted_student_id=v_student,converted_at=now() where id=v_case.prospect_id;
     end if;
   elsif v_action='BILL' and v_case.status='ACCEPTED' then
     select coalesce(sum(amount),0) into v_total from public.fee_plan_components where fee_plan_version_id=v_fee.id;
     v_total:=v_total+coalesce((select sum((value->>'amount')::numeric) from jsonb_array_elements(v_case.additional_charges) where (value->>'is_active')::boolean),0);
     if not exists(select 1 from public.fee_plan_components where fee_plan_version_id=v_fee.id) then raise exception 'Fee Plan has no charge components.'; end if;
     insert into public.admission_invoices(admission_id,student_id,fee_plan_version_id,currency_code,total,issued_on,due_on,posted_by,billing_period)
     values(v_case.id,v_case.student_id,v_fee.id,v_fee.currency_code,v_total,v_today,
       case when v_fee.due_day is not null then greatest(v_today,date_trunc('month',v_today)::date+v_fee.due_day-1) else v_today end,v_actor,date_trunc('month',v_today)::date) returning id into v_invoice;
     insert into public.admission_invoice_lines(invoice_id,fee_component_id,name,charge_type,amount)
     select v_invoice,id,name,charge_type,amount from public.fee_plan_components where fee_plan_version_id=v_fee.id
     union all select v_invoice,null,value->>'name',value->>'charge_type',(value->>'amount')::numeric from jsonb_array_elements(v_case.additional_charges) where (value->>'is_active')::boolean;
     perform public.apply_invoice_discounts(v_invoice);
     update public.admission_cases set status='BILLING_POSTED' where id=v_case.id;
   elsif v_action='ACTIVATE' and v_case.status in ('BILLING_POSTED','PENDING_PAYMENT') then
     select * into v_policy from public.business_rule_versions where id=v_case.activation_policy_version_id;
     select total into v_total from public.admission_invoices where admission_id=v_case.id and invoice_kind='INITIAL';
     if v_total is null or v_case.student_id is null or v_policy.id is null then raise exception 'Accepted identity, initial billing and pinned activation policy are required.'; end if;
     -- Payment-backed activation is added by the following payment migration.
     if not coalesce(public.admission_payment_satisfied(v_case.id),false) then
       update public.admission_cases set status='PENDING_PAYMENT' where id=v_case.id;
     else
       select * into v_capacity from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE';
       if v_capacity.id is null then raise exception 'Capacity policy missing.'; end if;
       select count(*) into v_occupied from public.enrollments where batch_id=v_batch.id and status='ACTIVE';
       if v_occupied>=least(v_batch.capacity,(v_capacity.payload->>'max_students')::integer) then raise exception 'Selected batch is full under the current capacity policy.'; end if;
       if exists(select 1 from public.enrollments where student_id=v_case.student_id and academic_year_id=v_batch.academic_year_id and status='ACTIVE') then raise exception 'Student already has an active enrollment in this academic year.';end if;
       insert into public.enrollments(student_id,organization_id,branch_id,academic_year_id,class_id,program_id,batch_id,status,created_by)
       values(v_case.student_id,v_batch.organization_id,v_batch.branch_id,v_batch.academic_year_id,v_batch.class_id,v_batch.program_id,v_batch.id,'ACTIVE',v_actor) returning id into v_enrollment;
       update public.admission_cases set status='ACTIVE_ENROLLMENT',enrollment_id=v_enrollment,capacity_policy_version_id=v_capacity.id where id=v_case.id;
       update public.students set status='ACTIVE' where id=v_case.student_id;
     end if;
   else raise exception 'This action is not allowed from the current admission state.';
   end if;
   select * into v_case from public.admission_cases where id=v_case.id;
   v_result:=jsonb_build_object('id',v_case.id,'status',v_case.status);
 end if;
 insert into public.audit_events(correlation_id,actor_profile_id,actor_staff_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(v_request,v_actor,(select id from public.staff where profile_id=v_actor limit 1),
   case when v_action='CREATE_BATCH' then 'BATCH' else 'ADMISSION' end,v_result->>'id',v_action,v_reason,v_before,
   case when v_action='CREATE_BATCH' then to_jsonb(v_batch) else to_jsonb(v_case) end);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(v_request,v_actor,p_input,v_result);
 return v_result;
end;
$function$;

-- Upstream 10_accounting_workflows.sql
-- Sohoj Academy fresh database baseline: accounting workflows.
-- Install on an empty application schema. Each object is defined once.

CREATE OR REPLACE FUNCTION public.finance_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 actor uuid:=auth.uid(); action text:=p_input->>'action'; req uuid:=(p_input->>'request_id')::uuid;
 reason text:=btrim(coalesce(p_input->>'reason','')); key public.admission_command_keys;
 a public.admission_cases;
 start_date date; end_date date; kind text; value numeric; preview jsonb; row jsonb; invoice_id uuid; gross numeric:=0; count_invoices integer:=0;
 result jsonb; permission text; today date; year public.academic_years; term public.billing_terms;
begin
 if actor is null then raise exception 'Sign in to continue.'; end if;
 if req is null or length(reason)<5 then raise exception 'A request identity and reason are required.'; end if;
 if action in('APPLY_DISCOUNT','CANCEL_ADMISSION','REFUND') then return public.apply_finance_adjustment(p_input); end if;
 if action not in('RUN_BILLING','CREATE_TERM') or not public.has_permission('finance.billing.manage') then raise exception 'Billing management permission required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into key from public.admission_command_keys where request_id=req;
 if found then
  if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity already used for different input.'; end if;
  return key.result;
 end if;
 if action='CREATE_TERM' then
  select * into year from public.academic_years where id=(p_input->>'academic_year_id')::uuid for update;
  start_date:=(p_input->>'starts_on')::date; end_date:=(p_input->>'ends_on')::date;
  if year.id is null or start_date is null or end_date is null or start_date<year.starts_on or end_date>year.ends_on or end_date<start_date
   or length(btrim(coalesce(p_input->>'name','')))<2 or (p_input->>'due_on')::date is null then raise exception 'Enter a valid term inside the academic year.'; end if;
  if exists(select 1 from public.billing_terms t where t.academic_year_id=year.id and daterange(t.starts_on,t.ends_on,'[]')&&daterange(start_date,end_date,'[]')) then raise exception 'Term overlaps an existing term.'; end if;
  insert into public.billing_terms(academic_year_id,name,starts_on,ends_on,due_on,created_by)
  values(year.id,btrim(p_input->>'name'),start_date,end_date,(p_input->>'due_on')::date,actor) returning * into term;
  result:=jsonb_build_object('id',term.id,'message','Term created.');
 elsif action='RUN_BILLING' then
  -- Serialize all relevant case changes before comparing the user's reviewed preview.
  perform 1 from public.admission_cases where status='ACTIVE_ENROLLMENT' order by id for update;
  preview:=public.billing_preview((p_input->>'period')::date,nullif(p_input->>'term_id','')::uuid);
  if preview->>'token' is distinct from p_input->>'preview_token' then raise exception 'Billing preview changed. Refresh and review it before posting.'; end if;
  if jsonb_array_length(preview->'rows')=0 then raise exception 'No unbilled eligible enrollments for this period.'; end if;
  for row in select x from jsonb_array_elements(preview->'rows') x loop
   select * into a from public.admission_cases where id=(row->>'admissionId')::uuid;
   select (now() at time zone o.timezone)::date into today from public.batches b join public.organizations o on o.id=b.organization_id where b.id=a.batch_id;
   insert into public.admission_invoices(admission_id,student_id,fee_plan_version_id,currency_code,total,issued_on,due_on,posted_by,invoice_kind,billing_period)
   select a.id,a.student_id,a.fee_plan_version_id,f.currency_code,(row->>'gross')::numeric,today,(row->>'dueOn')::date,actor,'RECURRING',(preview->>'period')::date from public.fee_plan_versions f where f.id=a.fee_plan_version_id returning id into invoice_id;
   insert into public.admission_invoice_lines(invoice_id,fee_component_id,name,charge_type,amount)
   select invoice_id,fc.id,fc.name,fc.charge_type,fc.amount from public.fee_plan_components fc where fc.fee_plan_version_id=a.fee_plan_version_id and fc.recurrence='PER_CYCLE';
   perform public.apply_invoice_discounts(invoice_id);
   gross:=gross+(row->>'gross')::numeric; count_invoices:=count_invoices+1;
  end loop;
  insert into public.billing_runs(id,period,term_id,posted_by,invoice_count,gross_total,reason)
  values(req,(preview->>'period')::date,nullif(preview->>'termId','')::uuid,actor,count_invoices,gross,reason);
  result:=jsonb_build_object('id',req,'message',count_invoices||' recurring invoices posted.');
 else
  raise exception 'Choose a supported billing action.';
 end if;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,after_data,metadata)
 values(req,actor,'FINANCE_WORKFLOW',result->>'id',action,reason,result,p_input);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);
 return result;
end;
$function$;

CREATE OR REPLACE FUNCTION public.assert_journal_balanced()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare
  v_journal uuid := coalesce(new.journal_id,old.journal_id);
  v_debit numeric;
  v_credit numeric;
begin
  select
    coalesce(sum(debit),0),
    coalesce(sum(credit),0)
  into v_debit,v_credit
  from public.general_ledger_lines
  where journal_id=v_journal;

  if v_debit<>v_credit then
    raise exception 'Journal % is not balanced. Debit %, credit %.',
      v_journal,v_debit,v_credit;
  end if;

  return coalesce(new,old);
end;
$function$;

CREATE OR REPLACE FUNCTION public.finance_account_balance(p_account_id uuid, p_as_of date DEFAULT CURRENT_DATE)
 RETURNS numeric
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case
    when a.account_type in('ASSET','EXPENSE') then
      coalesce(sum(l.debit-l.credit),0)
    when a.account_type in('LIABILITY','EQUITY','REVENUE','CONTRA_REVENUE') then
      coalesce(sum(l.credit-l.debit),0)
    else 0
  end
  from public.finance_accounts a
  join public.general_ledger_lines l on l.account_id=a.id
  join public.general_ledger_journals j on j.id=l.journal_id
  where a.id=p_account_id
    and j.status='POSTED'
    and j.journal_date<=p_as_of
  group by a.id,a.account_type;
$function$;

CREATE OR REPLACE FUNCTION public.advance_balance(p_advance_id uuid)
 RETURNS numeric
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(sum(
    case movement_type
      when 'PAYMENT' then amount
      when 'SETTLEMENT' then -amount
      when 'REFUND' then -amount
    end
  ),0)
  from public.finance_advance_movements
  where advance_id=p_advance_id;
$function$;

CREATE OR REPLACE FUNCTION public.finance_post_journal(p_organization_id uuid, p_journal_date date, p_journal_type text, p_source_type text, p_source_id text, p_description text, p_posted_by uuid, p_lines jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  journal_id uuid;
  line jsonb;
  n integer:=0;
  debit_total numeric:=0;
  credit_total numeric:=0;
  account_org uuid;
begin
  if p_lines is null or jsonb_typeof(p_lines)<>'array'
     or jsonb_array_length(p_lines)<2 then
    raise exception 'A journal requires at least two lines.';
  end if;

  if exists(
    select 1 from public.general_ledger_journals
    where source_type=p_source_type and source_id=p_source_id
  ) then
    select id into journal_id
    from public.general_ledger_journals
    where source_type=p_source_type and source_id=p_source_id;
    return journal_id;
  end if;

  for line in select value from jsonb_array_elements(p_lines)
  loop
    n:=n+1;
    if nullif(line->>'account_id','') is null then
      raise exception 'Journal line % has no account.',n;
    end if;

    select organization_id into account_org
    from public.finance_accounts
    where id=(line->>'account_id')::uuid and is_active;

    if account_org is null or account_org<>p_organization_id then
      raise exception 'Journal line % uses an invalid account.',n;
    end if;

    debit_total:=debit_total+coalesce((line->>'debit')::numeric,0);
    credit_total:=credit_total+coalesce((line->>'credit')::numeric,0);

    if coalesce((line->>'debit')::numeric,0)>0
       and coalesce((line->>'credit')::numeric,0)>0 then
      raise exception 'Journal line % cannot contain both debit and credit.',n;
    end if;

    if coalesce((line->>'debit')::numeric,0)<=0
       and coalesce((line->>'credit')::numeric,0)<=0 then
      raise exception 'Journal line % must contain a positive debit or credit.',n;
    end if;
  end loop;

  if round(debit_total,2)<>round(credit_total,2) then
    raise exception 'Journal must balance. Debit %, credit %.',debit_total,credit_total;
  end if;

  insert into public.general_ledger_journals(
    organization_id,journal_date,journal_type,source_type,source_id,
    description,posted_by
  )
  values(
    p_organization_id,p_journal_date,p_journal_type,p_source_type,p_source_id,
    btrim(p_description),p_posted_by
  )
  returning id into journal_id;

  for line in select value from jsonb_array_elements(p_lines)
  loop
    n:=n+1;
  end loop;

  n:=0;
  for line in select value from jsonb_array_elements(p_lines)
  loop
    n:=n+1;
    insert into public.general_ledger_lines(
      journal_id,line_no,account_id,debit,credit,memo,
      cost_centre_id,branch_id,program_id,batch_id
    )
    values(
      journal_id,n,(line->>'account_id')::uuid,
      coalesce((line->>'debit')::numeric,0),
      coalesce((line->>'credit')::numeric,0),
      nullif(btrim(line->>'memo'),''),
      nullif(line->>'cost_centre_id','')::uuid,
      nullif(line->>'branch_id','')::uuid,
      nullif(line->>'program_id','')::uuid,
      nullif(line->>'batch_id','')::uuid
    );
  end loop;

  return journal_id;
end;
$function$;

CREATE OR REPLACE FUNCTION public.finance_sync_invoice(p_invoice_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  i public.admission_invoices;
  a public.admission_cases;
  org uuid;
  ar uuid;
  other_revenue uuid;
  lines jsonb:='[]'::jsonb;
begin
  select * into i from public.admission_invoices where id=p_invoice_id;
  if i.id is null or i.total <= 0 then return null; end if;

  select * into a from public.admission_cases where id=i.admission_id;
  select organization_id into org from public.students where id=i.student_id;

  select id into ar from public.finance_accounts
  where organization_id=org and account_subtype='STUDENT_RECEIVABLE' and is_active limit 1;
  select id into other_revenue from public.finance_accounts
  where organization_id=org and account_subtype='OTHER_FEE_REVENUE' and is_active limit 1;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'account_id',coalesce(m.account_id,other_revenue),
      'debit',0,
      'credit',l.amount,
      'memo',l.name,
      'branch_id',b.branch_id,
      'program_id',b.program_id,
      'batch_id',b.id
    )
  ),'[]'::jsonb)
  into lines
  from public.admission_invoice_lines l
  left join public.finance_fee_revenue_map m
    on m.organization_id=org and m.charge_type=l.charge_type
  join public.admission_cases ac on ac.id=i.admission_id
  join public.batches b on b.id=ac.batch_id
  where l.invoice_id=i.id and l.amount>0;

  if jsonb_array_length(lines)=0 then
    raise exception 'A positive invoice has no positive charge lines.';
  end if;

  lines:=jsonb_build_array(
    jsonb_build_object(
      'account_id',ar,
      'debit',i.total,
      'credit',0,
      'memo','Student receivable'
    )
  ) || lines;

  return public.finance_post_journal(
    org,i.issued_on,
    'INVOICE','ADMISSION_INVOICE',i.id::text,
    'Invoice '||i.invoice_no,
    i.posted_by,lines
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.finance_sync_invoice_line_statement()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  r record;
begin
  for r in select distinct invoice_id from new_table
  loop
    perform public.finance_sync_invoice(r.invoice_id);
  end loop;
  return null;
end;
$function$;

CREATE OR REPLACE FUNCTION public.finance_sync_invoice_credit(p_credit_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  c public.invoice_credits;
  i public.admission_invoices;
  org uuid;
  ar uuid;
  contra uuid;
begin
  select * into c from public.invoice_credits where id=p_credit_id;
  select * into i from public.admission_invoices where id=c.invoice_id;
  select organization_id into org from public.students where id=i.student_id;
  select id into ar from public.finance_accounts where organization_id=org and account_subtype='STUDENT_RECEIVABLE' and is_active limit 1;
  select id into contra from public.finance_accounts where organization_id=org and account_subtype='FEE_CREDITS' and is_active limit 1;

  return public.finance_post_journal(
    org,current_date,'INVOICE_CREDIT','INVOICE_CREDIT',c.id::text,
    initcap(lower(c.kind))||' credit for invoice '||i.invoice_no,
    (select posted_by from public.admission_cases a join public.admission_invoices x on x.admission_id=a.id where x.id=i.id limit 1),
    jsonb_build_array(
      jsonb_build_object('account_id',contra,'debit',c.amount,'credit',0,'memo',c.kind),
      jsonb_build_object('account_id',ar,'debit',0,'credit',c.amount,'memo','Reduce student receivable')
    )
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.finance_sync_invoice_credit_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  perform public.finance_sync_invoice_credit(new.id);
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.finance_sync_payment(p_payment_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  p public.admission_payments;
  pa public.admission_payment_allocations;
  i public.admission_invoices;
  org uuid;
  cash_account uuid;
  ar uuid;
begin
  select * into p from public.admission_payments where id=p_payment_id;
  select * into pa from public.admission_payment_allocations where payment_id=p.id;
  select * into i from public.admission_invoices where id=pa.invoice_id;
  select organization_id into org from public.students where id=p.student_id;
  select account_id into cash_account from public.finance_payment_account_map where payment_method_id=p.payment_method_id;
  select id into ar from public.finance_accounts where organization_id=org and account_subtype='STUDENT_RECEIVABLE' and is_active limit 1;

  return public.finance_post_journal(
    org,p.posted_at::date,'PAYMENT','ADMISSION_PAYMENT',p.id::text,
    'Payment '||p.receipt_no,p.posted_by,
    jsonb_build_array(
      jsonb_build_object('account_id',cash_account,'debit',p.amount,'credit',0,'memo',p.receipt_no),
      jsonb_build_object('account_id',ar,'debit',0,'credit',p.amount,'memo','Reduce student receivable')
    )
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.finance_sync_payment_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  perform public.finance_sync_payment(new.payment_id);
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.finance_sync_refund(p_payout_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  rp public.refund_payouts;
  ra public.refund_authorizations;
  i public.admission_invoices;
  org uuid;
  cash_account uuid;
  ar uuid;
begin
  select * into rp from public.refund_payouts where id=p_payout_id;
  select * into ra from public.refund_authorizations where id=rp.authorization_id;
  select * into i from public.admission_invoices where id=ra.invoice_id;
  select organization_id into org from public.students where id=i.student_id;
  select account_id into cash_account from public.finance_payment_account_map where payment_method_id=rp.payment_method_id;
  select id into ar from public.finance_accounts where organization_id=org and account_subtype='STUDENT_RECEIVABLE' and is_active limit 1;

  return public.finance_post_journal(
    org,rp.posted_at::date,'REFUND','REFUND_PAYOUT',rp.id::text,
    'Refund '||rp.refund_no,rp.posted_by,
    jsonb_build_array(
      jsonb_build_object('account_id',ar,'debit',ra.amount,'credit',0,'memo','Reinstate student receivable'),
      jsonb_build_object('account_id',cash_account,'debit',0,'credit',ra.amount,'memo',rp.refund_no)
    )
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.finance_sync_refund_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  perform public.finance_sync_refund(new.id);
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.finance_net_collected_tuition(p_from date, p_to date)
 RETURNS TABLE(admission_id uuid, batch_id uuid, billing_period date, tuition_collected numeric)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
with cash_events as (
 select i.id invoice_id,i.admission_id,a.batch_id,
  timezone(o.timezone,p.posted_at)::date event_date,
  pa.amount signed_amount,
  (select coalesce(sum(l.amount),0) from public.admission_invoice_lines l
    where l.invoice_id=i.id and l.charge_type='TUITION') tuition_gross
 from public.admission_payment_allocations pa
 join public.admission_payments p on p.id=pa.payment_id
 join public.admission_invoices i on i.id=pa.invoice_id
 join public.admission_cases a on a.id=i.admission_id
 join public.students s on s.id=p.student_id
 join public.organizations o on o.id=s.organization_id
 where timezone(o.timezone,p.posted_at)::date between p_from and p_to
 union all
 select i.id,i.admission_id,a.batch_id,
  timezone(o.timezone,rp.posted_at)::date,-r.amount,
  (select coalesce(sum(l.amount),0) from public.admission_invoice_lines l
    where l.invoice_id=i.id and l.charge_type='TUITION')
 from public.refund_payouts rp
 join public.refund_authorizations r on r.id=rp.authorization_id
 join public.admission_invoices i on i.id=r.invoice_id
 join public.admission_cases a on a.id=i.admission_id
 join public.students s on s.id=i.student_id
 join public.organizations o on o.id=s.organization_id
 where timezone(o.timezone,rp.posted_at)::date between p_from and p_to
), attributed as (
 select e.*, greatest(i.total-coalesce((select sum(c.amount) from public.invoice_credits c
   where c.invoice_id=e.invoice_id and c.created_at::date<=e.event_date),0),0) net_invoice,
  greatest(e.tuition_gross-coalesce((select sum(c.amount) from public.invoice_credits c
   where c.invoice_id=e.invoice_id and c.kind='DISCOUNT' and c.created_at::date<=e.event_date),0),0) net_tuition
 from cash_events e join public.admission_invoices i on i.id=e.invoice_id
)
select admission_id,batch_id,date_trunc('month',event_date)::date,
 round(sum(case when net_invoice>0 then signed_amount*least(net_tuition,net_invoice)/net_invoice else 0 end),2)
from attributed group by admission_id,batch_id,date_trunc('month',event_date)::date;
$function$;

CREATE OR REPLACE FUNCTION public.teacher_compensation_preview(p_from date, p_to date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid:=auth.uid();
  policy public.business_rule_versions;
  rows jsonb:='[]'::jsonb;
  teacher_row record;
  batch_row record;
  event_amount numeric;
  pool_percent numeric;
  acquisition_percent numeric;
  retention3_percent numeric;
  retention6_percent numeric;
  first_period date;
  first_collected numeric;
  month3 date;
  month6 date;
  month_paid boolean;
  continuous3 boolean;
  continuous6 boolean;
begin
  if actor is null or not public.has_permission('staff.compensation.view') then
    raise exception 'Compensation access denied.';
  end if;
  if p_from is null or p_to is null or p_to<p_from then
    raise exception 'Choose a valid compensation period.';
  end if;

  select * into policy
  from public.business_rule_versions
  where domain='teacher_compensation'
    and rule_key='default_policy'
    and status='ACTIVE'
  order by version desc
  limit 1;

  if policy.id is null
     or not public.validate_business_rule_payload('teacher_compensation','default_policy',policy.payload) then
    raise exception 'A valid teacher compensation policy is required.';
  end if;

  pool_percent:=(policy.payload->>'teaching_pool_percent')::numeric;
  acquisition_percent:=(policy.payload->>'acquisition_bonus_percent')::numeric;
  retention3_percent:=(policy.payload->>'retention_3_month_percent')::numeric;
  retention6_percent:=(policy.payload->>'retention_6_month_percent')::numeric;

  -- Teaching pool is calculated per batch from Net Collected Tuition and
  -- allocated by approved attendance/session workload within that batch.
  for batch_row in
    with batch_revenue as (
      select batch_id,sum(tuition_collected) net_collected
      from public.finance_net_collected_tuition(p_from,p_to)
      group by batch_id
    ),
    session_weights as (
      select
        cs.batch_id,
        cs.teacher_id,
        count(*) filter(
          where exists(
            select 1 from public.attendance_submissions aa
            where aa.id=(
              select z.id from public.attendance_submissions z
              where z.session_id=cs.id
              order by z.revision desc limit 1
            )
            and aa.status='APPROVED'
          )
        )::numeric as session_count
      from public.class_sessions cs
      where cs.session_date between p_from and p_to
        and cs.status='SCHEDULED'
      group by cs.batch_id,cs.teacher_id
    )
    select
      r.batch_id,
      r.net_collected,
      r.net_collected*pool_percent/100 as pool_amount,
      w.teacher_id,
      w.session_count,
      sum(w.session_count) over(partition by w.batch_id) total_sessions
    from batch_revenue r
    join session_weights w on w.batch_id=r.batch_id
    where r.net_collected>0 and w.session_count>0
  loop
    event_amount:=round(batch_row.pool_amount*batch_row.session_count/nullif(batch_row.total_sessions,0),2);
    if event_amount>0 and not exists (select 1 from public.teacher_compensation_claims c
      where c.teacher_id=batch_row.teacher_id and c.source_type='BATCH_PERIOD'
        and c.source_id=batch_row.batch_id::text||':'||p_from::text||':'||p_to::text) then
    rows:=rows||jsonb_build_array(
      jsonb_build_object(
        'teacherId',batch_row.teacher_id,
        'lineType','TEACHING_REMUNERATION',
        'amount',event_amount,
        'sourceType','BATCH_PERIOD',
        'sourceId',batch_row.batch_id::text||':'||p_from::text||':'||p_to::text,
        'calculation',jsonb_build_object(
          'batchId',batch_row.batch_id,
          'netCollectedTuition',batch_row.net_collected,
          'poolPercent',pool_percent,
          'poolAmount',batch_row.pool_amount,
          'approvedSessions',batch_row.session_count,
          'batchApprovedSessions',batch_row.total_sessions
        )
      )
    );
    end if;
  end loop;

  -- Acquisition/retention bonuses require a structured teacher referral.
  for teacher_row in
    select
      tr.teacher_id,
      tr.admission_id,
      min(n.billing_period) first_billing_period
    from public.teacher_referrals tr
    join public.admission_cases a on a.id=tr.admission_id and a.status='ACTIVE_ENROLLMENT'
    join public.finance_net_collected_tuition(date '2000-01-01',p_to) n
      on n.admission_id=tr.admission_id and n.tuition_collected>0
    group by tr.teacher_id,tr.admission_id
  loop
    first_period:=teacher_row.first_billing_period;

    select coalesce(sum(n.tuition_collected),0)
    into first_collected
    from public.finance_net_collected_tuition(first_period,(first_period+interval '1 month - 1 day')::date) n
    where n.admission_id=teacher_row.admission_id;

    if first_period between p_from and p_to and first_collected>0
      and not exists(select 1 from public.teacher_compensation_claims c
        where c.teacher_id=teacher_row.teacher_id and c.source_type='ACQUISITION'
          and c.source_id=teacher_row.admission_id::text) then
      rows:=rows||jsonb_build_array(
        jsonb_build_object(
          'teacherId',teacher_row.teacher_id,
          'admissionId',teacher_row.admission_id,
          'lineType','ACQUISITION_BONUS',
          'amount',round(first_collected*acquisition_percent/100,2),
          'sourceType','ACQUISITION',
          'sourceId',teacher_row.admission_id::text,
          'calculation',jsonb_build_object(
            'firstMonthNetCollectedTuition',first_collected,
            'bonusPercent',acquisition_percent
          )
        )
      );
    end if;

    month3:=(first_period+interval '2 months')::date;
    month6:=(first_period+interval '5 months')::date;

    select bool_and(tuition_collected>0)
    into continuous3
    from (
      select
        m.month_start,
        coalesce((
          select sum(n.tuition_collected)
          from public.finance_net_collected_tuition(m.month_start,(m.month_start+interval '1 month - 1 day')::date) n
          where n.admission_id=teacher_row.admission_id
        ),0) tuition_collected
      from generate_series(first_period,month3,interval '1 month') g
      cross join lateral(select g::date month_start) m
    ) x;

    if month3 between p_from and p_to and continuous3 is true
      and not exists(select 1 from public.teacher_compensation_claims c
        where c.teacher_id=teacher_row.teacher_id and c.source_type='RETENTION_3'
          and c.source_id=teacher_row.admission_id::text) then
      select coalesce(sum(n.tuition_collected),0)
      into event_amount
      from public.finance_net_collected_tuition(month3,(month3+interval '1 month - 1 day')::date) n
      where n.admission_id=teacher_row.admission_id;

      if event_amount>0 then
        rows:=rows||jsonb_build_array(
          jsonb_build_object(
            'teacherId',teacher_row.teacher_id,
            'admissionId',teacher_row.admission_id,
            'lineType','RETENTION_3_MONTH',
            'amount',round(event_amount*retention3_percent/100,2),
            'sourceType','RETENTION_3',
            'sourceId',teacher_row.admission_id::text,
            'calculation',jsonb_build_object(
              'milestoneMonth',month3,
              'monthNetCollectedTuition',event_amount,
              'bonusPercent',retention3_percent
            )
          )
        );
      end if;
    end if;

    select bool_and(tuition_collected>0)
    into continuous6
    from (
      select
        m.month_start,
        coalesce((
          select sum(n.tuition_collected)
          from public.finance_net_collected_tuition(m.month_start,(m.month_start+interval '1 month - 1 day')::date) n
          where n.admission_id=teacher_row.admission_id
        ),0) tuition_collected
      from generate_series(first_period,month6,interval '1 month') g
      cross join lateral(select g::date month_start) m
    ) x;

    if month6 between p_from and p_to and continuous6 is true
      and not exists(select 1 from public.teacher_compensation_claims c
        where c.teacher_id=teacher_row.teacher_id and c.source_type='RETENTION_6'
          and c.source_id=teacher_row.admission_id::text) then
      select coalesce(sum(n.tuition_collected),0)
      into event_amount
      from public.finance_net_collected_tuition(month6,(month6+interval '1 month - 1 day')::date) n
      where n.admission_id=teacher_row.admission_id;

      if event_amount>0 then
        rows:=rows||jsonb_build_array(
          jsonb_build_object(
            'teacherId',teacher_row.teacher_id,
            'admissionId',teacher_row.admission_id,
            'lineType','RETENTION_6_MONTH',
            'amount',round(event_amount*retention6_percent/100,2),
            'sourceType','RETENTION_6',
            'sourceId',teacher_row.admission_id::text,
            'calculation',jsonb_build_object(
              'milestoneMonth',month6,
              'monthNetCollectedTuition',event_amount,
              'bonusPercent',retention6_percent
            )
          )
        );
      end if;
    end if;
  end loop;

  for teacher_row in
    select teacher_id,adjustment_type,id,amount
    from public.teacher_compensation_adjustments
    where status='APPROVED'
      and effective_period between p_from and p_to
      and not exists(select 1 from public.teacher_compensation_claims c
        where c.teacher_id=teacher_compensation_adjustments.teacher_id
          and c.source_type='ADJUSTMENT' and c.source_id=teacher_compensation_adjustments.id::text)
  loop
    rows:=rows||jsonb_build_array(
      jsonb_build_object(
        'teacherId',teacher_row.teacher_id,
        'lineType',case when teacher_row.adjustment_type='GROWTH_BONUS'
          then 'GROWTH_BONUS' else 'ADJUSTMENT' end,
        'amount',teacher_row.amount,
        'sourceType','ADJUSTMENT',
        'sourceId',teacher_row.id::text,
        'calculation',jsonb_build_object(
          'adjustmentType',teacher_row.adjustment_type
        )
      )
    );
  end loop;

  return jsonb_build_object(
    'periodStart',p_from,
    'periodEnd',p_to,
    'policyVersion',policy.version,
    'rows',rows,
    'total',coalesce((select sum((x->>'amount')::numeric) from jsonb_array_elements(rows) x),0)
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.finance_accounting_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid:=auth.uid();
  action text:=p_input->>'action';
  req uuid:=nullif(p_input->>'request_id','')::uuid;
  key public.admission_command_keys;
  result jsonb;
  reason text:=btrim(coalesce(p_input->>'reason',''));
  org uuid;
  account public.finance_accounts;
  journal_id uuid;
  advance public.finance_advances;
  adv_balance numeric;
  payable public.finance_payables;
  expense public.finance_expenses;
  vendor public.vendors;
  amount numeric;
  expense_account uuid;
  payment_account uuid;
  payment_mode text;
  category public.finance_expense_categories;
  compensation public.teacher_compensation_runs;
  policy public.business_rule_versions;
  preview jsonb;
  line jsonb;
  teacher_id uuid;
  v_teacher uuid;
  settlement public.teacher_compensation_settlements;
  cash_paid numeric;
  advance_offset numeric;
  advance_row record;
  settlement_id uuid;
  decision text;
  source_type text;
  permission text;
begin
  if actor is null then raise exception 'Sign in to continue.'; end if;
  if req is null or length(reason)<5 then
    raise exception 'A request identity and reason of at least five characters are required.';
  end if;

  permission := null;
  -- Action permission is assigned below because compensation/expense/advance
  -- workflows have different authorization boundaries.
  if action in('CREATE_ADVANCE','CREATE_EXPENSE_DIRECT','RUN_COMPENSATION','APPLY_COMP_ADJUSTMENT') then
    return public.post_accounting_operation(p_input);
  end if;
  permission:=case
    when action in('CREATE_ACCOUNT','POST_JOURNAL') then 'accounting.manage'
    when action in('CREATE_VENDOR','PAY_ADVANCE','REFUND_ADVANCE','APPLY_ADVANCE') then 'finance.advances.manage'
    when action='SETTLE_PAYABLE' then 'finance.payments.post'
    when action in('RECONCILE_EXPENSE','RECONCILE_ACCOUNT') then 'accounting.reconcile'
    when action='SETTLE_COMPENSATION' then 'staff.compensation.manage'
    else null end;

  if permission is null or not public.has_permission(permission) then
    raise exception 'Permission denied for this accounting action.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(req::text,7));
  select * into key from public.admission_command_keys where request_id=req;
  if found then
    if key.actor_id<>actor or key.payload<>p_input then
      raise exception 'Request identity already used for different input.';
    end if;
    return key.result;
  end if;

  select id into org from public.organizations where is_active limit 1;

  if action='CREATE_ACCOUNT' then
    if length(btrim(coalesce(p_input->>'code','')))<2
       or length(btrim(coalesce(p_input->>'name','')))<2
       or p_input->>'account_type' not in('ASSET','LIABILITY','EQUITY','REVENUE','CONTRA_REVENUE','EXPENSE')
       or length(btrim(coalesce(p_input->>'account_subtype','')))<2 then
      raise exception 'Enter valid account code, name, type and category.';
    end if;

    insert into public.finance_accounts(
      organization_id,code,name,account_type,account_subtype,parent_id,
      is_control_account,created_by
    )
    values(
      org,btrim(p_input->>'code'),btrim(p_input->>'name'),
      p_input->>'account_type',btrim(p_input->>'account_subtype'),
      nullif(p_input->>'parent_id','')::uuid,
      coalesce((p_input->>'is_control_account')::boolean,false),actor
    )
    returning * into account;

    result:=jsonb_build_object('id',account.id,'message','Financial account created.');

  elsif action='POST_JOURNAL' then
    if not public.has_permission('accounting.manage') then raise exception 'Accounting management permission required.'; end if;
    perform public.finance_post_journal(
      org,
      (p_input->>'journal_date')::date,
      'MANUAL',
      'MANUAL_JOURNAL',
      req::text,
      btrim(p_input->>'description'),
      actor,
      p_input->'lines'
    );
    result:=jsonb_build_object('id',req,'message','Balanced journal posted.');

  elsif action='CREATE_VENDOR' then
    if length(btrim(coalesce(p_input->>'name','')))<2 then
      raise exception 'Vendor name is required.';
    end if;
    insert into public.vendors(
      organization_id,name,mobile,email,address,service_category,created_by
    )
    values(
      org,btrim(p_input->>'name'),
      nullif(btrim(p_input->>'mobile'),''),
      nullif(lower(btrim(p_input->>'email')),''),
      nullif(btrim(p_input->>'address'),''),
      nullif(btrim(p_input->>'service_category'),''),
      actor
    )
    returning * into vendor;
    result:=jsonb_build_object('id',vendor.id,'vendorNo',vendor.vendor_no,'message','Vendor created.');

  elsif action='PAY_ADVANCE' then
    select * into advance from public.finance_advances where id=(p_input->>'advance_id')::uuid for update;
    amount:=(p_input->>'amount')::numeric;
    if advance.id is null or advance.status not in('APPROVED','PAID') then raise exception 'Only approved advances can be paid.'; end if;
    if amount is null or amount<=0 then raise exception 'Advance payment must be positive.'; end if;
    if amount>advance.approved_amount-public.advance_paid(advance.id) then raise exception 'Payment exceeds approved advance balance.'; end if;

    select id into payment_account
    from public.finance_accounts
    where id=(p_input->>'payment_account_id')::uuid
      and organization_id=org
      and account_subtype in('CASH','BANK','MOBILE_BANK')
      and is_active;

    if payment_account is null then raise exception 'Choose an active cash or bank account.'; end if;

    insert into public.finance_advance_movements(
      advance_id,movement_type,amount,source_type,source_id,payment_account_id,created_by,reason
    )
    values(
      advance.id,'PAYMENT',amount,'ADVANCE_PAYMENT',req::text,payment_account,actor,reason
    );

    perform public.finance_post_journal(
      org,current_date,'ADVANCE_PAYMENT','ADVANCE_PAYMENT',req::text,
      'Advance payment '||advance.advance_no,actor,
      jsonb_build_array(
        jsonb_build_object(
          'account_id',
          case when advance.beneficiary_type='STAFF'
            then (select id from public.finance_accounts where organization_id=org and account_subtype='STAFF_ADVANCE' limit 1)
            when advance.beneficiary_type='VENDOR'
            then (select id from public.finance_accounts where organization_id=org and account_subtype='VENDOR_ADVANCE' limit 1)
            else (select id from public.finance_accounts where organization_id=org and account_subtype='STAFF_ADVANCE' limit 1)
          end,
          'debit',amount,'credit',0
        ),
        jsonb_build_object('account_id',payment_account,'debit',0,'credit',amount)
      )
    );

    if public.advance_paid(advance.id)>=advance.approved_amount then
      update public.finance_advances set status='PAID' where id=advance.id;
    end if;
    result:=jsonb_build_object('id',advance.id,'message','Advance payment posted.');

  elsif action='REFUND_ADVANCE' then
    select * into advance from public.finance_advances where id=(p_input->>'advance_id')::uuid for update;
    amount:=(p_input->>'amount')::numeric;
    adv_balance:=public.advance_balance(advance.id);
    if advance.id is null or adv_balance<=0 or amount is null or amount<=0 or amount>adv_balance then
      raise exception 'Refund exceeds the unsettled advance balance.';
    end if;
    select id into payment_account
    from public.finance_accounts
    where id=(p_input->>'payment_account_id')::uuid
      and organization_id=org
      and account_subtype in('CASH','BANK','MOBILE_BANK')
      and is_active;
    if payment_account is null then raise exception 'Choose an active cash or bank account.'; end if;

    perform public.finance_post_journal(
      org,current_date,'ADVANCE_REFUND','ADVANCE_REFUND',req::text,
      'Advance refund '||advance.advance_no,actor,
      jsonb_build_array(
        jsonb_build_object(
          'account_id',payment_account,'debit',amount,'credit',0
        ),
        jsonb_build_object(
          'account_id',
          case when advance.beneficiary_type='VENDOR'
            then (select id from public.finance_accounts where organization_id=org and account_subtype='VENDOR_ADVANCE' limit 1)
            else (select id from public.finance_accounts where organization_id=org and account_subtype='STAFF_ADVANCE' limit 1)
          end,
          'debit',0,'credit',amount
        )
      )
    );

    insert into public.finance_advance_movements(
      advance_id,movement_type,amount,source_type,source_id,payment_account_id,created_by,reason
    )
    values(advance.id,'REFUND',amount,'ADVANCE_REFUND',req::text,payment_account,actor,reason);

    update public.finance_advances
    set status=case when public.advance_balance(id)<=0 then 'REFUNDED' else status end
    where id=advance.id;

    result:=jsonb_build_object('id',advance.id,'message','Advance refund recorded.');

  elsif action='SETTLE_PAYABLE' then
    select * into payable from public.finance_payables where id=(p_input->>'payable_id')::uuid for update;
    amount:=(p_input->>'amount')::numeric;
    if payable.id is null or payable.status not in('OPEN','PARTIALLY_SETTLED') then raise exception 'Payable is not open.'; end if;
    if payable.payable_type='TEACHER_COMPENSATION' then raise exception 'Use the compensation settlement to preserve advance offsets.'; end if;
    if amount is null or amount<=0 or amount > payable.original_amount-coalesce((
      select sum(s.amount) from public.finance_payable_settlements s where s.payable_id=payable.id
    ),0) then raise exception 'Settlement exceeds payable balance.'; end if;

    select id into payment_account
    from public.finance_accounts
    where id=(p_input->>'payment_account_id')::uuid
      and organization_id=org
      and account_subtype in('CASH','BANK','MOBILE_BANK')
      and is_active;
    if payment_account is null then raise exception 'Choose an active cash or bank account.'; end if;

    insert into public.finance_payable_settlements(
      payable_id,amount,payment_account_id,external_reference,settled_by,reason
    )
    values(
      payable.id,amount,payment_account,nullif(btrim(p_input->>'external_reference'),''),
      actor,reason
    );

    perform public.finance_post_journal(
      org,current_date,'PAYABLE_SETTLEMENT','PAYABLE_SETTLEMENT',req::text,
      'Payable settlement '||payable.payable_no,actor,
      jsonb_build_array(
        jsonb_build_object('account_id',payable.payable_account_id,'debit',amount,'credit',0),
        jsonb_build_object('account_id',payment_account,'debit',0,'credit',amount)
      )
    );

    update public.finance_payables p
    set status=case
      when coalesce((select sum(s.amount) from public.finance_payable_settlements s where s.payable_id=p.id),0)>=p.original_amount
        then 'SETTLED'
      else 'PARTIALLY_SETTLED' end
    where p.id=payable.id;

    result:=jsonb_build_object('id',payable.id,'message','Payable settlement posted.');

  elsif action='RECONCILE_EXPENSE' then
    select * into expense from public.finance_expenses
    where id=(p_input->>'expense_id')::uuid for update;
    amount:=(p_input->>'matched_amount')::numeric;
    if expense.id is null or expense.status<>'POSTED' then raise exception 'Post the expense before reconciliation.'; end if;
    if amount is null or amount<>expense.amount then raise exception 'Reconciled amount must equal the posted expense amount.'; end if;

    insert into public.finance_expense_reconciliations(
      expense_id,matched_amount,statement_reference,reconciled_by,note
    )
    values(
      expense.id,amount,btrim(p_input->>'statement_reference'),actor,reason
    )
    on conflict(expense_id) do nothing;

    if not found then raise exception 'Expense is already reconciled.'; end if;
    update public.finance_expenses set status='RECONCILED' where id=expense.id;
    result:=jsonb_build_object('id',expense.id,'message','Expense reconciled to the statement reference.');

  elsif action='RECONCILE_ACCOUNT' then
    select * into account from public.finance_accounts
    where id=(p_input->>'account_id')::uuid
      and organization_id=org and is_active;
    if account.id is null then raise exception 'Choose an active account.'; end if;

    select public.finance_account_balance(account.id,(p_input->>'statement_date')::date)
    into amount;

    if amount is null then amount:=0; end if;
    insert into public.finance_account_reconciliations(
      account_id,statement_date,statement_reference,statement_balance,
      ledger_balance,difference,status,note,reconciled_by,reconciled_at
    )
    values(
      account.id,(p_input->>'statement_date')::date,
      btrim(p_input->>'statement_reference'),
      (p_input->>'statement_balance')::numeric,
      amount,
      round((p_input->>'statement_balance')::numeric-amount,2),
      case when round((p_input->>'statement_balance')::numeric-amount,2)=0 then 'RECONCILED' else 'OPEN' end,
      reason,
      case when round((p_input->>'statement_balance')::numeric-amount,2)=0 then actor else null end,
      case when round((p_input->>'statement_balance')::numeric-amount,2)=0 then now() else null end
    )
    on conflict(account_id,statement_date,statement_reference) do update
      set statement_balance=excluded.statement_balance,
          ledger_balance=excluded.ledger_balance,
          difference=excluded.difference,
          status=excluded.status,
          reconciled_by=excluded.reconciled_by,
          reconciled_at=excluded.reconciled_at,
          note=excluded.note;

    result:=jsonb_build_object('id',req,'message',
      case when round((p_input->>'statement_balance')::numeric-amount,2)=0
        then 'Account reconciled.'
        else 'Reconciliation saved as open; investigate the difference before closing it.' end);

  elsif action='SETTLE_COMPENSATION' then
    select * into compensation from public.teacher_compensation_runs
    where id=(p_input->>'run_id')::uuid and status='APPROVED' for update;
    if compensation.id is null then raise exception 'Only an approved compensation run can be settled.'; end if;

    teacher_id:=(p_input->>'teacher_id')::uuid;
    select * into payable from public.finance_payables
    where source_type='COMPENSATION_RUN'
      and source_id=compensation.id::text||':'||teacher_id::text
      and staff_id=teacher_id
    for update;
    if payable.id is null then raise exception 'Teacher payable not found.'; end if;

    amount:=payable.original_amount-coalesce((
      select sum(s.amount) from public.finance_payable_settlements s where s.payable_id=payable.id
    ),0);
    if amount<=0 then raise exception 'Teacher payable is already settled.'; end if;

    advance_offset:=coalesce((p_input->>'advance_offset')::numeric,0);
    if advance_offset<0 or advance_offset>amount then raise exception 'Advance offset is outside the payable balance.'; end if;

    if advance_offset>0 then
      select * into advance_row
      from (
        select adv.*,public.advance_balance(adv.id) balance
        from public.finance_advances adv
        where adv.staff_id=teacher_id
          and adv.beneficiary_type='STAFF'
          and public.advance_balance(adv.id)>0
          and adv.status in('PAID','PARTIALLY_SETTLED','OVERDUE')
        order by adv.expected_settlement_date nulls last,adv.created_at
      ) q
      limit 1 for update;

      if advance_row.id is null or advance_row.balance<advance_offset then
        raise exception 'Requested advance offset exceeds available teacher advance balance.';
      end if;
    end if;

    cash_paid:=amount-advance_offset;
    if cash_paid>0 then
      select id into payment_account
      from public.finance_accounts
      where id=(p_input->>'payment_account_id')::uuid
        and organization_id=compensation.organization_id
        and account_subtype in('CASH','BANK','MOBILE_BANK')
        and is_active;
      if payment_account is null then raise exception 'Choose an active cash or bank account.'; end if;
    end if;

    insert into public.teacher_compensation_settlements(
      run_id,teacher_id,payable_id,gross_amount,advance_offset,cash_paid,
      payment_account_id,external_reference,settled_by,reason
    )
    values(
      compensation.id,teacher_id,payable.id,amount,advance_offset,cash_paid,
      payment_account,nullif(btrim(p_input->>'external_reference'),''),
      actor,reason
    )
    returning id into settlement;

    if advance_offset>0 then
      perform public.finance_post_journal(
        compensation.organization_id,current_date,'COMPENSATION_SETTLEMENT',
        'COMPENSATION_SETTLEMENT',settlement.id::text,
        'Teacher compensation advance offset',actor,
        jsonb_build_array(
          jsonb_build_object(
            'account_id',(select id from public.finance_accounts where organization_id=compensation.organization_id and account_subtype='TEACHER_PAYABLE' limit 1),
            'debit',advance_offset,'credit',0
          ),
          jsonb_build_object(
            'account_id',(select id from public.finance_accounts where organization_id=compensation.organization_id and account_subtype='STAFF_ADVANCE' limit 1),
            'debit',0,'credit',advance_offset
          )
        )
      );
      insert into public.finance_advance_movements(
        advance_id,movement_type,amount,source_type,source_id,payable_id,created_by,reason
      )
      values(
        advance_row.id,'SETTLEMENT',advance_offset,
        'COMPENSATION_SETTLEMENT',settlement.id::text,payable.id,actor,reason
      );
    end if;

    if cash_paid>0 then
      perform public.finance_post_journal(
        compensation.organization_id,current_date,'COMPENSATION_SETTLEMENT',
        'COMPENSATION_CASH_SETTLEMENT',settlement.id::text,
        'Teacher compensation cash settlement',actor,
        jsonb_build_array(
          jsonb_build_object(
            'account_id',(select id from public.finance_accounts where organization_id=compensation.organization_id and account_subtype='TEACHER_PAYABLE' limit 1),
            'debit',cash_paid,'credit',0
          ),
          jsonb_build_object(
            'account_id',payment_account,'debit',0,'credit',cash_paid
          )
        )
      );
    end if;

    if advance_offset>0 then
      insert into public.finance_payable_settlements(
        payable_id,amount,advance_id,settled_by,reason
      ) values(payable.id,advance_offset,advance_row.id,actor,reason);
    end if;
    if cash_paid>0 then
      insert into public.finance_payable_settlements(
        payable_id,amount,payment_account_id,external_reference,settled_by,reason
      ) values(payable.id,cash_paid,payment_account,
        nullif(btrim(p_input->>'external_reference'),''),actor,reason);
    end if;

    update public.finance_payables p
    set status=case
      when coalesce((select sum(s.amount) from public.finance_payable_settlements s where s.payable_id=p.id),0)>=p.original_amount
      then 'SETTLED' else 'PARTIALLY_SETTLED' end
    where p.id=payable.id;

    if not exists(
      select 1 from public.finance_payables
      where source_type='COMPENSATION_RUN'
        and source_id like compensation.id::text||':%'
        and status<>'SETTLED'
    ) then
      update public.teacher_compensation_runs set status='SETTLED' where id=compensation.id;
    end if;

    result:=jsonb_build_object('id',settlement.id,'message','Teacher compensation settlement posted.');
  
  elsif action='APPLY_ADVANCE' then
    select * into advance from public.finance_advances where id=(p_input->>'advance_id')::uuid for update;
    select * into payable from public.finance_payables where id=(p_input->>'payable_id')::uuid for update;
    amount:=(p_input->>'amount')::numeric;
    if advance.id is null or advance.status not in('PAID','PARTIALLY_SETTLED','OVERDUE')
      or payable.id is null or payable.status not in('OPEN','PARTIALLY_SETTLED')
      or payable.organization_id<>advance.organization_id
      or not ((advance.beneficiary_type='VENDOR' and payable.vendor_id=advance.vendor_id)
        or (advance.beneficiary_type='STAFF' and payable.staff_id=advance.staff_id))
      or amount is null or amount<=0 or amount<>round(amount,2)
      or amount>public.advance_balance(advance.id)
      or amount>payable.original_amount-coalesce((select sum(s.amount)
        from public.finance_payable_settlements s where s.payable_id=payable.id),0) then
      raise exception 'Choose a matching approved payable and outstanding advance balance.';
    end if;
      perform public.finance_post_journal(
        org,current_date,'ADVANCE_SETTLEMENT','ADVANCE_SETTLEMENT',req::text,
        'Approved advance against payable '||payable.payable_no,actor,
        jsonb_build_array(
          jsonb_build_object('account_id',payable.payable_account_id,'debit',amount,'credit',0),
          jsonb_build_object('account_id',(select id from public.finance_accounts
            where organization_id=org and account_subtype=case when advance.beneficiary_type='VENDOR'
              then 'VENDOR_ADVANCE' else 'STAFF_ADVANCE' end limit 1),
            'debit',0,'credit',amount)
        )
      );
      insert into public.finance_advance_movements(advance_id,movement_type,amount,
        source_type,source_id,payable_id,created_by,reason)
      values(advance.id,'SETTLEMENT',amount,'ADVANCE_SETTLEMENT',req::text,payable.id,actor,reason);
      insert into public.finance_payable_settlements(payable_id,amount,advance_id,settled_by,reason)
      values(payable.id,amount,advance.id,actor,'Advance application: '||reason);
      update public.finance_advances set status=case when public.advance_balance(id)=0
        then 'SETTLED' else 'PARTIALLY_SETTLED' end where id=advance.id;
      update public.finance_payables p set status=case when
        coalesce((select sum(s.amount) from public.finance_payable_settlements s
          where s.payable_id=p.id),0)>=p.original_amount then 'SETTLED' else 'PARTIALLY_SETTLED' end
      where p.id=payable.id;
    result:=jsonb_build_object('id',advance.id,'message','Advance applied to payable.');

  end if;

  insert into public.audit_events(
    correlation_id,actor_profile_id,actor_staff_id,entity_type,entity_id,action,reason,after_data,metadata
  )
  values(
    req,actor,(select id from public.staff where profile_id=actor limit 1),
    'FINANCE_ACCOUNTING',coalesce(result->>'id',req::text),action,reason,result,p_input
  );

  insert into public.admission_command_keys(request_id,actor_id,payload,result)
  values(req,actor,p_input,result);

  return result;
end;
$function$;

CREATE OR REPLACE FUNCTION public.advance_paid(p_advance_id uuid)
 RETURNS numeric
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(sum(amount),0)
  from public.finance_advance_movements
  where advance_id=p_advance_id and movement_type='PAYMENT';
$function$;

CREATE OR REPLACE FUNCTION public.finance_read_account_balance(p_account_id uuid, p_as_of date DEFAULT CURRENT_DATE)
 RETURNS numeric
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null or not public.has_permission('accounting.view') then
    raise exception 'Accounting view permission required.';
  end if;
  if p_account_id is null or p_as_of is null or not exists(
    select 1 from public.finance_accounts where id=p_account_id and is_active
  ) then raise exception 'Choose an active financial account and date.'; end if;
  return coalesce(public.finance_account_balance(p_account_id,p_as_of),0);
end $function$;

CREATE OR REPLACE FUNCTION public.referral_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 actor uuid:=auth.uid();
 action text:=p_input->>'action';
 req uuid:=nullif(p_input->>'request_id','')::uuid;
 reason text:=btrim(coalesce(p_input->>'reason',''));
 k public.admission_command_keys;
 a public.admission_cases;
 person public.referral_people;
 referral public.admission_referrals;
 award public.referral_bonus_awards;
 policy public.business_rule_versions;
 org uuid;
 first_month date;
 collected numeric;
 rate numeric;
 amount numeric;
 payable public.finance_payables;
 result jsonb;
begin
 if actor is null or req is null or length(reason)<5 then raise exception 'Sign in and provide a request ID and reason.'; end if;
 if action='CAPTURE' and not public.has_permission('admissions.create') or
    action='AWARD_BONUS' and not public.has_permission('staff.compensation.manage') or
    action not in('CAPTURE','AWARD_BONUS') then
   raise exception 'Permission denied for this referral action.';
 end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,7));
 select * into k from public.admission_command_keys where request_id=req;
 if found then
  if k.actor_id<>actor or k.payload<>p_input then raise exception 'Request identity already used for different input.'; end if;
  return k.result;
 end if;
 if action='CAPTURE' then
  select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
  if a.id is null or a.status='CANCELLED'
    or (a.status not in('DRAFT','READY') and exists(
      select 1 from public.admission_referrals prior where prior.admission_id=a.id
    )) then
   raise exception 'A referral can be added to an accepted case only when no source is already on file.'; end if;
  select id into org from public.organizations where is_active;
  if p_input->>'source'='ORGANIC' then
   insert into public.admission_referrals(admission_id,source,referrer_id,captured_by,reason)
   values(a.id,'ORGANIC',null,actor,reason)
   on conflict(admission_id) do update set source='ORGANIC',referrer_id=null,captured_by=actor,captured_at=now(),reason=excluded.reason;
   delete from public.teacher_referrals where admission_id=a.id;
  elsif p_input->>'source'='REFERRED' then
   if nullif(p_input->>'staff_id','') is not null then
    if not exists(select 1 from public.staff where id=(p_input->>'staff_id')::uuid and status='ACTIVE') then
      raise exception 'Choose an active staff member.'; end if;
    insert into public.referral_people(organization_id,staff_id,full_name,mobile,created_by)
      select org,id,full_name,null,actor from public.staff where id=(p_input->>'staff_id')::uuid
    on conflict(staff_id) do update set full_name=excluded.full_name
    returning * into person;
   elsif nullif(p_input->>'referrer_id','') is not null then
    select * into person from public.referral_people
     where id=(p_input->>'referrer_id')::uuid and organization_id=org;
    if person.id is null then raise exception 'Choose an existing referrer.'; end if;
   else
    if length(btrim(coalesce(p_input->>'full_name','')))<2 or
       coalesce(p_input->>'mobile','') !~ '^01[3-9][0-9]{8}$' then
      raise exception 'Enter the new referrer name and an 11-digit Bangladesh mobile.';
    end if;
    insert into public.referral_people(organization_id,staff_id,full_name,mobile,relationship_note,contact_note,created_by)
    values(org,null,btrim(p_input->>'full_name'),p_input->>'mobile',
      nullif(btrim(p_input->>'relationship_note'),''),nullif(btrim(p_input->>'contact_note'),''),actor)
    on conflict(organization_id,mobile) do update set
      full_name=public.referral_people.full_name
    returning * into person;
    if lower(btrim(person.full_name))<>lower(btrim(p_input->>'full_name')) then
      raise exception 'A different referrer already uses this mobile. Select the existing record or verify identity.';
    end if;
   end if;
   insert into public.admission_referrals(admission_id,source,referrer_id,captured_by,reason)
   values(a.id,'REFERRED',person.id,actor,reason)
   on conflict(admission_id) do update set source='REFERRED',referrer_id=excluded.referrer_id,
      captured_by=actor,captured_at=now(),reason=excluded.reason;
   if person.staff_id is not null and exists(select 1 from public.staff_role_assignments sra
      join public.staff_roles sr on sr.id=sra.staff_role_id
      where sra.staff_id=person.staff_id and sr.is_teaching_role) then
     insert into public.teacher_referrals(admission_id,teacher_id,captured_by,reason)
     values(a.id,person.staff_id,actor,reason)
     on conflict(admission_id) do update set teacher_id=excluded.teacher_id,captured_by=actor,captured_at=now(),reason=excluded.reason;
   else
     delete from public.teacher_referrals where admission_id=a.id;
   end if;
  else raise exception 'Select an existing or new referrer, or Organic.'; end if;
  result:=jsonb_build_object('id',a.id,'message','Admission referral choice saved.');
 elsif action='AWARD_BONUS' then
  select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
  select * into referral from public.admission_referrals where admission_id=a.id;
  select * into person from public.referral_people where id=referral.referrer_id;
  if a.id is null or a.status<>'ACTIVE_ENROLLMENT' or referral.source<>'REFERRED'
    or person.id is null or person.staff_id is not null then
    raise exception 'Choose an active admission with an external referrer.'; end if;
  if exists(select 1 from public.referral_bonus_awards where admission_id=a.id and status in('PENDING','APPROVED')) then
   raise exception 'The referral reward is already requested or approved.'; end if;
  select min(n.billing_period) into first_month from public.finance_net_collected_tuition(date '2000-01-01',current_date) n
   where n.admission_id=a.id and n.tuition_collected>0;
  if first_month is null then raise exception 'No posted tuition collection qualifies for an acquisition reward.'; end if;
  select coalesce(sum(n.tuition_collected),0) into collected from public.finance_net_collected_tuition(first_month,(first_month+interval '1 month - 1 day')::date) n
   where n.admission_id=a.id;
  if collected<=0 then raise exception 'First-month net collected tuition is not positive.'; end if;
  select * into policy from public.business_rule_versions where domain='teacher_compensation'
   and rule_key='default_policy' and status='ACTIVE' order by version desc limit 1;
  if policy.id is null or not public.validate_business_rule_payload('teacher_compensation','default_policy',policy.payload) then
   raise exception 'Configure a valid acquisition compensation policy first.'; end if;
  rate:=(policy.payload->>'acquisition_bonus_percent')::numeric;
  amount:=round(collected*rate/100,2);
  if amount<=0 then raise exception 'The reward would be zero under the current policy.'; end if;
  select id into org from public.organizations where is_active;
  insert into public.referral_bonus_awards(admission_id,referrer_id,period_start,net_collected,policy_version_id,
    bonus_percent,amount,requested_by,status,reviewed_by,reviewed_at)
  values(a.id,person.id,first_month,collected,policy.id,rate,amount,actor,'APPROVED',actor,now()) returning * into award;
  insert into public.finance_payables(organization_id,payable_type,referrer_id,source_type,source_id,payable_account_id,original_amount,due_on,created_by)
  values(org,'OTHER',person.id,'REFERRAL_BONUS',a.id::text,
    (select id from public.finance_accounts where organization_id=org and code='2130'),amount,current_date,actor) returning * into payable;
  perform public.finance_post_journal(org,current_date,'COMPENSATION_RUN','REFERRAL_BONUS',award.id::text,
    reason,actor,jsonb_build_array(
      jsonb_build_object('account_id',(select id from public.finance_accounts where organization_id=org and code='5200'),'debit',amount,'credit',0),
      jsonb_build_object('account_id',payable.payable_account_id,'debit',0,'credit',amount)));
  update public.referral_bonus_awards set payable_id=payable.id where id=award.id;
  result:=jsonb_build_object('id',award.id,'message','Referral reward calculated and posted to payable.');
 end if;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,after_data,metadata)
 values(req,actor,'ADMISSION_REFERRAL',result->>'id',action,reason,result,jsonb_build_object('module','referrals'));
 insert into public.admission_command_keys(request_id,actor_id,payload,result)
 values(req,actor,p_input,result);
 return result;
end
$function$;

CREATE OR REPLACE FUNCTION public.finance_workspace()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null or not public.has_permission('finance.view') then raise exception 'Finance access denied.'; end if;
 return jsonb_build_object(
 'admissions',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'name',coalesce(s.full_name,a.identity_snapshot->>'student_name'),'number',a.admission_no,'status',a.status,'studentId',s.id,'studentNo',s.student_no,'mobile',a.identity_snapshot->>'mobile') order by a.created_at desc) from public.admission_cases a left join public.students s on s.id=a.student_id),'[]'::jsonb),
 'years',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name)) from public.academic_years),'[]'::jsonb),
 'terms',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name,'startsOn',starts_on,'endsOn',ends_on,'dueOn',due_on)) from public.billing_terms),'[]'::jsonb),
 'invoices',coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'admissionId',a.id,'name',a.identity_snapshot->>'student_name','number',i.invoice_no,'kind',i.invoice_kind,'period',i.billing_period,'dueOn',i.due_on,'currency',i.currency_code,'gross',b.gross,'credits',b.credits,'net',b.net,'paid',b.paid,'refunded',b.refunded,'due',b.due,'credit',b.credit_balance,'reserved',b.reserved_refunds,
 'lines',coalesce((select jsonb_agg(jsonb_build_object('name',name,'amount',amount)) from public.admission_invoice_lines where invoice_id=i.id),'[]'::jsonb)) order by i.posted_at desc) from public.admission_invoices i join public.admission_cases a on a.id=i.admission_id cross join lateral public.invoice_balance(i.id) b),'[]'::jsonb),
 'payments',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'invoiceId',pa.invoice_id,'number',p.receipt_no,'amount',p.amount,'postedAt',p.posted_at,'method',pm.name,'remaining',p.amount-coalesce((select sum(amount) from public.refund_authorizations where payment_id=p.id),0))) from public.admission_payments p join public.admission_payment_allocations pa on pa.payment_id=p.id join public.payment_methods pm on pm.id=p.payment_method_id),'[]'::jsonb),
 'discounts',coalesce((select jsonb_agg(jsonb_build_object('id',id,'admissionId',admission_id,'kind',kind,'value',value,'startsOn',starts_on,'endsOn',ends_on)) from public.admission_discounts),'[]'::jsonb),
 'refunds',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'invoiceId',r.invoice_id,'paymentId',r.payment_id,'amount',r.amount,'number',p.refund_no,'postedAt',p.posted_at,'method',pm.name,'reference',p.external_reference)) from public.refund_authorizations r left join public.refund_payouts p on p.authorization_id=r.id left join public.payment_methods pm on pm.id=p.payment_method_id),'[]'::jsonb),
 'runs',coalesce((select jsonb_agg(jsonb_build_object('id',id,'period',period,'count',invoice_count,'gross',gross_total,'postedAt',posted_at) order by posted_at desc) from public.billing_runs),'[]'::jsonb),
 'paymentMethods',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name)) from public.payment_methods where is_active),'[]'::jsonb)
 );
end;
$function$;

CREATE OR REPLACE FUNCTION public.apply_finance_adjustment(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid:=auth.uid();
  action text:=p_input->>'action';
  req uuid:=nullif(p_input->>'request_id','')::uuid;
  reason text:=btrim(coalesce(p_input->>'reason',''));
  key public.admission_command_keys;
  a public.admission_cases;
  i public.admission_invoices;
  payment public.admission_payments;
  discount public.admission_discounts;
  cancellation public.admission_cancellations;
  refund_auth public.refund_authorizations;
  payout public.refund_payouts;
  balance record;
  invoice_allocation numeric;
  reserved numeric;
  amount numeric;
  kind text;
  value numeric;
  start_date date;
  end_date date;
  settlement text;
  payment_method uuid;
  today date;
  before_data jsonb;
  after_data jsonb;
  result jsonb;
begin
  if actor is null then
    raise exception 'Sign in to continue.';
  end if;

  if req is null or length(reason)<5 then
    raise exception 'A request identity and reason are required.';
  end if;

  if action not in ('APPLY_DISCOUNT','CANCEL_ADMISSION','REFUND') then
    raise exception 'Unsupported finance adjustment.';
  end if;

  if action='APPLY_DISCOUNT' and not public.has_permission('finance.billing.manage') then
    raise exception 'Billing management permission required.';
  end if;

  if action='CANCEL_ADMISSION' and not public.has_permission('admissions.create') then
    raise exception 'Admission management permission required.';
  end if;

  if action='REFUND' and not public.has_permission('finance.payments.post') then
    raise exception 'Payment posting permission required.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(req::text,0));

  select * into key
  from public.admission_command_keys
  where request_id=req;

  if found then
    if key.actor_id<>actor or key.payload<>p_input then
      raise exception 'Request identity already used for different input.';
    end if;
    return key.result;
  end if;

  select * into a
  from public.admission_cases
  where id=nullif(p_input->>'admission_id','')::uuid
  for update;

  if action in ('APPLY_DISCOUNT','CANCEL_ADMISSION') and a.id is null then
    raise exception 'Admission not found.';
  end if;

  if a.id is not null then
    select (now() at time zone o.timezone)::date
    into today
    from public.batches b
    join public.organizations o on o.id=b.organization_id
    where b.id=a.batch_id;
  end if;

  if action='APPLY_DISCOUNT' then
    kind:=p_input->>'kind';
    value:=(p_input->>'value')::numeric;
    start_date:=(p_input->>'starts_on')::date;
    end_date:=(p_input->>'ends_on')::date;

    if a.status='CANCELLED'
      or kind not in ('PERCENT','FIXED')
      or value is null
      or value<=0
      or value<>round(value,2)
      or value>9999999999.99
      or (kind='PERCENT' and value>100)
      or start_date is null
      or end_date is null
      or end_date<start_date
    then
      raise exception 'Enter a valid discount and effective period.';
    end if;

    if exists(
      select 1
      from public.admission_discounts d
      where d.admission_id=a.id
        and daterange(d.starts_on,d.ends_on,'[]')
          && daterange(start_date,end_date,'[]')
    ) then
      raise exception 'Discount overlaps an existing discount. Use a non-overlapping period.';
    end if;

    before_data:=jsonb_build_object(
      'admission_id',a.id,
      'status',a.status
    );

    insert into public.admission_discounts(admission_id, authorized_by, authorization_reason, correlation_id, kind, value, starts_on, ends_on)
    values(a.id, actor, reason, req, kind, value, start_date, end_date)
    returning * into discount;

    for i in
      select *
      from public.admission_invoices
      where admission_id=a.id
        and billing_period between start_date and end_date
    loop
      perform public.apply_invoice_discounts(i.id);
    end loop;

    after_data:=jsonb_build_object(
      'discount_id',discount.id,
      'admission_id',a.id,
      'kind',discount.kind,
      'value',discount.value,
      'starts_on',discount.starts_on,
      'ends_on',discount.ends_on
    );

    result:=jsonb_build_object(
      'id',discount.id,
      'message','Discount applied and recorded.'
    );

    insert into public.audit_events(
      correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,metadata
    )
    values(
      req,actor,'ADMISSION_DISCOUNT',a.id::text,'APPLY_DISCOUNT',reason,
      before_data,after_data,jsonb_build_object('finance_flow','V3_DIRECT_ADMIN')
    );

  elsif action='CANCEL_ADMISSION' then
    settlement:=p_input->>'settlement';

    if a.status='CANCELLED'
      or settlement not in ('KEEP_CHARGES','CREDIT_ALL')
    then
      raise exception 'Choose a valid cancellation settlement for an open admission.';
    end if;

    if exists(
      select 1 from public.admission_cancellations
      where admission_id=a.id
    ) then
      raise exception 'Admission cancellation is already recorded.';
    end if;

    before_data:=jsonb_build_object(
      'admission_id',a.id,
      'status',a.status,
      'enrollment_id',a.enrollment_id
    );

    insert into public.admission_cancellations(admission_id, cancelled_by, cancellation_reason, correlation_id, settlement)
    values(a.id, actor, reason, req, settlement)
    returning * into cancellation;

    if settlement='CREDIT_ALL' then
      for i in
        select *
        from public.admission_invoices
        where admission_id=a.id
      loop
        select * into balance
        from public.invoice_balance(i.id);

        if balance.net>0 then
          insert into public.invoice_credits(invoice_id, kind, amount, applied_by)
          values(i.id, 'CANCELLATION', balance.net, actor)
          on conflict (invoice_id)
            where kind='CANCELLATION'
          do nothing;
        end if;
      end loop;
    end if;

    update public.admission_cases
    set status='CANCELLED'
    where id=a.id;

    update public.enrollments
    set status='WITHDRAWN',
        ended_on=today
    where id=a.enrollment_id
      and status='ACTIVE';

    if a.student_id is not null
      and not exists(
        select 1
        from public.enrollments
        where student_id=a.student_id
          and status='ACTIVE'
      )
    then
      update public.students
      set status='INACTIVE'
      where id=a.student_id;
    end if;

    after_data:=jsonb_build_object(
      'cancellation_id',cancellation.id,
      'admission_id',a.id,
      'status','CANCELLED',
      'settlement',settlement
    );

    result:=jsonb_build_object(
      'id',cancellation.id,
      'message','Admission cancelled and recorded.'
    );

    insert into public.audit_events(
      correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,metadata
    )
    values(
      req,actor,'ADMISSION_CANCELLATION',a.id::text,'CANCEL_ADMISSION',reason,
      before_data,after_data,jsonb_build_object('finance_flow','V3_DIRECT_ADMIN')
    );

  else
    select * into payment
    from public.admission_payments
    where id=nullif(p_input->>'payment_id','')::uuid
    for update;

    select * into i
    from public.admission_invoices
    where id=nullif(p_input->>'invoice_id','')::uuid
    for update;

    amount:=(p_input->>'amount')::numeric;
    payment_method:=nullif(p_input->>'payment_method_id','')::uuid;

    if payment.id is null or i.id is null then
      raise exception 'Payment or invoice not found.';
    end if;

    if not exists(
      select 1
      from public.admission_payment_allocations pa
      where pa.payment_id=payment.id
        and pa.invoice_id=i.id
    ) then
      raise exception 'The selected payment is not allocated to this invoice.';
    end if;

    select coalesce(sum(pa.amount),0)
    into invoice_allocation
    from public.admission_payment_allocations pa
    where pa.payment_id=payment.id
      and pa.invoice_id=i.id;

    select coalesce(sum(r.amount),0)
    into reserved
    from public.refund_authorizations r
    where r.payment_id=payment.id;

    select * into balance
    from public.invoice_balance(i.id);

    if amount is null
      or amount<=0
      or amount<>round(amount,2)
      or payment_method is null
      or amount>payment.amount-reserved
      or amount>invoice_allocation
      or amount>balance.credit_balance-balance.reserved_refunds
    then
      raise exception 'Refund exceeds the unreserved eligible credit for this payment and invoice.';
    end if;

    if not exists(
      select 1
      from public.payment_methods
      where id=payment_method
        and is_active
    ) then
      raise exception 'Choose an active refund payment method.';
    end if;

    before_data:=jsonb_build_object(
      'payment_id',payment.id,
      'invoice_id',i.id,
      'amount_received',payment.amount,
      'invoice_credit',balance.credit_balance
    );

    insert into public.refund_authorizations(payment_id, invoice_id, amount, authorized_by, authorization_reason, correlation_id)
    values(payment.id, i.id, amount, actor, reason, req)
    returning * into refund_auth;

    insert into public.refund_payouts(
      authorization_id,
      payment_method_id,
      external_reference,
      posted_by,
      reason
    )
    values(
      refund_auth.id,
      payment_method,
      nullif(btrim(coalesce(p_input->>'external_reference','')),''),
      actor,
      reason
    )
    returning * into payout;

    after_data:=jsonb_build_object(
      'refund_authorization_id',refund_auth.id,
      'refund_id',payout.id,
      'refund_no',payout.refund_no,
      'invoice_id',i.id,
      'payment_id',payment.id,
      'amount',amount
    );

    result:=jsonb_build_object(
      'id',payout.id,
      'refund_no',payout.refund_no,
      'message','Actual refund posted: '||payout.refund_no||'.'
    );

    insert into public.audit_events(
      correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,metadata
    )
    values(
      req,actor,'REFUND',payout.id::text,'POST_REFUND',reason,
      before_data,after_data,jsonb_build_object(
        'finance_flow','V3_DIRECT_ADMIN',
        'invoice_id',i.id,
        'payment_id',payment.id
      )
    );
  end if;

  insert into public.admission_command_keys(request_id,actor_id,payload,result)
  values(req,actor,p_input,result);

  return result;
end;
$function$;

CREATE OR REPLACE FUNCTION public.post_accounting_operation(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid:=auth.uid();
  action text:=p_input->>'action';
  req uuid:=nullif(p_input->>'request_id','')::uuid;
  reason text:=btrim(coalesce(p_input->>'reason',''));
  key public.admission_command_keys;
  org uuid;
  result jsonb;
  amount numeric;
  payment_account uuid;
  advance public.finance_advances;
  expense public.finance_expenses;
  category public.finance_expense_categories;
  payable public.finance_payables;
  compensation public.teacher_compensation_runs;
  policy public.business_rule_versions;
  preview jsonb;
  line jsonb;
  v_teacher_id uuid;
  teacher_total numeric;
  decision text;
  adjustment_id uuid;
begin
  if actor is null then
    raise exception 'Sign in to continue.';
  end if;

  if req is null or length(reason)<5 then
    raise exception 'A request identity and reason of at least five characters are required.';
  end if;

  if action not in (
    'CREATE_ADVANCE',
    'CREATE_EXPENSE_DIRECT',
    'RUN_COMPENSATION',
    'APPLY_COMP_ADJUSTMENT'
  ) then
    raise exception 'Unsupported V3 accounting action.';
  end if;

  if action='CREATE_ADVANCE'
    and not public.has_permission('finance.advances.manage') then
    raise exception 'Advance management permission required.';
  end if;

  if action='CREATE_EXPENSE_DIRECT'
    and not public.has_permission('accounting.expense.manage') then
    raise exception 'Expense management permission required.';
  end if;

  if action in ('RUN_COMPENSATION','APPLY_COMP_ADJUSTMENT')
    and not public.has_permission('staff.compensation.manage') then
    raise exception 'Teacher compensation management permission required.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(req::text,9));

  select * into key
  from public.admission_command_keys
  where request_id=req;

  if found then
    if key.actor_id<>actor or key.payload<>p_input then
      raise exception 'Request identity already used for different input.';
    end if;
    return key.result;
  end if;

  select id into org
  from public.organizations
  where is_active
  limit 1;

  if action='CREATE_ADVANCE' then
    if p_input->>'beneficiary_type' not in ('STAFF','VENDOR','PROJECT') then
      raise exception 'Choose staff, vendor or project as the advance beneficiary.';
    end if;

    amount:=(p_input->>'requested_amount')::numeric;

    if amount is null or amount<=0 or amount<>round(amount,2) then
      raise exception 'Advance amount must be a positive two-decimal amount.';
    end if;

    if p_input->>'beneficiary_type'='STAFF' and not exists(
      select 1 from public.staff
      where id=nullif(p_input->>'staff_id','')::uuid
        and organization_id=org
        and status='ACTIVE'
    ) then
      raise exception 'Choose an active staff member.';
    end if;

    if p_input->>'beneficiary_type'='VENDOR' and not exists(
      select 1 from public.vendors
      where id=nullif(p_input->>'vendor_id','')::uuid
        and organization_id=org
        and is_active
    ) then
      raise exception 'Choose an active vendor.';
    end if;

    if p_input->>'beneficiary_type'='PROJECT'
      and nullif(btrim(p_input->>'project_reference'),'') is null then
      raise exception 'Project reference is required for a project advance.';
    end if;

    if length(btrim(coalesce(p_input->>'purpose','')))<5 then
      raise exception 'Advance purpose must be at least five characters.';
    end if;

    insert into public.finance_advances(
      organization_id,
      beneficiary_type,
      staff_id,
      vendor_id,
      project_reference,
      purpose,
      requested_amount,
      approved_amount,
      expected_settlement_date,
      requested_by,
      authorized_by,
      authorization_reason,
      status
    )
    values(
      org,
      p_input->>'beneficiary_type',
      nullif(p_input->>'staff_id','')::uuid,
      nullif(p_input->>'vendor_id','')::uuid,
      nullif(btrim(p_input->>'project_reference'),''),
      btrim(p_input->>'purpose'),
      amount,
      amount,
      nullif(p_input->>'expected_settlement_date','')::date,
      actor,
      actor,
      reason,
      'APPROVED'
    )
    returning * into advance;

    result:=jsonb_build_object(
      'id',advance.id,
      'advanceNo',advance.advance_no,
      'message','Advance authorized and recorded.'
    );

    insert into public.audit_events(
      correlation_id,
      actor_profile_id,
      actor_staff_id,
      entity_type,
      entity_id,
      action,
      reason,
      after_data,
      metadata
    )
    values(
      req,
      actor,
      (select id from public.staff where profile_id=actor limit 1),
      'FINANCE_ADVANCE',
      advance.id::text,
      'CREATE_ADVANCE',
      reason,
      jsonb_build_object(
        'advance_no',advance.advance_no,
        'beneficiary_type',advance.beneficiary_type,
        'requested_amount',advance.requested_amount,
        'approved_amount',advance.approved_amount,
        'status',advance.status
      ),
      jsonb_build_object('finance_flow','V3_DIRECT_ADMIN')
    );

  elsif action='CREATE_EXPENSE_DIRECT' then
    amount:=(p_input->>'amount')::numeric;

    if amount is null or amount<=0 or amount<>round(amount,2) then
      raise exception 'Expense amount must be a positive two-decimal amount.';
    end if;

    select * into category
    from public.finance_expense_categories
    where id=nullif(p_input->>'category_id','')::uuid
      and organization_id=org
      and is_active;

    if category.id is null then
      raise exception 'Choose an active expense category.';
    end if;

    if p_input->>'payment_mode' not in ('PAID_NOW','ON_ACCOUNT') then
      raise exception 'Choose whether the expense is paid now or payable later.';
    end if;

    if length(btrim(coalesce(p_input->>'description','')))<3 then
      raise exception 'Expense description is required.';
    end if;

    if p_input->>'payment_mode'='PAID_NOW' then
      select id into payment_account
      from public.finance_accounts
      where id=nullif(p_input->>'payment_account_id','')::uuid
        and organization_id=org
        and account_subtype in ('CASH','BANK','MOBILE_BANK')
        and is_active;

      if payment_account is null then
        raise exception 'Choose an active cash or bank account for a paid expense.';
      end if;
    else
      payment_account:=null;
    end if;

    insert into public.finance_expenses(organization_id, expense_date, category_id, expense_account_id, payment_mode, payment_account_id, vendor_id, staff_id, amount, description, receipt_reference, status, authorized_by, authorization_reason, submitted_by, posted_by, posted_at)
    values(org, coalesce(nullif(p_input->>'expense_date','')::date,current_date), category.id, category.expense_account_id, p_input->>'payment_mode', payment_account, nullif(p_input->>'vendor_id','')::uuid, nullif(p_input->>'staff_id','')::uuid, amount, btrim(p_input->>'description'), nullif(btrim(p_input->>'receipt_reference'),''), 'POSTED', actor, reason, actor, actor, now())
    returning * into expense;

    if expense.payment_mode='PAID_NOW' then
      perform public.finance_post_journal(
        org,
        expense.expense_date,
        'EXPENSE',
        'EXPENSE',
        expense.id::text,
        'Expense '||expense.expense_no,
        actor,
        jsonb_build_array(
          jsonb_build_object(
            'account_id',expense.expense_account_id,
            'debit',expense.amount,
            'credit',0,
            'memo',expense.description
          ),
          jsonb_build_object(
            'account_id',payment_account,
            'debit',0,
            'credit',expense.amount,
            'memo',coalesce(expense.receipt_reference,'Paid expense')
          )
        )
      );
    else
      insert into public.finance_payables(
        organization_id,
        payable_type,
        staff_id,
        vendor_id,
        source_type,
        source_id,
        payable_account_id,
        original_amount,
        due_on,
        created_by
      )
      values(
        org,
        case
          when expense.vendor_id is not null then 'VENDOR'
          when expense.staff_id is not null then 'STAFF_REIMBURSEMENT'
          else 'OTHER'
        end,
        expense.staff_id,
        expense.vendor_id,
        'EXPENSE',
        expense.id::text,
        case
          when expense.vendor_id is not null then
            (select id from public.finance_accounts where organization_id=org and account_subtype='VENDOR_PAYABLE' limit 1)
          else
            (select id from public.finance_accounts where organization_id=org and account_subtype='STAFF_PAYABLE' limit 1)
        end,
        expense.amount,
        expense.expense_date+30,
        actor
      )
      returning * into payable;

      update public.finance_expenses
      set payable_id=payable.id
      where id=expense.id;

      perform public.finance_post_journal(
        org,
        expense.expense_date,
        'EXPENSE',
        'EXPENSE',
        expense.id::text,
        'Expense payable '||expense.expense_no,
        actor,
        jsonb_build_array(
          jsonb_build_object(
            'account_id',expense.expense_account_id,
            'debit',expense.amount,
            'credit',0,
            'memo',expense.description
          ),
          jsonb_build_object(
            'account_id',payable.payable_account_id,
            'debit',0,
            'credit',expense.amount,
            'memo','Payable for expense '||expense.expense_no
          )
        )
      );
    end if;

    result:=jsonb_build_object(
      'id',expense.id,
      'expenseNo',expense.expense_no,
      'message','Expense posted to the ledger.'
    );

    insert into public.audit_events(
      correlation_id,
      actor_profile_id,
      actor_staff_id,
      entity_type,
      entity_id,
      action,
      reason,
      after_data,
      metadata
    )
    values(
      req,
      actor,
      (select id from public.staff where profile_id=actor limit 1),
      'FINANCE_EXPENSE',
      expense.id::text,
      'CREATE_EXPENSE_DIRECT',
      reason,
      jsonb_build_object(
        'expense_no',expense.expense_no,
        'amount',expense.amount,
        'payment_mode',expense.payment_mode,
        'status',expense.status
      ),
      jsonb_build_object('finance_flow','V3_DIRECT_ADMIN')
    );

  elsif action='RUN_COMPENSATION' then
    preview:=public.teacher_compensation_preview(
      (p_input->>'period_start')::date,
      (p_input->>'period_end')::date
    );

    if jsonb_array_length(preview->'rows')=0 then
      raise exception 'No eligible compensation lines for this period.';
    end if;

    select * into policy
    from public.business_rule_versions
    where domain='teacher_compensation'
      and rule_key='default_policy'
      and status='ACTIVE'
    order by version desc
    limit 1;

    if policy.id is null then
      raise exception 'No active teacher compensation policy is configured.';
    end if;

    insert into public.teacher_compensation_runs(
      organization_id,
      period_start,
      period_end,
      policy_version_id,
      status,
      total_amount,
      submitted_by,
      approved_by,
      approved_at,
      authorized_by,
      authorization_reason
    )
    values(
      org,
      (p_input->>'period_start')::date,
      (p_input->>'period_end')::date,
      policy.id,
      'APPROVED',
      (preview->>'total')::numeric,
      actor,
      actor,
      now(),
      actor,
      reason
    )
    returning * into compensation;

    for line in
      select value
      from jsonb_array_elements(preview->'rows')
    loop
      insert into public.teacher_compensation_lines(
        run_id,
        teacher_id,
        admission_id,
        line_type,
        source_type,
        source_id,
        amount,
        calculation
      )
      values(
        compensation.id,
        (line->>'teacherId')::uuid,
        nullif(line->>'admissionId','')::uuid,
        line->>'lineType',
        line->>'sourceType',
        line->>'sourceId',
        (line->>'amount')::numeric,
        coalesce(line->'calculation','{}'::jsonb)
      )
      on conflict(run_id,source_type,source_id) do nothing;
    end loop;

    for v_teacher_id in
      select distinct l.teacher_id
      from public.teacher_compensation_lines l
      where l.run_id=compensation.id
    loop
      select coalesce(sum(l.amount),0)
      into teacher_total
      from public.teacher_compensation_lines l
      where l.run_id=compensation.id
        and l.teacher_id=v_teacher_id;

      if teacher_total>0 then
        insert into public.finance_payables(
          organization_id,
          payable_type,
          staff_id,
          source_type,
          source_id,
          payable_account_id,
          original_amount,
          due_on,
          created_by
        )
        values(
          org,
          'TEACHER_COMPENSATION',
          v_teacher_id,
          'COMPENSATION_RUN',
          compensation.id::text||':'||v_teacher_id::text,
          (
            select id
            from public.finance_accounts
            where organization_id=org
              and account_subtype='TEACHER_PAYABLE'
            limit 1
          ),
          teacher_total,
          compensation.period_end,
          actor
        )
        on conflict(source_type,source_id) do nothing;
      end if;
    end loop;

    perform public.finance_post_journal(
      org,
      compensation.period_end,
      'COMPENSATION_RUN',
      'COMPENSATION_RUN',
      compensation.id::text,
      'Teacher compensation run '||compensation.run_no,
      actor,
      (
        select jsonb_build_array(
          jsonb_build_object(
            'account_id',(
              select id
              from public.finance_accounts
              where organization_id=org
                and account_subtype='TEACHING_COMPENSATION'
              limit 1
            ),
            'debit',compensation.total_amount,
            'credit',0,
            'memo','Teaching compensation expense'
          )
        ) ||
        coalesce((
          select jsonb_agg(
            jsonb_build_object(
              'account_id',(
                select id
                from public.finance_accounts
                where organization_id=org
                  and account_subtype='TEACHER_PAYABLE'
                limit 1
              ),
              'debit',0,
              'credit',sum(l.amount),
              'memo','Payable for teacher '||l.teacher_id::text
            )
          )
          from public.teacher_compensation_lines l
          where l.run_id=compensation.id
          group by l.teacher_id
        ),'[]'::jsonb)
      )
    );

    result:=jsonb_build_object(
      'id',compensation.id,
      'runNo',compensation.run_no,
      'message','Teacher compensation run approved and posted.',
      'total',compensation.total_amount
    );

    insert into public.audit_events(
      correlation_id,
      actor_profile_id,
      actor_staff_id,
      entity_type,
      entity_id,
      action,
      reason,
      after_data,
      metadata
    )
    values(
      req,
      actor,
      (select id from public.staff where profile_id=actor limit 1),
      'TEACHER_COMPENSATION_RUN',
      compensation.id::text,
      'RUN_COMPENSATION',
      reason,
      jsonb_build_object(
        'run_no',compensation.run_no,
        'status',compensation.status,
        'total_amount',compensation.total_amount
      ),
      jsonb_build_object('finance_flow','V3_DIRECT_ADMIN')
    );

  else
    if not exists(
      select 1
      from public.staff
      where id=nullif(p_input->>'teacher_id','')::uuid
        and status='ACTIVE'
    ) then
      raise exception 'Choose an active teacher.';
    end if;

    amount:=(p_input->>'amount')::numeric;

    if amount is null or amount<=0 or amount<>round(amount,2) then
      raise exception 'Adjustment amount must be a positive two-decimal amount.';
    end if;

    if (p_input->>'effective_period')::date is null then
      raise exception 'Choose an effective period.';
    end if;

    insert into public.teacher_compensation_adjustments(teacher_id, amount, adjustment_type, effective_period, reason, authorized_by, authorization_reason, status, requested_by, approved_by, approved_at)
    values((p_input->>'teacher_id')::uuid, amount, coalesce(p_input->>'adjustment_type','ADJUSTMENT'), (p_input->>'effective_period')::date, reason, actor, reason, 'APPROVED', actor, actor, now())
    returning id into adjustment_id;

    result:=jsonb_build_object(
      'id',adjustment_id,
      'message','Teacher compensation adjustment authorized and recorded.'
    );

    insert into public.audit_events(
      correlation_id,
      actor_profile_id,
      actor_staff_id,
      entity_type,
      entity_id,
      action,
      reason,
      after_data,
      metadata
    )
    values(
      req,
      actor,
      (select id from public.staff where profile_id=actor limit 1),
      'TEACHER_COMPENSATION_ADJUSTMENT',
      adjustment_id::text,
      'APPLY_COMP_ADJUSTMENT',
      reason,
      jsonb_build_object(
        'teacher_id',(p_input->>'teacher_id')::uuid,
        'amount',amount,
        'effective_period',(p_input->>'effective_period')::date,
        'status','APPROVED'
      ),
      jsonb_build_object('finance_flow','V3_DIRECT_ADMIN')
    );
  end if;

  insert into public.admission_command_keys(
    request_id,actor_id,payload,result
  )
  values(req,actor,p_input,result);

  return result;
end;
$function$;

-- Upstream 11_teacher_workflows.sql
-- Sohoj Academy fresh database baseline: teacher workflows.
-- Install on an empty application schema. Each object is defined once.

CREATE OR REPLACE FUNCTION public.enforce_staff_subject_teaching_role()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if not exists (
    select 1
    from public.staff_role_assignments sra
    join public.staff_roles sr on sr.id=sra.staff_role_id
    where sra.staff_id=new.staff_id
      and sr.is_teaching_role
      and sra.effective_from<=current_date
      and (sra.effective_to is null or sra.effective_to>=current_date)
  ) then
    raise exception 'Teaching subjects can only be assigned to staff with an active teaching role.';
  end if;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.can_access_class_session(p_session uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select auth.uid() is not null and public.has_permission('academics.view') and exists(select 1 from public.class_sessions cs join public.staff st on st.id=cs.teacher_id where cs.id=p_session and (public.has_permission('academics.sessions.manage') or public.has_permission('academics.attendance.approve') or st.profile_id=auth.uid()));
$function$;

CREATE OR REPLACE FUNCTION public.academic_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 actor uuid:=auth.uid();req uuid:=(p_input->>'request_id')::uuid;action text:=p_input->>'action';reason text:=btrim(coalesce(p_input->>'reason',''));key public.admission_command_keys;
 b public.batches;room public.academic_rooms;r public.academic_routines;cs public.class_sessions;cv public.curriculum_versions;teacher public.staff;year public.academic_years;
 att public.attendance_submissions;last_att public.attendance_submissions;approval public.approval_requests;
 sid uuid;rid uuid;bid uuid;subid uuid;tid uuid;roomid uuid;date_from date;date_to date;day date;st time;et time;tz text;start_at timestamptz;end_at timestamptz;
 rows jsonb;roster jsonb;entry jsonb;unit jsonb;result jsonb;created integer:=0;permission text;scope text;id_out uuid;
begin
 if actor is null or not public.has_permission('academics.view') then raise exception 'Academic access required.';end if;
 if req is null or length(reason)<5 or length(reason)>500 then raise exception 'A request identity and reason of 5–500 characters are required.';end if;
 permission:=case action when 'CREATE_ROOM' then 'academics.sessions.manage' when 'PUBLISH_CURRICULUM' then 'academics.curriculum.manage' when 'CREATE_ROUTINE' then 'academics.sessions.manage' when 'RETIRE_ROUTINE' then 'academics.sessions.manage' when 'GENERATE_SESSIONS' then 'academics.sessions.manage' when 'CREATE_SESSION' then 'academics.sessions.manage' when 'CANCEL_SESSION' then 'academics.sessions.manage' when 'SAVE_ATTENDANCE' then 'academics.attendance.record' when 'SUBMIT_ATTENDANCE' then 'academics.attendance.record' when 'DECIDE_ATTENDANCE' then 'academics.attendance.approve' else null end;
 if permission is null or not public.has_permission(permission) then raise exception 'Permission denied for this academic action.';end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into key from public.admission_command_keys where request_id=req;
 if found then if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity already used for different input.';end if;return key.result;end if;
 -- Serialize schedule conflict checks and attendance/session-state transitions.
 perform pg_advisory_xact_lock(hashtextextended('sohoj-academic-operations',20));
 if action='CREATE_ROOM' then
  if not exists(select 1 from public.branches where id=(p_input->>'branch_id')::uuid and is_active) then raise exception 'Choose an active branch.';end if;
  insert into public.academic_rooms(branch_id,name,capacity,created_by) values((p_input->>'branch_id')::uuid,btrim(p_input->>'name'),(p_input->>'capacity')::integer,actor) returning id into id_out;
  result:=jsonb_build_object('id',id_out,'message','Room created.');
 elsif action='PUBLISH_CURRICULUM' then
  select * into b from public.batches where id=(p_input->>'batch_id')::uuid and is_active;
  select * into year from public.academic_years where id=b.academic_year_id;
  if b.id is null or not exists(select 1 from public.subjects where id=(p_input->>'subject_id')::uuid and organization_id=b.organization_id and is_active) then raise exception 'Choose an active batch and subject in the same organization.';end if;
  rows:=p_input->'units';
  if length(btrim(coalesce(p_input->>'title','')))<2 or rows is null or jsonb_typeof(rows)<>'array' then raise exception 'A title and curriculum units are required.';end if;
  if jsonb_array_length(rows)=0 then raise exception 'Add at least one curriculum unit.';end if;
  for unit in select x from jsonb_array_elements(rows) x loop
   if length(btrim(coalesce(unit->>'title','')))<2 or (unit->>'target_date')::date is null or (unit->>'target_date')::date not between year.starts_on and year.ends_on then raise exception 'Each unit needs a title and target date inside the academic year.';end if;
  end loop;
  insert into public.curriculum_versions(batch_id,subject_id,version,title,units,reason,published_by)
  select b.id,(p_input->>'subject_id')::uuid,coalesce(max(v.version),0)+1,btrim(p_input->>'title'),rows,btrim(p_input->>'reason'),actor from public.curriculum_versions v where v.batch_id=b.id and v.subject_id=(p_input->>'subject_id')::uuid returning id into id_out;
  result:=jsonb_build_object('id',id_out,'message','Curriculum version published. Earlier versions and session references are preserved.');
 elsif action in('CREATE_ROUTINE','GENERATE_SESSIONS','CREATE_SESSION') then
  if action='GENERATE_SESSIONS' then
   select * into r from public.academic_routines where id=(p_input->>'routine_id')::uuid and retired_at is null;
   if r.id is null then raise exception 'Active routine not found.';end if;
   bid:=r.batch_id;subid:=r.subject_id;tid:=r.teacher_id;roomid:=r.room_id;st:=r.start_time;et:=r.end_time;
   date_from:=(p_input->>'starts_on')::date;date_to:=(p_input->>'ends_on')::date;
   if date_from<r.starts_on or date_to>r.ends_on then raise exception 'Generation dates must stay inside the routine period.';end if;
  else
   bid:=(p_input->>'batch_id')::uuid;subid:=(p_input->>'subject_id')::uuid;tid:=(p_input->>'teacher_id')::uuid;roomid:=(p_input->>'room_id')::uuid;
   st:=(p_input->>'start_time')::time;et:=(p_input->>'end_time')::time;
   date_from:=(p_input->>'starts_on')::date;date_to:=case when action='CREATE_SESSION' then date_from else (p_input->>'ends_on')::date end;
  end if;
  select * into b from public.batches where id=bid and is_active for update;
  select * into room from public.academic_rooms where id=roomid;
  select * into teacher from public.staff where id=tid and status='ACTIVE';
  select * into year from public.academic_years where id=b.academic_year_id;
  select timezone into tz from public.organizations where id=b.organization_id;
  if b.id is null or b.offering_id is null or room.id is null or room.branch_id is distinct from b.branch_id or teacher.id is null then raise exception 'Choose an active batch, active teacher and room in the batch branch.';end if;
  if teacher.branch_id is not null and teacher.branch_id<>b.branch_id then raise exception 'Teacher belongs to a different branch.';end if;
  if room.capacity<b.capacity then raise exception 'Room capacity is below the configured batch capacity.';end if;
  if not exists(select 1 from public.subjects where id=subid and organization_id=b.organization_id and is_active) then raise exception 'Subject is unavailable for this organization.';end if;
  if date_from is null or date_to is null or date_to<date_from or date_from<year.starts_on or date_to>year.ends_on or st is null or et is null or et<=st then raise exception 'Enter valid same-day class times and dates inside the academic year.';end if;
  if not exists(select 1 from public.staff_subject_assignments where staff_id=tid and subject_id=subid and effective_from<=date_from and (effective_to is null or effective_to>=date_to)) or not exists(select 1 from public.staff_role_assignments a join public.staff_roles sr on sr.id=a.staff_role_id where a.staff_id=tid and sr.is_teaching_role and a.effective_from<=date_from and (a.effective_to is null or a.effective_to>=date_to)) then raise exception 'Teacher must have a teaching role and subject qualification covering these dates.';end if;
  if action='CREATE_ROUTINE' then
   if (p_input->>'weekday')::integer is null or (p_input->>'weekday')::integer not between 0 and 6 then raise exception 'Choose a weekday.';end if;
   if exists(select 1 from public.academic_routines x where x.retired_at is null and x.weekday=(p_input->>'weekday')::integer and x.starts_on<=date_to and x.ends_on>=date_from and x.start_time<et and x.end_time>st and (x.batch_id=bid or x.teacher_id=tid or x.room_id=roomid)) then raise exception 'Routine conflicts with an existing teacher, batch or room assignment.';end if;
   if exists(select 1 from public.class_sessions x where x.status='SCHEDULED' and x.session_date between date_from and date_to and extract(dow from x.session_date)=(p_input->>'weekday')::integer and (x.starts_at at time zone tz)::time<et and (x.ends_at at time zone tz)::time>st and (x.batch_id=bid or x.teacher_id=tid or x.room_id=roomid)) then raise exception 'Routine conflicts with an existing dated session.';end if;
   insert into public.academic_routines(batch_id,subject_id,teacher_id,room_id,weekday,start_time,end_time,starts_on,ends_on,created_by)
   values(bid,subid,tid,roomid,(p_input->>'weekday')::integer,st,et,date_from,date_to,actor) returning id into id_out;
   result:=jsonb_build_object('id',id_out,'message','Routine created. Generate dated sessions to make classes operational.');
  else
   if date_to-date_from>93 then raise exception 'Generate at most 94 days per request; split larger jobs.';end if;
   scope:=btrim(coalesce(p_input->>'planned_scope',''));
   if length(scope)<2 then raise exception 'Describe the planned scope for these classes.';end if;
   if nullif(p_input->>'curriculum_id','') is not null then
    select * into cv from public.curriculum_versions where id=(p_input->>'curriculum_id')::uuid and batch_id=bid and subject_id=subid;
    if cv.id is null then raise exception 'Curriculum version must match the session batch and subject.';end if;
   end if;
   for day in select d::date from generate_series(date_from::timestamp,date_to::timestamp,interval '1 day') d loop
    if action='GENERATE_SESSIONS' and extract(dow from day)<>r.weekday then continue;end if;
    if action='GENERATE_SESSIONS' and exists(select 1 from public.class_sessions where routine_id=r.id and session_date=day) then continue;end if;
    start_at:=(day+st) at time zone tz;end_at:=(day+et) at time zone tz;
    if exists(select 1 from public.class_sessions x where x.status='SCHEDULED' and x.starts_at<end_at and x.ends_at>start_at and (x.batch_id=bid or x.teacher_id=tid or x.room_id=roomid)) then raise exception 'Session conflict on %: teacher, batch or room is occupied. Nothing was posted.',day;end if;
    if exists(select 1 from public.academic_routines x where x.retired_at is null and x.id is distinct from r.id and x.weekday=extract(dow from day) and day between x.starts_on and x.ends_on and x.start_time<et and x.end_time>st and (x.batch_id=bid or x.teacher_id=tid or x.room_id=roomid)) then raise exception 'Session conflicts with a reserved routine on %.',day;end if;
    insert into public.class_sessions(routine_id,batch_id,subject_id,teacher_id,room_id,curriculum_version_id,planned_scope,session_date,starts_at,ends_at,created_by)
    values(r.id,bid,subid,tid,roomid,cv.id,scope,day,start_at,end_at,actor) returning id into id_out;
    created:=created+1;
   end loop;
   result:=jsonb_build_object('id',coalesce(id_out,r.id),'message',created||' dated sessions created. Existing routine dates were preserved.');
  end if;
 elsif action='RETIRE_ROUTINE' then
  update public.academic_routines set retired_at=now() where id=(p_input->>'routine_id')::uuid and retired_at is null returning id into id_out;
  if id_out is null then raise exception 'Active routine not found.';end if;
  result:=jsonb_build_object('id',id_out,'message','Routine retired. Existing dated sessions remain; cancel affected occurrences explicitly.');
 else
  if action='DECIDE_ATTENDANCE' then
   select * into approval from public.approval_requests where id=(p_input->>'approval_id')::uuid and workflow_type='ATTENDANCE';
   if approval.id is null then raise exception 'Attendance approval not found.';end if;
   sid:=approval.entity_id::uuid;
  else sid:=(p_input->>'session_id')::uuid;end if;
  if not public.can_access_class_session(sid) then raise exception 'This class is outside your assigned scope.';end if;
  select * into cs from public.class_sessions where id=sid for update;
  select * into last_att from public.attendance_submissions where session_id=sid order by revision desc limit 1;
  if action='CANCEL_SESSION' then
   if cs.status='CANCELLED' then raise exception 'Session already cancelled.';end if;
   if exists(select 1 from public.attendance_submissions where session_id=sid and status in('SUBMITTED','APPROVED')) then raise exception 'A session with submitted or approved attendance cannot be cancelled.';end if;
   update public.class_sessions set status='CANCELLED',cancellation_reason=reason,cancelled_by=actor,cancelled_at=now() where id=sid;
   result:=jsonb_build_object('id',sid,'message','Session cancelled; the original schedule and reason remain in history.');
  elsif action='SAVE_ATTENDANCE' then
   if cs.status<>'SCHEDULED' or cs.starts_at>now() then raise exception 'Attendance can be recorded only after a scheduled class has started.';end if;
   if last_att.status='SUBMITTED' then raise exception 'Attendance is awaiting a decision.';end if;
   if last_att.id is distinct from nullif(p_input->>'base_id','')::uuid then raise exception 'Attendance changed. Refresh before saving a new revision.';end if;
   -- Lock placement while the first roster is snapshotted. Later revisions retain that roster.
   perform 1 from public.batches where id=cs.batch_id for update;
   if last_att.id is null then
    select coalesce(jsonb_agg(jsonb_build_object('student_id',s.id,'enrollment_id',e.id,'number',s.student_no,'name',s.full_name) order by s.student_no),'[]'::jsonb) into roster
    from public.enrollments e join public.students s on s.id=e.student_id where e.batch_id=cs.batch_id and e.admission_date<=cs.session_date and (e.ended_on is null or e.ended_on>cs.session_date) and e.status in('ACTIVE','WITHDRAWN','COMPLETED');
   else roster:=last_att.entries;end if;
   rows:=p_input->'entries';
   if rows is null or jsonb_typeof(rows)<>'array' then raise exception 'Attendance entries are required.';end if;
   if jsonb_array_length(roster)=0 or jsonb_array_length(rows)<>jsonb_array_length(roster) or (select count(distinct x->>'enrollment_id') from jsonb_array_elements(rows) x)<>jsonb_array_length(rows) then raise exception 'Record exactly one attendance status for every roster member. Refresh if the roster changed.';end if;
   for entry in select x from jsonb_array_elements(rows) x loop
    if coalesce(entry->>'status','') not in('PRESENT','ABSENT','LATE','EXCUSED') or not exists(select 1 from jsonb_array_elements(roster) x where x->>'enrollment_id'=entry->>'enrollment_id') or length(coalesce(entry->>'note',''))>500 then raise exception 'Invalid attendance status, note or roster member.';end if;
   end loop;
   select jsonb_agg(x||jsonb_build_object('status',y->>'status','note',coalesce(y->>'note','')) order by x->>'number') into rows from jsonb_array_elements(roster) x join jsonb_array_elements(rows) y on x->>'enrollment_id'=y->>'enrollment_id';
   insert into public.attendance_submissions(session_id,revision,entries,reason,recorded_by) values(sid,coalesce(last_att.revision,0)+1,rows,reason,actor) returning id into id_out;
   result:=jsonb_build_object('id',id_out,'message','Attendance draft saved. Submit it for independent approval.');
  elsif action='SUBMIT_ATTENDANCE' then
   if cs.status<>'SCHEDULED' or last_att.id is distinct from (p_input->>'attendance_id')::uuid or last_att.status<>'DRAFT' then raise exception 'Only the latest saved draft can be submitted.';end if;
   if last_att.recorded_by<>actor then raise exception 'Only the draft author may submit it. Save your own reviewed revision first.';end if;
   insert into public.approval_requests(workflow_type,entity_type,entity_id,requested_action,payload_snapshot,request_note,requested_by,correlation_id)
   values('ATTENDANCE','CLASS_SESSION',sid::text,action,jsonb_build_object('attendance_id',last_att.id,'revision',last_att.revision,'entries',last_att.entries),reason,actor,req) returning id into id_out;
   update public.attendance_submissions set status='SUBMITTED',approval_id=id_out where id=last_att.id;
   result:=jsonb_build_object('id',id_out,'message','Attendance submitted for independent approval.');
  elsif action='DECIDE_ATTENDANCE' then
   if approval.status<>'PENDING' then raise exception 'Attendance request already decided.';end if;
   select * into att from public.attendance_submissions where id=(approval.payload_snapshot->>'attendance_id')::uuid and status='SUBMITTED';
   if att.id is null then raise exception 'Submitted attendance not found.';end if;
   if actor=approval.requested_by or actor=att.recorded_by then raise exception 'Maker-checker: another authorized person must decide attendance.';end if;
   if p_input->>'decision' not in('APPROVED','REJECTED') or p_input->>'decision' is null then raise exception 'Choose Approve or Reject.';end if;
   update public.attendance_submissions set status=p_input->>'decision' where id=att.id;
   update public.approval_requests set status=(p_input->>'decision')::public.approval_status,decided_by=actor,decided_at=now(),decision_note=reason where id=approval.id;
   result:=jsonb_build_object('id',att.id,'message','Attendance '||lower(p_input->>'decision')||'. Prior approved revisions remain in history.');
  end if;
 end if;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,after_data,metadata)
 values(req,actor,'ACADEMIC_WORKFLOW',result->>'id',action,reason,result,p_input);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);
 return result;
end; $function$;

CREATE OR REPLACE FUNCTION public.protect_academic_record()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op='DELETE' then
    raise exception 'Academic history cannot be deleted.';
  end if;

  if tg_table_name='academic_routines' then
    if (to_jsonb(new)-'retired_at') is distinct from (to_jsonb(old)-'retired_at')
      or old.retired_at is not null
      or new.retired_at is null then
      raise exception 'Routine terms are immutable; retire and create a replacement.';
    end if;
  elsif tg_table_name='class_sessions' then
    if (to_jsonb(new)-array[
      'status','cancellation_reason','cancelled_by','cancelled_at'
    ]) is distinct from (to_jsonb(old)-array[
      'status','cancellation_reason','cancelled_by','cancelled_at'
    ])
      or old.status<>'SCHEDULED'
      or new.status<>'CANCELLED' then
      raise exception 'Session schedule is immutable; cancel and create a replacement occurrence.';
    end if;
  else
    if (to_jsonb(new)-array[
      'status','approval_id','reviewer_id','review_note','reviewed_at'
    ]) is distinct from (to_jsonb(old)-array[
      'status','approval_id','reviewer_id','review_note','reviewed_at'
    ]) then
      raise exception 'Attendance evidence is immutable; create a new revision.';
    end if;

    if old.status='DRAFT'
      and new.status='SUBMITTED'
      and new.approval_id is not null
      and new.reviewer_id is null
      and new.reviewed_at is null then
      return new;
    end if;

    if old.status='SUBMITTED'
      and new.status in ('APPROVED','REJECTED')
      and new.approval_id=old.approval_id
      and new.reviewer_id is not null
      and new.reviewed_at is not null
      and length(btrim(coalesce(new.review_note,'')))>=5 then
      if new.reviewer_id=old.recorded_by then
        raise exception 'The submitting teacher cannot review their own attendance.';
      end if;
      return new;
    end if;

    if old.status in ('APPROVED','REJECTED') then
      raise exception 'Reviewed attendance evidence is immutable; create a new revision.';
    end if;

    raise exception 'Attendance evidence transition is not allowed.';
  end if;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.academic_workspace(p_from date, p_to date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare manager boolean:=public.has_permission('academics.sessions.manage');curriculum_manager boolean:=public.has_permission('academics.curriculum.manage');begin
 if auth.uid() is null or not public.has_permission('academics.view') then raise exception 'Academic access required.';end if;
 if p_from is null or p_to is null or p_to<p_from or p_to-p_from>366 then raise exception 'Choose a date range of at most 367 days.';end if;
 return jsonb_build_object(
 'branches',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name)) from public.branches where is_active),'[]'::jsonb),
 'batches',case when manager or curriculum_manager then coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'name',b.name||' · '||y.name,'branchId',b.branch_id,'capacity',b.capacity)) from public.batches b join public.academic_years y on y.id=b.academic_year_id where b.is_active and b.offering_id is not null),'[]'::jsonb) else '[]'::jsonb end,
 'subjects',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name)) from public.subjects where is_active),'[]'::jsonb),
 'teachers',case when manager then coalesce((select jsonb_agg(jsonb_build_object('id',s.id,'name',s.full_name,'subjects',coalesce((select jsonb_agg(subject_id) from public.staff_subject_assignments where staff_id=s.id),'[]'::jsonb))) from public.staff s where s.status='ACTIVE' and exists(select 1 from public.staff_subject_assignments where staff_id=s.id)),'[]'::jsonb) else '[]'::jsonb end,
 'rooms',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name,'branchId',branch_id,'capacity',capacity)) from public.academic_rooms),'[]'::jsonb),
 'curricula',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'batchId',v.batch_id,'subjectId',v.subject_id,'batch',b.name,'subject',s.name,'version',v.version,'title',v.title,'units',v.units) order by v.published_at desc) from public.curriculum_versions v join public.batches b on b.id=v.batch_id join public.subjects s on s.id=v.subject_id where manager or curriculum_manager or exists(select 1 from public.class_sessions x where x.curriculum_version_id=v.id and public.can_access_class_session(x.id))),'[]'::jsonb),
 'routines',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'batchId',r.batch_id,'subjectId',r.subject_id,'batch',b.name,'subject',s.name,'teacher',t.full_name,'room',rm.name,'weekday',r.weekday,'startTime',r.start_time,'endTime',r.end_time,'startsOn',r.starts_on,'endsOn',r.ends_on,'retired',r.retired_at is not null)) from public.academic_routines r join public.batches b on b.id=r.batch_id join public.subjects s on s.id=r.subject_id join public.staff t on t.id=r.teacher_id join public.academic_rooms rm on rm.id=r.room_id where manager or t.profile_id=auth.uid()),'[]'::jsonb),
 'sessions',coalesce((select jsonb_agg(jsonb_build_object('id',x.id,'batch',b.name,'subject',s.name,'teacher',t.full_name,'room',rm.name,'date',x.session_date,'startTime',to_char(x.starts_at at time zone o.timezone,'HH24:MI'),'endTime',to_char(x.ends_at at time zone o.timezone,'HH24:MI'),'timezone',o.timezone,'status',x.status,'scope',x.planned_scope,'latestStatus',(select status from public.attendance_submissions where session_id=x.id order by revision desc limit 1),'approvedRevision',(select max(revision) from public.attendance_submissions where session_id=x.id and status='APPROVED')) order by x.starts_at) from public.class_sessions x join public.batches b on b.id=x.batch_id join public.organizations o on o.id=b.organization_id join public.subjects s on s.id=x.subject_id join public.staff t on t.id=x.teacher_id join public.academic_rooms rm on rm.id=x.room_id where x.session_date between p_from and p_to and public.can_access_class_session(x.id)),'[]'::jsonb)
 );
end; $function$;

CREATE OR REPLACE FUNCTION public.class_session_workspace(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare cs public.class_sessions;latest public.attendance_submissions;roster jsonb;begin
 if not public.can_access_class_session(p_session_id) then raise exception 'This class is outside your assigned scope.';end if;
 select * into cs from public.class_sessions where id=p_session_id;
 select * into latest from public.attendance_submissions where session_id=cs.id order by revision desc limit 1;
 if latest.id is null then
  select coalesce(jsonb_agg(jsonb_build_object('enrollment_id',e.id,'student_id',s.id,'number',s.student_no,'name',s.full_name) order by s.student_no),'[]'::jsonb) into roster from public.enrollments e join public.students s on s.id=e.student_id where e.batch_id=cs.batch_id and e.admission_date<=cs.session_date and (e.ended_on is null or e.ended_on>cs.session_date) and e.status in('ACTIVE','WITHDRAWN','COMPLETED');
 else roster:=latest.entries;end if;
 return jsonb_build_object(
 'session',(select jsonb_build_object('id',cs.id,'batch',b.name,'subject',s.name,'teacher',t.full_name,'teacherProfileId',t.profile_id,'room',r.name,'date',cs.session_date,'canRecordNow',cs.starts_at<=now(),'startsAt',cs.starts_at,'endsAt',cs.ends_at,'timezone',o.timezone,'status',cs.status,'scope',cs.planned_scope,'cancellationReason',cs.cancellation_reason,'curriculumTitle',v.title,'curriculumVersion',v.version,'units',coalesce(v.units,'[]'::jsonb)) from public.batches b join public.organizations o on o.id=b.organization_id cross join public.subjects s cross join public.staff t cross join public.academic_rooms r left join public.curriculum_versions v on v.id=cs.curriculum_version_id where b.id=cs.batch_id and s.id=cs.subject_id and t.id=cs.teacher_id and r.id=cs.room_id),
 'roster',roster,
 'submissions',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'revision',a.revision,'status',a.status,'entries',a.entries,'reason',a.reason,'recordedBy',a.recorded_by,'recorder',p.display_name,'createdAt',a.created_at,'approvalId',a.approval_id,'decisionNote',r.decision_note) order by a.revision desc) from public.attendance_submissions a join public.profiles p on p.id=a.recorded_by left join public.approval_requests r on r.id=a.approval_id where a.session_id=cs.id),'[]'::jsonb)
 );
end; $function$;

CREATE OR REPLACE FUNCTION public.guard_submitted_class_log()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if tg_op = 'DELETE' then
    raise exception 'Class-log history cannot be deleted.';
  end if;

  if old.status = 'DRAFT' then
    if new.status = 'DRAFT' then
      return new;
    end if;

    if new.status = 'SUBMITTED'
      and (to_jsonb(new) - array['status','submitted_at','reviewer_id','review_note','reviewed_at'])
          is distinct from
          (to_jsonb(old) - array['status','submitted_at','reviewer_id','review_note','reviewed_at']) then
      raise exception 'Submit the saved class-log draft without changing its contents.';
    end if;

    if new.status not in ('DRAFT','SUBMITTED') then
      raise exception 'A class-log draft must be submitted before review.';
    end if;

    return new;
  end if;

  if old.status = 'SUBMITTED' then
    if new.status not in ('APPROVED','REJECTED') then
      raise exception 'Submitted class-log evidence must be approved or rejected.';
    end if;

    if (to_jsonb(new) - array['status','reviewer_id','review_note','reviewed_at'])
       is distinct from
       (to_jsonb(old) - array['status','reviewer_id','review_note','reviewed_at']) then
      raise exception 'Submitted class-log evidence is immutable; create a new revision after rejection or approval.';
    end if;

    if new.reviewer_id is null or new.reviewed_at is null or length(btrim(coalesce(new.review_note,''))) < 5 then
      raise exception 'A class-log review requires a reviewer, time and review note.';
    end if;

    return new;
  end if;

  raise exception 'Finalized class-log evidence is immutable; create a new revision.';
end;
$function$;

CREATE OR REPLACE FUNCTION public.class_log_workspace(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare result jsonb;
begin
 if not public.can_access_class_session(p_session_id) then raise exception 'This class is outside your assigned scope.'; end if;
 select jsonb_build_object(
  'logs',coalesce((select jsonb_agg(to_jsonb(l) order by revision desc) from public.class_logs l where l.session_id=p_session_id),'[]'::jsonb),
  'units',coalesce((select cv.units from public.class_sessions cs join public.curriculum_versions cv on cv.id=cs.curriculum_version_id where cs.id=p_session_id),'[]'::jsonb)
 ) into result;
 return result;
end $function$;

CREATE OR REPLACE FUNCTION public.class_log_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid := auth.uid();
  rid uuid := nullif(p_input->>'request_id','')::uuid;
  sid uuid := nullif(p_input->>'session_id','')::uuid;
  act text := p_input->>'action';
  why text := trim(coalesce(p_input->>'reason',''));
  key public.admission_command_keys;
  cs public.class_sessions;
  latest public.class_logs;
  draft public.class_logs;
  review public.class_logs;
  progress jsonb := coalesce(p_input->'unit_progress','[]'::jsonb);
  unit_count integer;
  summary text := trim(coalesce(p_input->>'class_summary',''));
  unfinished text := trim(coalesce(p_input->>'unfinished_reason',''));
  homework_value text := trim(coalesce(p_input->>'homework',''));
  next_value text := trim(coalesce(p_input->>'next_session_plan',''));
  result jsonb;
  new_revision integer;
  branch uuid;
begin
  if actor is null or not public.has_permission('academics.view') then
    raise exception 'Academic access required.';
  end if;

  if rid is null or sid is null or length(why) < 5 or length(why) > 500 then
    raise exception 'Session, request identity and reason (5–500 characters) are required.';
  end if;

  if act = 'DECIDE' then
    if not public.has_permission('academics.attendance.approve') then
      raise exception 'Academic review permission required.';
    end if;
  elsif not (
    public.has_permission('academics.attendance.record')
    or public.has_permission('academics.sessions.manage')
  ) then
    raise exception 'Attendance recording permission required.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(rid::text,0));
  select * into key from public.admission_command_keys where request_id=rid;
  if found then
    if key.actor_id<>actor or key.payload<>p_input then
      raise exception 'Request identity already used for different input.';
    end if;
    return key.result;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(sid::text,21));

  select * into cs
  from public.class_sessions
  where id=sid
  for update;

  if cs.id is null then
    raise exception 'Class session not found.';
  end if;

  select branch_id
  into branch
  from public.batches
  where id=cs.batch_id;

  if act='DECIDE' then
    select *
    into review
    from public.class_logs
    where id=nullif(p_input->>'class_log_id','')::uuid
      and session_id=sid
      and status='SUBMITTED'
    for update;

    if review.id is null then
      raise exception 'No submitted class log is awaiting review.';
    end if;

    if review.authored_by=actor then
      raise exception 'The class-log author cannot approve or reject their own submission.';
    end if;

    if p_input->>'decision' not in ('APPROVED','REJECTED') then
      raise exception 'Choose Approve or Reject.';
    end if;

    if length(trim(coalesce(p_input->>'review_note',''))) < 5
      or length(trim(coalesce(p_input->>'review_note',''))) > 1000 then
      raise exception 'Enter a review note of 5–1000 characters.';
    end if;

    update public.class_logs
    set status=p_input->>'decision',
        reviewer_id=actor,
        review_note=trim(p_input->>'review_note'),
        reviewed_at=now()
    where id=review.id
    returning * into review;

    result:=jsonb_build_object(
      'id',review.id,
      'revision',review.revision,
      'status',review.status,
      'message',case when review.status='APPROVED'
        then 'Class log approved.'
        else 'Class log rejected. The teacher can prepare a corrected revision.'
      end
    );

  else
    if not public.can_access_class_session(sid) then
      raise exception 'This class is outside your assigned scope.';
    end if;

    if cs.status<>'SCHEDULED' then
      raise exception 'A cancelled class cannot receive a class log.';
    end if;

    if cs.starts_at>now() then
      raise exception 'Class log opens after the scheduled class starts.';
    end if;

    if not public.has_permission('academics.sessions.manage')
      and not exists(
        select 1
        from public.staff st
        where st.profile_id=actor and st.id=cs.teacher_id
      ) then
      raise exception 'Only the assigned teacher may record this class.';
    end if;

    select * into latest
    from public.class_logs
    where session_id=sid
    order by revision desc
    limit 1;

    select * into draft
    from public.class_logs
    where session_id=sid
      and status='DRAFT'
    for update;

    if act='SAVE_DRAFT' then
      if latest.status='SUBMITTED' then
        raise exception 'This class log is awaiting admin review. Correct it only after a review decision.';
      end if;

      if jsonb_typeof(progress)<>'array' or jsonb_array_length(progress)>200 then
        raise exception 'Check curriculum progress entries.';
      end if;

      select coalesce(jsonb_array_length(cv.units),0)
      into unit_count
      from public.class_sessions x
      left join public.curriculum_versions cv on cv.id=x.curriculum_version_id
      where x.id=sid;

      if jsonb_array_length(progress)>unit_count then
        raise exception 'Progress must refer only to the curriculum pinned to this class.';
      end if;

      if exists(
        select 1
        from jsonb_array_elements(progress) e
        where (e->>'unit_index')::integer<0
          or (e->>'unit_index')::integer>=unit_count
          or e->>'status' not in ('COVERED','PARTIAL','NOT_COVERED')
          or length(coalesce(e->>'note',''))>500
      ) then
        raise exception 'Invalid curriculum progress entry.';
      end if;

      if summary='' or length(summary)>4000
        or length(unfinished)>2000
        or length(homework_value)>2000
        or length(next_value)>2000 then
        raise exception 'Class summary is required; keep each field within its limit.';
      end if;

      if exists(
        select 1 from jsonb_array_elements(progress) e
        where e->>'status' in ('PARTIAL','NOT_COVERED')
      ) and unfinished='' then
        raise exception 'Explain any planned curriculum left incomplete.';
      end if;

      if draft.id is not null and draft.authored_by<>actor then
        raise exception 'Another staff member owns the current draft.';
      end if;

      if draft.id is null then
        select coalesce(max(revision),0)+1
        into new_revision
        from public.class_logs
        where session_id=sid;

        insert into public.class_logs(
          session_id,revision,previous_log_id,status,unit_progress,
          class_summary,unfinished_reason,homework,next_session_plan,
          reason,authored_by
        )
        values(
          sid,new_revision,latest.id,'DRAFT',progress,summary,
          unfinished,homework_value,next_value,why,actor
        )
        returning * into draft;
      else
        update public.class_logs
        set unit_progress=progress,
            class_summary=summary,
            unfinished_reason=unfinished,
            homework=homework_value,
            next_session_plan=next_value,
            reason=why
        where id=draft.id
        returning * into draft;
      end if;

      result:=jsonb_build_object(
        'id',draft.id,
        'revision',draft.revision,
        'status',draft.status,
        'message','Class-log draft saved.'
      );

    elsif act='SUBMIT' then
      if draft.id is null or draft.authored_by<>actor then
        raise exception 'Save your class-log draft before submitting it.';
      end if;

      update public.class_logs
      set status='SUBMITTED',
          submitted_at=now()
      where id=draft.id
      returning * into draft;

      result:=jsonb_build_object(
        'id',draft.id,
        'revision',draft.revision,
        'status',draft.status,
        'message','Class log submitted for admin review.'
      );

    else
      raise exception 'Unsupported class-log action.';
    end if;
  end if;

  insert into public.audit_events(
    actor_profile_id,
    branch_id,
    entity_type,
    entity_id,
    action,
    reason,
    before_data,
    after_data,
    metadata
  )
  values(
    actor,
    branch,
    'CLASS_LOG',
    coalesce(draft.id,review.id)::text,
    act,
    why,
    null,
    case when review.id is not null then to_jsonb(review) else to_jsonb(draft) end,
    jsonb_build_object('session_id',sid,'revision',coalesce(draft.revision,review.revision))
  );

  insert into public.admission_command_keys(request_id,actor_id,payload,result)
  values(rid,actor,p_input,result);

  return result;
end;
$function$;

CREATE OR REPLACE FUNCTION public.question_bank_workspace()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare actor uuid := auth.uid(); reviewer boolean;
begin
  if actor is null or not public.has_permission('academics.view') then raise exception 'Academic access required.'; end if;
  reviewer := public.has_permission('academics.assessments.approve');
  return jsonb_build_object(
    'batches', coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'name',b.name) order by b.name)
      from public.batches b where b.is_active and (reviewer or public.has_permission('academics.sessions.manage')
        or exists (select 1 from public.class_sessions cs join public.staff st on st.id=cs.teacher_id
          where cs.batch_id=b.id and st.profile_id=actor))), '[]'::jsonb),
    'subjects', coalesce((select jsonb_agg(jsonb_build_object('id',s.id,'name',s.name) order by s.name)
      from public.subjects s where s.is_active and (reviewer or public.has_permission('academics.sessions.manage')
        or exists (select 1 from public.staff_subject_assignments sa join public.staff st on st.id=sa.staff_id
          where sa.subject_id=s.id and st.profile_id=actor and sa.effective_from<=current_date
            and (sa.effective_to is null or sa.effective_to>=current_date)))), '[]'::jsonb),
    'items', coalesce((select jsonb_agg(jsonb_build_object(
      'id',q.id,'rootId',q.root_id,'revision',q.revision,'batchId',q.batch_id,'batch',b.name,
      'subjectId',q.subject_id,'subject',s.name,'curriculumVersionId',q.curriculum_version_id,
      'topic',q.topic,'difficulty',q.difficulty,'questionType',q.question_type,
      'prompt',q.prompt,'choices',q.choices,'answerKey',q.answer_key,'explanation',q.explanation,
      'status',q.status,'authorId',q.author_id,'author',p.display_name,'reviewNote',q.review_note,
      'createdAt',q.created_at) order by q.created_at desc)
      from public.question_bank_items q
      join public.batches b on b.id=q.batch_id
      join public.subjects s on s.id=q.subject_id
      join public.profiles p on p.id=q.author_id
      where q.author_id=actor or reviewer), '[]'::jsonb)
  );
end $function$;

CREATE OR REPLACE FUNCTION public.question_bank_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid := auth.uid(); act text := p_input->>'action'; rid uuid;
  q public.question_bank_items; b public.batches; s public.subjects;
  v_staff_id uuid; v_batch_id uuid; v_subject_id uuid; v_curriculum_id uuid;
  options jsonb; prompt_value text; answer_value text; note text;
  command_key public.admission_command_keys; result jsonb; next_id uuid;
begin
  if actor is null or not public.has_permission('academics.view') then raise exception 'Academic access required.'; end if;
  if p_input is null or jsonb_typeof(p_input)<>'object' then raise exception 'Question command must be an object.'; end if;
  rid := (p_input->>'request_id')::uuid;
  if rid is null then raise exception 'Request identity required.'; end if;
  perform pg_advisory_xact_lock(hashtextextended(rid::text,0));
  select * into command_key from public.admission_command_keys where request_id=rid;
  if found then
    if command_key.actor_id<>actor or command_key.payload<>p_input then raise exception 'Request identity already used for different input.'; end if;
    return command_key.result;
  end if;

  if act='CREATE_DRAFT' then
    if not (public.has_permission('academics.assessments.record') or public.has_permission('academics.sessions.manage')) then raise exception 'Question authoring permission required.'; end if;
    v_batch_id := (p_input->>'batch_id')::uuid;
    v_subject_id := (p_input->>'subject_id')::uuid;
    select * into b from public.batches where id=v_batch_id and is_active;
    select * into s from public.subjects where id=v_subject_id and is_active;
    if b.id is null or s.id is null or b.organization_id<>s.organization_id then raise exception 'Choose an active batch and subject in the same public.'; end if;
    select id into v_staff_id from public.staff where profile_id=actor and status='ACTIVE';
    if not public.has_permission('academics.sessions.manage') and not exists (
      select 1 from public.class_sessions cs
      join public.staff_subject_assignments sa on sa.staff_id=cs.teacher_id and sa.subject_id=cs.subject_id
      where cs.batch_id=v_batch_id and cs.subject_id=v_subject_id and cs.teacher_id=v_staff_id
        and sa.effective_from<=cs.session_date and (sa.effective_to is null or sa.effective_to>=cs.session_date)
    ) then raise exception 'Question scope requires an assigned class and subject qualification.'; end if;
    v_curriculum_id := nullif(p_input->>'curriculum_version_id','')::uuid;
    if v_curriculum_id is not null and not exists(select 1 from public.curriculum_versions cv where cv.id=v_curriculum_id and cv.batch_id=v_batch_id and cv.subject_id=v_subject_id) then raise exception 'Curriculum version must match the batch and subject.'; end if;
    q.root_id := null;
    q.revision := 1;
  else
    select * into q from public.question_bank_items where id=(p_input->>'item_id')::uuid for update;
    if q.id is null then raise exception 'Question not found.'; end if;
    if act in ('EDIT_DRAFT','SUBMIT','REVISE_REJECTED') and q.author_id<>actor then raise exception 'Only the author can change this question.'; end if;
    if act in ('APPROVE','REJECT') then
      if not public.has_permission('academics.assessments.approve') then raise exception 'Question review permission required.'; end if;
      if q.author_id=actor then raise exception 'A question author cannot review their own work.'; end if;
      if q.status<>'SUBMITTED' then raise exception 'Only submitted questions can be reviewed.'; end if;
    elsif act='EDIT_DRAFT' or act='SUBMIT' then
      if q.status<>'DRAFT' then raise exception 'Only a draft can be edited or submitted.'; end if;
    elsif act='REVISE_REJECTED' then
      if q.status<>'REJECTED' then raise exception 'Only a rejected question can start a new revision.'; end if;
      if exists(select 1 from public.question_bank_items newer where newer.root_id=coalesce(q.root_id,q.id) and newer.revision>q.revision) then raise exception 'A newer revision already exists.'; end if;
    else raise exception 'Unknown question action.'; end if;
  end if;

  if act in ('CREATE_DRAFT','EDIT_DRAFT') then
    options := coalesce(p_input->'choices','[]'::jsonb);
    prompt_value := btrim(coalesce(p_input->>'prompt',''));
    answer_value := btrim(coalesce(p_input->>'answer_key',''));
    if length(prompt_value) not between 10 and 3000 or length(answer_value) not between 1 and 1500
      or length(btrim(coalesce(p_input->>'topic',''))) not between 2 and 180
      or coalesce(length(p_input->>'explanation'),0)>3000
      or p_input->>'difficulty' not in ('FOUNDATION','STANDARD','ADVANCED')
      or p_input->>'question_type' not in ('MCQ','SHORT_ANSWER') then raise exception 'Check the question content and difficulty.'; end if;
    if jsonb_typeof(options)<>'array' or jsonb_array_length(options)>6
      or exists(select 1 from jsonb_array_elements(options) e where jsonb_typeof(e)<>'string' or length(btrim(e#>>'{}')) not between 1 and 500) then raise exception 'Invalid answer choices.'; end if;
    if p_input->>'question_type'='MCQ' and (jsonb_array_length(options)<2 or answer_value not in ('A','B','C','D','E','F')
      or ascii(answer_value)-64>jsonb_array_length(options)) then raise exception 'MCQ needs choices and a matching answer key (A–F).'; end if;
    if p_input->>'question_type'='SHORT_ANSWER' and jsonb_array_length(options)<>0 then raise exception 'Short answers cannot have MCQ choices.'; end if;
    if act='CREATE_DRAFT' then
      insert into public.question_bank_items(batch_id,subject_id,curriculum_version_id,topic,difficulty,question_type,prompt,choices,answer_key,explanation,author_id)
      values(v_batch_id,v_subject_id,v_curriculum_id,btrim(p_input->>'topic'),p_input->>'difficulty',p_input->>'question_type',prompt_value,options,answer_value,nullif(btrim(coalesce(p_input->>'explanation','')),''),actor) returning * into q;
    else
      update public.question_bank_items set topic=btrim(p_input->>'topic'),difficulty=p_input->>'difficulty',question_type=p_input->>'question_type',prompt=prompt_value,choices=options,answer_key=answer_value,explanation=nullif(btrim(coalesce(p_input->>'explanation','')),'') where id=q.id returning * into q;
    end if;
  elsif act='REVISE_REJECTED' then
    insert into public.question_bank_items(root_id,revision,batch_id,subject_id,curriculum_version_id,topic,difficulty,question_type,prompt,choices,answer_key,explanation,author_id)
    values(coalesce(q.root_id,q.id),q.revision+1,q.batch_id,q.subject_id,q.curriculum_version_id,q.topic,q.difficulty,q.question_type,q.prompt,q.choices,q.answer_key,q.explanation,actor) returning * into q;
  elsif act='SUBMIT' then
    update public.question_bank_items set status='SUBMITTED',submitted_at=now() where id=q.id returning * into q;
  else
    note := btrim(coalesce(p_input->>'review_note',''));
    if length(note)<5 or length(note)>1000 then raise exception 'Give a review reason (5–1000 characters).'; end if;
    update public.question_bank_items set status=case when act='APPROVE' then 'APPROVED' else 'REJECTED' end,
      reviewer_id=actor,review_note=note,reviewed_at=now() where id=q.id returning * into q;
  end if;
  result := jsonb_build_object('id',q.id,'status',q.status,'revision',q.revision);
  insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason,after_data)
  values(actor,(select branch_id from public.batches where id=q.batch_id),'QUESTION_BANK_ITEM',q.id::text,act,
    case when act in ('APPROVE','REJECT') then note else null end,to_jsonb(q));
  insert into public.admission_command_keys(request_id,actor_id,payload,result) values(rid,actor,p_input,result);
  return result;
end $function$;

CREATE OR REPLACE FUNCTION public.homework_workspace(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare log_row public.class_logs; session_row public.class_sessions;
begin
  if not public.can_access_class_session(p_session_id) then raise exception 'This class is outside your assigned scope.'; end if;
  select * into session_row from public.class_sessions where id=p_session_id;
  select * into log_row from public.class_logs where session_id=p_session_id and status='SUBMITTED' and btrim(homework)<>'' order by revision desc limit 1;
  return jsonb_build_object(
    'assignment',case when log_row.id is null then null else jsonb_build_object('id',log_row.id,'revision',log_row.revision,'description',log_row.homework,'submittedAt',log_row.submitted_at) end,
    'students',coalesce((select jsonb_agg(jsonb_build_object(
      'enrollmentId',e.id,'studentNo',s.student_no,'name',s.full_name,
      'latestRevision',hc.revision,'status',hc.status,'submittedOn',hc.submitted_on,'feedback',hc.feedback
      ) order by s.student_no)
      from public.enrollments e join public.students s on s.id=e.student_id
      left join lateral (select * from public.homework_checks h where h.class_log_id=log_row.id and h.enrollment_id=e.id order by revision desc limit 1) hc on true
      where log_row.id is not null and e.batch_id=session_row.batch_id and e.admission_date<=session_row.session_date
      and (e.ended_on is null or e.ended_on>session_row.session_date) and e.status in ('ACTIVE','WITHDRAWN','COMPLETED')),'[]'::jsonb),
    'history',coalesce((select jsonb_agg(jsonb_build_object('id',h.id,'enrollmentId',h.enrollment_id,'revision',h.revision,'status',h.status,'submittedOn',h.submitted_on,'feedback',h.feedback,'recordedAt',h.recorded_at) order by h.recorded_at desc)
      from public.homework_checks h where h.class_log_id=log_row.id),'[]'::jsonb)
  );
end $function$;

CREATE OR REPLACE FUNCTION public.homework_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare actor uuid:=auth.uid(); rid uuid:=(p_input->>'request_id')::uuid;
  sid uuid:=(p_input->>'session_id')::uuid; log_id uuid:=(p_input->>'class_log_id')::uuid;
  v_enrollment_id uuid:=(p_input->>'enrollment_id')::uuid; cs public.class_sessions;
  log_row public.class_logs; previous integer; check_row public.homework_checks;
  key public.admission_command_keys; result jsonb; feedback_value text:=btrim(coalesce(p_input->>'feedback',''));
  submitted_on_value date;
begin
  if actor is null or not public.has_permission('academics.view') or not (public.has_permission('academics.attendance.record') or public.has_permission('academics.sessions.manage')) then raise exception 'Teaching permission required.'; end if;
  if rid is null or sid is null or log_id is null or v_enrollment_id is null then raise exception 'Homework request identity and scope are required.'; end if;
  perform pg_advisory_xact_lock(hashtextextended(rid::text,0));
  select * into key from public.admission_command_keys where request_id=rid;
  if found then
    if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity already used for different input.'; end if;
    return key.result;
  end if;
  if not public.can_access_class_session(sid) then raise exception 'This class is outside your assigned scope.'; end if;
  select * into cs from public.class_sessions where id=sid;
  if cs.status<>'SCHEDULED' or (not public.has_permission('academics.sessions.manage') and not exists(select 1 from public.staff st where st.id=cs.teacher_id and st.profile_id=actor)) then raise exception 'Only the assigned teacher may check homework.'; end if;
  select * into log_row from public.class_logs where id=log_id and session_id=sid and status='SUBMITTED' and btrim(homework)<>'';
  if log_row.id is null then raise exception 'Submit the class log with homework before follow-up.'; end if;
  if not exists(select 1 from public.enrollments e where e.id=v_enrollment_id and e.batch_id=cs.batch_id
    and e.admission_date<=cs.session_date and (e.ended_on is null or e.ended_on>cs.session_date)
    and e.status in ('ACTIVE','WITHDRAWN','COMPLETED')) then raise exception 'Student was not on this class roster.'; end if;
  if p_input->>'status' not in ('NOT_SUBMITTED','NEEDS_WORK','COMPLETE') or length(feedback_value)>1000
    or (p_input->>'status'='NEEDS_WORK' and length(feedback_value)<5) then raise exception 'Choose a status and explain work that needs attention.'; end if;
  submitted_on_value:=nullif(p_input->>'submitted_on','')::date;
  if submitted_on_value>current_date or (p_input->>'status'='NOT_SUBMITTED' and submitted_on_value is not null) then raise exception 'Check the homework submission date.'; end if;
  perform pg_advisory_xact_lock(hashtextextended(log_id::text||v_enrollment_id::text,31));
  select coalesce(max(revision),0) into previous from public.homework_checks where class_log_id=log_id and enrollment_id=v_enrollment_id;
  if previous<>coalesce((p_input->>'base_revision')::integer,0) then raise exception 'Homework review changed. Refresh and try again.'; end if;
  insert into public.homework_checks(class_log_id,enrollment_id,revision,status,submitted_on,feedback,recorded_by)
  values(log_id,v_enrollment_id,previous+1,p_input->>'status',submitted_on_value,feedback_value,actor) returning * into check_row;
  result:=jsonb_build_object('id',check_row.id,'revision',check_row.revision);
  insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,after_data)
  values(actor,'HOMEWORK_CHECK',check_row.id::text,'RECORD',to_jsonb(check_row));
  insert into public.admission_command_keys(request_id,actor_id,payload,result) values(rid,actor,p_input,result);
  return result;
end $function$;

CREATE OR REPLACE FUNCTION public.can_access_assessment(p_batch uuid, p_subject uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select auth.uid() is not null and public.has_permission('academics.view') and (
  public.has_permission('academics.assessments.approve') or public.has_permission('academics.sessions.manage')
  or exists(select 1 from public.class_sessions cs join public.staff st on st.id=cs.teacher_id
    where cs.batch_id=p_batch and cs.subject_id=p_subject and st.profile_id=auth.uid())
 );
$function$;

CREATE OR REPLACE FUNCTION public.assessment_workspace()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare actor uuid:=auth.uid();
begin
 if actor is null or not public.has_permission('academics.view') then raise exception 'Academic access required.'; end if;
 return jsonb_build_object(
  'scopes',coalesce((select jsonb_agg(jsonb_build_object('batchId',cs.batch_id,'subjectId',cs.subject_id,'batch',b.name,'subject',s.name) order by b.name,s.name)
    from (select distinct batch_id,subject_id from public.class_sessions) cs
    join public.batches b on b.id=cs.batch_id join public.subjects s on s.id=cs.subject_id
    where public.can_access_assessment(cs.batch_id,cs.subject_id)),'[]'::jsonb),
  'assessments',coalesce((select jsonb_agg(jsonb_build_object(
    'id',a.id,'batchId',a.batch_id,'subjectId',a.subject_id,'batch',b.name,'subject',s.name,
    'title',a.title,'date',a.assessment_date,'maxMarks',a.max_marks,'status',a.status,
    'authorId',a.author_id,'roster',coalesce((select jsonb_agg(jsonb_build_object('enrollmentId',e.id,'studentNo',st.student_no,'name',st.full_name) order by st.student_no)
      from public.enrollments e join public.students st on st.id=e.student_id
      where e.batch_id=a.batch_id and e.admission_date<=a.assessment_date
        and (e.ended_on is null or e.ended_on>a.assessment_date) and e.status in ('ACTIVE','WITHDRAWN','COMPLETED')),'[]'::jsonb),
    'submissions',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'revision',r.revision,'status',r.status,'entries',r.entries,'authorId',r.author_id,'reviewNote',r.review_note,'createdAt',r.created_at) order by r.revision desc)
      from public.assessment_result_submissions r where r.assessment_id=a.id),'[]'::jsonb)
    ) order by a.assessment_date desc)
    from public.academic_assessments a join public.batches b on b.id=a.batch_id join public.subjects s on s.id=a.subject_id
    where public.can_access_assessment(a.batch_id,a.subject_id)),'[]'::jsonb)
 );
end $function$;

CREATE OR REPLACE FUNCTION public.assessment_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare actor uuid:=auth.uid(); act text:=p_input->>'action'; rid uuid:=(p_input->>'request_id')::uuid;
  a public.academic_assessments; r public.assessment_result_submissions; key public.admission_command_keys;
  v_entries jsonb:=coalesce(p_input->'entries','[]'::jsonb); expected integer; result jsonb;
  v_batch uuid; v_subject uuid; v_date date; v_max numeric;
begin
 if actor is null or not public.has_permission('academics.view') then raise exception 'Academic access required.'; end if;
 if rid is null then raise exception 'Request identity required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(rid::text,0));
 select * into key from public.admission_command_keys where request_id=rid;
 if found then
   if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity already used for different input.'; end if;
   return key.result;
 end if;
 if act='CREATE' then
   if not public.has_permission('academics.assessments.record') then raise exception 'Assessment recording permission required.'; end if;
   v_batch:=(p_input->>'batch_id')::uuid; v_subject:=(p_input->>'subject_id')::uuid;
   if not public.can_access_assessment(v_batch,v_subject) then raise exception 'Assessment is outside your teaching scope.'; end if;
   if not exists(select 1 from public.class_sessions where batch_id=v_batch and subject_id=v_subject) then raise exception 'Schedule a class for this batch and subject first.'; end if;
   v_date:=(p_input->>'assessment_date')::date; v_max:=(p_input->>'max_marks')::numeric;
   if v_date is null or v_max is null or v_max<=0 or v_max>1000
     or length(btrim(coalesce(p_input->>'title',''))) not between 3 and 180 then raise exception 'Enter assessment title, date and valid maximum marks.'; end if;
   if not exists(select 1 from public.batches b join public.academic_years y on y.id=b.academic_year_id where b.id=v_batch and v_date between y.starts_on and y.ends_on) then raise exception 'Assessment date must be in the batch academic year.'; end if;
   insert into public.academic_assessments(batch_id,subject_id,title,assessment_date,max_marks,author_id)
   values(v_batch,v_subject,btrim(p_input->>'title'),v_date,v_max,actor) returning * into a;
 else
   select * into a from public.academic_assessments where id=(p_input->>'assessment_id')::uuid for update;
   if a.id is null or not public.can_access_assessment(a.batch_id,a.subject_id) then raise exception 'Assessment not found in your scope.'; end if;
   if act='PUBLISH' then
     if a.status<>'DRAFT' or not public.has_permission('academics.assessments.record') then raise exception 'Only a draft can be published.'; end if;
     if a.author_id<>actor and not public.has_permission('academics.sessions.manage') then raise exception 'Only the author may publish this assessment.'; end if;
     update public.academic_assessments set status='PUBLISHED',published_at=now() where id=a.id returning * into a;
   elsif act='SAVE_RESULTS' then
     if a.status<>'PUBLISHED' or not public.has_permission('academics.assessments.record') then raise exception 'Published assessment and recording permission required.'; end if;
     if jsonb_typeof(v_entries)<>'array' or jsonb_array_length(v_entries)>500 then raise exception 'Check result entries.'; end if;
     select count(*) into expected from public.enrollments e where e.batch_id=a.batch_id and e.admission_date<=a.assessment_date
       and (e.ended_on is null or e.ended_on>a.assessment_date) and e.status in ('ACTIVE','WITHDRAWN','COMPLETED');
     if expected=0 or expected<>jsonb_array_length(v_entries) then raise exception 'Record exactly one result for every eligible student.'; end if;
     if exists(select 1 from jsonb_array_elements(v_entries) e where
       not (e ? 'enrollment_id' and e ? 'score') or (e->>'score') !~ '^([0-9]+)(\.[0-9]{1,2})?$'
       or (e->>'score')::numeric>a.max_marks or length(coalesce(e->>'feedback',''))>500
       or not exists(select 1 from public.enrollments x where x.id=(e->>'enrollment_id')::uuid and x.batch_id=a.batch_id
         and x.admission_date<=a.assessment_date and (x.ended_on is null or x.ended_on>a.assessment_date)
         and x.status in ('ACTIVE','WITHDRAWN','COMPLETED')))
       or (select count(distinct e->>'enrollment_id') from jsonb_array_elements(v_entries) e)<>expected
       then raise exception 'Invalid or duplicate result entries.'; end if;
     select * into r from public.assessment_result_submissions where assessment_id=a.id and status='DRAFT' for update;
     if r.id is null then
       if exists(select 1 from public.assessment_result_submissions where assessment_id=a.id and status='SUBMITTED') then raise exception 'Results are awaiting independent review.'; end if;
       insert into public.assessment_result_submissions(assessment_id,revision,entries,author_id)
       values(a.id,(select coalesce(max(revision),0)+1 from public.assessment_result_submissions where assessment_id=a.id),v_entries,actor) returning * into r;
     else
       if r.author_id<>actor then raise exception 'Only the draft author can change these results.'; end if;
       update public.assessment_result_submissions set entries=v_entries where id=r.id returning * into r;
     end if;
   elsif act='SUBMIT_RESULTS' then
     select * into r from public.assessment_result_submissions where assessment_id=a.id and status='DRAFT' for update;
     if r.id is null or r.author_id<>actor then raise exception 'Save your result draft before submitting.'; end if;
     update public.assessment_result_submissions set status='SUBMITTED',submitted_at=now() where id=r.id returning * into r;
   elsif act in ('APPROVE_RESULTS','REJECT_RESULTS') then
     if not public.has_permission('academics.assessments.approve') then raise exception 'Assessment review permission required.'; end if;
     select * into r from public.assessment_result_submissions where assessment_id=a.id and status='SUBMITTED' for update;
     if r.id is null then raise exception 'No submitted result revision is awaiting review.'; end if;
     if r.author_id=actor then raise exception 'Result author cannot approve or reject their own submission.'; end if;
     if length(btrim(coalesce(p_input->>'review_note','')))<5 then raise exception 'Enter a review reason.'; end if;
     update public.assessment_result_submissions set status=case when act='APPROVE_RESULTS' then 'APPROVED' else 'REJECTED' end,
       reviewer_id=actor,review_note=btrim(p_input->>'review_note'),reviewed_at=now() where id=r.id returning * into r;
   else raise exception 'Unknown assessment action.'; end if;
 end if;
 result:=jsonb_build_object('id',a.id,'status',coalesce(r.status,a.status),'revision',r.revision);
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,after_data)
 values(actor,'ASSESSMENT',a.id::text,act,case when r.id is null then to_jsonb(a) else to_jsonb(r) end);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(rid,actor,p_input,result);
 return result;
end $function$;

CREATE OR REPLACE FUNCTION public.attendance_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid:=auth.uid();
  action text:=p_input->>'action';
  req uuid:=nullif(p_input->>'request_id','')::uuid;
  reason text:=btrim(coalesce(p_input->>'reason',''));
  key public.admission_command_keys;
  session_row public.class_sessions;
  latest public.attendance_submissions;
  attendance public.attendance_submissions;
  approval public.approval_requests;
  roster jsonb;
  rows jsonb;
  entry jsonb;
  result jsonb;
  id_out uuid;
  session_id uuid:=nullif(p_input->>'session_id','')::uuid;
  attendance_id uuid:=nullif(p_input->>'attendance_id','')::uuid;
  approval_id uuid:=nullif(p_input->>'approval_id','')::uuid;
begin
  if actor is null or not public.has_permission('academics.view') then
    raise exception 'Academic access required.';
  end if;

  if req is null or length(reason)<5 or length(reason)>500 then
    raise exception 'A request identity and reason of 5–500 characters are required.';
  end if;

  if action not in ('SAVE_ATTENDANCE','SUBMIT_ATTENDANCE','DECIDE_ATTENDANCE') then
    raise exception 'Unsupported V3 attendance action.';
  end if;

  if action in ('SAVE_ATTENDANCE','SUBMIT_ATTENDANCE')
    and not public.has_permission('academics.attendance.record') then
    raise exception 'Attendance recording permission required.';
  end if;

  if action='DECIDE_ATTENDANCE'
    and not public.has_permission('academics.attendance.approve') then
    raise exception 'Attendance review permission required.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(req::text,11));

  select * into key
  from public.admission_command_keys
  where request_id=req;

  if found then
    if key.actor_id<>actor or key.payload<>p_input then
      raise exception 'Request identity already used for different input.';
    end if;
    return key.result;
  end if;

  if action='DECIDE_ATTENDANCE' then
    select * into approval
    from public.approval_requests
    where id=approval_id
      and workflow_type='ATTENDANCE'
    for update;

    if approval.id is null or approval.status<>'PENDING' then
      raise exception 'Pending attendance review was not found.';
    end if;

    attendance_id:=nullif(approval.payload_snapshot->>'attendance_id','')::uuid;
    select * into attendance
    from public.attendance_submissions
    where id=attendance_id
      and status='SUBMITTED'
    for update;

    if attendance.id is null then
      raise exception 'Submitted attendance was not found.';
    end if;

    if attendance.recorded_by=actor then
      raise exception 'The submitting teacher cannot review their own attendance.';
    end if;

    if length(reason)<5 then
      raise exception 'A review note is required.';
    end if;

    if p_input->>'decision' not in ('APPROVED','REJECTED') then
      raise exception 'Choose Approve or Reject.';
    end if;

    update public.attendance_submissions
    set status=p_input->>'decision',
        reviewer_id=actor,
        review_note=reason,
        reviewed_at=now()
    where id=attendance.id;

    update public.approval_requests
    set status=(p_input->>'decision')::public.approval_status,
        decided_by=actor,
        decided_at=now(),
        decision_note=reason
    where id=approval.id;

    result:=jsonb_build_object(
      'id',attendance.id,
      'message','Attendance '||lower(p_input->>'decision')||'. The reviewed revision is preserved in history.'
    );

  else
    select * into session_row
    from public.class_sessions
    where id=session_id
      and public.can_access_class_session(id)
    for update;

    if session_row.id is null then
      raise exception 'Class session was not found or is not accessible.';
    end if;

    if session_row.status<>'SCHEDULED' or session_row.starts_at>now() then
      raise exception 'Attendance can be recorded only after a scheduled class has started.';
    end if;

    select * into latest
    from public.attendance_submissions
    where id in (
      select id
      from public.attendance_submissions
      where session_id=session_row.id
      order by revision desc
      limit 1
    )
    for update;

    if action='SUBMIT_ATTENDANCE' then
      if attendance_id is null
        or latest.id is distinct from attendance_id
        or latest.status<>'DRAFT' then
        raise exception 'Only the latest saved attendance draft can be submitted.';
      end if;

      if latest.recorded_by<>actor then
        raise exception 'Only the draft author may submit the attendance.';
      end if;

      if exists(
        select 1
        from public.attendance_submissions
        where session_id=session_row.id
          and status='SUBMITTED'
      ) then
        raise exception 'Attendance is already awaiting admin review.';
      end if;

      insert into public.approval_requests(
        workflow_type,
        entity_type,
        entity_id,
        requested_action,
        payload_snapshot,
        request_note,
        requested_by,
        correlation_id
      )
      values(
        'ATTENDANCE',
        'CLASS_SESSION',
        session_row.id::text,
        'SUBMIT_ATTENDANCE',
        jsonb_build_object(
          'attendance_id',latest.id,
          'revision',latest.revision,
          'entries',latest.entries
        ),
        reason,
        actor,
        req
      )
      returning id into id_out;

      update public.attendance_submissions
      set status='SUBMITTED',
          approval_id=id_out
      where id=latest.id;

      result:=jsonb_build_object(
        'id',latest.id,
        'message','Attendance submitted for admin review.'
      );

    else
      if latest.status='SUBMITTED' then
        raise exception 'Attendance is awaiting admin review.';
      end if;

      if latest.id is not null
        and latest.id is distinct from nullif(p_input->>'base_id','')::uuid then
        raise exception 'Attendance changed. Refresh before saving a new revision.';
      end if;

      perform pg_advisory_xact_lock(hashtextextended('attendance:'||session_row.id::text,31));

      if latest.id is null then
        select coalesce(
          jsonb_agg(
            jsonb_build_object(
              'student_id',s.id,
              'enrollment_id',e.id,
              'number',s.student_no,
              'name',s.full_name,
              'status',null,
              'note',''
            )
            order by s.student_no
          ),
          '[]'::jsonb
        )
        into roster
        from public.enrollments e
        join public.students s on s.id=e.student_id
        where e.batch_id=session_row.batch_id
          and e.admission_date<=session_row.session_date
          and (e.ended_on is null or e.ended_on>session_row.session_date)
          and e.status in ('ACTIVE','WITHDRAWN','COMPLETED');
      else
        roster:=latest.entries;
      end if;

      rows:=p_input->'entries';

      if rows is null or jsonb_typeof(rows)<>'array' then
        raise exception 'Attendance entries are required.';
      end if;

      if jsonb_array_length(roster)=0
        or jsonb_array_length(rows)<>jsonb_array_length(roster)
        or (
          select count(distinct x->>'enrollment_id')
          from jsonb_array_elements(rows) x
        )<>jsonb_array_length(rows) then
        raise exception 'Record exactly one attendance status for every roster member.';
      end if;

      for entry in
        select x from jsonb_array_elements(rows) x
      loop
        if coalesce(entry->>'status','') not in ('PRESENT','ABSENT','LATE','EXCUSED')
          or length(coalesce(entry->>'note',''))>500
          or not exists(
            select 1
            from jsonb_array_elements(roster) r
            where r->>'enrollment_id'=entry->>'enrollment_id'
          ) then
          raise exception 'Invalid attendance status, note or roster member.';
        end if;
      end loop;

      select jsonb_agg(
        r||jsonb_build_object(
          'status',e->>'status',
          'note',coalesce(e->>'note','')
        )
        order by r->>'number'
      )
      into rows
      from jsonb_array_elements(roster) r
      join jsonb_array_elements(rows) e
        on r->>'enrollment_id'=e->>'enrollment_id';

      insert into public.attendance_submissions(
        session_id,
        revision,
        entries,
        reason,
        recorded_by
      )
      values(
        session_row.id,
        coalesce(latest.revision,0)+1,
        rows,
        reason,
        actor
      )
      returning id into id_out;

      result:=jsonb_build_object(
        'id',id_out,
        'message','Attendance draft saved. Submit it for admin review.'
      );
    end if;
  end if;

  insert into public.audit_events(
    correlation_id,
    actor_profile_id,
    actor_staff_id,
    entity_type,
    entity_id,
    action,
    reason,
    after_data,
    metadata
  )
  values(
    req,
    actor,
    (select id from public.staff where profile_id=actor limit 1),
    'ATTENDANCE_SUBMISSION',
    result->>'id',
    action,
    reason,
    result,
    jsonb_build_object('academic_flow','V3_ATTENDANCE_REVIEW')
  );

  insert into public.admission_command_keys(
    request_id,
    actor_id,
    payload,
    result
  )
  values(
    req,
    actor,
    p_input,
    result
  );

  return result;
end;
$function$;

-- Upstream 12_security_audit_triggers.sql
-- Sohoj Academy fresh database baseline: security audit triggers.
-- Install on an empty application schema. Each object is defined once.

grant usage on schema public to anon, authenticated, service_role;
revoke create on schema public from public, anon, authenticated;
revoke all on all functions in schema public from public, anon, authenticated;
revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
alter default privileges in schema public revoke execute on functions from public;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
grant execute on all functions in schema public to service_role;

alter table public.organizations enable row level security;

alter table public.branches enable row level security;

alter table public.profiles enable row level security;

alter table public.system_roles enable row level security;

alter table public.permissions enable row level security;

alter table public.role_permissions enable row level security;

alter table public.user_role_assignments enable row level security;

alter table public.staff enable row level security;

alter table public.staff_roles enable row level security;

alter table public.staff_role_assignments enable row level security;

alter table public.audit_events enable row level security;

alter table public.approval_requests enable row level security;

alter table public.business_rule_versions enable row level security;

alter table public.academic_years enable row level security;

alter table public.classes enable row level security;

alter table public.programs enable row level security;

alter table public.subjects enable row level security;

alter table public.areas enable row level security;

alter table public.schools enable row level security;

alter table public.lead_sources enable row level security;

alter table public.guardian_relationships enable row level security;

alter table public.payment_methods enable row level security;

alter table public.prospects enable row level security;

alter table public.prospect_program_interests enable row level security;

alter table public.prospect_subject_interests enable row level security;

alter table public.prospect_followups enable row level security;

alter table public.students enable row level security;

alter table public.guardians enable row level security;

alter table public.student_guardians enable row level security;

alter table public.batches enable row level security;

alter table public.enrollments enable row level security;

alter table public.staff_subject_assignments enable row level security;

alter table public.academic_groups enable row level security;

alter table public.programme_offerings enable row level security;

alter table public.fee_plan_versions enable row level security;

alter table public.fee_plan_components enable row level security;

alter table public.admission_cases enable row level security;

alter table public.admission_invoices enable row level security;

alter table public.admission_invoice_lines enable row level security;

alter table public.admission_command_keys enable row level security;

alter table public.admission_payments enable row level security;

alter table public.admission_payment_allocations enable row level security;

alter table public.billing_terms enable row level security;

alter table public.admission_discounts enable row level security;

alter table public.invoice_credits enable row level security;

alter table public.refund_authorizations enable row level security;

alter table public.refund_payouts enable row level security;

alter table public.admission_cancellations enable row level security;

alter table public.billing_runs enable row level security;

alter table public.student_merges enable row level security;

alter table public.enrollment_transfers enable row level security;

alter table public.academic_rooms enable row level security;

alter table public.curriculum_versions enable row level security;

alter table public.academic_routines enable row level security;

alter table public.class_sessions enable row level security;

alter table public.attendance_submissions enable row level security;

alter table public.programme_offering_subjects enable row level security;

alter table public.class_logs enable row level security;

alter table public.question_bank_items enable row level security;

alter table public.homework_checks enable row level security;

alter table public.academic_assessments enable row level security;

alter table public.assessment_result_submissions enable row level security;

alter table public.finance_accounts enable row level security;

alter table public.finance_cost_centres enable row level security;

alter table public.general_ledger_journals enable row level security;

alter table public.general_ledger_lines enable row level security;

alter table public.vendors enable row level security;

alter table public.finance_payment_account_map enable row level security;

alter table public.finance_fee_revenue_map enable row level security;

alter table public.finance_payables enable row level security;

alter table public.finance_payable_settlements enable row level security;

alter table public.finance_advances enable row level security;

alter table public.finance_advance_movements enable row level security;

alter table public.finance_expense_categories enable row level security;

alter table public.finance_expenses enable row level security;

alter table public.finance_expense_reconciliations enable row level security;

alter table public.finance_account_reconciliations enable row level security;

alter table public.teacher_referrals enable row level security;

alter table public.teacher_compensation_runs enable row level security;

alter table public.teacher_compensation_events enable row level security;

alter table public.teacher_compensation_adjustments enable row level security;

alter table public.teacher_compensation_lines enable row level security;

alter table public.teacher_compensation_settlements enable row level security;

alter table public.teacher_compensation_claims enable row level security;

alter table public.referral_people enable row level security;

alter table public.admission_referrals enable row level security;

alter table public.referral_bonus_awards enable row level security;

alter table public.staff_admission_intake_requests enable row level security;

alter table public.admission_physical_consent_receipts enable row level security;

alter table public.staff_access_requests enable row level security;

create policy organizations_authenticated_read on public.organizations as permissive for select to authenticated using (true);

create policy branches_authenticated_read on public.branches as permissive for select to authenticated using (true);

create policy staff_roles_authenticated_read on public.staff_roles as permissive for select to authenticated using (true);

create policy audit_permission_read on public.audit_events as permissive for select to authenticated using (has_permission('audit.view'::text));

create policy staff_role_assignments_read on public.staff_role_assignments as permissive for select to authenticated using (has_permission('staff.view'::text));

create policy staff_role_assignments_insert on public.staff_role_assignments as permissive for insert to authenticated with check (has_permission('staff.manage'::text));

create policy staff_role_assignments_update on public.staff_role_assignments as permissive for update to authenticated using (has_permission('staff.manage'::text)) with check (has_permission('staff.manage'::text));

create policy academic_years_read on public.academic_years as permissive for select to authenticated using (true);

create policy master_data_manage_academic_years on public.academic_years as permissive for all to authenticated using (has_permission('system.master_data.manage'::text)) with check (has_permission('system.master_data.manage'::text));

create policy classes_public_read on public.classes as permissive for select to anon, authenticated using (is_active);

create policy master_data_manage_classes on public.classes as permissive for all to authenticated using (has_permission('system.master_data.manage'::text)) with check (has_permission('system.master_data.manage'::text));

create policy programs_public_read on public.programs as permissive for select to anon, authenticated using (is_active);

create policy master_data_manage_programs on public.programs as permissive for all to authenticated using (has_permission('system.master_data.manage'::text)) with check (has_permission('system.master_data.manage'::text));

create policy subjects_public_read on public.subjects as permissive for select to anon, authenticated using (is_active);

create policy master_data_manage_subjects on public.subjects as permissive for all to authenticated using (has_permission('system.master_data.manage'::text)) with check (has_permission('system.master_data.manage'::text));

create policy areas_authenticated_read on public.areas as permissive for select to authenticated using (is_active);

create policy master_data_manage_areas on public.areas as permissive for all to authenticated using (has_permission('system.master_data.manage'::text)) with check (has_permission('system.master_data.manage'::text));

create policy schools_public_read on public.schools as permissive for select to anon, authenticated using (is_active);

create policy master_data_manage_schools on public.schools as permissive for all to authenticated using (has_permission('system.master_data.manage'::text)) with check (has_permission('system.master_data.manage'::text));

create policy lead_sources_public_read on public.lead_sources as permissive for select to anon, authenticated using (is_active);

create policy master_data_manage_lead_sources on public.lead_sources as permissive for all to authenticated using (has_permission('system.master_data.manage'::text)) with check (has_permission('system.master_data.manage'::text));

create policy payment_methods_authenticated_read on public.payment_methods as permissive for select to authenticated using (is_active);

create policy master_data_manage_payment_methods on public.payment_methods as permissive for all to authenticated using (has_permission('system.master_data.manage'::text)) with check (has_permission('system.master_data.manage'::text));

create policy guardian_relationships_authenticated_read on public.guardian_relationships as permissive for select to authenticated using (is_active);

create policy master_data_manage_guardian_relationships on public.guardian_relationships as permissive for all to authenticated using (has_permission('system.master_data.manage'::text)) with check (has_permission('system.master_data.manage'::text));

create policy guardian_relationships_public_read on public.guardian_relationships as permissive for select to anon using (is_active);

create policy staff_permission_read on public.staff as permissive for select to authenticated using ((has_permission('staff.view'::text) OR (profile_id = auth.uid())));

create policy staff_permission_insert on public.staff as permissive for insert to authenticated with check (has_permission('staff.manage'::text));

create policy staff_permission_update on public.staff as permissive for update to authenticated using (has_permission('staff.manage'::text)) with check (has_permission('staff.manage'::text));

create policy profiles_read on public.profiles as permissive for select to authenticated using (((id = auth.uid()) OR has_permission('system.users.manage'::text) OR has_permission('staff.view'::text)));

create policy student_guardians_view on public.student_guardians as permissive for select to authenticated using (has_permission('students.view'::text));

create policy student_guardians_manage on public.student_guardians as permissive for all to authenticated using (has_permission('students.manage'::text)) with check (has_permission('students.manage'::text));

create policy prospect_program_interests_view on public.prospect_program_interests as permissive for select to authenticated using (has_permission('crm.prospects.view'::text));

create policy prospect_program_interests_manage on public.prospect_program_interests as permissive for all to authenticated using (has_permission('crm.prospects.manage'::text)) with check (has_permission('crm.prospects.manage'::text));

create policy prospect_subject_interests_view on public.prospect_subject_interests as permissive for select to authenticated using (has_permission('crm.prospects.view'::text));

create policy prospect_subject_interests_manage on public.prospect_subject_interests as permissive for all to authenticated using (has_permission('crm.prospects.manage'::text)) with check (has_permission('crm.prospects.manage'::text));

create policy staff_subjects_read on public.staff_subject_assignments as permissive for select to authenticated using (has_permission('staff.view'::text));

create policy staff_subjects_manage_insert on public.staff_subject_assignments as permissive for insert to authenticated with check (has_permission('staff.manage'::text));

create policy staff_subjects_manage_update on public.staff_subject_assignments as permissive for update to authenticated using (has_permission('staff.manage'::text)) with check (has_permission('staff.manage'::text));

create policy prospect_followups_view on public.prospect_followups as permissive for select to authenticated using (has_permission('crm.prospects.view'::text));

create policy prospect_followups_manage on public.prospect_followups as permissive for all to authenticated using (has_permission('crm.followups.manage'::text)) with check ((has_permission('crm.followups.manage'::text) AND (recorded_by = auth.uid())));

create policy prospects_view on public.prospects as permissive for select to authenticated using (has_permission('crm.prospects.view'::text));

create policy prospects_manage_insert on public.prospects as permissive for insert to authenticated with check (has_permission('crm.prospects.manage'::text));

create policy prospects_manage_update on public.prospects as permissive for update to authenticated using (has_permission('crm.prospects.manage'::text)) with check (has_permission('crm.prospects.manage'::text));

create policy students_manage_insert on public.students as permissive for insert to authenticated with check (has_permission('students.manage'::text));

create policy students_view on public.students as permissive for select to authenticated using (has_permission('students.view'::text));

create policy students_manage_update on public.students as permissive for update to authenticated using (has_permission('students.manage'::text)) with check (has_permission('students.manage'::text));

create policy guardians_view on public.guardians as permissive for select to authenticated using (has_permission('students.view'::text));

create policy guardians_manage on public.guardians as permissive for all to authenticated using (has_permission('students.manage'::text)) with check (has_permission('students.manage'::text));

create policy system_roles_read on public.system_roles as permissive for select to authenticated using (true);

create policy permissions_read on public.permissions as permissive for select to authenticated using (true);

create policy role_permissions_read on public.role_permissions as permissive for select to authenticated using ((has_permission('system.roles.manage'::text) OR has_permission('system.users.manage'::text)));

create policy business_rules_read on public.business_rule_versions as permissive for select to authenticated using ((has_permission('system.rules.view'::text) OR (status = 'ACTIVE'::rule_status)));

create policy user_roles_admin_read on public.user_role_assignments as permissive for select to authenticated using (((profile_id = auth.uid()) OR has_permission('system.users.manage'::text)));

create policy user_roles_admin_write on public.user_role_assignments as permissive for insert to authenticated with check (has_permission('system.users.manage'::text));

create policy user_roles_admin_update on public.user_role_assignments as permissive for update to authenticated using (has_permission('system.users.manage'::text)) with check (has_permission('system.users.manage'::text));

create policy academic_groups_read on public.academic_groups as permissive for select to authenticated using ((has_permission('academics.view'::text) OR has_permission('admissions.view'::text)));

create policy master_data_manage_academic_groups on public.academic_groups as permissive for all to authenticated using (has_permission('system.master_data.manage'::text)) with check (has_permission('system.master_data.manage'::text));

create policy programme_offerings_read on public.programme_offerings as permissive for select to authenticated using ((has_permission('academics.view'::text) OR has_permission('admissions.view'::text) OR has_permission('finance.view'::text)));

create policy fee_plan_versions_read on public.fee_plan_versions as permissive for select to authenticated using ((has_permission('finance.view'::text) OR has_permission('finance.billing.manage'::text) OR has_permission('admissions.view'::text)));

create policy fee_plan_components_read on public.fee_plan_components as permissive for select to authenticated using ((has_permission('finance.view'::text) OR has_permission('finance.billing.manage'::text) OR has_permission('admissions.view'::text)));

create policy batches_view on public.batches as permissive for select to authenticated using ((has_permission('academics.view'::text) OR has_permission('admissions.view'::text)));

create policy batches_manage on public.batches as permissive for all to authenticated using (has_permission('academics.manage'::text)) with check (has_permission('academics.manage'::text));

create policy enrollments_view on public.enrollments as permissive for select to authenticated using ((has_permission('students.view'::text) OR has_permission('admissions.view'::text)));

create policy enrollments_manage on public.enrollments as permissive for all to authenticated using ((has_permission('students.manage'::text) OR has_permission('admissions.create'::text))) with check ((has_permission('students.manage'::text) OR has_permission('admissions.create'::text)));

create policy admission_lines_read on public.admission_invoice_lines as permissive for select to authenticated using ((has_permission('admissions.view'::text) OR has_permission('finance.view'::text)));

create policy admission_payment_read on public.admission_payments as permissive for select to authenticated using ((has_permission('admissions.view'::text) OR has_permission('finance.view'::text)));

create policy admission_allocation_read on public.admission_payment_allocations as permissive for select to authenticated using ((has_permission('admissions.view'::text) OR has_permission('finance.view'::text)));

create policy admission_invoices_read on public.admission_invoices as permissive for select to authenticated using ((has_permission('admissions.view'::text) OR has_permission('finance.view'::text)));

create policy admission_cases_read on public.admission_cases as permissive for select to authenticated using (has_permission('admissions.view'::text));

create policy finance_read on public.invoice_credits as permissive for select to authenticated using (has_permission('finance.view'::text));

create policy finance_read on public.billing_terms as permissive for select to authenticated using (has_permission('finance.view'::text));

create policy finance_read on public.admission_discounts as permissive for select to authenticated using (has_permission('finance.view'::text));

create policy finance_read on public.refund_authorizations as permissive for select to authenticated using (has_permission('finance.view'::text));

create policy finance_read on public.refund_payouts as permissive for select to authenticated using (has_permission('finance.view'::text));

create policy finance_read on public.billing_runs as permissive for select to authenticated using (has_permission('finance.view'::text));

create policy approvals_permission_read on public.approval_requests as permissive for select to authenticated using ((has_permission('approvals.view'::text) OR (requested_by = auth.uid())));

create policy approvals_submit on public.approval_requests as permissive for insert to authenticated with check ((requested_by = auth.uid()));

create policy approvals_decide on public.approval_requests as permissive for update to authenticated using (has_permission('approvals.decide'::text)) with check (has_permission('approvals.decide'::text));

create policy finance_read on public.admission_cancellations as permissive for select to authenticated using (has_permission('finance.view'::text));

create policy lifecycle_read on public.student_merges as permissive for select to authenticated using (has_permission('students.view'::text));

create policy lifecycle_read on public.enrollment_transfers as permissive for select to authenticated using (has_permission('students.view'::text));

create policy academic_room_read on public.academic_rooms as permissive for select to authenticated using (has_permission('academics.view'::text));

create policy attendance_read on public.attendance_submissions as permissive for select to authenticated using (can_access_class_session(session_id));

create policy curriculum_read on public.curriculum_versions as permissive for select to authenticated using ((has_permission('academics.curriculum.manage'::text) OR has_permission('academics.sessions.manage'::text) OR (EXISTS ( SELECT 1
   FROM class_sessions s
  WHERE ((s.curriculum_version_id = curriculum_versions.id) AND can_access_class_session(s.id))))));

create policy routine_read on public.academic_routines as permissive for select to authenticated using ((has_permission('academics.sessions.manage'::text) OR (EXISTS ( SELECT 1
   FROM staff
  WHERE ((staff.id = academic_routines.teacher_id) AND (staff.profile_id = auth.uid()))))));

create policy session_read on public.class_sessions as permissive for select to authenticated using (can_access_class_session(id));

create policy offering_subjects_read on public.programme_offering_subjects as permissive for select to anon, authenticated using ((EXISTS ( SELECT 1
   FROM programme_offerings o
  WHERE ((o.id = programme_offering_subjects.offering_id) AND (o.is_website_visible OR has_permission('academics.view'::text) OR has_permission('admissions.view'::text))))));

create policy finance_accounts_read on public.finance_accounts as permissive for select to authenticated using ((has_permission('accounting.view'::text) OR has_permission('finance.view'::text)));

create policy finance_cost_centres_read on public.finance_cost_centres as permissive for select to authenticated using ((has_permission('accounting.view'::text) OR has_permission('finance.view'::text)));

create policy ledger_read on public.general_ledger_journals as permissive for select to authenticated using (has_permission('accounting.view'::text));

create policy ledger_lines_read on public.general_ledger_lines as permissive for select to authenticated using (has_permission('accounting.view'::text));

create policy vendors_read on public.vendors as permissive for select to authenticated using ((has_permission('finance.view'::text) OR has_permission('accounting.view'::text)));

create policy payment_map_read on public.finance_payment_account_map as permissive for select to authenticated using (has_permission('accounting.view'::text));

create policy fee_map_read on public.finance_fee_revenue_map as permissive for select to authenticated using (has_permission('accounting.view'::text));

create policy expense_categories_read on public.finance_expense_categories as permissive for select to authenticated using ((has_permission('accounting.view'::text) OR has_permission('accounting.expense.manage'::text)));

create policy expense_reconciliation_read on public.finance_expense_reconciliations as permissive for select to authenticated using (has_permission('accounting.reconcile'::text));

create policy account_reconciliation_read on public.finance_account_reconciliations as permissive for select to authenticated using (has_permission('accounting.reconcile'::text));

create policy teacher_referrals_read on public.teacher_referrals as permissive for select to authenticated using ((has_permission('staff.compensation.view'::text) OR has_permission('admissions.view'::text)));

create policy compensation_events_read on public.teacher_compensation_events as permissive for select to authenticated using (has_permission('staff.compensation.view'::text));

create policy compensation_settlements_read on public.teacher_compensation_settlements as permissive for select to authenticated using (has_permission('staff.compensation.view'::text));

create policy compensation_lines_read on public.teacher_compensation_lines as permissive for select to authenticated using (has_permission('staff.compensation.view'::text));

create policy advances_read on public.finance_advances as permissive for select to authenticated using ((has_permission('finance.view'::text) OR has_permission('finance.advances.manage'::text)));

create policy expenses_read on public.finance_expenses as permissive for select to authenticated using ((has_permission('finance.view'::text) OR has_permission('accounting.expense.manage'::text)));

create policy compensation_runs_read on public.teacher_compensation_runs as permissive for select to authenticated using (has_permission('staff.compensation.view'::text));

create policy compensation_adjustments_read on public.teacher_compensation_adjustments as permissive for select to authenticated using (has_permission('staff.compensation.view'::text));

create policy teacher_compensation_claims_read on public.teacher_compensation_claims as permissive for select to authenticated using (has_permission('staff.compensation.view'::text));

create policy advance_movements_read on public.finance_advance_movements as permissive for select to authenticated using ((has_permission('finance.view'::text) OR has_permission('finance.advances.manage'::text)));

create policy payable_settlements_read on public.finance_payable_settlements as permissive for select to authenticated using ((has_permission('finance.view'::text) OR has_permission('accounting.view'::text)));

create policy payables_read on public.finance_payables as permissive for select to authenticated using ((has_permission('finance.view'::text) OR has_permission('accounting.view'::text)));

create policy referral_people_read on public.referral_people as permissive for select to authenticated using ((has_permission('admissions.view'::text) OR has_permission('finance.view'::text) OR has_permission('accounting.view'::text)));

create policy admission_referrals_read on public.admission_referrals as permissive for select to authenticated using ((has_permission('admissions.view'::text) OR has_permission('finance.view'::text) OR has_permission('accounting.view'::text)));

create policy referral_bonus_awards_read on public.referral_bonus_awards as permissive for select to authenticated using ((has_permission('staff.compensation.view'::text) OR has_permission('finance.view'::text) OR has_permission('accounting.view'::text)));

create policy staff_requests_read on public.staff_access_requests as permissive for select to authenticated using (has_permission('system.users.manage'::text));

create policy admission_physical_consent_staff_read on public.admission_physical_consent_receipts as permissive for select to authenticated using (has_permission('admissions.view'::text));

grant select on public.organizations to authenticated;

grant select on public.branches to authenticated;

grant select on public.staff_roles to authenticated;

grant select on public.audit_events to authenticated;

grant select on public.staff_role_assignments to authenticated;

grant select on public.academic_years to authenticated;

grant select on public.classes to anon;

grant select on public.classes to authenticated;

grant select on public.programs to anon;

grant select on public.programs to authenticated;

grant select on public.subjects to anon;

grant select on public.subjects to authenticated;

grant select on public.areas to authenticated;

grant select on public.schools to anon;

grant select on public.schools to authenticated;

grant select on public.lead_sources to anon;

grant select on public.lead_sources to authenticated;

grant select on public.payment_methods to authenticated;

grant select on public.guardian_relationships to authenticated;

grant select on public.guardian_relationships to anon;

grant select on public.staff to authenticated;

grant select on public.profiles to authenticated;

grant select on public.student_guardians to authenticated;

grant select on public.prospect_program_interests to authenticated;

grant select on public.prospect_subject_interests to authenticated;

grant select on public.staff_subject_assignments to authenticated;

grant select on public.prospect_followups to authenticated;

grant select on public.prospects to authenticated;

grant select on public.students to authenticated;

grant select on public.guardians to authenticated;

grant select on public.system_roles to authenticated;

grant select on public.permissions to authenticated;

grant select on public.role_permissions to authenticated;

grant select on public.business_rule_versions to authenticated;

grant select on public.user_role_assignments to authenticated;

grant select on public.academic_groups to authenticated;

grant select on public.programme_offerings to authenticated;

grant select on public.fee_plan_versions to authenticated;

grant select on public.fee_plan_components to authenticated;

grant select on public.batches to authenticated;

grant select on public.enrollments to authenticated;

grant select on public.admission_invoice_lines to authenticated;

grant select on public.admission_payments to authenticated;

grant select on public.admission_payment_allocations to authenticated;

grant select on public.admission_invoices to authenticated;

grant select on public.admission_cases to authenticated;

grant select on public.invoice_credits to authenticated;

grant select on public.billing_terms to authenticated;

grant select on public.admission_discounts to authenticated;

grant select on public.refund_authorizations to authenticated;

grant select on public.refund_payouts to authenticated;

grant select on public.billing_runs to authenticated;

grant select on public.approval_requests to authenticated;

grant select on public.admission_cancellations to authenticated;

grant select on public.student_merges to authenticated;

grant select on public.enrollment_transfers to authenticated;

grant select on public.academic_rooms to authenticated;

grant select on public.attendance_submissions to authenticated;

grant select on public.curriculum_versions to authenticated;

grant select on public.academic_routines to authenticated;

grant select on public.class_sessions to authenticated;

grant select on public.programme_offering_subjects to authenticated;

grant select on public.programme_offering_subjects to anon;

grant select on public.finance_accounts to authenticated;

grant select on public.finance_cost_centres to authenticated;

grant select on public.general_ledger_journals to authenticated;

grant select on public.general_ledger_lines to authenticated;

grant select on public.vendors to authenticated;

grant select on public.finance_payment_account_map to authenticated;

grant select on public.finance_fee_revenue_map to authenticated;

grant select on public.finance_expense_categories to authenticated;

grant select on public.finance_expense_reconciliations to authenticated;

grant select on public.finance_account_reconciliations to authenticated;

grant select on public.teacher_referrals to authenticated;

grant select on public.teacher_compensation_events to authenticated;

grant select on public.teacher_compensation_settlements to authenticated;

grant select on public.teacher_compensation_lines to authenticated;

grant select on public.finance_advances to authenticated;

grant select on public.finance_expenses to authenticated;

grant select on public.teacher_compensation_runs to authenticated;

grant select on public.teacher_compensation_adjustments to authenticated;

grant select on public.teacher_compensation_claims to authenticated;

grant select on public.finance_advance_movements to authenticated;

grant select on public.finance_payable_settlements to authenticated;

grant select on public.finance_payables to authenticated;

grant select on public.referral_people to authenticated;

grant select on public.admission_referrals to authenticated;

grant select on public.referral_bonus_awards to authenticated;

grant select on public.staff_access_requests to authenticated;

grant select on public.admission_physical_consent_receipts to authenticated;

grant select on public.current_fee_plans to authenticated;

grant select on public.current_fee_plan_components to authenticated;

grant select on public.current_operating_rules to authenticated;

grant execute on function public.academic_command(p_input jsonb) to authenticated;

grant execute on function public.academic_workspace(p_from date, p_to date) to authenticated;

grant execute on function public.academy_setup_status() to authenticated;

grant execute on function public.admin_review_queue() to authenticated;

grant execute on function public.admission_case_detail(p_admission_id uuid) to authenticated;

grant execute on function public.admission_command(p_input jsonb) to authenticated;

grant execute on function public.admission_directory_options() to authenticated;

grant execute on function public.admission_discount_options(p_admission_id uuid) to authenticated;

grant execute on function public.admission_offering_options() to authenticated;

grant execute on function public.admission_review_checks(p_admission_id uuid) to authenticated;

grant execute on function public.admission_workspace() to authenticated;

grant execute on function public.assessment_command(p_input jsonb) to authenticated;

grant execute on function public.assessment_workspace() to authenticated;

grant execute on function public.assign_prospect_staff(p_input jsonb) to authenticated;

grant execute on function public.attendance_command(p_input jsonb) to authenticated;

grant execute on function public.audit_event_list(p_correlation uuid) to authenticated;

grant execute on function public.batch_command(p_input jsonb) to authenticated;

grant execute on function public.billing_preview(p_period date, p_term_id uuid) to authenticated;

grant execute on function public.can_access_assessment(p_batch uuid, p_subject uuid) to authenticated;

grant execute on function public.can_access_class_session(p_session uuid) to authenticated;

grant execute on function public.class_log_command(p_input jsonb) to authenticated;

grant execute on function public.class_log_workspace(p_session_id uuid) to authenticated;

grant execute on function public.class_session_workspace(p_session_id uuid) to authenticated;

grant execute on function public.close_student_enrollment(p_input jsonb) to authenticated;

grant execute on function public.complete_academy_setup() to authenticated;

grant execute on function public.correct_admission_placement(p_input jsonb) to authenticated;

grant execute on function public.create_admission_directory_choice(p_input jsonb) to authenticated;

grant execute on function public.create_programme_offering(p_input jsonb) to authenticated;

grant execute on function public.create_prospect_admission(p_input jsonb) to authenticated;

grant execute on function public.create_staff_admission_intake(p_input jsonb) to authenticated;

grant execute on function public.create_staff_member(p_input jsonb) to authenticated;

grant execute on function public.deactivate_admission_extra_charge(p_admission_id uuid, p_charge_id uuid) to authenticated;

grant execute on function public.edit_admission_identity(p_input jsonb) to authenticated;

grant execute on function public.edit_staff_record(p_input jsonb) to authenticated;

grant execute on function public.finance_accounting_command(p_input jsonb) to authenticated;

grant execute on function public.finance_command(p_input jsonb) to authenticated;

grant execute on function public.finance_read_account_balance(p_account_id uuid, p_as_of date) to authenticated;

grant execute on function public.finance_workspace() to authenticated;

grant execute on function public.has_permission(p_permission_code text) to authenticated;

grant execute on function public.homework_command(p_input jsonb) to authenticated;

grant execute on function public.homework_workspace(p_session_id uuid) to authenticated;

grant execute on function public.is_valid_prospect_transition(p_from prospect_status, p_to prospect_status) to authenticated;

grant execute on function public.list_public_programme_offerings() to anon;

grant execute on function public.list_public_programme_offerings() to authenticated;

grant execute on function public.manage_crm_master_record(p_input jsonb) to authenticated;

grant execute on function public.my_erp_context() to authenticated;

grant execute on function public.post_admission_payment(p_input jsonb) to authenticated;

grant execute on function public.prospect_assignment_options() to authenticated;

grant execute on function public.publish_business_rule_version(p_domain text, p_rule_key text, p_payload jsonb, p_reason text) to authenticated;

grant execute on function public.question_bank_command(p_input jsonb) to authenticated;

grant execute on function public.question_bank_workspace() to authenticated;

grant execute on function public.record_lifecycle_command(p_input jsonb) to authenticated;

grant execute on function public.record_physical_admission_consent(p_input jsonb) to authenticated;

grant execute on function public.record_prospect_followup(p_input jsonb) to authenticated;

grant execute on function public.referral_command(p_input jsonb) to authenticated;

grant execute on function public.request_staff_access(p_input jsonb) to anon;

grant execute on function public.request_staff_access(p_input jsonb) to authenticated;

grant execute on function public.review_staff_access(p_input jsonb) to authenticated;

grant execute on function public.save_academy_identity(p_input jsonb) to authenticated;

grant execute on function public.save_admission_extra_charge(p_input jsonb) to authenticated;

grant execute on function public.save_fee_plan(p_input jsonb) to authenticated;

grant execute on function public.save_offering_discount_policy(p_input jsonb) to authenticated;

grant execute on function public.set_role_permissions(p_role_code text, p_permission_codes text[], p_reason text) to authenticated;

grant execute on function public.set_user_operational_roles(p_profile_id uuid, p_role_codes text[], p_reason text, p_branch_id uuid) to authenticated;

grant execute on function public.student_command(p_input jsonb) to authenticated;

grant execute on function public.student_profile_workspace(p_student_id uuid) to authenticated;

grant execute on function public.submit_public_interest(p_payload jsonb) to anon;

grant execute on function public.submit_public_interest(p_payload jsonb) to authenticated;

grant execute on function public.teacher_compensation_preview(p_from date, p_to date) to authenticated;

grant execute on function public.update_programme_offering(p_input jsonb) to authenticated;

grant execute on function public.update_programme_offering_public_controls(p_input jsonb) to authenticated;

grant execute on function public.validate_business_rule_payload(p_domain text, p_rule_key text, p_payload jsonb) to authenticated;

grant execute on function public.has_permission(text) to anon;

CREATE TRIGGER organizations_set_updated_at BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER branches_set_updated_at BEFORE UPDATE ON branches FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER profiles_set_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER staff_set_updated_at BEFORE UPDATE ON staff FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER schools_set_updated_at BEFORE UPDATE ON schools FOR EACH ROW EXECUTE FUNCTION set_updated_at();



CREATE TRIGGER approval_requests_decision_guard BEFORE UPDATE OF status ON approval_requests FOR EACH ROW EXECUTE FUNCTION enforce_approval_decision();

CREATE TRIGGER business_rule_version_guard BEFORE DELETE OR UPDATE ON business_rule_versions FOR EACH ROW EXECUTE FUNCTION protect_active_business_rule();

CREATE TRIGGER prospects_set_updated_at BEFORE UPDATE ON prospects FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER students_set_updated_at BEFORE UPDATE ON students FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER guardians_set_updated_at BEFORE UPDATE ON guardians FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER batches_set_updated_at BEFORE UPDATE ON batches FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER enrollments_set_updated_at BEFORE UPDATE ON enrollments FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER batches_capacity_policy BEFORE INSERT OR UPDATE OF capacity ON batches FOR EACH ROW EXECUTE FUNCTION enforce_batch_policy();

CREATE TRIGGER enrollments_batch_integrity BEFORE INSERT OR UPDATE OF batch_id, status, academic_year_id, class_id, program_id ON enrollments FOR EACH ROW EXECUTE FUNCTION enforce_enrollment_batch_integrity();

CREATE TRIGGER staff_subject_requires_teaching_role BEFORE INSERT OR UPDATE OF staff_id, subject_id, effective_to ON staff_subject_assignments FOR EACH ROW EXECUTE FUNCTION enforce_staff_subject_teaching_role();

CREATE TRIGGER programme_offerings_set_updated_at BEFORE UPDATE ON programme_offerings FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER fee_plan_version_history_guard BEFORE DELETE OR UPDATE ON fee_plan_versions FOR EACH ROW EXECUTE FUNCTION guard_fee_plan_history();

CREATE TRIGGER fee_plan_component_history_guard BEFORE INSERT OR DELETE OR UPDATE ON fee_plan_components FOR EACH ROW EXECUTE FUNCTION guard_fee_plan_history();

CREATE TRIGGER admission_updated BEFORE UPDATE ON admission_cases FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER admission_invoice_immutable BEFORE DELETE OR UPDATE ON admission_invoices FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER admission_lines_immutable BEFORE DELETE OR UPDATE ON admission_invoice_lines FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER admission_payment_immutable BEFORE DELETE OR UPDATE ON admission_payments FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER admission_allocation_immutable BEFORE DELETE OR UPDATE ON admission_payment_allocations FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER immutable_finance_history BEFORE DELETE OR UPDATE ON billing_terms FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER immutable_finance_history BEFORE DELETE OR UPDATE ON admission_discounts FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER immutable_finance_history BEFORE DELETE OR UPDATE ON invoice_credits FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER immutable_finance_history BEFORE DELETE OR UPDATE ON refund_authorizations FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER immutable_finance_history BEFORE DELETE OR UPDATE ON refund_payouts FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER immutable_finance_history BEFORE DELETE OR UPDATE ON admission_cancellations FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER immutable_finance_history BEFORE DELETE OR UPDATE ON billing_runs FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER lifecycle_immutable BEFORE DELETE OR UPDATE ON student_merges FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER lifecycle_immutable BEFORE DELETE OR UPDATE ON enrollment_transfers FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER academic_immutable BEFORE DELETE OR UPDATE ON academic_rooms FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER academic_immutable BEFORE DELETE OR UPDATE ON curriculum_versions FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER academic_immutable BEFORE DELETE OR UPDATE ON academic_routines FOR EACH ROW EXECUTE FUNCTION protect_academic_record();

CREATE TRIGGER academic_immutable BEFORE DELETE OR UPDATE ON class_sessions FOR EACH ROW EXECUTE FUNCTION protect_academic_record();

CREATE TRIGGER academic_immutable BEFORE DELETE OR UPDATE ON attendance_submissions FOR EACH ROW EXECUTE FUNCTION protect_academic_record();

CREATE TRIGGER class_log_history_guard BEFORE DELETE OR UPDATE ON class_logs FOR EACH ROW EXECUTE FUNCTION guard_submitted_class_log();

CREATE TRIGGER staff_link_profile AFTER INSERT OR UPDATE OF email, status ON staff FOR EACH ROW WHEN (new.profile_id IS NULL AND new.email IS NOT NULL) EXECUTE FUNCTION staff_link_profile_trigger();



CREATE CONSTRAINT TRIGGER journal_must_balance AFTER INSERT OR DELETE OR UPDATE ON general_ledger_lines DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION assert_journal_balanced();

CREATE TRIGGER vendors_set_updated_at BEFORE UPDATE ON vendors FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER admission_invoice_lines_to_ledger AFTER INSERT ON admission_invoice_lines REFERENCING NEW TABLE AS new_table FOR EACH STATEMENT EXECUTE FUNCTION finance_sync_invoice_line_statement();

CREATE TRIGGER invoice_credits_to_ledger AFTER INSERT ON invoice_credits FOR EACH ROW EXECUTE FUNCTION finance_sync_invoice_credit_trigger();

CREATE TRIGGER admission_payment_allocations_to_ledger AFTER INSERT ON admission_payment_allocations FOR EACH ROW EXECUTE FUNCTION finance_sync_payment_trigger();

CREATE TRIGGER refund_payouts_to_ledger AFTER INSERT ON refund_payouts FOR EACH ROW EXECUTE FUNCTION finance_sync_refund_trigger();

CREATE TRIGGER immutable_compensation_claim BEFORE DELETE OR UPDATE ON teacher_compensation_claims FOR EACH ROW EXECUTE FUNCTION protect_admission_invoice();

CREATE TRIGGER admission_referral_choice_gate BEFORE UPDATE OF status ON admission_cases FOR EACH ROW EXECUTE FUNCTION require_admission_referral_choice();

CREATE TRIGGER teacher_referral_match BEFORE INSERT OR UPDATE ON teacher_referrals FOR EACH ROW EXECUTE FUNCTION teacher_referral_matches_admission();

CREATE TRIGGER admission_student_details_sync AFTER UPDATE OF student_id ON admission_cases FOR EACH ROW EXECUTE FUNCTION sync_admission_student_details();

CREATE TRIGGER admission_workflow_evidence_gate BEFORE UPDATE OF status ON admission_cases FOR EACH ROW EXECUTE FUNCTION require_admission_workflow_evidence();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON organizations FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON branches FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON profiles FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON staff FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON schools FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON academic_years FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON classes FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON academic_groups FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON subjects FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON programs FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON students FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON guardians FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON prospects FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON batches FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON enrollments FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON admission_cases FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON admission_invoices FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON admission_invoice_lines FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON admission_payments FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON invoice_credits FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON admission_physical_consent_receipts FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER preserve_permanent_record BEFORE DELETE ON staff_access_requests FOR EACH ROW EXECUTE FUNCTION prevent_permanent_record_delete();

CREATE TRIGGER capture_audit_identity BEFORE INSERT ON audit_events FOR EACH ROW EXECUTE FUNCTION capture_audit_actor();

-- Upstream 13_essential_system_seed.sql
-- Sohoj Academy fresh database baseline: essential system seed.
-- Install on an empty application schema. Each object is defined once.

insert into public.organizations (id, code, name, timezone, currency_code, is_active, created_at, updated_at, setup_completed_at, setup_completed_by, setup_identity_confirmed_at) values
  ('bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'SOHOJ', 'Sohoj Academy', 'Asia/Dhaka', 'BDT', true, '2026-10-01T00:01:59.763Z', '2026-10-01T00:01:59.763Z', null, null, null);

insert into public.branches (id, organization_id, code, name, address, timezone, is_active, created_at, updated_at) values
  ('87a7d34b-4c6d-43ba-96b9-3dcf22da2c7c', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'MAIN', 'Main Campus', 'Gopalpur Bazar, Narundi Road, Jamalpur Sadar', 'Asia/Dhaka', true, '2026-10-01T00:01:59.763Z', '2026-10-01T00:01:59.763Z');

insert into public.system_roles (id, code, name, description, is_system, is_active, created_at) values
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'ADMIN', 'Administrator', 'Full ERP administration with approval and audit access.', true, true, '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', 'ACADEMIC_DIRECTOR', 'Academic Director', 'Academic planning, review and approval authority.', true, true, '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', 'OPERATOR', 'Operator', 'Admissions, CRM, routine operations and fee collection.', true, true, '2026-10-01T00:01:59.763Z'),
  ('26b7ccdc-6303-499e-ba5a-1d5e716a2b45', 'TEACHER', 'Teacher', 'Teaching, attendance, assessment and class-log workflows.', true, true, '2026-10-01T00:01:59.763Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', 'ACCOUNTANT', 'Accountant', 'Finance, billing, reconciliation and accounting workflows.', true, true, '2026-10-01T00:01:59.763Z');

insert into public.permissions (id, code, name, description, created_at) values
  ('9dd6ebe2-b267-4075-9fd7-495e334a2fb7', 'dashboard.view', 'View dashboard', 'Access ERP dashboard.', '2026-10-01T00:01:59.763Z'),
  ('cff5b41c-2fbe-40c5-90ce-7b37b297cd67', 'action_center.view', 'View Action Center', 'View tasks and exceptions requiring action.', '2026-10-01T00:01:59.763Z'),
  ('b73f9cbb-b402-4fe7-8d76-acefbdcab89d', 'crm.prospects.view', 'View prospects', 'View CRM prospects and timelines.', '2026-10-01T00:01:59.763Z'),
  ('9b3239d4-d38c-40f3-82b8-fc73b2c44f6c', 'crm.prospects.manage', 'Manage prospects', 'Create/update prospects and outcomes.', '2026-10-01T00:01:59.763Z'),
  ('75911b3f-51c6-4760-8f01-3ae1455c1c05', 'crm.followups.manage', 'Manage follow-ups', 'Record CRM follow-ups.', '2026-10-01T00:01:59.763Z'),
  ('c6356a75-43eb-4627-b585-fe924622a7c6', 'admissions.view', 'View admissions', 'View admissions.', '2026-10-01T00:01:59.763Z'),
  ('48a583b6-3a64-4c34-b8a8-8b041ff3f499', 'admissions.create', 'Create admissions', 'Create admission workflows.', '2026-10-01T00:01:59.763Z'),
  ('3d55d0ec-4cd4-444d-866d-ff641300803b', 'admissions.approve', 'Approve admissions', 'Approve controlled admission exceptions.', '2026-10-01T00:01:59.763Z'),
  ('0e751c57-ad44-4837-8a09-b3e8de702ed8', 'students.view', 'View students', 'View student master data.', '2026-10-01T00:01:59.763Z'),
  ('8139a5df-b9d6-440a-a845-b90d06aba83b', 'students.manage', 'Manage students', 'Manage student lifecycle data.', '2026-10-01T00:01:59.763Z'),
  ('60550137-7dfa-4111-afbb-e4d333265ebb', 'academics.view', 'View academics', 'View academic operations.', '2026-10-01T00:01:59.763Z'),
  ('d8f20a6e-1f19-455a-9353-d22a5d4f5825', 'academics.manage', 'Manage academics', 'Manage academic master/operational data.', '2026-10-01T00:01:59.763Z'),
  ('70223469-e869-4098-ac98-0236901dfd82', 'academics.curriculum.manage', 'Manage curriculum', 'Manage curriculum and syllabus plans.', '2026-10-01T00:01:59.763Z'),
  ('acb5056e-000b-431b-9c48-26aecf26a18d', 'academics.sessions.manage', 'Manage sessions', 'Manage routines and class sessions.', '2026-10-01T00:01:59.763Z'),
  ('85981acb-bd20-4ad6-8d9a-fda0341a2763', 'academics.attendance.record', 'Record attendance', 'Create attendance drafts.', '2026-10-01T00:01:59.763Z'),
  ('8831b7df-9d08-4aa6-94ad-ef5e3ac4ebe3', 'academics.attendance.approve', 'Approve attendance', 'Approve/finalize attendance.', '2026-10-01T00:01:59.763Z'),
  ('c3450f46-3fca-40a9-ba3d-1844fec9eec1', 'academics.assessments.record', 'Record results', 'Create assessment/result drafts.', '2026-10-01T00:01:59.763Z'),
  ('63516397-0f55-4c49-95fb-0498dde3cede', 'academics.assessments.approve', 'Approve results', 'Approve/finalize assessment results.', '2026-10-01T00:01:59.763Z'),
  ('779e1218-5c74-48f7-b2c9-66f5599cce8d', 'academics.coverage.manage', 'Manage coverage', 'Manage coverage gaps and recovery.', '2026-10-01T00:01:59.763Z'),
  ('347865c6-326c-4118-bf24-bf79dba438f0', 'finance.view', 'View finance', 'View financial records and reports.', '2026-10-01T00:01:59.763Z'),
  ('c2287aad-b873-4494-8858-4b6d28fd9581', 'finance.billing.manage', 'Manage billing', 'Manage fee plans, charges and allocations.', '2026-10-01T00:01:59.763Z'),
  ('37afecd1-4957-4dd0-add5-99148eb84002', 'finance.payments.post', 'Post payments', 'Post official student payments.', '2026-10-01T00:01:59.763Z'),
  ('04abe3ea-fb8a-4948-903c-867461a4529a', 'finance.payments.reverse', 'Reverse payments', 'Request/approve controlled payment corrections.', '2026-10-01T00:01:59.763Z'),
  ('58ffbfa3-2f62-4804-83ab-526f521526f2', 'finance.discounts.approve', 'Approve discounts', 'Approve controlled discounts/scholarships.', '2026-10-01T00:01:59.763Z'),
  ('8732785b-3807-46c5-813f-05615325aab0', 'staff.view', 'View staff', 'View Staff directory and workload.', '2026-10-01T00:01:59.763Z'),
  ('90c35540-44be-48d2-9ac3-3745f40e3518', 'staff.manage', 'Manage staff', 'Manage Staff identities and assignments.', '2026-10-01T00:01:59.763Z'),
  ('806853d4-f997-4ec4-9728-8029ad8514cb', 'staff.leave.manage', 'Manage leave', 'Create/manage leave and availability.', '2026-10-01T00:01:59.763Z'),
  ('cf4d86b8-8082-4bda-ab0e-b834f3608adc', 'staff.leave.approve', 'Approve leave', 'Approve staff leave.', '2026-10-01T00:01:59.763Z'),
  ('2bd5d0cb-2b82-471c-8995-c0538687fd00', 'assets.view', 'View assets', 'View assets and maintenance.', '2026-10-01T00:01:59.763Z'),
  ('36b58db0-9301-45f7-9c7c-c593915f5fa0', 'assets.manage', 'Manage assets', 'Manage assets and lifecycle.', '2026-10-01T00:01:59.763Z'),
  ('3ea03b08-e09e-4388-8c0b-3a8beceb96dc', 'procurement.view', 'View procurement', 'View vendors and procurement.', '2026-10-01T00:01:59.763Z'),
  ('4be3482f-69de-4322-8ffc-2db3671b5464', 'procurement.manage', 'Manage procurement', 'Manage procurement workflows.', '2026-10-01T00:01:59.763Z'),
  ('bcbc44d7-0df1-4bc6-b122-535ad6642af4', 'procurement.approve', 'Approve procurement', 'Approve procurement workflows.', '2026-10-01T00:01:59.763Z'),
  ('656a44ed-9a85-4f23-b444-c3d36aee8f99', 'analytics.view', 'View analytics', 'View management analytics.', '2026-10-01T00:01:59.763Z'),
  ('f1d0a17d-d478-4806-b9bd-9597d3469ab7', 'system.master_data.manage', 'Manage master data', 'Manage controlled master data.', '2026-10-01T00:01:59.763Z'),
  ('350eea1a-63ce-42c2-a295-0b162bedcbe0', 'system.rules.view', 'View business rules', 'View versioned business rules.', '2026-10-01T00:01:59.763Z'),
  ('7bc9c055-8230-46fb-8856-5c2383593a70', 'system.rules.manage', 'Manage business rules', 'Create/retire rule versions.', '2026-10-01T00:01:59.763Z'),
  ('4e4177d2-5ca3-4a66-a484-518a1dd873b3', 'system.users.manage', 'Manage user access', 'Manage user-role assignments.', '2026-10-01T00:01:59.763Z'),
  ('e70337bd-740b-4025-9d03-3cce44446b83', 'audit.view', 'View audit trail', 'View immutable audit history.', '2026-10-01T00:01:59.763Z'),
  ('3cdc72f5-1858-4b63-9a2d-5f95520a42ef', 'approvals.view', 'View approvals', 'View approval requests.', '2026-10-01T00:01:59.763Z'),
  ('a7b6c0fb-5159-41cd-9d77-e8c0e3605aff', 'approvals.decide', 'Decide approvals', 'Approve/reject permitted workflows.', '2026-10-01T00:01:59.763Z'),
  ('97226053-3927-4caa-8c64-b8a187544fbe', 'system.settings.view', 'View settings', 'View configuration and active policy values.', '2026-10-01T00:01:59.763Z'),
  ('2e602462-fdb6-4825-a6e8-889424b21937', 'system.settings.manage', 'Manage settings', 'Publish versioned configuration changes.', '2026-10-01T00:01:59.763Z'),
  ('52b44dcd-44c4-4ac7-a5c5-e3f0dfa5dd09', 'system.roles.manage', 'Manage roles and permissions', 'Create/maintain role permission bundles.', '2026-10-01T00:01:59.763Z'),
  ('2143bda2-ea3b-4185-b20e-b893069e043a', 'students.merge.approve', 'Approve student identity merges', 'Independently approve linking a duplicate identity to its canonical student.', '2026-10-01T00:02:00.004Z'),
  ('d109a580-d3f0-4d2f-b446-7c53376cbd60', 'accounting.view', 'View accounting', 'View ledger, chart of accounts and reconciliations.', '2026-10-01T00:01:59.763Z'),
  ('c630ae87-efed-488e-b52c-a17d1a91c1c6', 'accounting.manage', 'Manage accounting', 'Post controlled accounting journals and mappings.', '2026-10-01T00:01:59.763Z'),
  ('c44d969b-2f3b-417e-88df-55bdbad62aa3', 'finance.advances.manage', 'Manage advances', 'Request, pay and settle staff/vendor/project advances.', '2026-10-01T00:01:59.763Z'),
  ('60d7cfa5-6246-4b22-a1b2-a4e498f656d7', 'finance.advances.approve', 'Approve advances', 'Approve or reject advance requests.', '2026-10-01T00:01:59.763Z'),
  ('0081143a-db43-45d3-81e1-852caf918102', 'staff.compensation.view', 'View teacher compensation', 'View teacher compensation calculations and settlements.', '2026-10-01T00:01:59.763Z'),
  ('dbbc76cd-96b1-4d8e-a814-8af4b7911623', 'staff.compensation.manage', 'Manage teacher compensation', 'Prepare compensation runs and settlements.', '2026-10-01T00:01:59.763Z'),
  ('0e202e69-dda1-4451-850a-4bdbcd5e9664', 'staff.compensation.approve', 'Approve teacher compensation', 'Approve compensation runs and adjustments.', '2026-10-01T00:01:59.763Z'),
  ('dc20e6f1-ca80-447b-b5d0-d0611272f34e', 'accounting.expense.manage', 'Manage expenses', 'Create and post controlled expense records.', '2026-10-01T00:02:00.143Z'),
  ('197d7aaf-7643-4772-8311-4f48a5dca668', 'accounting.expense.approve', 'Approve expenses', 'Approve expense records before posting.', '2026-10-01T00:02:00.143Z'),
  ('ce7437a3-9229-4284-acd0-5c2b6150bf06', 'accounting.reconcile', 'Reconcile financial records', 'Reconcile expenses and cash/bank statements.', '2026-10-01T00:02:00.143Z'),
  ('f7814aff-0ec0-4a00-b40e-66c33d06ad8f', 'finance.payments.reconcile', 'Reconcile payments', 'Match posted payments to controlled financial statements.', '2026-10-01T00:02:00.143Z');

insert into public.role_permissions (role_id, permission_id, created_at) values
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '9dd6ebe2-b267-4075-9fd7-495e334a2fb7', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'cff5b41c-2fbe-40c5-90ce-7b37b297cd67', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'b73f9cbb-b402-4fe7-8d76-acefbdcab89d', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '9b3239d4-d38c-40f3-82b8-fc73b2c44f6c', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '75911b3f-51c6-4760-8f01-3ae1455c1c05', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'c6356a75-43eb-4627-b585-fe924622a7c6', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '48a583b6-3a64-4c34-b8a8-8b041ff3f499', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '3d55d0ec-4cd4-444d-866d-ff641300803b', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '0e751c57-ad44-4837-8a09-b3e8de702ed8', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '8139a5df-b9d6-440a-a845-b90d06aba83b', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '60550137-7dfa-4111-afbb-e4d333265ebb', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'd8f20a6e-1f19-455a-9353-d22a5d4f5825', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '70223469-e869-4098-ac98-0236901dfd82', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'acb5056e-000b-431b-9c48-26aecf26a18d', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '85981acb-bd20-4ad6-8d9a-fda0341a2763', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '8831b7df-9d08-4aa6-94ad-ef5e3ac4ebe3', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'c3450f46-3fca-40a9-ba3d-1844fec9eec1', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '63516397-0f55-4c49-95fb-0498dde3cede', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '779e1218-5c74-48f7-b2c9-66f5599cce8d', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '347865c6-326c-4118-bf24-bf79dba438f0', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'c2287aad-b873-4494-8858-4b6d28fd9581', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '37afecd1-4957-4dd0-add5-99148eb84002', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '04abe3ea-fb8a-4948-903c-867461a4529a', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '58ffbfa3-2f62-4804-83ab-526f521526f2', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'c44d969b-2f3b-417e-88df-55bdbad62aa3', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '60d7cfa5-6246-4b22-a1b2-a4e498f656d7', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '8732785b-3807-46c5-813f-05615325aab0', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '90c35540-44be-48d2-9ac3-3745f40e3518', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '806853d4-f997-4ec4-9728-8029ad8514cb', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'cf4d86b8-8082-4bda-ab0e-b834f3608adc', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '0081143a-db43-45d3-81e1-852caf918102', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'dbbc76cd-96b1-4d8e-a814-8af4b7911623', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '0e202e69-dda1-4451-850a-4bdbcd5e9664', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '2bd5d0cb-2b82-471c-8995-c0538687fd00', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '36b58db0-9301-45f7-9c7c-c593915f5fa0', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '3ea03b08-e09e-4388-8c0b-3a8beceb96dc', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '4be3482f-69de-4322-8ffc-2db3671b5464', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'bcbc44d7-0df1-4bc6-b122-535ad6642af4', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'd109a580-d3f0-4d2f-b446-7c53376cbd60', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'c630ae87-efed-488e-b52c-a17d1a91c1c6', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '656a44ed-9a85-4f23-b444-c3d36aee8f99', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'f1d0a17d-d478-4806-b9bd-9597d3469ab7', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '350eea1a-63ce-42c2-a295-0b162bedcbe0', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '7bc9c055-8230-46fb-8856-5c2383593a70', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '4e4177d2-5ca3-4a66-a484-518a1dd873b3', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'e70337bd-740b-4025-9d03-3cce44446b83', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '3cdc72f5-1858-4b63-9a2d-5f95520a42ef', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'a7b6c0fb-5159-41cd-9d77-e8c0e3605aff', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '9dd6ebe2-b267-4075-9fd7-495e334a2fb7', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', 'cff5b41c-2fbe-40c5-90ce-7b37b297cd67', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', 'b73f9cbb-b402-4fe7-8d76-acefbdcab89d', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '0e751c57-ad44-4837-8a09-b3e8de702ed8', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '60550137-7dfa-4111-afbb-e4d333265ebb', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', 'd8f20a6e-1f19-455a-9353-d22a5d4f5825', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '70223469-e869-4098-ac98-0236901dfd82', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', 'acb5056e-000b-431b-9c48-26aecf26a18d', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '85981acb-bd20-4ad6-8d9a-fda0341a2763', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '8831b7df-9d08-4aa6-94ad-ef5e3ac4ebe3', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', 'c3450f46-3fca-40a9-ba3d-1844fec9eec1', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '63516397-0f55-4c49-95fb-0498dde3cede', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '779e1218-5c74-48f7-b2c9-66f5599cce8d', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '8732785b-3807-46c5-813f-05615325aab0', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '806853d4-f997-4ec4-9728-8029ad8514cb', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', 'cf4d86b8-8082-4bda-ab0e-b834f3608adc', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '656a44ed-9a85-4f23-b444-c3d36aee8f99', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', 'e70337bd-740b-4025-9d03-3cce44446b83', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '3cdc72f5-1858-4b63-9a2d-5f95520a42ef', '2026-10-01T00:01:59.763Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', 'a7b6c0fb-5159-41cd-9d77-e8c0e3605aff', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', '9dd6ebe2-b267-4075-9fd7-495e334a2fb7', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', 'cff5b41c-2fbe-40c5-90ce-7b37b297cd67', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', 'b73f9cbb-b402-4fe7-8d76-acefbdcab89d', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', '9b3239d4-d38c-40f3-82b8-fc73b2c44f6c', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', '75911b3f-51c6-4760-8f01-3ae1455c1c05', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', 'c6356a75-43eb-4627-b585-fe924622a7c6', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', '48a583b6-3a64-4c34-b8a8-8b041ff3f499', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', '0e751c57-ad44-4837-8a09-b3e8de702ed8', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', '8139a5df-b9d6-440a-a845-b90d06aba83b', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', '60550137-7dfa-4111-afbb-e4d333265ebb', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', '85981acb-bd20-4ad6-8d9a-fda0341a2763', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', '347865c6-326c-4118-bf24-bf79dba438f0', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', '37afecd1-4957-4dd0-add5-99148eb84002', '2026-10-01T00:01:59.763Z'),
  ('33ee061b-370f-4445-827e-35a3f75f6b6b', '8732785b-3807-46c5-813f-05615325aab0', '2026-10-01T00:01:59.763Z'),
  ('26b7ccdc-6303-499e-ba5a-1d5e716a2b45', '9dd6ebe2-b267-4075-9fd7-495e334a2fb7', '2026-10-01T00:01:59.763Z'),
  ('26b7ccdc-6303-499e-ba5a-1d5e716a2b45', 'cff5b41c-2fbe-40c5-90ce-7b37b297cd67', '2026-10-01T00:01:59.763Z'),
  ('26b7ccdc-6303-499e-ba5a-1d5e716a2b45', '0e751c57-ad44-4837-8a09-b3e8de702ed8', '2026-10-01T00:01:59.763Z'),
  ('26b7ccdc-6303-499e-ba5a-1d5e716a2b45', '60550137-7dfa-4111-afbb-e4d333265ebb', '2026-10-01T00:01:59.763Z'),
  ('26b7ccdc-6303-499e-ba5a-1d5e716a2b45', '85981acb-bd20-4ad6-8d9a-fda0341a2763', '2026-10-01T00:01:59.763Z'),
  ('26b7ccdc-6303-499e-ba5a-1d5e716a2b45', 'c3450f46-3fca-40a9-ba3d-1844fec9eec1', '2026-10-01T00:01:59.763Z'),
  ('26b7ccdc-6303-499e-ba5a-1d5e716a2b45', '8732785b-3807-46c5-813f-05615325aab0', '2026-10-01T00:01:59.763Z'),
  ('26b7ccdc-6303-499e-ba5a-1d5e716a2b45', '0081143a-db43-45d3-81e1-852caf918102', '2026-10-01T00:01:59.763Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', '9dd6ebe2-b267-4075-9fd7-495e334a2fb7', '2026-10-01T00:01:59.763Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', 'cff5b41c-2fbe-40c5-90ce-7b37b297cd67', '2026-10-01T00:01:59.763Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', '347865c6-326c-4118-bf24-bf79dba438f0', '2026-10-01T00:01:59.763Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', 'c2287aad-b873-4494-8858-4b6d28fd9581', '2026-10-01T00:01:59.763Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', '37afecd1-4957-4dd0-add5-99148eb84002', '2026-10-01T00:01:59.763Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', 'c44d969b-2f3b-417e-88df-55bdbad62aa3', '2026-10-01T00:01:59.763Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', '8732785b-3807-46c5-813f-05615325aab0', '2026-10-01T00:01:59.763Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', '0081143a-db43-45d3-81e1-852caf918102', '2026-10-01T00:01:59.763Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', 'd109a580-d3f0-4d2f-b446-7c53376cbd60', '2026-10-01T00:01:59.763Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', 'c630ae87-efed-488e-b52c-a17d1a91c1c6', '2026-10-01T00:01:59.763Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', '656a44ed-9a85-4f23-b444-c3d36aee8f99', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '97226053-3927-4caa-8c64-b8a187544fbe', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '2e602462-fdb6-4825-a6e8-889424b21937', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '52b44dcd-44c4-4ac7-a5c5-e3f0dfa5dd09', '2026-10-01T00:01:59.763Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '2143bda2-ea3b-4185-b20e-b893069e043a', '2026-10-01T00:02:00.004Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'dc20e6f1-ca80-447b-b5d0-d0611272f34e', '2026-10-01T00:02:00.143Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', '197d7aaf-7643-4772-8311-4f48a5dca668', '2026-10-01T00:02:00.143Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'ce7437a3-9229-4284-acd0-5c2b6150bf06', '2026-10-01T00:02:00.143Z'),
  ('178c3fa6-0f13-4273-bce0-f0cde61c217b', 'f7814aff-0ec0-4a00-b40e-66c33d06ad8f', '2026-10-01T00:02:00.143Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', '60d7cfa5-6246-4b22-a1b2-a4e498f656d7', '2026-10-01T00:02:00.143Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', 'dbbc76cd-96b1-4d8e-a814-8af4b7911623', '2026-10-01T00:02:00.143Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', 'dc20e6f1-ca80-447b-b5d0-d0611272f34e', '2026-10-01T00:02:00.143Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', 'ce7437a3-9229-4284-acd0-5c2b6150bf06', '2026-10-01T00:02:00.143Z'),
  ('30688fbe-f906-4065-8f5d-7817d6b80472', 'f7814aff-0ec0-4a00-b40e-66c33d06ad8f', '2026-10-01T00:02:00.143Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '0e202e69-dda1-4451-850a-4bdbcd5e9664', '2026-10-01T00:02:00.143Z'),
  ('61c66f45-b626-4d48-8d8d-e4221d8796ac', '197d7aaf-7643-4772-8311-4f48a5dca668', '2026-10-01T00:02:00.143Z');

insert into public.staff_roles (id, code, name, is_teaching_role, is_active, created_at) values
  ('f6f99555-7062-473e-b10f-f863347621cf', 'ADMINISTRATION', 'Administration', false, true, '2026-10-01T00:01:59.763Z'),
  ('05da9811-7cea-4c6a-a561-809d37598c29', 'ACADEMIC_DIRECTOR', 'Academic Director', false, true, '2026-10-01T00:01:59.763Z'),
  ('b89d472b-50fb-4bd0-b988-7a2996de89be', 'OPERATOR', 'Operator', false, true, '2026-10-01T00:01:59.763Z'),
  ('01b4eb7d-5b41-4722-97dc-ca0dcc3b466c', 'TEACHER', 'Teacher', true, true, '2026-10-01T00:01:59.763Z'),
  ('4d1eeb43-16ff-4ba0-bfde-91f67926c70b', 'ACCOUNTING', 'Accounting', false, true, '2026-10-01T00:01:59.763Z'),
  ('4c98d89f-57b3-4892-978e-d0affb87cdcd', 'COUNSELLOR', 'Counsellor', false, true, '2026-10-01T00:01:59.763Z'),
  ('3b34bbfb-e02a-44f6-832b-b5982a6740e2', 'SUPPORT', 'Support Staff', false, true, '2026-10-01T00:01:59.763Z');

insert into public.business_rule_versions (id, domain, rule_key, version, status, effective_from, effective_to, payload, change_reason, created_by, created_at) values
  ('b2d15b4a-4acd-488f-b576-5eee65af4fb7', 'academics', 'batch_capacity_policy', 1, 'ACTIVE', current_date, null, '{"max_students":12}', 'Initial Sohoj Academy batch-capacity policy.', null, '2026-10-01T00:01:59.763Z'),
  ('00bd2ba4-9d8b-4d86-9d12-58acb1f73124', 'teacher_compensation', 'default_policy', 1, 'ACTIVE', current_date, null, '{"teaching_pool_percent":30,"acquisition_bonus_percent":50,"retention_3_month_percent":15,"retention_6_month_percent":20,"teaching_pool_review_max_percent":40}', 'Initial management-approved teacher compensation policy.', null, '2026-10-01T00:01:59.763Z'),
  ('035d52a1-8c22-41e3-b077-4cc00597f797', 'admissions', 'activation_policy', 1, 'ACTIVE', current_date, null, '{"payment_requirement":"NONE","allow_credit_enrollment":true,"minimum_payment_percent":0,"requires_admission_acceptance":true,"requires_initial_billing_posted":true,"count_student_active_only_when_enrollment_active":true}', 'Initial configurable admission activation policy.', null, '2026-10-01T00:01:59.763Z');

insert into public.lead_sources (id, organization_id, code, name, is_active, created_at) values
  ('e5c747a3-efce-4025-b415-6bcadb0fd2e8', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'WALK_IN', 'Walk-in', true, '2026-10-01T00:01:59.763Z'),
  ('ac038b68-8895-4305-a71e-8fda2f6b75e8', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'SOCIAL', 'Social Media', true, '2026-10-01T00:01:59.763Z'),
  ('28e466e1-bf29-4573-9183-6df5d9e2d016', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'TEACHER_REFERRAL', 'Teacher Referral', true, '2026-10-01T00:01:59.763Z'),
  ('e5ec3e55-6d66-48b1-9018-568527df0e14', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'STUDENT_REFERRAL', 'Student Referral', true, '2026-10-01T00:01:59.763Z'),
  ('955de145-6307-4948-8bef-3b447a3bee0e', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'GUARDIAN_REFERRAL', 'Guardian Referral', true, '2026-10-01T00:01:59.763Z'),
  ('f7b369b2-c864-4bca-a75f-bf0b898e4c9b', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'SCHOOL_VISIT', 'School Visit', true, '2026-10-01T00:01:59.763Z'),
  ('fab3a5f0-b792-4d23-82e8-ea2f004b3594', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'OFFLINE_CAMPAIGN', 'Offline Campaign', true, '2026-10-01T00:01:59.763Z'),
  ('09e6183d-0067-4c06-ae19-e7d53e5ebf09', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'OTHER', 'Other', true, '2026-10-01T00:01:59.763Z');

insert into public.guardian_relationships (id, organization_id, code, name, is_active, created_at) values
  ('583c5b6a-3f70-4ce4-abbf-d11d42da500c', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'FATHER', 'Father', true, '2026-10-01T00:01:59.763Z'),
  ('6951b5a7-a311-49db-800a-0127a1a12aec', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'MOTHER', 'Mother', true, '2026-10-01T00:01:59.763Z'),
  ('417a344e-4099-4d62-8fa4-ad4c50d698bc', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'BROTHER', 'Brother', true, '2026-10-01T00:01:59.763Z'),
  ('013156c8-1d66-44e2-bf05-2a073af2809d', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'SISTER', 'Sister', true, '2026-10-01T00:01:59.763Z'),
  ('49bc8399-f117-4410-9682-a8192a35ae85', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'GRANDFATHER', 'Grandfather', true, '2026-10-01T00:01:59.763Z'),
  ('e12dedaa-bf2d-44ee-827c-28a4992d3967', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'GRANDMOTHER', 'Grandmother', true, '2026-10-01T00:01:59.763Z'),
  ('dbd73253-dfe3-4010-80d5-048cf3bba8d7', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'UNCLE', 'Uncle', true, '2026-10-01T00:01:59.763Z'),
  ('ee0924a3-677f-4854-a709-0b75bc99ab4b', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'AUNT', 'Aunt', true, '2026-10-01T00:01:59.763Z'),
  ('f119874d-d96f-4933-804e-7830f84f2d11', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'OTHER_GUARDIAN', 'Other Guardian', true, '2026-10-01T00:01:59.763Z');

insert into public.payment_methods (id, organization_id, code, name, is_active, created_at) values
  ('49fa93bb-1ddb-488f-b02a-16009bbe448a', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'CASH', 'Cash', true, '2026-10-01T00:01:59.763Z'),
  ('8accc7de-2d80-4127-9e33-5cc8ae9a6ec8', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'BANK', 'Bank', true, '2026-10-01T00:01:59.763Z'),
  ('915255be-0009-4238-b79d-7557d2f8db2b', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'MOBILE_BANKING', 'Mobile Banking', true, '2026-10-01T00:01:59.763Z');

insert into public.finance_accounts (id, organization_id, code, name, account_type, account_subtype, parent_id, is_control_account, is_active, created_by, created_at) values
  ('eca950c9-02e5-4766-a900-9c2940a45c4a', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '1100', 'Cash', 'ASSET', 'CASH', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('5ad73100-1ef1-4d65-b342-682c8348789f', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '1110', 'Bank', 'ASSET', 'BANK', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('fab61cfe-d1bc-499a-9f71-a638caec8011', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '1120', 'Mobile Banking', 'ASSET', 'MOBILE_BANK', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('c0dcd0ca-c3ef-4e81-84fd-d33f6bae0bf1', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '1200', 'Student Receivables', 'ASSET', 'STUDENT_RECEIVABLE', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('f8d39e2c-2ea1-4b8b-90b4-4350254bbc41', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '1210', 'Staff Advances', 'ASSET', 'STAFF_ADVANCE', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('66214959-7abe-4f98-8a69-afd22f59c0bf', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '1220', 'Vendor Advances', 'ASSET', 'VENDOR_ADVANCE', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('85f0f7ae-e163-4ce7-b427-3301d6f2b6b0', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '2100', 'Teacher Compensation Payable', 'LIABILITY', 'TEACHER_PAYABLE', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('9dd31f36-5a1b-44b3-a03a-e31f161a9a91', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '2110', 'Vendor Payable', 'LIABILITY', 'VENDOR_PAYABLE', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('6403e5b6-2e5b-497a-9b93-66e8a0a93e7c', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '2120', 'Staff Reimbursement Payable', 'LIABILITY', 'STAFF_PAYABLE', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('6607d0b7-2461-4635-b311-e79f5eef0d2f', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '3000', 'Retained Earnings', 'EQUITY', 'RETAINED_EARNINGS', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('b9f1ee54-7d26-4b4a-984b-8842a4fa1a97', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '4000', 'Tuition Revenue', 'REVENUE', 'TUITION_REVENUE', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('bf7adad8-c3ed-49df-ad6c-e463890f1251', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '4010', 'Admission Revenue', 'REVENUE', 'ADMISSION_REVENUE', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('267dc3e3-b53f-4750-8193-8ee706407345', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '4020', 'Other Fee Revenue', 'REVENUE', 'OTHER_FEE_REVENUE', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('41ad753b-0c71-438e-971e-65007907874a', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '4090', 'Discounts & Cancellation Credits', 'CONTRA_REVENUE', 'FEE_CREDITS', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('605180b5-c602-4b4c-9213-c44204bd06b7', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '5000', 'Teaching Compensation Expense', 'EXPENSE', 'TEACHING_COMPENSATION', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('3ede81d2-752d-4317-8f89-cceb546a6dbb', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '5100', 'General Operating Expense', 'EXPENSE', 'OPERATING_EXPENSE', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('2544cbbc-25da-4a92-a624-a31f9586cae1', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '2130', 'Referral Reward Payable', 'LIABILITY', 'REFERRER_PAYABLE', null, true, true, null, '2026-10-01T00:02:00.143Z'),
  ('7fb195cf-f099-4f73-8f98-45b71e151172', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', '5200', 'Student Acquisition Expense', 'EXPENSE', 'ACQUISITION_EXPENSE', null, true, true, null, '2026-10-01T00:02:00.143Z');

insert into public.finance_payment_account_map (payment_method_id, account_id, created_at) values
  ('49fa93bb-1ddb-488f-b02a-16009bbe448a', 'eca950c9-02e5-4766-a900-9c2940a45c4a', '2026-10-01T00:02:00.143Z'),
  ('8accc7de-2d80-4127-9e33-5cc8ae9a6ec8', '5ad73100-1ef1-4d65-b342-682c8348789f', '2026-10-01T00:02:00.143Z'),
  ('915255be-0009-4238-b79d-7557d2f8db2b', 'fab61cfe-d1bc-499a-9f71-a638caec8011', '2026-10-01T00:02:00.143Z');

insert into public.finance_fee_revenue_map (id, organization_id, charge_type, account_id, created_at) values
  ('5fc2486c-88f6-4dd8-987b-a62d740404e8', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'TUITION', 'b9f1ee54-7d26-4b4a-984b-8842a4fa1a97', '2026-10-01T00:02:00.143Z'),
  ('0c7b433b-0aa5-43f5-9351-17c831f9bc96', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'ADMISSION', 'bf7adad8-c3ed-49df-ad6c-e463890f1251', '2026-10-01T00:02:00.143Z'),
  ('590d02ac-9533-44d9-90c6-1f776db5ad5b', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'EXAM', '267dc3e3-b53f-4750-8193-8ee706407345', '2026-10-01T00:02:00.143Z'),
  ('8e96eab1-988a-4698-be76-5f650dfbc25d', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'MATERIALS', '267dc3e3-b53f-4750-8193-8ee706407345', '2026-10-01T00:02:00.143Z'),
  ('9e71bc96-2d6a-47a2-8971-29fe9a4767e6', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'BOOKS', '267dc3e3-b53f-4750-8193-8ee706407345', '2026-10-01T00:02:00.143Z'),
  ('0fd4d1b6-c384-4e92-a221-5f9c6e6b3ab8', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'OTHER', '267dc3e3-b53f-4750-8193-8ee706407345', '2026-10-01T00:02:00.143Z');

insert into public.finance_expense_categories (id, organization_id, code, name, expense_account_id, is_active, created_by, created_at) values
  ('c2a73c6b-1b14-4e1a-8a5e-a2eb0bcd94cf', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'GENERAL', 'General Operating Expense', '3ede81d2-752d-4317-8f89-cceb546a6dbb', true, null, '2026-10-01T00:02:00.143Z'),
  ('b834c4ba-ce6c-4ad8-95c2-af9f21ef9d7b', 'bc4198a2-31a0-45f6-81ed-72e4e87a15fb', 'TEACHING', 'Teaching Compensation', '605180b5-c602-4b4c-9213-c44204bd06b7', true, null, '2026-10-01T00:02:00.143Z');

insert into public.profiles(id,display_name) select id,coalesce(nullif(raw_user_meta_data->>'full_name',''),split_part(email,'@',1)) from auth.users on conflict(id) do nothing;

-- Upstream 14_referrer_portal_collection_discounts.sql
-- Forward migration: apply after the fresh 01-13 baseline. No reset required.
alter table public.referral_people add column email text;
alter table public.referral_people add column profile_id uuid references public.profiles(id);
alter table public.referral_people add column is_active boolean not null default true;
create unique index referral_people_profile_unique on public.referral_people(profile_id) where profile_id is not null;
update public.referral_people r set profile_id=s.profile_id,email=s.email from public.staff s where s.id=r.staff_id;
alter table public.invoice_credits add column category text not null default 'DISCOUNT' check(category in('DISCOUNT','SCHOLARSHIP','ADJUSTMENT','CANCELLATION'));
alter table public.invoice_credits add column description text;
update public.invoice_credits set category='CANCELLATION' where kind='CANCELLATION';
create table public.referral_reward_contracts (
 admission_id uuid primary key references public.admission_cases(id), referrer_id uuid not null references public.referral_people(id),
 billing_period date not null, bonus_percent numeric(7,3) not null check(bonus_percent between 0 and 100),
 policy_version_id uuid not null references public.business_rule_versions(id), created_at timestamptz not null default now()
);
create table public.referral_reward_entries (
 id uuid primary key default gen_random_uuid(), admission_id uuid not null references public.admission_cases(id),
 referrer_id uuid not null references public.referral_people(id), amount numeric(14,2) not null check(amount<>0),
 net_collected numeric(14,2) not null, bonus_percent numeric(7,3) not null, journal_id uuid references public.general_ledger_journals(id),
 payable_id uuid references public.finance_payables(id), source_reference text unique, created_at timestamptz not null default now(), actor_id uuid references public.profiles(id)
);
alter table public.referral_reward_contracts enable row level security;
alter table public.referral_reward_entries enable row level security;
revoke all on public.referral_reward_contracts,public.referral_reward_entries from anon,authenticated;
grant all on public.referral_reward_contracts,public.referral_reward_entries to service_role;
insert into public.permissions(code,name,description) values('referrals.portal.view','View own referrals','Only referrals linked to the signed-in identity') on conflict(code) do nothing;
insert into public.system_roles(code,name,description,is_system) values('REFERRER','Referrer','Own referred students and reward statement only',true) on conflict(code) do nothing;
insert into public.role_permissions(role_id,permission_id) select r.id,p.id from public.system_roles r cross join public.permissions p where r.code='REFERRER' and p.code='referrals.portal.view' on conflict do nothing;
insert into public.role_permissions(role_id,permission_id) select r.id,p.id from public.system_roles r cross join public.permissions p where r.code in('ADMIN','OPERATOR','TEACHER','ACCOUNTANT','ACADEMIC_DIRECTOR') and p.code='referrals.portal.view' on conflict do nothing;


CREATE OR REPLACE FUNCTION public.validate_business_rule_payload(p_domain text, p_rule_key text, p_payload jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
declare
  v_pool numeric;
  v_pool_max numeric;
  v_acquisition numeric;
  v_retention_3 numeric;
  v_retention_6 numeric;
  v_capacity numeric;
  v_payment_requirement text;
  v_minimum_payment numeric;
begin
  if p_payload is null or jsonb_typeof(p_payload)<>'object' then return false; end if;

  if p_domain='referrals' and p_rule_key='acquisition_policy' then
    return jsonb_typeof(p_payload->'bonus_percent')='number' and (p_payload->>'bonus_percent')::numeric between 0 and 100;
  end if;
  if p_domain='finance' and p_rule_key='collection_discount_policy' then
    return jsonb_typeof(p_payload->'max_discount_percent')='number' and jsonb_typeof(p_payload->'max_scholarship_percent')='number'
      and (p_payload->>'max_discount_percent')::numeric between 0 and 100 and (p_payload->>'max_scholarship_percent')::numeric between 0 and 100;
  end if;
  if p_domain='academics'  and p_rule_key='batch_capacity_policy' then
    if jsonb_typeof(p_payload->'max_students')<>'number' then return false; end if;
    v_capacity:=(p_payload->>'max_students')::numeric;
    return v_capacity=trunc(v_capacity) and v_capacity between 1 and 500;
  end if;

  if p_domain='teacher_compensation' and p_rule_key='default_policy' then
    if jsonb_typeof(p_payload->'teaching_pool_percent')<>'number'
       or jsonb_typeof(p_payload->'teaching_pool_review_max_percent')<>'number'
       or jsonb_typeof(p_payload->'acquisition_bonus_percent')<>'number'
       or jsonb_typeof(p_payload->'retention_3_month_percent')<>'number'
       or jsonb_typeof(p_payload->'retention_6_month_percent')<>'number' then
      return false;
    end if;
    v_pool:=(p_payload->>'teaching_pool_percent')::numeric;
    v_pool_max:=(p_payload->>'teaching_pool_review_max_percent')::numeric;
    v_acquisition:=(p_payload->>'acquisition_bonus_percent')::numeric;
    v_retention_3:=(p_payload->>'retention_3_month_percent')::numeric;
    v_retention_6:=(p_payload->>'retention_6_month_percent')::numeric;
    if coalesce(p_payload->>'teaching_allocation_method','APPROVED_SESSION_WEIGHT')
       not in('APPROVED_SESSION_WEIGHT') then
      return false;
    end if;
    return v_pool between 0 and 100
      and v_pool_max between 0 and 100
      and v_pool<=v_pool_max
      and v_acquisition between 0 and 100
      and v_retention_3 between 0 and 100
      and v_retention_6 between 0 and 100;
  end if;

  if p_domain='admissions' and p_rule_key='activation_policy' then
    if jsonb_typeof(p_payload->'requires_admission_acceptance')<>'boolean'
       or jsonb_typeof(p_payload->'requires_initial_billing_posted')<>'boolean'
       or jsonb_typeof(p_payload->'allow_credit_enrollment')<>'boolean'
       or jsonb_typeof(p_payload->'count_student_active_only_when_enrollment_active')<>'boolean'
       or jsonb_typeof(p_payload->'minimum_payment_percent')<>'number'
       or jsonb_typeof(p_payload->'payment_requirement')<>'string' then return false; end if;
    v_payment_requirement:=p_payload->>'payment_requirement';
    v_minimum_payment:=(p_payload->>'minimum_payment_percent')::numeric;
    if v_payment_requirement not in('NONE','MINIMUM_PERCENT','FULL') then return false; end if;
    if v_minimum_payment<0 or v_minimum_payment>100 then return false; end if;
    if v_payment_requirement='NONE' and v_minimum_payment<>0 then return false; end if;
    if v_payment_requirement='MINIMUM_PERCENT' and (v_minimum_payment<=0 or v_minimum_payment>=100) then return false; end if;
    if v_payment_requirement='FULL' and v_minimum_payment<>100 then return false; end if;
    return true;
  end if;

  return false;
exception when others then
  return false;
end;
$function$;

insert into public.business_rule_versions(domain,rule_key,version,status,effective_from,payload,change_reason)
select 'referrals','acquisition_policy',1,'ACTIVE',current_date,jsonb_build_object('bonus_percent',coalesce((payload->>'acquisition_bonus_percent')::numeric,50)), 'Initial unified referrer acquisition settings'
from public.business_rule_versions where domain='teacher_compensation' and rule_key='default_policy' and status='ACTIVE' order by version desc limit 1;
insert into public.business_rule_versions(domain,rule_key,version,status,effective_from,payload,change_reason)
values('finance','collection_discount_policy',1,'ACTIVE',current_date,'{"max_discount_percent":30,"max_scholarship_percent":100}','Initial authorized collection-time adjustment limits');


CREATE OR REPLACE FUNCTION public.teacher_compensation_preview(p_from date, p_to date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid:=auth.uid();
  policy public.business_rule_versions;
  rows jsonb:='[]'::jsonb;
  teacher_row record;
  batch_row record;
  event_amount numeric;
  pool_percent numeric;
  acquisition_percent numeric;
  retention3_percent numeric;
  retention6_percent numeric;
  first_period date;
  first_collected numeric;
  month3 date;
  month6 date;
  month_paid boolean;
  continuous3 boolean;
  continuous6 boolean;
begin
  if actor is null or not public.has_permission('staff.compensation.view') then
    raise exception 'Compensation access denied.';
  end if;
  if p_from is null or p_to is null or p_to<p_from then
    raise exception 'Choose a valid compensation period.';
  end if;

  select * into policy
  from public.business_rule_versions
  where domain='teacher_compensation'
    and rule_key='default_policy'
    and status='ACTIVE'
  order by version desc
  limit 1;

  if policy.id is null
     or not public.validate_business_rule_payload('teacher_compensation','default_policy',policy.payload) then
    raise exception 'A valid teacher compensation policy is required.';
  end if;

  pool_percent:=(policy.payload->>'teaching_pool_percent')::numeric;
  acquisition_percent:=(policy.payload->>'acquisition_bonus_percent')::numeric;
  retention3_percent:=(policy.payload->>'retention_3_month_percent')::numeric;
  retention6_percent:=(policy.payload->>'retention_6_month_percent')::numeric;

  -- Teaching pool is calculated per batch from Net Collected Tuition and
  -- allocated by approved attendance/session workload within that batch.
  for batch_row in
    with batch_revenue as (
      select batch_id,sum(tuition_collected) net_collected
      from public.finance_net_collected_tuition(p_from,p_to)
      group by batch_id
    ),
    session_weights as (
      select
        cs.batch_id,
        cs.teacher_id,
        count(*) filter(
          where exists(
            select 1 from public.attendance_submissions aa
            where aa.id=(
              select z.id from public.attendance_submissions z
              where z.session_id=cs.id
              order by z.revision desc limit 1
            )
            and aa.status='APPROVED'
          )
        )::numeric as session_count
      from public.class_sessions cs
      where cs.session_date between p_from and p_to
        and cs.status='SCHEDULED'
      group by cs.batch_id,cs.teacher_id
    )
    select
      r.batch_id,
      r.net_collected,
      r.net_collected*pool_percent/100 as pool_amount,
      w.teacher_id,
      w.session_count,
      sum(w.session_count) over(partition by w.batch_id) total_sessions
    from batch_revenue r
    join session_weights w on w.batch_id=r.batch_id
    where r.net_collected>0 and w.session_count>0
  loop
    event_amount:=round(batch_row.pool_amount*batch_row.session_count/nullif(batch_row.total_sessions,0),2);
    if event_amount>0 and not exists (select 1 from public.teacher_compensation_claims c
      where c.teacher_id=batch_row.teacher_id and c.source_type='BATCH_PERIOD'
        and c.source_id=batch_row.batch_id::text||':'||p_from::text||':'||p_to::text) then
    rows:=rows||jsonb_build_array(
      jsonb_build_object(
        'teacherId',batch_row.teacher_id,
        'lineType','TEACHING_REMUNERATION',
        'amount',event_amount,
        'sourceType','BATCH_PERIOD',
        'sourceId',batch_row.batch_id::text||':'||p_from::text||':'||p_to::text,
        'calculation',jsonb_build_object(
          'batchId',batch_row.batch_id,
          'netCollectedTuition',batch_row.net_collected,
          'poolPercent',pool_percent,
          'poolAmount',batch_row.pool_amount,
          'approvedSessions',batch_row.session_count,
          'batchApprovedSessions',batch_row.total_sessions
        )
      )
    );
    end if;
  end loop;

  -- Acquisition/retention bonuses require a structured teacher referral.
  for teacher_row in
    select
      tr.teacher_id,
      tr.admission_id,
      min(n.billing_period) first_billing_period
    from public.teacher_referrals tr
    join public.admission_cases a on a.id=tr.admission_id and a.status='ACTIVE_ENROLLMENT'
    join public.finance_net_collected_tuition(date '2000-01-01',p_to) n
      on n.admission_id=tr.admission_id and n.tuition_collected>0
    group by tr.teacher_id,tr.admission_id
  loop
    first_period:=teacher_row.first_billing_period;

    select coalesce(sum(n.tuition_collected),0)
    into first_collected
    from public.finance_net_collected_tuition(first_period,(first_period+interval '1 month - 1 day')::date) n
    where n.admission_id=teacher_row.admission_id;

    -- Acquisition is accrued by the unified referrer collection workflow.
    month3:=(first_period+interval '2 months')::date;
    month6:=(first_period+interval '5 months')::date;

    select bool_and(tuition_collected>0)
    into continuous3
    from (
      select
        m.month_start,
        coalesce((
          select sum(n.tuition_collected)
          from public.finance_net_collected_tuition(m.month_start,(m.month_start+interval '1 month - 1 day')::date) n
          where n.admission_id=teacher_row.admission_id
        ),0) tuition_collected
      from generate_series(first_period,month3,interval '1 month') g
      cross join lateral(select g::date month_start) m
    ) x;

    if month3 between p_from and p_to and continuous3 is true
      and not exists(select 1 from public.teacher_compensation_claims c
        where c.teacher_id=teacher_row.teacher_id and c.source_type='RETENTION_3'
          and c.source_id=teacher_row.admission_id::text) then
      select coalesce(sum(n.tuition_collected),0)
      into event_amount
      from public.finance_net_collected_tuition(month3,(month3+interval '1 month - 1 day')::date) n
      where n.admission_id=teacher_row.admission_id;

      if event_amount>0 then
        rows:=rows||jsonb_build_array(
          jsonb_build_object(
            'teacherId',teacher_row.teacher_id,
            'admissionId',teacher_row.admission_id,
            'lineType','RETENTION_3_MONTH',
            'amount',round(event_amount*retention3_percent/100,2),
            'sourceType','RETENTION_3',
            'sourceId',teacher_row.admission_id::text,
            'calculation',jsonb_build_object(
              'milestoneMonth',month3,
              'monthNetCollectedTuition',event_amount,
              'bonusPercent',retention3_percent
            )
          )
        );
      end if;
    end if;

    select bool_and(tuition_collected>0)
    into continuous6
    from (
      select
        m.month_start,
        coalesce((
          select sum(n.tuition_collected)
          from public.finance_net_collected_tuition(m.month_start,(m.month_start+interval '1 month - 1 day')::date) n
          where n.admission_id=teacher_row.admission_id
        ),0) tuition_collected
      from generate_series(first_period,month6,interval '1 month') g
      cross join lateral(select g::date month_start) m
    ) x;

    if month6 between p_from and p_to and continuous6 is true
      and not exists(select 1 from public.teacher_compensation_claims c
        where c.teacher_id=teacher_row.teacher_id and c.source_type='RETENTION_6'
          and c.source_id=teacher_row.admission_id::text) then
      select coalesce(sum(n.tuition_collected),0)
      into event_amount
      from public.finance_net_collected_tuition(month6,(month6+interval '1 month - 1 day')::date) n
      where n.admission_id=teacher_row.admission_id;

      if event_amount>0 then
        rows:=rows||jsonb_build_array(
          jsonb_build_object(
            'teacherId',teacher_row.teacher_id,
            'admissionId',teacher_row.admission_id,
            'lineType','RETENTION_6_MONTH',
            'amount',round(event_amount*retention6_percent/100,2),
            'sourceType','RETENTION_6',
            'sourceId',teacher_row.admission_id::text,
            'calculation',jsonb_build_object(
              'milestoneMonth',month6,
              'monthNetCollectedTuition',event_amount,
              'bonusPercent',retention6_percent
            )
          )
        );
      end if;
    end if;
  end loop;

  for teacher_row in
    select teacher_id,adjustment_type,id,amount
    from public.teacher_compensation_adjustments
    where status='APPROVED'
      and effective_period between p_from and p_to
      and not exists(select 1 from public.teacher_compensation_claims c
        where c.teacher_id=teacher_compensation_adjustments.teacher_id
          and c.source_type='ADJUSTMENT' and c.source_id=teacher_compensation_adjustments.id::text)
  loop
    rows:=rows||jsonb_build_array(
      jsonb_build_object(
        'teacherId',teacher_row.teacher_id,
        'lineType',case when teacher_row.adjustment_type='GROWTH_BONUS'
          then 'GROWTH_BONUS' else 'ADJUSTMENT' end,
        'amount',teacher_row.amount,
        'sourceType','ADJUSTMENT',
        'sourceId',teacher_row.id::text,
        'calculation',jsonb_build_object(
          'adjustmentType',teacher_row.adjustment_type
        )
      )
    );
  end loop;

  return jsonb_build_object(
    'periodStart',p_from,
    'periodEnd',p_to,
    'policyVersion',policy.version,
    'rows',rows,
    'total',coalesce((select sum((x->>'amount')::numeric) from jsonb_array_elements(rows) x),0)
  );
end;
$function$;

-- Monetary collection attributed to tuition after recorded discounts and refunds.
create function public.referral_invoice_collections(p_admission_id uuid)
returns table(invoice_id uuid,billing_period date,tuition_net numeric,net_paid numeric,tuition_collected numeric)
language sql stable security definer set search_path='public' as $$
select i.id,i.billing_period,n.tuition_net,c.net_paid,
 round(least(n.tuition_net,case when n.net_invoice>0 then c.net_paid*least(n.tuition_net,n.net_invoice)/n.net_invoice else 0 end),2)
from public.admission_invoices i
cross join lateral(select greatest(i.total-coalesce(sum(ic.amount),0),0) net_invoice,
 greatest(coalesce((select sum(l.amount) from public.admission_invoice_lines l where l.invoice_id=i.id and l.charge_type='TUITION'),0)-coalesce(sum(ic.amount) filter(where ic.kind='DISCOUNT'),0),0) tuition_net
 from public.invoice_credits ic where ic.invoice_id=i.id) n
cross join lateral(select greatest(coalesce((select sum(pa.amount) from public.admission_payment_allocations pa where pa.invoice_id=i.id),0)-coalesce((select sum(ra.amount) from public.refund_authorizations ra join public.refund_payouts rp on rp.authorization_id=ra.id where ra.invoice_id=i.id),0),0) net_paid) c
where i.admission_id=p_admission_id;
$$;
-- Preserve previously posted external awards as opening evidence, without reposting journals.
insert into public.referral_reward_contracts(admission_id,referrer_id,billing_period,bonus_percent,policy_version_id)
select admission_id,referrer_id,period_start,bonus_percent,policy_version_id from public.referral_bonus_awards where status='APPROVED' on conflict do nothing;
insert into public.referral_reward_entries(admission_id,referrer_id,amount,net_collected,bonus_percent,payable_id,source_reference,actor_id)
select admission_id,referrer_id,amount,net_collected,bonus_percent,payable_id,'LEGACY_AWARD:'||id,requested_by from public.referral_bonus_awards where status='APPROVED';
-- Teacher acquisition already posted in an older run must not accrue twice.
insert into public.referral_reward_contracts(admission_id,referrer_id,billing_period,bonus_percent,policy_version_id)
select distinct on(l.admission_id) l.admission_id,ar.referrer_id,date_trunc('month',r.period_start)::date,
 coalesce((l.calculation->>'bonusPercent')::numeric,0),r.policy_version_id
from public.teacher_compensation_lines l join public.teacher_compensation_runs r on r.id=l.run_id
join public.admission_referrals ar on ar.admission_id=l.admission_id and ar.source='REFERRED'
where l.line_type='ACQUISITION_BONUS' and r.status='APPROVED' order by l.admission_id,r.created_at on conflict do nothing;
insert into public.referral_reward_entries(admission_id,referrer_id,amount,net_collected,bonus_percent,source_reference,actor_id)
select l.admission_id,ar.referrer_id,l.amount,coalesce((l.calculation->>'firstMonthNetCollectedTuition')::numeric,0),coalesce((l.calculation->>'bonusPercent')::numeric,0),'LEGACY_TEACHER:'||l.id,r.submitted_by
from public.teacher_compensation_lines l join public.teacher_compensation_runs r on r.id=l.run_id
join public.admission_referrals ar on ar.admission_id=l.admission_id and ar.source='REFERRED'
where l.line_type='ACQUISITION_BONUS' and r.status='APPROVED' and l.amount>0;
create function public.sync_referral_reward(p_admission_id uuid) returns void
language plpgsql security definer set search_path='public' as $$
declare a public.admission_cases; ar public.admission_referrals; c public.referral_reward_contracts;
 policy public.business_rule_versions; person public.referral_people; first_month date; collected numeric; target numeric; delta numeric;
 actor uuid; org uuid; liability uuid; expense uuid; payable uuid; event_id uuid:=gen_random_uuid(); journal uuid;
begin
 select * into a from public.admission_cases where id=p_admission_id for update;
 if a.id is null then return; end if;
 select * into ar from public.admission_referrals where admission_id=a.id;
 if ar.source is distinct from 'REFERRED' then return; end if;
 select * into person from public.referral_people where id=ar.referrer_id;
 select * into c from public.referral_reward_contracts where admission_id=a.id;
 actor:=coalesce(auth.uid(),a.created_by); org:=person.organization_id;
 if c.admission_id is null then
   select min(billing_period) into first_month from public.referral_invoice_collections(a.id) where tuition_collected>0;
   if first_month is null then return; end if;
   select * into policy from public.business_rule_versions where domain='referrals' and rule_key='acquisition_policy' and status='ACTIVE' order by version desc limit 1;
   if policy.id is null then raise exception 'Configure referrer acquisition settings first.'; end if;
   insert into public.referral_reward_contracts(admission_id,referrer_id,billing_period,bonus_percent,policy_version_id)
   values(a.id,person.id,first_month,(policy.payload->>'bonus_percent')::numeric,policy.id) returning * into c;
 end if;
 select coalesce(sum(tuition_collected),0) into collected from public.referral_invoice_collections(a.id) where billing_period=c.billing_period;
 target:=round(collected*c.bonus_percent/100,2);
 select target-coalesce(sum(amount),0) into delta from public.referral_reward_entries where admission_id=a.id;
 if delta=0 then return; end if;
 select id into liability from public.finance_accounts where organization_id=org and code='2130';
 select id into expense from public.finance_accounts where organization_id=org and code='5200';
 if delta>0 then
  insert into public.finance_payables(organization_id,payable_type,referrer_id,source_type,source_id,payable_account_id,original_amount,due_on,created_by)
  values(org,'OTHER',c.referrer_id,'REFERRAL_ACCRUAL',event_id::text,liability,delta,current_date,actor) returning id into payable;
 end if;
 journal:=public.finance_post_journal(org,current_date,'COMPENSATION_RUN','REFERRAL_ACCRUAL',event_id::text,
 'Referral acquisition entitlement adjusted to actual net tuition collected',actor,
 case when delta>0 then jsonb_build_array(jsonb_build_object('account_id',expense,'debit',delta,'credit',0),jsonb_build_object('account_id',liability,'debit',0,'credit',delta))
 else jsonb_build_array(jsonb_build_object('account_id',liability,'debit',-delta,'credit',0),jsonb_build_object('account_id',expense,'debit',0,'credit',-delta)) end);
 insert into public.referral_reward_entries(id,admission_id,referrer_id,amount,net_collected,bonus_percent,journal_id,payable_id,actor_id)
 values(event_id,a.id,c.referrer_id,delta,collected,c.bonus_percent,journal,payable,actor);
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,after_data)
 values(actor,'REFERRAL_REWARD',event_id::text,case when delta>0 then 'ACCRUE' else 'CORRECT' end,'Based on actual net collected tuition',jsonb_build_object('admission_id',a.id,'amount',delta,'net_collected',collected,'rate',c.bonus_percent));
end; $$;
create function public.referral_collection_changed() returns trigger language plpgsql security definer set search_path='public' as $$
declare admission uuid;
begin
 if TG_TABLE_NAME='admission_payment_allocations' then select admission_id into admission from public.admission_invoices where id=new.invoice_id;
 elsif TG_TABLE_NAME='invoice_credits' then select admission_id into admission from public.admission_invoices where id=new.invoice_id;
 elsif TG_TABLE_NAME='refund_payouts' then select i.admission_id into admission from public.refund_authorizations r join public.admission_invoices i on i.id=r.invoice_id where r.id=new.authorization_id;
 else admission:=new.admission_id; end if;
 perform public.sync_referral_reward(admission); return new;
end; $$;
create trigger referral_collection_accrual after insert on public.admission_payment_allocations for each row execute function public.referral_collection_changed();
create trigger referral_discount_correction after insert on public.invoice_credits for each row execute function public.referral_collection_changed();
create trigger referral_refund_correction after insert on public.refund_payouts for each row execute function public.referral_collection_changed();
create trigger referral_capture_accrual after insert or update on public.admission_referrals for each row execute function public.referral_collection_changed();
create function public.referrer_paid(p_referrer uuid) returns numeric language sql stable security definer set search_path='public' as $$
 select coalesce((select sum(s.amount) from public.finance_payable_settlements s join public.finance_payables p on p.id=s.payable_id where p.referrer_id=p_referrer),0)
 +coalesce((select sum(l.amount*least(s.gross_amount/greatest(t.total,0.01),1)) from public.teacher_compensation_lines l
 join public.admission_referrals ar on ar.admission_id=l.admission_id and ar.referrer_id=p_referrer
 join public.teacher_compensation_settlements s on s.run_id=l.run_id and s.teacher_id=l.teacher_id
 cross join lateral(select sum(amount) total from public.teacher_compensation_lines x where x.run_id=l.run_id and x.teacher_id=l.teacher_id) t
 where l.line_type='ACQUISITION_BONUS'),0);
$$;


CREATE OR REPLACE FUNCTION public.referral_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 actor uuid:=auth.uid();
 action text:=p_input->>'action';
 req uuid:=nullif(p_input->>'request_id','')::uuid;
 reason text:=btrim(coalesce(p_input->>'reason',''));
 k public.admission_command_keys;
 a public.admission_cases;
 person public.referral_people;
 referral public.admission_referrals;
 award public.referral_bonus_awards;
 policy public.business_rule_versions;
 org uuid;
 first_month date;
 collected numeric;
 rate numeric;
 amount numeric;
 payable public.finance_payables;
 result jsonb;
begin
 if actor is null or req is null or length(reason)<5 then raise exception 'Sign in and provide a request ID and reason.'; end if;
 if action='CAPTURE' and not public.has_permission('admissions.create') or
    action='AWARD_BONUS' and not public.has_permission('staff.compensation.manage') or
    action not in('CAPTURE','AWARD_BONUS') then
   raise exception 'Permission denied for this referral action.';
 end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,7));
 select * into k from public.admission_command_keys where request_id=req;
 if found then
  if k.actor_id<>actor or k.payload<>p_input then raise exception 'Request identity already used for different input.'; end if;
  return k.result;
 end if;
 if action='CAPTURE' then
  select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
  if a.id is null or a.status='CANCELLED'
    or (a.status not in('DRAFT','READY') and exists(
      select 1 from public.admission_referrals prior where prior.admission_id=a.id
    )) then
   raise exception 'A referral can be added to an accepted case only when no source is already on file.'; end if;
  select id into org from public.organizations where is_active;
  if p_input->>'source'='ORGANIC' then
   insert into public.admission_referrals(admission_id,source,referrer_id,captured_by,reason)
   values(a.id,'ORGANIC',null,actor,reason)
   on conflict(admission_id) do update set source='ORGANIC',referrer_id=null,captured_by=actor,captured_at=now(),reason=excluded.reason;
   delete from public.teacher_referrals where admission_id=a.id;
  elsif p_input->>'source'='REFERRED' then
   if nullif(p_input->>'staff_id','') is not null then
    if not exists(select 1 from public.staff where id=(p_input->>'staff_id')::uuid and status='ACTIVE') then
      raise exception 'Choose an active staff member.'; end if;
    insert into public.referral_people(organization_id,staff_id,full_name,mobile,created_by)
      select org,id,full_name,null,actor from public.staff where id=(p_input->>'staff_id')::uuid
    on conflict(staff_id) do update set full_name=excluded.full_name
    returning * into person;
   elsif nullif(p_input->>'referrer_id','') is not null then
    select * into person from public.referral_people
     where id=(p_input->>'referrer_id')::uuid and organization_id=org and is_active;
    if person.id is null then raise exception 'Choose an existing referrer.'; end if;
   else
    if length(btrim(coalesce(p_input->>'full_name','')))<2 or
       coalesce(p_input->>'mobile','') !~ '^01[3-9][0-9]{8}$' then
      raise exception 'Enter the new referrer name and an 11-digit Bangladesh mobile.';
    end if;
    insert into public.referral_people(organization_id,staff_id,full_name,mobile,relationship_note,contact_note,created_by)
    values(org,null,btrim(p_input->>'full_name'),p_input->>'mobile',
      nullif(btrim(p_input->>'relationship_note'),''),nullif(btrim(p_input->>'contact_note'),''),actor)
    on conflict(organization_id,mobile) do update set
      full_name=public.referral_people.full_name
    returning * into person;
    if lower(btrim(person.full_name))<>lower(btrim(p_input->>'full_name')) then
      raise exception 'A different referrer already uses this mobile. Select the existing record or verify identity.';
    end if;
   end if;
   if not person.is_active then raise exception 'This referrer is inactive for new admissions.'; end if;
   insert into public.admission_referrals(admission_id,source,referrer_id,captured_by,reason)
   values(a.id,'REFERRED',person.id,actor,reason)
   on conflict(admission_id) do update set source='REFERRED',referrer_id=excluded.referrer_id,
      captured_by=actor,captured_at=now(),reason=excluded.reason;
   if person.staff_id is not null and exists(select 1 from public.staff_role_assignments sra
      join public.staff_roles sr on sr.id=sra.staff_role_id
      where sra.staff_id=person.staff_id and sr.is_teaching_role) then
     insert into public.teacher_referrals(admission_id,teacher_id,captured_by,reason)
     values(a.id,person.staff_id,actor,reason)
     on conflict(admission_id) do update set teacher_id=excluded.teacher_id,captured_by=actor,captured_at=now(),reason=excluded.reason;
   else
     delete from public.teacher_referrals where admission_id=a.id;
   end if;
  else raise exception 'Select an existing or new referrer, or Organic.'; end if;
  result:=jsonb_build_object('id',a.id,'message','Admission referral choice saved.');
 elsif action='AWARD_BONUS' then
  perform public.sync_referral_reward((p_input->>'admission_id')::uuid);
  result:=jsonb_build_object('id',p_input->>'admission_id','message','Referral entitlement synchronized with recorded net tuition collection.');
 end if;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,after_data,metadata)
 values(req,actor,'ADMISSION_REFERRAL',result->>'id',action,reason,result,jsonb_build_object('module','referrals'));
 insert into public.admission_command_keys(request_id,actor_id,payload,result)
 values(req,actor,p_input,result);
 return result;
end
$function$;

CREATE OR REPLACE FUNCTION public.finance_accounting_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid:=auth.uid();
  action text:=p_input->>'action';
  req uuid:=nullif(p_input->>'request_id','')::uuid;
  key public.admission_command_keys;
  result jsonb;
  reason text:=btrim(coalesce(p_input->>'reason',''));
  org uuid;
  account public.finance_accounts;
  journal_id uuid;
  advance public.finance_advances;
  adv_balance numeric;
  payable public.finance_payables;
  expense public.finance_expenses;
  vendor public.vendors;
  amount numeric;
  expense_account uuid;
  payment_account uuid;
  payment_mode text;
  category public.finance_expense_categories;
  compensation public.teacher_compensation_runs;
  policy public.business_rule_versions;
  preview jsonb;
  line jsonb;
  teacher_id uuid;
  v_teacher uuid;
  settlement public.teacher_compensation_settlements;
  cash_paid numeric;
  advance_offset numeric;
  advance_row record;
  settlement_id uuid;
  decision text;
  source_type text;
  permission text;
begin
  if actor is null then raise exception 'Sign in to continue.'; end if;
  if req is null or length(reason)<5 then
    raise exception 'A request identity and reason of at least five characters are required.';
  end if;

  permission := null;
  -- Action permission is assigned below because compensation/expense/advance
  -- workflows have different authorization boundaries.
  if action='SETTLE_PAYABLE' and exists(select 1 from public.finance_payables where id=(p_input->>'payable_id')::uuid and referrer_id is not null) then
    raise exception 'Settle referral rewards from the Referrers page so corrected entitlement is checked.';
  end if;
  if action in('CREATE_ADVANCE' ,'CREATE_EXPENSE_DIRECT','RUN_COMPENSATION','APPLY_COMP_ADJUSTMENT') then
    return public.post_accounting_operation(p_input);
  end if;
  permission:=case
    when action in('CREATE_ACCOUNT','POST_JOURNAL') then 'accounting.manage'
    when action in('CREATE_VENDOR','PAY_ADVANCE','REFUND_ADVANCE','APPLY_ADVANCE') then 'finance.advances.manage'
    when action='SETTLE_PAYABLE' then 'finance.payments.post'
    when action in('RECONCILE_EXPENSE','RECONCILE_ACCOUNT') then 'accounting.reconcile'
    when action='SETTLE_COMPENSATION' then 'staff.compensation.manage'
    else null end;

  if permission is null or not public.has_permission(permission) then
    raise exception 'Permission denied for this accounting action.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(req::text,7));
  select * into key from public.admission_command_keys where request_id=req;
  if found then
    if key.actor_id<>actor or key.payload<>p_input then
      raise exception 'Request identity already used for different input.';
    end if;
    return key.result;
  end if;

  select id into org from public.organizations where is_active limit 1;

  if action='CREATE_ACCOUNT' then
    if length(btrim(coalesce(p_input->>'code','')))<2
       or length(btrim(coalesce(p_input->>'name','')))<2
       or p_input->>'account_type' not in('ASSET','LIABILITY','EQUITY','REVENUE','CONTRA_REVENUE','EXPENSE')
       or length(btrim(coalesce(p_input->>'account_subtype','')))<2 then
      raise exception 'Enter valid account code, name, type and category.';
    end if;

    insert into public.finance_accounts(
      organization_id,code,name,account_type,account_subtype,parent_id,
      is_control_account,created_by
    )
    values(
      org,btrim(p_input->>'code'),btrim(p_input->>'name'),
      p_input->>'account_type',btrim(p_input->>'account_subtype'),
      nullif(p_input->>'parent_id','')::uuid,
      coalesce((p_input->>'is_control_account')::boolean,false),actor
    )
    returning * into account;

    result:=jsonb_build_object('id',account.id,'message','Financial account created.');

  elsif action='POST_JOURNAL' then
    if not public.has_permission('accounting.manage') then raise exception 'Accounting management permission required.'; end if;
    perform public.finance_post_journal(
      org,
      (p_input->>'journal_date')::date,
      'MANUAL',
      'MANUAL_JOURNAL',
      req::text,
      btrim(p_input->>'description'),
      actor,
      p_input->'lines'
    );
    result:=jsonb_build_object('id',req,'message','Balanced journal posted.');

  elsif action='CREATE_VENDOR' then
    if length(btrim(coalesce(p_input->>'name','')))<2 then
      raise exception 'Vendor name is required.';
    end if;
    insert into public.vendors(
      organization_id,name,mobile,email,address,service_category,created_by
    )
    values(
      org,btrim(p_input->>'name'),
      nullif(btrim(p_input->>'mobile'),''),
      nullif(lower(btrim(p_input->>'email')),''),
      nullif(btrim(p_input->>'address'),''),
      nullif(btrim(p_input->>'service_category'),''),
      actor
    )
    returning * into vendor;
    result:=jsonb_build_object('id',vendor.id,'vendorNo',vendor.vendor_no,'message','Vendor created.');

  elsif action='PAY_ADVANCE' then
    select * into advance from public.finance_advances where id=(p_input->>'advance_id')::uuid for update;
    amount:=(p_input->>'amount')::numeric;
    if advance.id is null or advance.status not in('APPROVED','PAID') then raise exception 'Only approved advances can be paid.'; end if;
    if amount is null or amount<=0 then raise exception 'Advance payment must be positive.'; end if;
    if amount>advance.approved_amount-public.advance_paid(advance.id) then raise exception 'Payment exceeds approved advance balance.'; end if;

    select id into payment_account
    from public.finance_accounts
    where id=(p_input->>'payment_account_id')::uuid
      and organization_id=org
      and account_subtype in('CASH','BANK','MOBILE_BANK')
      and is_active;

    if payment_account is null then raise exception 'Choose an active cash or bank account.'; end if;

    insert into public.finance_advance_movements(
      advance_id,movement_type,amount,source_type,source_id,payment_account_id,created_by,reason
    )
    values(
      advance.id,'PAYMENT',amount,'ADVANCE_PAYMENT',req::text,payment_account,actor,reason
    );

    perform public.finance_post_journal(
      org,current_date,'ADVANCE_PAYMENT','ADVANCE_PAYMENT',req::text,
      'Advance payment '||advance.advance_no,actor,
      jsonb_build_array(
        jsonb_build_object(
          'account_id',
          case when advance.beneficiary_type='STAFF'
            then (select id from public.finance_accounts where organization_id=org and account_subtype='STAFF_ADVANCE' limit 1)
            when advance.beneficiary_type='VENDOR'
            then (select id from public.finance_accounts where organization_id=org and account_subtype='VENDOR_ADVANCE' limit 1)
            else (select id from public.finance_accounts where organization_id=org and account_subtype='STAFF_ADVANCE' limit 1)
          end,
          'debit',amount,'credit',0
        ),
        jsonb_build_object('account_id',payment_account,'debit',0,'credit',amount)
      )
    );

    if public.advance_paid(advance.id)>=advance.approved_amount then
      update public.finance_advances set status='PAID' where id=advance.id;
    end if;
    result:=jsonb_build_object('id',advance.id,'message','Advance payment posted.');

  elsif action='REFUND_ADVANCE' then
    select * into advance from public.finance_advances where id=(p_input->>'advance_id')::uuid for update;
    amount:=(p_input->>'amount')::numeric;
    adv_balance:=public.advance_balance(advance.id);
    if advance.id is null or adv_balance<=0 or amount is null or amount<=0 or amount>adv_balance then
      raise exception 'Refund exceeds the unsettled advance balance.';
    end if;
    select id into payment_account
    from public.finance_accounts
    where id=(p_input->>'payment_account_id')::uuid
      and organization_id=org
      and account_subtype in('CASH','BANK','MOBILE_BANK')
      and is_active;
    if payment_account is null then raise exception 'Choose an active cash or bank account.'; end if;

    perform public.finance_post_journal(
      org,current_date,'ADVANCE_REFUND','ADVANCE_REFUND',req::text,
      'Advance refund '||advance.advance_no,actor,
      jsonb_build_array(
        jsonb_build_object(
          'account_id',payment_account,'debit',amount,'credit',0
        ),
        jsonb_build_object(
          'account_id',
          case when advance.beneficiary_type='VENDOR'
            then (select id from public.finance_accounts where organization_id=org and account_subtype='VENDOR_ADVANCE' limit 1)
            else (select id from public.finance_accounts where organization_id=org and account_subtype='STAFF_ADVANCE' limit 1)
          end,
          'debit',0,'credit',amount
        )
      )
    );

    insert into public.finance_advance_movements(
      advance_id,movement_type,amount,source_type,source_id,payment_account_id,created_by,reason
    )
    values(advance.id,'REFUND',amount,'ADVANCE_REFUND',req::text,payment_account,actor,reason);

    update public.finance_advances
    set status=case when public.advance_balance(id)<=0 then 'REFUNDED' else status end
    where id=advance.id;

    result:=jsonb_build_object('id',advance.id,'message','Advance refund recorded.');

  elsif action='SETTLE_PAYABLE' then
    select * into payable from public.finance_payables where id=(p_input->>'payable_id')::uuid for update;
    amount:=(p_input->>'amount')::numeric;
    if payable.id is null or payable.status not in('OPEN','PARTIALLY_SETTLED') then raise exception 'Payable is not open.'; end if;
    if payable.payable_type='TEACHER_COMPENSATION' then raise exception 'Use the compensation settlement to preserve advance offsets.'; end if;
    if amount is null or amount<=0 or amount > payable.original_amount-coalesce((
      select sum(s.amount) from public.finance_payable_settlements s where s.payable_id=payable.id
    ),0) then raise exception 'Settlement exceeds payable balance.'; end if;

    select id into payment_account
    from public.finance_accounts
    where id=(p_input->>'payment_account_id')::uuid
      and organization_id=org
      and account_subtype in('CASH','BANK','MOBILE_BANK')
      and is_active;
    if payment_account is null then raise exception 'Choose an active cash or bank account.'; end if;

    insert into public.finance_payable_settlements(
      payable_id,amount,payment_account_id,external_reference,settled_by,reason
    )
    values(
      payable.id,amount,payment_account,nullif(btrim(p_input->>'external_reference'),''),
      actor,reason
    );

    perform public.finance_post_journal(
      org,current_date,'PAYABLE_SETTLEMENT','PAYABLE_SETTLEMENT',req::text,
      'Payable settlement '||payable.payable_no,actor,
      jsonb_build_array(
        jsonb_build_object('account_id',payable.payable_account_id,'debit',amount,'credit',0),
        jsonb_build_object('account_id',payment_account,'debit',0,'credit',amount)
      )
    );

    update public.finance_payables p
    set status=case
      when coalesce((select sum(s.amount) from public.finance_payable_settlements s where s.payable_id=p.id),0)>=p.original_amount
        then 'SETTLED'
      else 'PARTIALLY_SETTLED' end
    where p.id=payable.id;

    result:=jsonb_build_object('id',payable.id,'message','Payable settlement posted.');

  elsif action='RECONCILE_EXPENSE' then
    select * into expense from public.finance_expenses
    where id=(p_input->>'expense_id')::uuid for update;
    amount:=(p_input->>'matched_amount')::numeric;
    if expense.id is null or expense.status<>'POSTED' then raise exception 'Post the expense before reconciliation.'; end if;
    if amount is null or amount<>expense.amount then raise exception 'Reconciled amount must equal the posted expense amount.'; end if;

    insert into public.finance_expense_reconciliations(
      expense_id,matched_amount,statement_reference,reconciled_by,note
    )
    values(
      expense.id,amount,btrim(p_input->>'statement_reference'),actor,reason
    )
    on conflict(expense_id) do nothing;

    if not found then raise exception 'Expense is already reconciled.'; end if;
    update public.finance_expenses set status='RECONCILED' where id=expense.id;
    result:=jsonb_build_object('id',expense.id,'message','Expense reconciled to the statement reference.');

  elsif action='RECONCILE_ACCOUNT' then
    select * into account from public.finance_accounts
    where id=(p_input->>'account_id')::uuid
      and organization_id=org and is_active;
    if account.id is null then raise exception 'Choose an active account.'; end if;

    select public.finance_account_balance(account.id,(p_input->>'statement_date')::date)
    into amount;

    if amount is null then amount:=0; end if;
    insert into public.finance_account_reconciliations(
      account_id,statement_date,statement_reference,statement_balance,
      ledger_balance,difference,status,note,reconciled_by,reconciled_at
    )
    values(
      account.id,(p_input->>'statement_date')::date,
      btrim(p_input->>'statement_reference'),
      (p_input->>'statement_balance')::numeric,
      amount,
      round((p_input->>'statement_balance')::numeric-amount,2),
      case when round((p_input->>'statement_balance')::numeric-amount,2)=0 then 'RECONCILED' else 'OPEN' end,
      reason,
      case when round((p_input->>'statement_balance')::numeric-amount,2)=0 then actor else null end,
      case when round((p_input->>'statement_balance')::numeric-amount,2)=0 then now() else null end
    )
    on conflict(account_id,statement_date,statement_reference) do update
      set statement_balance=excluded.statement_balance,
          ledger_balance=excluded.ledger_balance,
          difference=excluded.difference,
          status=excluded.status,
          reconciled_by=excluded.reconciled_by,
          reconciled_at=excluded.reconciled_at,
          note=excluded.note;

    result:=jsonb_build_object('id',req,'message',
      case when round((p_input->>'statement_balance')::numeric-amount,2)=0
        then 'Account reconciled.'
        else 'Reconciliation saved as open; investigate the difference before closing it.' end);

  elsif action='SETTLE_COMPENSATION' then
    select * into compensation from public.teacher_compensation_runs
    where id=(p_input->>'run_id')::uuid and status='APPROVED' for update;
    if compensation.id is null then raise exception 'Only an approved compensation run can be settled.'; end if;

    teacher_id:=(p_input->>'teacher_id')::uuid;
    select * into payable from public.finance_payables
    where source_type='COMPENSATION_RUN'
      and source_id=compensation.id::text||':'||teacher_id::text
      and staff_id=teacher_id
    for update;
    if payable.id is null then raise exception 'Teacher payable not found.'; end if;

    amount:=payable.original_amount-coalesce((
      select sum(s.amount) from public.finance_payable_settlements s where s.payable_id=payable.id
    ),0);
    if amount<=0 then raise exception 'Teacher payable is already settled.'; end if;

    advance_offset:=coalesce((p_input->>'advance_offset')::numeric,0);
    if advance_offset<0 or advance_offset>amount then raise exception 'Advance offset is outside the payable balance.'; end if;

    if advance_offset>0 then
      select * into advance_row
      from (
        select adv.*,public.advance_balance(adv.id) balance
        from public.finance_advances adv
        where adv.staff_id=teacher_id
          and adv.beneficiary_type='STAFF'
          and public.advance_balance(adv.id)>0
          and adv.status in('PAID','PARTIALLY_SETTLED','OVERDUE')
        order by adv.expected_settlement_date nulls last,adv.created_at
      ) q
      limit 1 for update;

      if advance_row.id is null or advance_row.balance<advance_offset then
        raise exception 'Requested advance offset exceeds available teacher advance balance.';
      end if;
    end if;

    cash_paid:=amount-advance_offset;
    if cash_paid>0 then
      select id into payment_account
      from public.finance_accounts
      where id=(p_input->>'payment_account_id')::uuid
        and organization_id=compensation.organization_id
        and account_subtype in('CASH','BANK','MOBILE_BANK')
        and is_active;
      if payment_account is null then raise exception 'Choose an active cash or bank account.'; end if;
    end if;

    insert into public.teacher_compensation_settlements(
      run_id,teacher_id,payable_id,gross_amount,advance_offset,cash_paid,
      payment_account_id,external_reference,settled_by,reason
    )
    values(
      compensation.id,teacher_id,payable.id,amount,advance_offset,cash_paid,
      payment_account,nullif(btrim(p_input->>'external_reference'),''),
      actor,reason
    )
    returning id into settlement;

    if advance_offset>0 then
      perform public.finance_post_journal(
        compensation.organization_id,current_date,'COMPENSATION_SETTLEMENT',
        'COMPENSATION_SETTLEMENT',settlement.id::text,
        'Teacher compensation advance offset',actor,
        jsonb_build_array(
          jsonb_build_object(
            'account_id',(select id from public.finance_accounts where organization_id=compensation.organization_id and account_subtype='TEACHER_PAYABLE' limit 1),
            'debit',advance_offset,'credit',0
          ),
          jsonb_build_object(
            'account_id',(select id from public.finance_accounts where organization_id=compensation.organization_id and account_subtype='STAFF_ADVANCE' limit 1),
            'debit',0,'credit',advance_offset
          )
        )
      );
      insert into public.finance_advance_movements(
        advance_id,movement_type,amount,source_type,source_id,payable_id,created_by,reason
      )
      values(
        advance_row.id,'SETTLEMENT',advance_offset,
        'COMPENSATION_SETTLEMENT',settlement.id::text,payable.id,actor,reason
      );
    end if;

    if cash_paid>0 then
      perform public.finance_post_journal(
        compensation.organization_id,current_date,'COMPENSATION_SETTLEMENT',
        'COMPENSATION_CASH_SETTLEMENT',settlement.id::text,
        'Teacher compensation cash settlement',actor,
        jsonb_build_array(
          jsonb_build_object(
            'account_id',(select id from public.finance_accounts where organization_id=compensation.organization_id and account_subtype='TEACHER_PAYABLE' limit 1),
            'debit',cash_paid,'credit',0
          ),
          jsonb_build_object(
            'account_id',payment_account,'debit',0,'credit',cash_paid
          )
        )
      );
    end if;

    if advance_offset>0 then
      insert into public.finance_payable_settlements(
        payable_id,amount,advance_id,settled_by,reason
      ) values(payable.id,advance_offset,advance_row.id,actor,reason);
    end if;
    if cash_paid>0 then
      insert into public.finance_payable_settlements(
        payable_id,amount,payment_account_id,external_reference,settled_by,reason
      ) values(payable.id,cash_paid,payment_account,
        nullif(btrim(p_input->>'external_reference'),''),actor,reason);
    end if;

    update public.finance_payables p
    set status=case
      when coalesce((select sum(s.amount) from public.finance_payable_settlements s where s.payable_id=p.id),0)>=p.original_amount
      then 'SETTLED' else 'PARTIALLY_SETTLED' end
    where p.id=payable.id;

    if not exists(
      select 1 from public.finance_payables
      where source_type='COMPENSATION_RUN'
        and source_id like compensation.id::text||':%'
        and status<>'SETTLED'
    ) then
      update public.teacher_compensation_runs set status='SETTLED' where id=compensation.id;
    end if;

    result:=jsonb_build_object('id',settlement.id,'message','Teacher compensation settlement posted.');
  
  elsif action='APPLY_ADVANCE' then
    select * into advance from public.finance_advances where id=(p_input->>'advance_id')::uuid for update;
    select * into payable from public.finance_payables where id=(p_input->>'payable_id')::uuid for update;
    amount:=(p_input->>'amount')::numeric;
    if advance.id is null or advance.status not in('PAID','PARTIALLY_SETTLED','OVERDUE')
      or payable.id is null or payable.status not in('OPEN','PARTIALLY_SETTLED')
      or payable.organization_id<>advance.organization_id
      or not ((advance.beneficiary_type='VENDOR' and payable.vendor_id=advance.vendor_id)
        or (advance.beneficiary_type='STAFF' and payable.staff_id=advance.staff_id))
      or amount is null or amount<=0 or amount<>round(amount,2)
      or amount>public.advance_balance(advance.id)
      or amount>payable.original_amount-coalesce((select sum(s.amount)
        from public.finance_payable_settlements s where s.payable_id=payable.id),0) then
      raise exception 'Choose a matching approved payable and outstanding advance balance.';
    end if;
      perform public.finance_post_journal(
        org,current_date,'ADVANCE_SETTLEMENT','ADVANCE_SETTLEMENT',req::text,
        'Approved advance against payable '||payable.payable_no,actor,
        jsonb_build_array(
          jsonb_build_object('account_id',payable.payable_account_id,'debit',amount,'credit',0),
          jsonb_build_object('account_id',(select id from public.finance_accounts
            where organization_id=org and account_subtype=case when advance.beneficiary_type='VENDOR'
              then 'VENDOR_ADVANCE' else 'STAFF_ADVANCE' end limit 1),
            'debit',0,'credit',amount)
        )
      );
      insert into public.finance_advance_movements(advance_id,movement_type,amount,
        source_type,source_id,payable_id,created_by,reason)
      values(advance.id,'SETTLEMENT',amount,'ADVANCE_SETTLEMENT',req::text,payable.id,actor,reason);
      insert into public.finance_payable_settlements(payable_id,amount,advance_id,settled_by,reason)
      values(payable.id,amount,advance.id,actor,'Advance application: '||reason);
      update public.finance_advances set status=case when public.advance_balance(id)=0
        then 'SETTLED' else 'PARTIALLY_SETTLED' end where id=advance.id;
      update public.finance_payables p set status=case when
        coalesce((select sum(s.amount) from public.finance_payable_settlements s
          where s.payable_id=p.id),0)>=p.original_amount then 'SETTLED' else 'PARTIALLY_SETTLED' end
      where p.id=payable.id;
    result:=jsonb_build_object('id',advance.id,'message','Advance applied to payable.');

  end if;

  insert into public.audit_events(
    correlation_id,actor_profile_id,actor_staff_id,entity_type,entity_id,action,reason,after_data,metadata
  )
  values(
    req,actor,(select id from public.staff where profile_id=actor limit 1),
    'FINANCE_ACCOUNTING',coalesce(result->>'id',req::text),action,reason,result,p_input
  );

  insert into public.admission_command_keys(request_id,actor_id,payload,result)
  values(req,actor,p_input,result);

  return result;
end;
$function$;
create function public.referrer_workspace(p_referrer_id uuid default null) returns jsonb
language plpgsql stable security definer set search_path='public' as $$
declare manager boolean:=public.has_permission('staff.compensation.manage') or public.has_permission('admissions.create'); rid uuid; person public.referral_people; students jsonb; org uuid;
begin
 if auth.uid() is null or not exists(select 1 from public.profiles where id=auth.uid() and status='ACTIVE') then raise exception 'Active sign-in required.'; end if;
 if manager then rid:=p_referrer_id;
 else select r.id into rid from public.referral_people r left join public.staff s on s.id=r.staff_id where r.is_active and (r.profile_id=auth.uid() or (s.profile_id=auth.uid() and s.status='ACTIVE'));
  if rid is null or (p_referrer_id is not null and p_referrer_id<>rid) then raise exception 'Only your own referrals are available.'; end if;
 end if;
 select * into person from public.referral_people where id=rid;
 select id into org from public.organizations where is_active;
 select coalesce(jsonb_agg(jsonb_build_object('id',a.id,'number',a.admission_no,'name',a.identity_snapshot->>'student_name','studentNo',s.student_no,'programme',o.name,'status',a.status,
 'discountPercent',a.selected_discount_percent,
 'discountAmount',(select coalesce(sum(ic.amount),0) from public.invoice_credits ic join public.admission_invoices i on i.id=ic.invoice_id where i.admission_id=a.id and ic.kind='DISCOUNT'),
 'netTuition',(select coalesce(sum(tuition_collected),0) from public.referral_invoice_collections(a.id)),
 'reward',(select coalesce(sum(amount),0) from public.referral_reward_entries where admission_id=a.id),
 'rate',(select bonus_percent from public.referral_reward_contracts where admission_id=a.id),
 'collections',(select coalesce(jsonb_agg(jsonb_build_object('receipt',p.receipt_no,'receivedOn',p.posted_at,'allocated',pa.amount,'billingPeriod',i.billing_period,'tuitionCollected',c.tuition_collected) order by p.posted_at desc),'[]'::jsonb)
 from public.admission_invoices i join public.admission_payment_allocations pa on pa.invoice_id=i.id join public.admission_payments p on p.id=pa.payment_id
 join public.referral_invoice_collections(a.id) c on c.invoice_id=i.id where i.admission_id=a.id)) order by a.created_at desc),'[]'::jsonb) into students
 from public.admission_referrals ar join public.admission_cases a on a.id=ar.admission_id join public.batches b on b.id=a.batch_id join public.programme_offerings o on o.id=b.offering_id left join public.students s on s.id=a.student_id
 where ar.referrer_id=rid and ar.source='REFERRED';
 return jsonb_build_object('manager',manager,'people',case when manager then (select coalesce(jsonb_agg(jsonb_build_object('id',r.id,'name',r.full_name,'mobile',r.mobile,'email',r.email,'staffId',r.staff_id,'profileId',coalesce(r.profile_id,s.profile_id),'active',r.is_active,'relationship',r.relationship_note,'notes',r.contact_note) order by r.full_name),'[]'::jsonb) from public.referral_people r left join public.staff s on s.id=r.staff_id) else '[]'::jsonb end,
 'selected',rid,'name',person.full_name,'students',students,
 'earned',(select coalesce(sum(amount),0) from public.referral_reward_entries where referrer_id=rid),'settled',public.referrer_paid(rid),
 'entries',(select coalesce(jsonb_agg(jsonb_build_object('id',id,'admissionId',admission_id,'amount',amount,'collected',net_collected,'rate',bonus_percent,'date',created_at) order by created_at desc),'[]'::jsonb) from public.referral_reward_entries where referrer_id=rid),
 'settlements',(select coalesce(jsonb_agg(jsonb_build_object('amount',s.amount,'date',s.settled_at,'reference',s.external_reference) order by s.settled_at desc),'[]'::jsonb) from public.finance_payable_settlements s join public.finance_payables p on p.id=s.payable_id where p.referrer_id=rid),
 'accounts',case when manager then (select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name)),'[]'::jsonb) from public.finance_accounts where organization_id=org and is_active and account_subtype in('CASH','BANK','MOBILE_BANK')) else '[]'::jsonb end);
end; $$;
create function public.manage_referrer(p_input jsonb) returns jsonb language plpgsql security definer set search_path='public' as $$
declare r public.referral_people; actor uuid:=auth.uid(); org uuid; action text:=p_input->>'action'; profile uuid; assigned_role uuid; result jsonb; req uuid:=nullif(p_input->>'request_id','')::uuid; reason text:=btrim(coalesce(p_input->>'reason','')); previous public.admission_command_keys;
begin
 if actor is null or not public.has_permission('admissions.create') then raise exception 'Referrer management permission required.'; end if;
 if req is null or length(reason)<5 or length(reason)>500 then raise exception 'Supply a request ID and reason of 5-500 characters.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,12)); select * into previous from public.admission_command_keys where request_id=req;
 if found then if previous.actor_id<>actor or previous.payload<>p_input then raise exception 'Request ID already used.'; end if; return previous.result; end if;
 select id into org from public.organizations where is_active;
 if action='SAVE' then
  if length(btrim(coalesce(p_input->>'name','')))<2 or length(p_input->>'name')>160 then raise exception 'Enter the referrer name.'; end if;
  if coalesce(p_input->>'mobile','') !~ '^$|^01[3-9][0-9]{8}$' or coalesce(p_input->>'email','') !~ '^$|^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'Check mobile and email.'; end if;
  if nullif(p_input->>'id','') is null then
   insert into public.referral_people(organization_id,full_name,mobile,email,relationship_note,contact_note,created_by)
   values(org,btrim(p_input->>'name'),nullif(p_input->>'mobile',''),nullif(lower(btrim(p_input->>'email')),''),left(p_input->>'relationship',160),left(p_input->>'notes',500),actor) returning * into r;
  else
   select * into r from public.referral_people where id=(p_input->>'id')::uuid and organization_id=org for update;
   if r.id is null then raise exception 'Referrer not found.'; end if;
   if r.profile_id is not null and nullif(lower(btrim(p_input->>'email')),'') is distinct from r.email then raise exception 'Linked account email changes must use verified Supabase account recovery.'; end if;
   update public.referral_people set full_name=btrim(p_input->>'name'),mobile=nullif(p_input->>'mobile',''),email=nullif(lower(btrim(p_input->>'email')),''),relationship_note=left(p_input->>'relationship',160),contact_note=left(p_input->>'notes',500) where id=r.id;
  end if;
 elsif action='LINK_ACCOUNT' then
  if not public.has_permission('system.users.manage') then raise exception 'Account management permission required.'; end if;
  select * into r from public.referral_people where id=(p_input->>'id')::uuid and organization_id=org and is_active for update;
  if r.id is null or r.email is null then raise exception 'Save and verify the referrer email first.'; end if;
  select id into profile from auth.users where lower(email)=lower(r.email);
  if profile is null then raise exception 'Send the Supabase invitation first.'; end if;
  if r.staff_id is not null and not exists(select 1 from public.staff where id=r.staff_id and profile_id=profile) then raise exception 'Use the linked staff account, not a second identity.'; end if;
  insert into public.profiles(id,display_name) values(profile,r.full_name) on conflict(id) do nothing;
  update public.referral_people set profile_id=profile where id=r.id;
  select id into assigned_role from public.system_roles where code='REFERRER';
  if not exists(select 1 from public.user_role_assignments where profile_id=profile and user_role_assignments.role_id=assigned_role and is_active and effective_to is null) then
   insert into public.user_role_assignments(profile_id,role_id,assigned_by) values(profile,assigned_role,actor);
  end if;
 elsif action='SET_ACTIVE' then
  update public.referral_people set is_active=(p_input->>'active')::boolean where id=(p_input->>'id')::uuid and organization_id=org returning * into r;
  if r.id is null then raise exception 'Referrer not found.'; end if;
 else raise exception 'Unknown referrer action.'; end if;
 result:=jsonb_build_object('id',r.id,'message','Referrer record saved.');
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,after_data) values(req,actor,'REFERRER',r.id::text,action,reason,result);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result); return result;
end; $$;
create function public.settle_referrer_reward(p_input jsonb) returns jsonb language plpgsql security definer set search_path='public' as $$
declare rid uuid:=(p_input->>'referrer_id')::uuid; actor uuid:=auth.uid(); req uuid:=(p_input->>'request_id')::uuid; amount numeric:=round((p_input->>'amount')::numeric,2); cash uuid:=(p_input->>'account_id')::uuid;
 reason text:=btrim(coalesce(p_input->>'reason','')); available numeric; org uuid; liability uuid; remaining numeric; pay public.finance_payables; portion numeric; result jsonb; previous public.admission_command_keys;
begin
 if actor is null or not public.has_permission('staff.compensation.manage') then raise exception 'Compensation management permission required.'; end if;
 if req is null or amount is null or amount<=0 or length(reason)<5 then raise exception 'Enter a positive amount, reason and request ID.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,13)); select * into previous from public.admission_command_keys where request_id=req;
 if found then if previous.actor_id<>actor or previous.payload<>p_input then raise exception 'Request ID already used.'; end if; return previous.result; end if;
 select organization_id into org from public.referral_people where id=rid for update;
 if org is null then raise exception 'Referrer unavailable.'; end if;
 -- Lock admissions too: collection adjustments and settlements cannot race.
 perform 1 from public.admission_cases a join public.admission_referrals r on r.admission_id=a.id where r.referrer_id=rid order by a.id for update of a;
 select coalesce(sum(e.amount),0)-public.referrer_paid(rid) into available from public.referral_reward_entries e where e.referrer_id=rid;
 if amount>available then raise exception 'Payment exceeds the corrected outstanding referral entitlement.'; end if;
 if not exists(select 1 from public.finance_accounts where id=cash and organization_id=org and is_active and account_subtype in('CASH','BANK','MOBILE_BANK')) then raise exception 'Choose an active cash/bank account.'; end if;
 select id into liability from public.finance_accounts where organization_id=org and code='2130';
 remaining:=amount;
 for pay in select * from public.finance_payables where referrer_id=rid and status<>'VOIDED' order by created_at,id for update loop
  portion:=least(remaining,pay.original_amount-coalesce((select sum(s.amount) from public.finance_payable_settlements s where s.payable_id=pay.id),0));
  if portion>0 then
   insert into public.finance_payable_settlements(payable_id,amount,payment_account_id,external_reference,settled_by,reason) values(pay.id,portion,cash,nullif(p_input->>'reference',''),actor,reason);
   remaining:=remaining-portion;
  end if;
  exit when remaining=0;
 end loop;
 if remaining<>0 then raise exception 'Legacy teacher acquisition remains in teacher compensation settlement. Settle that run first.'; end if;
 perform public.finance_post_journal(org,current_date,'PAYABLE_SETTLEMENT','REFERRER_PAYMENT',req::text,reason,actor,jsonb_build_array(jsonb_build_object('account_id',liability,'debit',amount,'credit',0),jsonb_build_object('account_id',cash,'debit',0,'credit',amount)));
 result:=jsonb_build_object('id',rid,'message','Actual referrer payment recorded.');
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,after_data) values(req,actor,'REFERRER',rid::text,'SETTLE_REWARD',reason,p_input);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);return result;
end; $$;
create function public.collect_student_payment(p_input jsonb) returns jsonb language plpgsql security definer set search_path='public' as $$
declare actor uuid:=auth.uid(); req uuid:=(p_input->>'request_id')::uuid; i public.admission_invoices; b record; tuition numeric; adjustment numeric:=coalesce((p_input->>'adjustment_amount')::numeric,0); category text:=coalesce(p_input->>'adjustment_category','DISCOUNT'); limit_percent numeric; policy public.business_rule_versions; result jsonb; previous public.admission_command_keys;
begin
 if actor is null or not public.has_permission('finance.payments.post') then raise exception 'Payment permission required.'; end if;
 if req is null then raise exception 'Request ID required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,14));select * into previous from public.admission_command_keys where request_id=req;
 if found then if previous.actor_id<>actor or previous.payload<>p_input then raise exception 'Request ID already used.'; end if; return previous.result; end if;
 select * into i from public.admission_invoices where id=(p_input->>'invoice_id')::uuid for update;
 if i.id is null or i.admission_id<>(p_input->>'admission_id')::uuid then raise exception 'Choose the correct student invoice.'; end if;
 if adjustment<0 or adjustment<>round(adjustment,2) then raise exception 'Enter an adjustment amount with at most two decimals.'; end if;
 if adjustment>0 then
  if not public.has_permission('finance.billing.manage') then raise exception 'Billing management permission required for discounts or scholarships.'; end if;
  if category not in('DISCOUNT','SCHOLARSHIP') or length(btrim(coalesce(p_input->>'adjustment_reason','')))<5 then raise exception 'Select discount/scholarship and a reason of at least five characters.'; end if;
  select * into policy from public.business_rule_versions where domain='finance' and rule_key='collection_discount_policy' and status='ACTIVE' order by version desc limit 1;
  if policy.id is null then raise exception 'Configure collection-time adjustment limits.'; end if;
  limit_percent:=(policy.payload->>case when category='SCHOLARSHIP' then 'max_scholarship_percent' else 'max_discount_percent' end)::numeric;
  select coalesce(sum(amount),0) into tuition from public.admission_invoice_lines where invoice_id=i.id and charge_type='TUITION';
  select * into b from public.invoice_balance(i.id);
  if adjustment>greatest(tuition-coalesce((select sum(amount) from public.invoice_credits where invoice_id=i.id and kind='DISCOUNT'),0),0)
    or adjustment>tuition*limit_percent/100 or adjustment>b.due then raise exception 'Adjustment exceeds remaining tuition, the configured limit, or the unpaid balance.'; end if;
  insert into public.invoice_credits(invoice_id,kind,category,amount,applied_by,description) values(i.id,'DISCOUNT',category,adjustment,actor,btrim(p_input->>'adjustment_reason'));
 end if;
 if coalesce((p_input->>'amount')::numeric,0)>0 then
  result:=public.post_admission_payment((p_input-'adjustment_amount'-'adjustment_category'-'adjustment_reason')||jsonb_build_object('request_id',gen_random_uuid(),'action','PAY'));
 elsif adjustment>0 then result:=jsonb_build_object('message',initcap(lower(category))||' recorded; no money received.');
 else raise exception 'Record an actual payment or a positive discount/scholarship.'; end if;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,after_data) values(req,actor,'INVOICE',i.id::text,'COLLECT_OR_ADJUST',p_input->>'reason',p_input);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);return result;
end; $$;
create function public.finance_operating_summary() returns jsonb language plpgsql stable security definer set search_path='public' as $$
declare revenue numeric; contra numeric; expenses numeric;
begin
 if not public.has_permission('accounting.view') then raise exception 'Accounting view permission required.'; end if;
 select coalesce(sum(case when a.account_type='REVENUE' then l.credit-l.debit else 0 end),0),
 coalesce(sum(case when a.account_type='CONTRA_REVENUE' then l.debit-l.credit else 0 end),0),
 coalesce(sum(case when a.account_type='EXPENSE' then l.debit-l.credit else 0 end),0) into revenue,contra,expenses
 from public.general_ledger_lines l join public.finance_accounts a on a.id=l.account_id join public.general_ledger_journals j on j.id=l.journal_id where j.status='POSTED';
 return jsonb_build_object('revenue',revenue,'discountsAndReversals',contra,'expenses',expenses,'profitLoss',revenue-contra-expenses,
 'balances',(select coalesce(jsonb_object_agg(a.id::text,public.finance_account_balance(a.id,current_date)),'{}'::jsonb) from public.finance_accounts a where is_active));
end; $$;

CREATE OR REPLACE FUNCTION public.publish_business_rule_version(p_domain text, p_rule_key text, p_payload jsonb, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare previous public.business_rule_versions; saved public.business_rule_versions; next_version integer; trace uuid:=gen_random_uuid();
begin
 if auth.uid() is null or not public.has_permission('system.settings.manage') then raise exception 'Settings management permission required.'; end if;
 if (p_domain,p_rule_key) not in (('academics','batch_capacity_policy'),('admissions','activation_policy'),('teacher_compensation','default_policy'),('referrals','acquisition_policy'),('finance','collection_discount_policy')) then raise exception 'Choose a supported operating rule.'; end if;
 if length(btrim(coalesce(p_reason,''))) not between 5 and 500 or not public.validate_business_rule_payload(p_domain,p_rule_key,p_payload) then raise exception 'Check the operating values and change reason.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_domain||'.'||p_rule_key,0));
 select * into previous from public.business_rule_versions where domain=p_domain and rule_key=p_rule_key and status='ACTIVE' for update;
 if previous.id is not null and previous.payload=p_payload then return jsonb_build_object('id',previous.id,'version',previous.version); end if;
 select coalesce(max(version),0)+1 into next_version from public.business_rule_versions where domain=p_domain and rule_key=p_rule_key;
 update public.business_rule_versions set status='RETIRED',effective_to=current_date where id=previous.id;
 insert into public.business_rule_versions(domain,rule_key,version,status,effective_from,payload,change_reason,created_by)
 values(p_domain,p_rule_key,next_version,'ACTIVE',current_date,p_payload,btrim(p_reason),auth.uid()) returning * into saved;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(trace,auth.uid(),'BUSINESS_RULE',p_domain||'.'||p_rule_key,case when previous.id is null then 'CREATE_SETTINGS' else 'SAVE_SETTINGS' end,p_reason,to_jsonb(previous),to_jsonb(saved));
 return jsonb_build_object('id',saved.id,'version',saved.version,'correlation_id',trace);
end $function$;

CREATE OR REPLACE FUNCTION public.finance_workspace()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null or not public.has_permission('finance.view') then raise exception 'Finance access denied.'; end if;
 return jsonb_build_object(
 'admissions',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'name',coalesce(s.full_name,a.identity_snapshot->>'student_name'),'number',a.admission_no,'status',a.status,'studentId',s.id,'studentNo',s.student_no,'mobile',a.identity_snapshot->>'mobile') order by a.created_at desc) from public.admission_cases a left join public.students s on s.id=a.student_id),'[]'::jsonb),
 'years',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name)) from public.academic_years),'[]'::jsonb),
 'terms',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name,'startsOn',starts_on,'endsOn',ends_on,'dueOn',due_on)) from public.billing_terms),'[]'::jsonb),
 'invoices',coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'admissionId',a.id,'name',a.identity_snapshot->>'student_name','number',i.invoice_no,'kind',i.invoice_kind,'period',i.billing_period,'dueOn',i.due_on,'currency',i.currency_code,'gross',b.gross,'credits',b.credits,'discountAmount',(select coalesce(sum(amount),0) from public.invoice_credits where invoice_id=i.id and kind='DISCOUNT' and category<>'SCHOLARSHIP'),'scholarshipAmount',(select coalesce(sum(amount),0) from public.invoice_credits where invoice_id=i.id and category='SCHOLARSHIP'),'otherAdjustments',(select coalesce(sum(amount),0) from public.invoice_credits where invoice_id=i.id and kind<>'DISCOUNT'),'net',b.net,'paid',b.paid,'refunded',b.refunded,'due',b.due,'credit',b.credit_balance,'reserved',b.reserved_refunds,
 'lines',coalesce((select jsonb_agg(jsonb_build_object('name',name,'amount',amount)) from public.admission_invoice_lines where invoice_id=i.id),'[]'::jsonb)) order by i.posted_at desc) from public.admission_invoices i join public.admission_cases a on a.id=i.admission_id cross join lateral public.invoice_balance(i.id) b),'[]'::jsonb),
 'payments',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'invoiceId',pa.invoice_id,'number',p.receipt_no,'amount',p.amount,'postedAt',p.posted_at,'method',pm.name,'remaining',p.amount-coalesce((select sum(amount) from public.refund_authorizations where payment_id=p.id),0))) from public.admission_payments p join public.admission_payment_allocations pa on pa.payment_id=p.id join public.payment_methods pm on pm.id=p.payment_method_id),'[]'::jsonb),
 'discounts',coalesce((select jsonb_agg(jsonb_build_object('id',id,'admissionId',admission_id,'kind',kind,'value',value,'startsOn',starts_on,'endsOn',ends_on)) from public.admission_discounts),'[]'::jsonb),
 'refunds',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'invoiceId',r.invoice_id,'paymentId',r.payment_id,'amount',r.amount,'number',p.refund_no,'postedAt',p.posted_at,'method',pm.name,'reference',p.external_reference)) from public.refund_authorizations r left join public.refund_payouts p on p.authorization_id=r.id left join public.payment_methods pm on pm.id=p.payment_method_id),'[]'::jsonb),
 'runs',coalesce((select jsonb_agg(jsonb_build_object('id',id,'period',period,'count',invoice_count,'gross',gross_total,'postedAt',posted_at) order by posted_at desc) from public.billing_runs),'[]'::jsonb),
 'paymentMethods',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name)) from public.payment_methods where is_active),'[]'::jsonb)
 );
end;
$function$;
create or replace function public.edit_staff_record(p_input jsonb) returns jsonb language plpgsql security definer set search_path='public' as $$
declare original public.staff; saved public.staff; actor uuid:=auth.uid(); trace uuid:=gen_random_uuid();
begin
 if actor is null or not public.has_permission('staff.manage') then raise exception 'Staff management permission required.'; end if;
 select * into original from public.staff where id=(p_input->>'id')::uuid for update;
 if original.id is null then raise exception 'Staff identity not found.'; end if;
 if length(btrim(coalesce(p_input->>'full_name','')))<2 or length(p_input->>'full_name')>160 or length(btrim(coalesce(p_input->>'reason','')))<5 then raise exception 'Enter name and correction reason.'; end if;
 if coalesce(p_input->>'mobile','') !~ '^$|^01[3-9][0-9]{8}$' or coalesce(p_input->>'alternate_mobile','') !~ '^$|^01[3-9][0-9]{8}$' or coalesce(p_input->>'emergency_contact_mobile','') !~ '^$|^01[3-9][0-9]{8}$' then raise exception 'Check 11-digit Bangladesh mobile numbers.'; end if;
 if original.profile_id is not null and p_input ? 'email' and nullif(lower(btrim(p_input->>'email')),'') is distinct from original.email then raise exception 'Change linked account email through secure account settings.'; end if;
 if coalesce(p_input->>'email','') !~ '^$|^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'Enter a valid email.'; end if;
 update public.staff set full_name=btrim(p_input->>'full_name'), mobile=nullif(p_input->>'mobile',''),
 alternate_mobile=case when p_input ? 'alternate_mobile' then nullif(p_input->>'alternate_mobile','') else alternate_mobile end,
 email=case when p_input ? 'email' then nullif(lower(btrim(p_input->>'email')),'') else email end,
 address=case when p_input ? 'address' then left(p_input->>'address',500) else address end,
 emergency_contact_name=case when p_input ? 'emergency_contact_name' then left(p_input->>'emergency_contact_name',160) else emergency_contact_name end,
 emergency_contact_mobile=case when p_input ? 'emergency_contact_mobile' then nullif(p_input->>'emergency_contact_mobile','') else emergency_contact_mobile end,
 joined_on=case when p_input ? 'joined_on' then nullif(p_input->>'joined_on','')::date else joined_on end,
 notes=case when p_input ? 'notes' then left(p_input->>'notes',1000) else notes end where id=original.id returning * into saved;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data) values(trace,actor,'STAFF',saved.id::text,'CORRECT_DETAILS',p_input->>'reason',to_jsonb(original),to_jsonb(saved));
 return jsonb_build_object('id',saved.id);
end; $$;

CREATE OR REPLACE FUNCTION public.create_staff_admission_intake(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid := auth.uid();
  req uuid := nullif(p_input->>'request_id','')::uuid;
  reason text := btrim(coalesce(p_input->>'reason',''));
  existing public.staff_admission_intake_requests;
  offering public.programme_offerings;
  batch public.batches;
  fee public.fee_plan_versions;
  organization public.organizations;
  admission public.admission_cases;
  open_seats integer;
  local_today date; extras jsonb;
  student_name text := btrim(coalesce(p_input->>'student_name',''));
  guardian_name text := btrim(coalesce(p_input->>'guardian_name',''));
  mobile text := regexp_replace(coalesce(p_input->>'mobile',''), '\\D', '', 'g');
  alternate_mobile text := nullif(regexp_replace(coalesce(p_input->>'alternate_mobile',''), '\\D', '', 'g'), '');
  birth_date date := nullif(p_input->>'date_of_birth','')::date;
  gender_value text := nullif(btrim(coalesce(p_input->>'gender','')), '');
  school_name text := nullif(btrim(coalesce(p_input->>'school_name','')), '');
  school_roll text := nullif(btrim(coalesce(p_input->>'school_roll','')), '');
  guardian_address text := btrim(coalesce(p_input->>'guardian_address',''));
  guardian_relationship text := nullif(btrim(coalesce(p_input->>'guardian_relationship','')), '');
  intake_note text := nullif(btrim(coalesce(p_input->>'referral_note','')), '');
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if octet_length(p_input::text)>10000 then raise exception 'Application is too long.'; end if;
 if not exists(select 1 from public.organizations where setup_completed_at is not null and is_active) then raise exception 'Complete public setup before starting admissions.'; end if;
  if actor is null or not public.has_permission('admissions.create') then
    raise exception 'Admission permission required.';
  end if;

  if req is null or length(reason) < 5 or length(reason) > 500 then
    raise exception 'Request identity and an audit reason of 5 to 500 characters are required.';
  end if;

  if length(student_name) < 2 or length(student_name) > 160
    or length(guardian_name) < 2 or length(guardian_name) > 160
    or mobile !~ '^01[3-9][0-9]{8}$'
    or length(guardian_address) < 5
    or coalesce((p_input->>'consent_to_contact')::boolean, false) is not true then
    raise exception 'Enter the student, guardian, valid mobile, address, and confirm permission to contact.';
  end if;

  if coalesce(p_input->>'student_mobile','') !~ '^$|^01[3-9][0-9]{8}$' or coalesce(p_input->>'student_email','') !~ '^$|^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'Check optional student contact details.'; end if;
  if gender_value is not null
    and gender_value not in ('Female','Male','Other','Prefer not to say') then
    raise exception 'Choose a valid gender option or leave it blank.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(req::text, 0));

  select *
  into existing
  from public.staff_admission_intake_requests
  where request_id = req;

  if found then
    if existing.actor_id <> actor or existing.payload <> p_input then
      raise exception 'Request identity was already used for different intake details.';
    end if;

    select *
    into admission
    from public.admission_cases
    where id = existing.admission_id;

    return jsonb_build_object(
      'admission_id', existing.admission_id,
      'admission_no', admission.admission_no
    );
  end if;

  select *
  into offering
  from public.programme_offerings
  where id = nullif(p_input->>'offering_id','')::uuid
    and status = 'ACTIVE'
  for share;

  if offering.id is null then
    raise exception 'Choose an active programme offering.';
  end if;

  select *
  into batch
  from public.batches
  where id = nullif(p_input->>'batch_id','')::uuid
    and is_active
  for update;

  if batch.id is null or batch.offering_id is distinct from offering.id then
    raise exception 'Choose an active batch belonging to the selected programme offering.';
  end if;

  select *
  into organization
  from public.organizations
  where id = offering.organization_id;

  if organization.id is null then
    raise exception 'The selected programme organization is unavailable.';
  end if;

  local_today := timezone(organization.timezone, now())::date;

  select *
  into fee
  from public.fee_plan_versions
  where offering_id = offering.id
    and status = 'ACTIVE'
    and effective_from <= local_today
  order by effective_from desc, version desc
  limit 1;

  if fee.id is null then
    raise exception 'Publish an effective Fee Plan for this offering before starting admission.';
  end if;

  select count(*)
  into open_seats
  from public.enrollments
  where batch_id = batch.id
    and status = 'ACTIVE';

  if open_seats >= least(
    batch.capacity,
    coalesce(
      (
        select (payload->>'max_students')::integer
        from public.business_rule_versions
        where domain = 'academics'
          and rule_key = 'batch_capacity_policy'
          and status = 'ACTIVE'
        order by version desc
        limit 1
      ),
      batch.capacity
    )
  ) then
    raise exception 'The selected batch is full. Choose another available batch.';
  end if;

  if exists (
    select 1
    from public.admission_cases a
    where a.origin = 'DIRECT_STAFF'
      and lower(a.identity_snapshot->>'student_name') = lower(student_name)
      and regexp_replace(a.identity_snapshot->>'mobile', '\\D', '', 'g') = mobile
      and a.status <> 'CANCELLED'
  ) then
    raise exception 'A matching direct admission draft already exists. Open Admissions and continue that case.';
  end if;

  insert into public.admission_cases (
    prospect_id,
    origin,
    origin_prospect_id,
    batch_id,
    fee_plan_version_id,
    existing_student,
    identity_snapshot,
    created_by
  )
  values (
    null,
    'DIRECT_STAFF',
    null,
    batch.id,
    fee.id,
    false,
    jsonb_build_object(
      'student_name', student_name,
      'student_name_bn', nullif(btrim(coalesce(p_input->>'student_name_bn','')), ''),
      'date_of_birth', birth_date,
      'gender', gender_value,
      'school_name', school_name,
      'school_roll', school_roll,
      'guardian_name', guardian_name,
      'guardian_relationship', guardian_relationship,
      'mobile', mobile,
      'alternate_mobile', alternate_mobile,
      'guardian_address', guardian_address,
      'intake_note', intake_note,
      'consent_to_contact', true
    ),
    actor
  )
  returning *
  into admission;

  insert into public.audit_events(
    correlation_id,
    actor_profile_id,
    actor_staff_id,
    entity_type,
    entity_id,
    action,
    reason,
    before_data,
    after_data,
    metadata
  )
  values (
    req,
    actor,
    (select s.id from public.staff s where s.profile_id = actor limit 1),
    'ADMISSION',
    admission.id::text,
    'CREATE_DIRECT_STAFF_ADMISSION',
    reason,
    null,
    to_jsonb(admission),
    jsonb_build_object(
      'origin', 'DIRECT_STAFF',
      'offering_id', offering.id,
      'batch_id', batch.id
    )
  );

  insert into public.staff_admission_intake_requests(
    request_id,
    actor_id,
    payload,
    prospect_id,
    admission_id
  )
  values (
    req,
    actor,
    p_input,
    null,
    admission.id
  );

  extras:=jsonb_build_object('student_mobile',left(p_input->>'student_mobile',30),'student_email',left(p_input->>'student_email',254),'present_landmark',left(p_input->>'present_landmark',160),'permanent_same_as_present',coalesce(p_input->>'permanent_same_as_present','false'),'father_name',left(p_input->>'father_name',160),'mother_name',left(p_input->>'mother_name',160),
 'birth_registration',left(p_input->>'birth_registration',40),'permanent_address',left(p_input->>'permanent_address',300),
 'emergency_contact',left(p_input->>'emergency_contact',160),'emergency_mobile',left(p_input->>'emergency_mobile',30),
 'previous_result',left(p_input->>'previous_result',200),'learning_needs',left(p_input->>'learning_needs',500));
 update public.admission_cases set identity_snapshot=identity_snapshot||jsonb_strip_nulls(extras)
 where id=admission.id;

  return jsonb_build_object(
    'admission_id', admission.id,
    'admission_no', admission.admission_no
  );
end;
$function$;

revoke all on function public.referral_invoice_collections(uuid) from public,anon,authenticated;

revoke all on function public.sync_referral_reward(uuid) from public,anon,authenticated;

revoke all on function public.referral_collection_changed() from public,anon,authenticated;

revoke all on function public.referrer_paid(uuid) from public,anon,authenticated;

revoke all on function public.referrer_workspace(uuid) from public,anon,authenticated;

revoke all on function public.manage_referrer(jsonb) from public,anon,authenticated;

revoke all on function public.settle_referrer_reward(jsonb) from public,anon,authenticated;

revoke all on function public.collect_student_payment(jsonb) from public,anon,authenticated;

revoke all on function public.finance_operating_summary() from public,anon,authenticated;
grant execute on function public.referrer_workspace(uuid) to authenticated;
grant execute on function public.manage_referrer(jsonb) to authenticated;
grant execute on function public.settle_referrer_reward(jsonb) to authenticated;
grant execute on function public.collect_student_payment(jsonb) to authenticated;
grant execute on function public.finance_operating_summary() to authenticated;

revoke update,delete on public.referral_reward_contracts,public.referral_reward_entries from authenticated;
create function public.save_referral_operating_rules(p_input jsonb) returns jsonb language plpgsql security definer set search_path='public' as $$
begin
 perform public.publish_business_rule_version('referrals','acquisition_policy',jsonb_build_object('bonus_percent',(p_input->>'bonusPercent')::numeric),p_input->>'reason');
 perform public.publish_business_rule_version('finance','collection_discount_policy',jsonb_build_object('max_discount_percent',(p_input->>'discountMax')::numeric,'max_scholarship_percent',(p_input->>'scholarshipMax')::numeric),p_input->>'reason');
 return jsonb_build_object('message','Referrer and collection settings saved.');
end; $$;
revoke all on function public.save_referral_operating_rules(jsonb) from public,anon;
grant execute on function public.save_referral_operating_rules(jsonb) to authenticated;
create function public.preserve_referral_evidence() returns trigger language plpgsql as $$ begin raise exception 'Referral reward evidence is immutable; use a compensating entry.';end;$$;
revoke all on function public.preserve_referral_evidence() from public,anon,authenticated;
create trigger preserve_reward_entries before update or delete on public.referral_reward_entries for each row execute function public.preserve_referral_evidence();
create trigger preserve_reward_contract before update or delete on public.referral_reward_contracts for each row execute function public.preserve_referral_evidence();

CREATE OR REPLACE FUNCTION public.admission_case_detail(p_admission_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  result jsonb; charges jsonb; extras jsonb;
begin
  if auth.uid() is null or not public.has_permission('admissions.view') then
    raise exception 'Admission workspace access denied.';
  end if;

  select jsonb_build_object(
    'id', a.id,
    'number', a.admission_no,
    'status', a.status,
    'createdAt', a.created_at,
    'existingStudent', a.existing_student,
    'origin', a.origin,
    'originProspectId', a.origin_prospect_id,
    'batchId', a.batch_id,
    'batchName', b.name,
    'batchCode', b.code,
    'batchCapacity', b.capacity,
    'batchOccupied', (
      select count(*)
      from public.enrollments e
      where e.batch_id = b.id
        and e.status = 'ACTIVE'
    ),
    'offeringId', o.id,
    'offeringName', o.name,
    'className', cl.name,
    'yearName', ay.name,
    'branchName', br.name,
    'studentNo', s.student_no,
    'studentId', s.id,
    'name', a.identity_snapshot->>'student_name',
    'nameBn', a.identity_snapshot->>'student_name_bn',
    'gender', a.identity_snapshot->>'gender',
    'dateOfBirth', a.identity_snapshot->>'date_of_birth',
    'schoolName', a.identity_snapshot->>'school_name',
    'schoolRoll', a.identity_snapshot->>'school_roll',
    'guardianAddress', a.identity_snapshot->>'guardian_address',
    'alternateMobile', a.identity_snapshot->>'alternate_mobile',
    'guardianRelationship', a.identity_snapshot->>'guardian_relationship',
    'guardian', a.identity_snapshot->>'guardian_name',
    'mobile', a.identity_snapshot->>'mobile',
    'feeVersion', f.version,
    'feePlanId', f.id,
    'policyVersion', r.version,
    'paymentRequirement', r.payload->>'payment_requirement',
    'components', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'name', fc.name,
          'amount', fc.amount,
          'recurrence', fc.recurrence
        )
        order by fc.sort_order, fc.id
      )
      from public.fee_plan_components fc
      where fc.fee_plan_version_id = f.id
    ), '[]'::jsonb),
    'invoice', case
      when i.id is null then null
      else jsonb_build_object(
        'id', i.id, 'number', i.invoice_no,
        'total', i.total,
        'dueOn', i.due_on,
        'paid', bal.paid,
        'credits', bal.credits,
        'net', bal.net,
        'refunded', bal.refunded,
        'due', bal.due,
        'credit', bal.credit_balance
      )
    end,
    'receipts', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'number', p.receipt_no,
          'amount', pa.amount,
          'postedAt', p.posted_at,
          'method', pm.name,
          'refunded', coalesce((
            select sum(ra.amount)
            from public.refund_authorizations ra
            join public.refund_payouts rp
              on rp.authorization_id = ra.id
            where ra.payment_id = p.id
          ), 0)
        )
        order by p.posted_at, p.receipt_no
      )
      from public.admission_payment_allocations pa
      join public.admission_payments p
        on p.id = pa.payment_id
      join public.payment_methods pm
        on pm.id = p.payment_method_id
      where pa.invoice_id = i.id
    ), '[]'::jsonb)
  )
  into result
  from public.admission_cases a
  join public.fee_plan_versions f
    on f.id = a.fee_plan_version_id
  join public.batches b
    on b.id = a.batch_id
  join public.programme_offerings o
    on o.id = b.offering_id
  join public.classes cl
    on cl.id = b.class_id
  join public.academic_years ay
    on ay.id = b.academic_year_id
  left join public.branches br
    on br.id = b.branch_id
  left join public.students s
    on s.id = a.student_id
  left join public.business_rule_versions r
    on r.id = a.activation_policy_version_id
  left join public.admission_invoices i
    on i.admission_id = a.id
   and i.invoice_kind = 'INITIAL'
  left join lateral public.invoice_balance(i.id) bal
    on true
  where a.id = p_admission_id;

  if result is null then
    raise exception 'Admission Case not found.';
  end if;

  result:=result||(select jsonb_build_object('academyRoll',s.academy_roll::text,'discountPercent',a.selected_discount_percent,'discountReason',a.discount_reason,'additionalDetails',
 jsonb_build_object('student_mobile',a.identity_snapshot->>'student_mobile','student_email',a.identity_snapshot->>'student_email','present_landmark',a.identity_snapshot->>'present_landmark','permanent_same_as_present',a.identity_snapshot->>'permanent_same_as_present','father_name',a.identity_snapshot->>'father_name','mother_name',a.identity_snapshot->>'mother_name',
 'birth_registration',a.identity_snapshot->>'birth_registration','permanent_address',a.identity_snapshot->>'permanent_address',
 'emergency_contact',a.identity_snapshot->>'emergency_contact','emergency_mobile',a.identity_snapshot->>'emergency_mobile',
 'previous_result',a.identity_snapshot->>'previous_result','learning_needs',a.identity_snapshot->>'learning_needs'))
 from public.admission_cases a left join public.students s on s.id=a.student_id where a.id=p_admission_id);

 select additional_charges into charges from public.admission_cases where id=p_admission_id;
 select coalesce(jsonb_agg(jsonb_build_object('name',value->>'name','amount',(value->>'amount')::numeric,'recurrence','ONE_TIME')),'[]') into extras from jsonb_array_elements(charges) where (value->>'is_active')::boolean;
 return result||jsonb_build_object('tuitionTotal',(select coalesce(sum(c.amount),0) from public.fee_plan_components c join public.admission_cases a on a.fee_plan_version_id=c.fee_plan_version_id where a.id=p_admission_id and c.charge_type='TUITION'),'additionalCharges',charges,'components',(result->'components')||extras);
end;
$function$;
CREATE OR REPLACE FUNCTION public.edit_admission_identity(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.admission_cases; identity jsonb:=p_input->'identity'; guardian_id uuid; before_data jsonb;
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission management permission required.'; end if;
 if jsonb_typeof(identity) is distinct from 'object' or octet_length(identity::text)>5000
 or length(btrim(coalesce(p_input->>'reason','')))<5
 or length(btrim(coalesce(identity->>'student_name',''))) not between 2 and 160
 or length(btrim(coalesce(identity->>'guardian_name',''))) not between 2 and 160
 or coalesce(identity->>'mobile','') !~ '^01[3-9][0-9]{8}$'
 or length(btrim(coalesce(identity->>'guardian_address',''))) not between 5 and 300 then raise exception 'Enter verified student, guardian, contact and address details.'; end if;
 select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
 if a.id is null or a.status='CANCELLED' then raise exception 'Choose an open admission case.'; end if;
 if a.existing_student and a.student_id is null then raise exception 'Existing student identity is unavailable.'; end if;
 before_data:=a.identity_snapshot;
 if coalesce(identity->>'student_mobile','') !~ '^$|^01[3-9][0-9]{8}$' or coalesce(identity->>'student_email','') !~ '^$|^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'Check optional student contact.'; end if;
 identity:=jsonb_build_object('student_mobile',identity->>'student_mobile','student_email',identity->>'student_email','present_landmark',left(identity->>'present_landmark',160),'permanent_address',left(identity->>'permanent_address',300),'permanent_same_as_present',identity->>'permanent_same_as_present','student_name',btrim(identity->>'student_name'),'student_name_bn',nullif(btrim(identity->>'student_name_bn'),''),
 'guardian_name',btrim(identity->>'guardian_name'),'mobile',identity->>'mobile','alternate_mobile',nullif(identity->>'alternate_mobile',''),
 'guardian_address',btrim(identity->>'guardian_address'),'guardian_relationship',btrim(identity->>'guardian_relationship'),
 'date_of_birth',nullif(identity->>'date_of_birth','')::date,'gender',nullif(identity->>'gender',''),
 'school_name',btrim(identity->>'school_name'),'school_roll',btrim(identity->>'school_roll'));
 if a.student_id is not null then
  if not public.has_permission('students.manage') then raise exception 'Student correction permission required.'; end if;
  update public.students set full_name=identity->>'student_name',school_name_snapshot=identity->>'school_name' where id=a.student_id;
  -- Do not change a shared guardian identity. Link to an existing matching guardian
  -- or create the corrected guardian; keep the old guardian record intact.
  select g.id into guardian_id from public.guardians g join public.students s on s.organization_id=g.organization_id
   where s.id=a.student_id and g.mobile=identity->>'mobile' and lower(g.full_name)=lower(identity->>'guardian_name') order by g.created_at limit 1;
  if guardian_id is null then
   insert into public.guardians(organization_id,full_name,mobile,created_by)
    select organization_id,identity->>'guardian_name',identity->>'mobile',auth.uid() from public.students where id=a.student_id returning id into guardian_id;
  end if;
  update public.student_guardians set is_primary=false where student_id=a.student_id and is_primary;
  insert into public.student_guardians(student_id,guardian_id,relationship_snapshot,is_primary)
  values(a.student_id,guardian_id,identity->>'guardian_relationship',true)
  on conflict(student_id,guardian_id) do update set is_primary=true,relationship_snapshot=excluded.relationship_snapshot;
 end if;
 update public.admission_cases set identity_snapshot=identity_snapshot||identity,
  identity_revision=identity_revision+1,
  status=case when status in('DRAFT','READY') then 'DRAFT' else status end where id=a.id;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),'ADMISSION',a.id::text,'CORRECT_IDENTITY',p_input->>'reason',before_data,identity);
 return jsonb_build_object('id',a.id);
end $function$;
alter table public.students add column mobile text;
alter table public.students add column email text;
create function public.sync_student_optional_contact() returns trigger language plpgsql security definer set search_path='public' as $$ begin
 if new.student_id is not null and not new.existing_student then
  update public.students set mobile=nullif(new.identity_snapshot->>'student_mobile',''),email=nullif(new.identity_snapshot->>'student_email','') where id=new.student_id;
 end if; return new;
end; $$;
revoke all on function public.sync_student_optional_contact() from public,anon,authenticated;
create trigger admission_student_contact after update of student_id,identity_snapshot on public.admission_cases for each row execute function public.sync_student_optional_contact();
do $$ declare a record;begin
 for a in select admission_id from public.admission_referrals where source='REFERRED' order by admission_id loop perform public.sync_referral_reward(a.admission_id);end loop;
end; $$;

CREATE OR REPLACE FUNCTION public.create_prospect_admission(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare chosen uuid; changed uuid; p public.prospects; o public.programme_offerings; k public.admission_command_keys;
 req uuid:=nullif(p_input->>'request_id','')::uuid; result jsonb;
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if req is null or p_input->>'action' is distinct from 'CREATE' or length(btrim(coalesce(p_input->>'reason','')))<5 then
  raise exception 'A valid request and verification note are required.';
 end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into k from public.admission_command_keys where request_id=req;
 if found then
  if k.actor_id<>auth.uid() or k.payload<>p_input then raise exception 'Request identity already used.'; end if;
  return k.result;
 end if;
 select * into p from public.prospects where id=(p_input->>'prospect_id')::uuid for update;
 select * into o from public.programme_offerings where id=(p_input->>'offering_id')::uuid and status='ACTIVE';
 if p.id is null or p.status in('CONVERTED','LOST') or o.id is null or p.organization_id<>o.organization_id
 or not exists(select 1 from public.batches where id=(p_input->>'batch_id')::uuid and offering_id=o.id and is_active) then
  raise exception 'Choose an open enquiry, active offering and its batch.';
 end if;
 if (p.current_class_id is not null and p.current_class_id<>o.class_id)
   or (p.interested_offering_id is not null and p.interested_offering_id<>o.id) then
  if coalesce((p_input->>'confirm_placement_correction')::boolean,false) is not true then
   raise exception 'Confirm the corrected placement.';
  end if;
 end if;
 update public.prospects set current_class_id=o.class_id,interested_offering_id=o.id,
  application_verified_at=now(),application_verified_by=auth.uid() where id=p.id;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(req,auth.uid(),'PROSPECT',p.id::text,'VERIFY_ADMISSION_PLACEMENT',p_input->>'reason',to_jsonb(p),
   jsonb_build_object('class_id',o.class_id,'offering_id',o.id));
 if not exists(select 1 from public.organizations where id=o.organization_id and setup_completed_at is not null and is_active) then raise exception 'Complete public setup before starting admissions.'; end if;
 result:=public.admission_command(p_input);
 update public.admission_cases set identity_snapshot=identity_snapshot||jsonb_strip_nulls(jsonb_build_object(
 'guardian_address',coalesce(p.guardian_address,p.application_snapshot->>'guardian_address'),
 'alternate_mobile',p.alternate_mobile,'student_name_bn',p.student_name_bn,
 'date_of_birth',coalesce(p.date_of_birth::text,p.application_snapshot->>'date_of_birth'),
 'gender',coalesce(p.gender,p.application_snapshot->>'gender'),
 'school_roll',coalesce(p.school_roll,p.application_snapshot->>'school_roll'),
 'student_mobile',p.application_snapshot->>'student_mobile','student_email',p.application_snapshot->>'student_email','present_landmark',p.application_snapshot->>'present_landmark','permanent_address',p.application_snapshot->>'permanent_address','permanent_same_as_present',p.application_snapshot->>'permanent_same_as_present','birth_registration',p.application_snapshot->>'birth_registration','previous_result',p.application_snapshot->>'previous_result',
 'father_name',p.application_snapshot->>'father_name','mother_name',p.application_snapshot->>'mother_name',
 'emergency_contact',p.application_snapshot->>'emergency_contact','emergency_mobile',p.application_snapshot->>'emergency_mobile',
 'learning_needs',p.application_snapshot->>'learning_needs'))
 where id=(result->>'id')::uuid;

 select id into chosen from public.staff where profile_id=auth.uid() and status in('ACTIVE','ON_LEAVE');
 if chosen is not null then
 update public.prospects set assigned_to_staff_id=chosen where id=(p_input->>'prospect_id')::uuid and assigned_to_staff_id is null returning id into changed;
 if changed is not null then
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,after_data)
 values((p_input->>'request_id')::uuid,auth.uid(),'PROSPECT',changed::text,'ASSIGN_FOLLOWUP_STAFF','Staff handled verified admission conversion',jsonb_build_object('staff_id',chosen));
 end if; end if;

 return result;
end
$function$;

CREATE OR REPLACE FUNCTION public.apply_finance_adjustment(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid:=auth.uid();
  action text:=p_input->>'action';
  req uuid:=nullif(p_input->>'request_id','')::uuid;
  reason text:=btrim(coalesce(p_input->>'reason',''));
  key public.admission_command_keys;
  a public.admission_cases;
  i public.admission_invoices;
  payment public.admission_payments;
  discount public.admission_discounts;
  cancellation public.admission_cancellations;
  refund_auth public.refund_authorizations;
  payout public.refund_payouts;
  balance record;
  invoice_allocation numeric;
  reserved numeric;
  amount numeric;
  kind text;
  value numeric;
  start_date date;
  end_date date;
  settlement text;
  payment_method uuid;
  today date;
  before_data jsonb;
  after_data jsonb;
  result jsonb;
begin
  if actor is null then
    raise exception 'Sign in to continue.';
  end if;

  if req is null or length(reason)<5 then
    raise exception 'A request identity and reason are required.';
  end if;

  if action not in ('APPLY_DISCOUNT','CANCEL_ADMISSION','REFUND') then
    raise exception 'Unsupported finance adjustment.';
  end if;

  if action='APPLY_DISCOUNT' and not public.has_permission('finance.billing.manage') then
    raise exception 'Billing management permission required.';
  end if;

  if action='CANCEL_ADMISSION' and not public.has_permission('admissions.create') then
    raise exception 'Admission management permission required.';
  end if;

  if action='REFUND' and not public.has_permission('finance.payments.post') then
    raise exception 'Payment posting permission required.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(req::text,0));

  select * into key
  from public.admission_command_keys
  where request_id=req;

  if found then
    if key.actor_id<>actor or key.payload<>p_input then
      raise exception 'Request identity already used for different input.';
    end if;
    return key.result;
  end if;

  select * into a
  from public.admission_cases
  where id=nullif(p_input->>'admission_id','')::uuid
  for update;

  if action in ('APPLY_DISCOUNT','CANCEL_ADMISSION') and a.id is null then
    raise exception 'Admission not found.';
  end if;

  if a.id is not null then
    select (now() at time zone o.timezone)::date
    into today
    from public.batches b
    join public.organizations o on o.id=b.organization_id
    where b.id=a.batch_id;
  end if;

  if action='APPLY_DISCOUNT' then
    kind:=p_input->>'kind';
    value:=(p_input->>'value')::numeric;
    start_date:=(p_input->>'starts_on')::date;
    end_date:=(p_input->>'ends_on')::date;

    if a.status='CANCELLED'
      or kind not in ('PERCENT','FIXED')
      or value is null
      or value<=0
      or value<>round(value,2)
      or value>9999999999.99
      or (kind='PERCENT' and value>100)
      or start_date is null
      or end_date is null
      or end_date<start_date
    then
      raise exception 'Enter a valid discount and effective period.';
    end if;

    if exists(
      select 1
      from public.admission_discounts d
      where d.admission_id=a.id
        and daterange(d.starts_on,d.ends_on,'[]')
          && daterange(start_date,end_date,'[]')
    ) then
      raise exception 'Discount overlaps an existing discount. Use a non-overlapping period.';
    end if;

    before_data:=jsonb_build_object(
      'admission_id',a.id,
      'status',a.status
    );

    insert into public.admission_discounts(admission_id, authorized_by, authorization_reason, correlation_id, kind, value, starts_on, ends_on)
    values(a.id, actor, reason, req, kind, value, start_date, end_date)
    returning * into discount;

    for i in
      select *
      from public.admission_invoices
      where admission_id=a.id
        and billing_period between start_date and end_date
    loop
      perform public.apply_invoice_discounts(i.id);
    end loop;

    after_data:=jsonb_build_object(
      'discount_id',discount.id,
      'admission_id',a.id,
      'kind',discount.kind,
      'value',discount.value,
      'starts_on',discount.starts_on,
      'ends_on',discount.ends_on
    );

    result:=jsonb_build_object(
      'id',discount.id,
      'message','Discount applied and recorded.'
    );

    insert into public.audit_events(
      correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,metadata
    )
    values(
      req,actor,'ADMISSION_DISCOUNT',a.id::text,'APPLY_DISCOUNT',reason,
      before_data,after_data,jsonb_build_object('finance_flow','V3_DIRECT_ADMIN')
    );

  elsif action='CANCEL_ADMISSION' then
    settlement:=p_input->>'settlement';

    if a.status='CANCELLED'
      or settlement not in ('KEEP_CHARGES','CREDIT_ALL')
    then
      raise exception 'Choose a valid cancellation settlement for an open admission.';
    end if;

    if exists(
      select 1 from public.admission_cancellations
      where admission_id=a.id
    ) then
      raise exception 'Admission cancellation is already recorded.';
    end if;

    before_data:=jsonb_build_object(
      'admission_id',a.id,
      'status',a.status,
      'enrollment_id',a.enrollment_id
    );

    insert into public.admission_cancellations(admission_id, cancelled_by, cancellation_reason, correlation_id, settlement)
    values(a.id, actor, reason, req, settlement)
    returning * into cancellation;

    if settlement='CREDIT_ALL' then
      for i in
        select *
        from public.admission_invoices
        where admission_id=a.id
      loop
        select * into balance
        from public.invoice_balance(i.id);

        if balance.net>0 then
          insert into public.invoice_credits(invoice_id, kind, amount, applied_by)
          values(i.id, 'CANCELLATION', balance.net, actor)
          on conflict (invoice_id)
            where invoice_credits.kind='CANCELLATION'
          do nothing;
        end if;
      end loop;
    end if;

    update public.admission_cases
    set status='CANCELLED'
    where id=a.id;

    update public.enrollments
    set status='WITHDRAWN',
        ended_on=today
    where id=a.enrollment_id
      and status='ACTIVE';

    if a.student_id is not null
      and not exists(
        select 1
        from public.enrollments
        where student_id=a.student_id
          and status='ACTIVE'
      )
    then
      update public.students
      set status='INACTIVE'
      where id=a.student_id;
    end if;

    after_data:=jsonb_build_object(
      'cancellation_id',cancellation.admission_id,
      'admission_id',a.id,
      'status','CANCELLED',
      'settlement',settlement
    );

    result:=jsonb_build_object(
      'id',cancellation.admission_id,
      'message','Admission cancelled and recorded.'
    );

    insert into public.audit_events(
      correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,metadata
    )
    values(
      req,actor,'ADMISSION_CANCELLATION',a.id::text,'CANCEL_ADMISSION',reason,
      before_data,after_data,jsonb_build_object('finance_flow','V3_DIRECT_ADMIN')
    );

  else
    select * into payment
    from public.admission_payments
    where id=nullif(p_input->>'payment_id','')::uuid
    for update;

    select * into i
    from public.admission_invoices
    where id=nullif(p_input->>'invoice_id','')::uuid
    for update;

    amount:=(p_input->>'amount')::numeric;
    payment_method:=nullif(p_input->>'payment_method_id','')::uuid;

    if payment.id is null or i.id is null then
      raise exception 'Payment or invoice not found.';
    end if;

    if not exists(
      select 1
      from public.admission_payment_allocations pa
      where pa.payment_id=payment.id
        and pa.invoice_id=i.id
    ) then
      raise exception 'The selected payment is not allocated to this invoice.';
    end if;

    select coalesce(sum(pa.amount),0)
    into invoice_allocation
    from public.admission_payment_allocations pa
    where pa.payment_id=payment.id
      and pa.invoice_id=i.id;

    select coalesce(sum(r.amount),0)
    into reserved
    from public.refund_authorizations r
    where r.payment_id=payment.id;

    select * into balance
    from public.invoice_balance(i.id);

    if amount is null
      or amount<=0
      or amount<>round(amount,2)
      or payment_method is null
      or amount>payment.amount-reserved
      or amount>invoice_allocation
      or amount>balance.credit_balance-balance.reserved_refunds
    then
      raise exception 'Refund exceeds the unreserved eligible credit for this payment and invoice.';
    end if;

    if not exists(
      select 1
      from public.payment_methods
      where id=payment_method
        and is_active
    ) then
      raise exception 'Choose an active refund payment method.';
    end if;

    before_data:=jsonb_build_object(
      'payment_id',payment.id,
      'invoice_id',i.id,
      'amount_received',payment.amount,
      'invoice_credit',balance.credit_balance
    );

    insert into public.refund_authorizations(payment_id, invoice_id, amount, authorized_by, authorization_reason, correlation_id)
    values(payment.id, i.id, amount, actor, reason, req)
    returning * into refund_auth;

    insert into public.refund_payouts(
      authorization_id,
      payment_method_id,
      external_reference,
      posted_by,
      reason
    )
    values(
      refund_auth.id,
      payment_method,
      nullif(btrim(coalesce(p_input->>'external_reference','')),''),
      actor,
      reason
    )
    returning * into payout;

    after_data:=jsonb_build_object(
      'refund_authorization_id',refund_auth.id,
      'refund_id',payout.id,
      'refund_no',payout.refund_no,
      'invoice_id',i.id,
      'payment_id',payment.id,
      'amount',amount
    );

    result:=jsonb_build_object(
      'id',payout.id,
      'refund_no',payout.refund_no,
      'message','Actual refund posted: '||payout.refund_no||'.'
    );

    insert into public.audit_events(
      correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,metadata
    )
    values(
      req,actor,'REFUND',payout.id::text,'POST_REFUND',reason,
      before_data,after_data,jsonb_build_object(
        'finance_flow','V3_DIRECT_ADMIN',
        'invoice_id',i.id,
        'payment_id',payment.id
      )
    );
  end if;

  insert into public.admission_command_keys(request_id,actor_id,payload,result)
  values(req,actor,p_input,result);

  return result;
end;
$function$;

-- Upstream 15_audit_search_and_daily_activity.sql
-- Bounded audit search. Correlation and change payloads remain immutable internally.
create function public.audit_event_page(p_filters jsonb default '{}'::jsonb) returns jsonb
language plpgsql stable security definer set search_path='public' as $$
declare page_no integer:=greatest(1,least(coalesce((p_filters->>'page')::integer,1),100000)); page_size integer:=25;
 q text:=left(btrim(coalesce(p_filters->>'q','')),160); entity text:=left(coalesce(p_filters->>'entity',''),80); action_value text:=left(coalesce(p_filters->>'action',''),80);
 from_day date:=nullif(p_filters->>'from','')::date; to_day date:=nullif(p_filters->>'to','')::date;
 day_start timestamptz:=(now() at time zone 'Asia/Dhaka')::date::timestamp at time zone 'Asia/Dhaka'; total_rows bigint; rows jsonb; activity jsonb;
begin
 if auth.uid() is null or not public.has_permission('audit.view') then raise exception 'Audit permission required.';end if;
 if from_day is not null and to_day is not null and from_day>to_day then raise exception 'Start date must be on or before end date.';end if;
 with matched as (
 select e.id,e.occurred_at,e.action,e.entity_type,e.entity_id,e.reason,e.actor_profile_id,
 coalesce(e.metadata->>'actor_name',s.full_name,p.display_name) actor_name,
 coalesce(e.metadata->>'actor_staff_no',s.staff_no) actor_staff_no,
 coalesce(e.actor_role_code,(select string_agg(distinct r.code,', ' order by r.code) from public.user_role_assignments a join public.system_roles r on r.id=a.role_id where a.profile_id=e.actor_profile_id and a.effective_from<=e.occurred_at::date and (a.effective_to is null or a.effective_to>=e.occurred_at::date))) actor_role_code
 from public.audit_events e left join public.profiles p on p.id=e.actor_profile_id
 left join public.staff s on s.id=e.actor_staff_id or (e.actor_staff_id is null and s.profile_id=e.actor_profile_id)
 where (entity='' or e.entity_type=entity) and (action_value='' or e.action=action_value)
 and (from_day is null or e.occurred_at>=from_day::timestamp at time zone 'Asia/Dhaka')
 and (to_day is null or e.occurred_at<(to_day+1)::timestamp at time zone 'Asia/Dhaka')
 and (coalesce(p_filters->>'preset','')<>'invoices' or (e.entity_type='ADMISSION' and e.action='BILL') or (e.entity_type='FINANCE_WORKFLOW' and e.action='RUN_BILLING'))
 and (q='' or position(lower(q) in lower(concat_ws(' ',coalesce(e.metadata->>'actor_name',s.full_name,p.display_name),coalesce(e.metadata->>'actor_staff_no',s.staff_no),e.actor_profile_id::text,e.actor_role_code,replace(e.action,'_',' '),e.action,e.entity_type,e.entity_id,e.reason)))>0)
 ), paged as (select * from matched order by occurred_at desc,id desc limit page_size offset (page_no-1)*page_size)
 select (select count(*) from matched),coalesce((select jsonb_agg(to_jsonb(paged) order by occurred_at desc,id desc) from paged),'[]'::jsonb) into total_rows,rows;
 activity:=jsonb_build_object('date',(now() at time zone 'Asia/Dhaka')::date,
 'admissions',case when public.has_permission('admissions.view') then (select count(distinct entity_id) from public.audit_events where entity_type='ADMISSION' and action='FINALIZE' and occurred_at>=day_start and occurred_at<day_start+interval '1 day') else null end,
 'invoices',case when public.has_permission('finance.view') then (select count(*) from public.admission_invoices where posted_at>=day_start and posted_at<day_start+interval '1 day') else null end,
 'grossIssued',case when public.has_permission('finance.view') then (select coalesce(sum(total),0) from public.admission_invoices where posted_at>=day_start and posted_at<day_start+interval '1 day') else null end,
 'collected',case when public.has_permission('finance.view') then (select coalesce(sum(amount),0) from public.admission_payments where posted_at>=day_start and posted_at<day_start+interval '1 day') else null end,
 'refunds',case when public.has_permission('finance.view') then (select coalesce(sum(a.amount),0) from public.refund_payouts r join public.refund_authorizations a on a.id=r.authorization_id where r.posted_at>=day_start and r.posted_at<day_start+interval '1 day') else null end);
 return jsonb_build_object('rows',rows,'total',total_rows,'page',page_no,'pageSize',page_size,'activity',activity);
end $$;
revoke all on function public.audit_event_page(jsonb) from public,anon;
grant execute on function public.audit_event_page(jsonb) to authenticated;
create index if not exists audit_events_entity_action_time on public.audit_events(entity_type,action,occurred_at desc,id desc);
create index if not exists audit_events_time_id on public.audit_events(occurred_at desc,id desc);

create index if not exists admission_invoices_posted_time on public.admission_invoices(posted_at);
create index if not exists admission_payments_posted_time on public.admission_payments(posted_at);

-- Upstream 16_request_onboarding_and_own_compensation.sql
-- Request-only staff onboarding and own financial statements. No historical identities are deleted.
alter table public.staff_access_requests drop constraint staff_access_requests_status_check;
alter table public.staff_access_requests add constraint staff_access_requests_status_check check(status in('PENDING','VERIFIED','INVITED','ACTIVE','DECLINED','INACTIVE'));
-- Backfill only accounts that have actually signed in; staff lifecycle ACTIVE alone is not proof.
update public.staff_access_requests r set status='ACTIVE' from auth.users u
where r.profile_id=u.id and r.status='INVITED' and nullif(to_jsonb(u)->>'last_sign_in_at','') is not null;

create function public.sync_staff_referrer() returns trigger language plpgsql security definer set search_path='public' as $$
declare existing public.referral_people; other_count integer; org uuid;
begin
 if new.profile_id is null or new.status<>'ACTIVE' then return new;end if;
 select organization_id into org from public.branches where id=new.branch_id;
 if org is null then select id into org from public.organizations order by created_at limit 1;end if;
 select * into existing from public.referral_people where staff_id=new.id;
 if existing.id is not null then
  if existing.profile_id is null and not exists(select 1 from public.referral_people where profile_id=new.profile_id and id<>existing.id) then update public.referral_people set profile_id=new.profile_id where id=existing.id;end if;
  return new;
 end if;
 select * into existing from public.referral_people where profile_id=new.profile_id;
 if existing.id is not null then
  if existing.staff_id is not null and existing.staff_id<>new.id then raise exception 'This account is linked to another staff identity. Resolve the identity before continuing.';end if;
  update public.referral_people set staff_id=new.id where id=existing.id;return new;
 end if;
 -- Preserve a unique existing external referrer with the same mobile instead of issuing a duplicate ID.
 select * into existing from public.referral_people where organization_id=org and mobile=new.mobile;
 if existing.id is not null then
  if existing.staff_id is not null or existing.profile_id is not null or lower(btrim(existing.full_name))<>lower(btrim(new.full_name)) then
   return new; -- ambiguous identity: portal shows an empty account; admin must verify the link
  end if;
  update public.referral_people set staff_id=new.id,profile_id=new.profile_id where id=existing.id;return new;
 end if;
 insert into public.referral_people(organization_id,staff_id,full_name,mobile,email,profile_id,created_by)
 values(org,new.id,new.full_name,new.mobile,new.email,new.profile_id,coalesce(auth.uid(),new.created_by)) on conflict(staff_id) do nothing;
 return new;
end $$;
revoke all on function public.sync_staff_referrer() from public,anon,authenticated;
create trigger staff_referrer_identity after insert or update of profile_id on public.staff for each row execute function public.sync_staff_referrer();
-- Reuse existing referral records; no UPDATE of immutable reward contracts or posted journals.
do $$ declare s public.staff;begin for s in select * from public.staff where profile_id is not null and status='ACTIVE' loop
 update public.staff set profile_id=profile_id where id=s.id;
end loop;end $$;

create function public.complete_own_staff_access() returns void language plpgsql security definer set search_path='public' as $$
declare updated public.staff_access_requests;
begin
 if auth.uid() is null or not exists(select 1 from public.profiles where id=auth.uid() and status='ACTIVE') then return;end if;
 for updated in update public.staff_access_requests r set status='ACTIVE' where r.profile_id=auth.uid() and r.status='INVITED'
 and exists(select 1 from public.staff s where s.profile_id=auth.uid() and s.status='ACTIVE')
 and exists(select 1 from public.user_role_assignments a join public.system_roles ro on ro.id=a.role_id where a.profile_id=auth.uid() and a.is_active and ro.is_active and a.effective_from<=current_date and (a.effective_to is null or a.effective_to>=current_date)) returning r.* loop
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason) values(auth.uid(),'STAFF_ACCESS_REQUEST',updated.id::text,'ACCOUNT_ACTIVATED','Verified account accessed the public workspace');
 end loop;
end $$;
revoke all on function public.complete_own_staff_access() from public,anon,authenticated;

CREATE OR REPLACE FUNCTION public.my_erp_context()
 RETURNS jsonb
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 perform public.complete_own_staff_access();
 return (select jsonb_build_object(
    'profile_id', p.id,
    'display_name', p.display_name,
    'status', p.status,
    'staff_id', s.id,
    'staff_no', s.staff_no,
    'staff_name', s.full_name,
    'roles', coalesce((
      select jsonb_agg(distinct sr.code order by sr.code)
      from public.user_role_assignments ura
      join public.system_roles sr on sr.id = ura.role_id
      where ura.profile_id = p.id
        and ura.is_active
        and ura.effective_from <= current_date
        and (ura.effective_to is null or ura.effective_to >= current_date)
        and sr.is_active
    ), '[]'::jsonb),
    'permissions', coalesce((
      select jsonb_agg(distinct pe.code order by pe.code)
      from public.user_role_assignments ura
      join public.system_roles sr on sr.id = ura.role_id
      join public.role_permissions rp on rp.role_id = sr.id
      join public.permissions pe on pe.id = rp.permission_id
      where ura.profile_id = p.id
        and ura.is_active
        and ura.effective_from <= current_date
        and (ura.effective_to is null or ura.effective_to >= current_date)
        and sr.is_active
    ), '[]'::jsonb)
  )
  from public.profiles p
  left join public.staff s on s.profile_id = p.id
  where p.id = auth.uid());
end
$function$;

CREATE OR REPLACE FUNCTION public.review_staff_access(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.staff_access_requests; role_value text:=p_input->>'assigned_role'; user_id uuid; matched_staff uuid; matching_count integer;
begin
 if auth.uid() is null or not public.has_permission('system.users.manage') then raise exception 'User management permission required.'; end if;
 if not exists(select 1 from public.user_role_assignments a join public.system_roles ro on ro.id=a.role_id
 where a.profile_id=auth.uid() and a.is_active and ro.code='ADMIN' and ro.is_active and a.effective_from<=current_date and (a.effective_to is null or a.effective_to>=current_date)) then raise exception 'Super admin verification required.'; end if;
 select * into r from public.staff_access_requests where id=(p_input->>'id')::uuid for update;
 if r.id is null then raise exception 'Request not found.'; end if;
 if p_input->>'action'='DECLINE' then
  if r.status not in('PENDING','VERIFIED') then raise exception 'Only pending requests can be declined.'; end if;
  update public.staff_access_requests set status='DECLINED',reviewed_by=auth.uid(),reviewed_at=now(),review_note=p_input->>'reason' where id=r.id;
 elsif p_input->>'action'='VERIFY' then
  if role_value not in('ADMIN','OPERATOR','TEACHER','ACCOUNTANT') then raise exception 'Choose a role.'; end if;
  if r.status not in('PENDING','VERIFIED') then raise exception 'Only pending requests can be verified.'; end if;
  update public.staff_access_requests set status='VERIFIED',assigned_role=role_value,reviewed_by=auth.uid(),reviewed_at=now(),review_note=p_input->>'reason' where id=r.id;
 elsif p_input->>'action'='COMPLETE_INVITATION' then
  if r.status not in('VERIFIED','INVITED') then raise exception 'Verify the request before inviting.'; end if;
  -- Identity is resolved from the verified request email, never an arbitrary caller ID.
  select id into user_id from auth.users where lower(email)=r.email;
  if user_id is null then raise exception 'Supabase invitation has not created the user yet.'; end if;
  insert into public.profiles(id,display_name) values(user_id,r.full_name) on conflict(id) do nothing;
  select id into matched_staff from public.staff where profile_id=user_id;
  if matched_staff is null then
   select count(*),min(id::text)::uuid into matching_count,matched_staff from public.staff where profile_id is null and status='ACTIVE'
    and (lower(email)=r.email or (email is null and mobile=r.mobile and lower(btrim(full_name))=lower(btrim(r.full_name))));
   if matching_count>1 then raise exception 'Multiple existing identities match this request. Verify and correct the existing staff records first.';end if;
   if matched_staff is not null then update public.staff set profile_id=user_id,email=r.email where id=matched_staff;
   else insert into public.staff(profile_id,full_name,email,mobile,joined_on,created_by) values(user_id,r.full_name,r.email,r.mobile,current_date,auth.uid()) returning id into matched_staff;end if;
  end if;
  if not exists(select 1 from public.system_roles where code=r.assigned_role and is_active) then raise exception 'Assigned role is unavailable.'; end if;
  insert into public.user_role_assignments(profile_id,role_id,assigned_by)
   select user_id,id,auth.uid() from public.system_roles where code=r.assigned_role and is_active
   on conflict do nothing;
  insert into public.staff_role_assignments(staff_id,staff_role_id,is_primary,assigned_by)
   select s.id,role.id,true,auth.uid() from public.staff s join public.staff_roles role on role.code=r.assigned_role and role.is_active
   where s.profile_id=user_id and not exists(select 1 from public.staff_role_assignments old where old.staff_id=s.id and old.is_primary and old.effective_to is null);
  update public.staff_access_requests set status='INVITED',profile_id=user_id,invitation_sent_at=now() where id=r.id;
 else raise exception 'Unsupported staff verification action.';
 end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason)
 values(auth.uid(),'STAFF_ACCESS_REQUEST',r.id::text,p_input->>'action',coalesce(p_input->>'reason','Verified staff invitation'));
 return jsonb_build_object('id',r.id);
end $function$;

-- Old clients cannot bypass the request/verification identity path.
create or replace function public.create_staff_member(p_input jsonb) returns jsonb language plpgsql security definer set search_path='public' as $$
begin raise exception 'Staff identities are issued from verified access requests. Use People → Staff access requests.';end $$;
revoke all on function public.create_staff_member(jsonb) from public,anon,authenticated;

create or replace function public.referrer_workspace(p_referrer_id uuid default null) returns jsonb
language plpgsql stable security definer set search_path='public' as $$
declare manager boolean:=public.has_permission('staff.compensation.manage') or public.has_permission('admissions.create'); rid uuid; person public.referral_people; students jsonb; org uuid; policy jsonb; teacher_policy jsonb; teaching boolean:=false; teaching_lines jsonb; teaching_payments jsonb; teacher_earned numeric:=0; teacher_settled numeric:=0; advances numeric:=0;
begin
 if auth.uid() is null or not exists(select 1 from public.profiles where id=auth.uid() and status='ACTIVE') then raise exception 'Active sign-in required.'; end if;
 if not manager and not public.has_permission('referrals.portal.view') then raise exception 'Referral account access required.';end if;
 if manager and p_referrer_id is not null then rid:=p_referrer_id;
 else select r.id into rid from public.referral_people r left join public.staff s on s.id=r.staff_id
  where r.is_active and (r.profile_id=auth.uid() or (s.profile_id=auth.uid() and s.status='ACTIVE')) order by (r.profile_id=auth.uid()) desc,r.created_at limit 1;
  if not manager and p_referrer_id is not null and p_referrer_id is distinct from rid then raise exception 'Only your own referrals are available.';end if;
 end if;
 select * into person from public.referral_people where id=rid;
 select id into org from public.organizations where is_active;
 select coalesce(jsonb_agg(jsonb_build_object('id',a.id,'number',a.admission_no,'name',a.identity_snapshot->>'student_name','studentNo',s.student_no,'programme',o.name,'status',a.status,
 'discountPercent',a.selected_discount_percent,
 'discountAmount',(select coalesce(sum(ic.amount),0) from public.invoice_credits ic join public.admission_invoices i on i.id=ic.invoice_id where i.admission_id=a.id and ic.kind='DISCOUNT'),
 'netTuition',(select coalesce(sum(tuition_collected),0) from public.referral_invoice_collections(a.id)),
 'reward',(select coalesce(sum(amount),0) from public.referral_reward_entries where admission_id=a.id),
 'rate',(select bonus_percent from public.referral_reward_contracts where admission_id=a.id),
 'collections',(select coalesce(jsonb_agg(jsonb_build_object('receipt',p.receipt_no,'receivedOn',p.posted_at,'allocated',pa.amount,'billingPeriod',i.billing_period,'tuitionCollected',c.tuition_collected) order by p.posted_at desc),'[]'::jsonb)
 from public.admission_invoices i join public.admission_payment_allocations pa on pa.invoice_id=i.id join public.admission_payments p on p.id=pa.payment_id
 join public.referral_invoice_collections(a.id) c on c.invoice_id=i.id where i.admission_id=a.id)) order by a.created_at desc),'[]'::jsonb) into students
 from public.admission_referrals ar join public.admission_cases a on a.id=ar.admission_id join public.batches b on b.id=a.batch_id join public.programme_offerings o on o.id=b.offering_id left join public.students s on s.id=a.student_id
 where ar.referrer_id=rid and ar.source='REFERRED';
 select payload into policy from public.business_rule_versions where domain='referrals' and rule_key='acquisition_policy' and status='ACTIVE' order by version desc limit 1;
 select payload into teacher_policy from public.business_rule_versions where domain='teacher_compensation' and rule_key='default_policy' and status='ACTIVE' order by version desc limit 1;
 teaching:=exists(select 1 from public.staff_role_assignments a join public.staff_roles r on r.id=a.staff_role_id where a.staff_id=person.staff_id and r.code in('TEACHER','ACADEMIC_DIRECTOR') and a.effective_from<=current_date and (a.effective_to is null or a.effective_to>=current_date));
 select coalesce(jsonb_agg(jsonb_build_object('id',l.id,'run',r.run_no,'from',r.period_start,'to',r.period_end,'type',l.line_type,'amount',l.amount,'netTuition',l.calculation->'netCollectedTuition','poolPercent',l.calculation->'poolPercent','approvedSessions',l.calculation->'approvedSessions','batchApprovedSessions',l.calculation->'batchApprovedSessions') order by r.period_end desc,l.id),'[]'::jsonb),coalesce(sum(l.amount),0) into teaching_lines,teacher_earned
 from public.teacher_compensation_lines l join public.teacher_compensation_runs r on r.id=l.run_id where l.teacher_id=person.staff_id and r.status='APPROVED' and l.line_type<>'ACQUISITION_BONUS';
 -- Attribute historical mixed settlements proportionately; acquisition stays in the referral statement.
 select coalesce(jsonb_agg(jsonb_build_object('date',s.settled_at,'run',r.run_no,'gross',round(s.gross_amount*coalesce(t.non_acquisition/nullif(t.total,0),0),2),'cash',round(s.cash_paid*coalesce(t.non_acquisition/nullif(t.total,0),0),2),'advanceOffset',round(s.advance_offset*coalesce(t.non_acquisition/nullif(t.total,0),0),2),'reference',s.external_reference) order by s.settled_at desc),'[]'::jsonb),coalesce(sum(round(s.gross_amount*coalesce(t.non_acquisition/nullif(t.total,0),0),2)),0) into teaching_payments,teacher_settled
 from public.teacher_compensation_settlements s join public.teacher_compensation_runs r on r.id=s.run_id
 cross join lateral(select sum(amount) total,sum(amount) filter(where line_type<>'ACQUISITION_BONUS') non_acquisition from public.teacher_compensation_lines where run_id=s.run_id and teacher_id=s.teacher_id) t where s.teacher_id=person.staff_id;
 select coalesce(sum(public.advance_balance(a.id)),0) into advances from public.finance_advances a where a.staff_id=person.staff_id and a.status in('PAID','PARTIALLY_SETTLED','OVERDUE');
 return jsonb_build_object('manager',manager,'people',case when manager then (select coalesce(jsonb_agg(jsonb_build_object('id',r.id,'name',r.full_name,'mobile',r.mobile,'email',r.email,'staffId',r.staff_id,'profileId',coalesce(r.profile_id,s.profile_id),'active',r.is_active,'relationship',r.relationship_note,'notes',r.contact_note) order by r.full_name),'[]'::jsonb) from public.referral_people r left join public.staff s on s.id=r.staff_id) else '[]'::jsonb end,
 'selected',rid,'name',person.full_name,'students',students,
 'policy',jsonb_build_object('acquisitionPercent',policy->'bonus_percent','teachingPoolPercent',teacher_policy->'teaching_pool_percent','teachingReviewMaxPercent',teacher_policy->'teaching_pool_review_max_percent','retention3Percent',teacher_policy->'retention_3_month_percent','retention6Percent',teacher_policy->'retention_6_month_percent'),
 'teacher',teaching,'teachingLines',teaching_lines,'teachingPayments',teaching_payments,'teachingEarned',teacher_earned,'teachingSettled',teacher_settled,'advanceOutstanding',advances,
 'ownReferrerId',(select r.id from public.referral_people r left join public.staff s on s.id=r.staff_id where r.is_active and (r.profile_id=auth.uid() or s.profile_id=auth.uid()) order by r.created_at limit 1),
 'earned',(select coalesce(sum(amount),0) from public.referral_reward_entries where referrer_id=rid),'settled',public.referrer_paid(rid),
 'entries',(select coalesce(jsonb_agg(jsonb_build_object('id',id,'admissionId',admission_id,'amount',amount,'collected',net_collected,'rate',bonus_percent,'date',created_at) order by created_at desc),'[]'::jsonb) from public.referral_reward_entries where referrer_id=rid),
 'settlements',(select coalesce(jsonb_agg(jsonb_build_object('amount',s.amount,'date',s.settled_at,'reference',s.external_reference) order by s.settled_at desc),'[]'::jsonb) from public.finance_payable_settlements s join public.finance_payables p on p.id=s.payable_id where p.referrer_id=rid),
 'accounts',case when manager then (select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name)),'[]'::jsonb) from public.finance_accounts where organization_id=org and is_active and account_subtype in('CASH','BANK','MOBILE_BANK')) else '[]'::jsonb end);
end; $$;

-- Upstream 17_staff_attendance_and_personal_work.sql
-- Workforce evidence is separate from student attendance and approved teaching workload.
insert into public.permissions(code,name,description) values
 ('workforce.self.view','View my work','Own attendance and compensation terms'),
 ('workforce.manage','Manage workforce','Record staff attendance and agreed compensation terms') on conflict(code) do nothing;
insert into public.role_permissions(role_id,permission_id)
select r.id,p.id from public.system_roles r cross join public.permissions p
where (p.code='workforce.self.view' and r.code in('ADMIN','OPERATOR','TEACHER','ACCOUNTANT')) or (p.code='workforce.manage' and r.code='ADMIN') on conflict do nothing;

create table public.staff_attendance_records(
 id uuid primary key default gen_random_uuid(),staff_id uuid not null references public.staff(id),work_date date not null,
 status text not null check(status in('PRESENT','ABSENT','LEAVE','HOLIDAY')),
 started_at timestamptz,ended_at timestamptz,break_minutes integer not null default 0 check(break_minutes between 0 and 1440),
 recorded_by uuid not null references public.profiles(id),reason text not null check(length(btrim(reason))>=5),
 updated_at timestamptz not null default now(),unique(staff_id,work_date),
 check((status='PRESENT' and started_at is not null and ended_at is not null and ended_at>started_at and ended_at-started_at<=interval '24 hours' and extract(epoch from ended_at-started_at)/60>break_minutes) or (status<>'PRESENT' and started_at is null and ended_at is null and break_minutes=0))
);
create index staff_attendance_date_idx on public.staff_attendance_records(work_date,staff_id);
create table public.staff_compensation_terms(
 staff_id uuid primary key references public.staff(id),model text not null check(model in('FIXED','HOURLY','REVENUE_SHARE','HYBRID')),
 monthly_base numeric(14,2) not null default 0 check(monthly_base>=0),hourly_rate numeric(14,2) not null default 0 check(hourly_rate>=0),
 pay_day integer not null check(pay_day between 1 and 28),effective_from date not null,
 recorded_by uuid not null references public.profiles(id),reason text not null check(length(btrim(reason))>=5),updated_at timestamptz not null default now(),
 check((model='FIXED' and monthly_base>0 and hourly_rate=0) or (model='HOURLY' and monthly_base=0 and hourly_rate>0) or (model='REVENUE_SHARE' and monthly_base=0 and hourly_rate=0) or (model='HYBRID' and monthly_base>0))
);
alter table public.staff_attendance_records enable row level security;
alter table public.staff_compensation_terms enable row level security;
create policy staff_attendance_scope on public.staff_attendance_records for select to authenticated using(public.has_permission('workforce.manage') or (public.has_permission('workforce.self.view') and staff_id in(select id from public.staff where profile_id=auth.uid() and status='ACTIVE')));
create policy compensation_terms_scope on public.staff_compensation_terms for select to authenticated using(public.has_permission('workforce.manage') or (public.has_permission('workforce.self.view') and staff_id in(select id from public.staff where profile_id=auth.uid() and status='ACTIVE')));
grant select on public.staff_attendance_records,public.staff_compensation_terms to authenticated;
revoke insert,update,delete on public.staff_attendance_records,public.staff_compensation_terms from anon,authenticated;
create trigger attendance_no_delete before delete on public.staff_attendance_records for each row execute function public.prevent_permanent_record_delete();
create trigger terms_no_delete before delete on public.staff_compensation_terms for each row execute function public.prevent_permanent_record_delete();

create function public.workforce_command(p_input jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid();sid uuid:=(p_input->>'staff_id')::uuid;request uuid:=(p_input->>'request_id')::uuid;old_key public.admission_command_keys;
 action text:=p_input->>'action';reason text:=btrim(p_input->>'reason');before_data jsonb;after_data jsonb;result jsonb;day date;start_time timestamptz;end_time timestamptz;
begin
 if actor is null or not public.has_permission('workforce.manage') or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') then raise exception 'Workforce management permission required.';end if;
 if request is null or coalesce(length(reason),0)<5 then raise exception 'A request ID and clear reason are required.';end if;
 perform pg_advisory_xact_lock(hashtextextended(request::text,0));
 select * into old_key from public.admission_command_keys where request_id=request;
 if found then if old_key.actor_id<>actor or old_key.payload<>p_input then raise exception 'Request identity conflict.';end if;return old_key.result;end if;
 perform 1 from public.staff where id=sid and status in('ACTIVE','ON_LEAVE') for update;
 if not found then raise exception 'Choose an active staff identity.';end if;
 if action='RECORD_ATTENDANCE' then
  day:=(p_input->>'work_date')::date;
  if day is null or day>(now() at time zone 'Asia/Dhaka')::date then raise exception 'Actual attendance cannot be recorded for a future date.';end if;
  if p_input->>'status'='PRESENT' then
   start_time:=(p_input->>'started_at')::timestamptz;end_time:=(p_input->>'ended_at')::timestamptz;
   if start_time is null or end_time is null or end_time>now() or (start_time at time zone 'Asia/Dhaka')::date<>day then raise exception 'Check the actual start, end and Bangladesh work date.';end if;
  end if;
  if start_time is not null and exists(select 1 from public.staff_attendance_records where staff_id=sid and work_date<>day and status='PRESENT' and started_at<end_time and ended_at>start_time) then raise exception 'These work hours overlap another attendance record.';end if;
  select to_jsonb(a) into before_data from public.staff_attendance_records a where staff_id=sid and work_date=day;
  insert into public.staff_attendance_records(staff_id,work_date,status,started_at,ended_at,break_minutes,recorded_by,reason)
  values(sid,day,p_input->>'status',start_time,end_time,case when p_input->>'status'='PRESENT' then coalesce((p_input->>'break_minutes')::integer,0) else 0 end,actor,reason)
  on conflict(staff_id,work_date) do update set status=excluded.status,started_at=excluded.started_at,ended_at=excluded.ended_at,break_minutes=excluded.break_minutes,recorded_by=actor,reason=excluded.reason,updated_at=now()
  returning to_jsonb(staff_attendance_records.*) into after_data;
 elsif action='SAVE_TERMS' then
  if (p_input->>'effective_from')::date>(now() at time zone 'Asia/Dhaka')::date then raise exception 'Future compensation scheduling is not available yet.';end if;
  select to_jsonb(t) into before_data from public.staff_compensation_terms t where staff_id=sid;
  insert into public.staff_compensation_terms(staff_id,model,monthly_base,hourly_rate,pay_day,effective_from,recorded_by,reason)
  values(sid,p_input->>'model',coalesce((p_input->>'monthly_base')::numeric,0),coalesce((p_input->>'hourly_rate')::numeric,0),(p_input->>'pay_day')::integer,(p_input->>'effective_from')::date,actor,reason)
  on conflict(staff_id) do update set model=excluded.model,monthly_base=excluded.monthly_base,hourly_rate=excluded.hourly_rate,pay_day=excluded.pay_day,effective_from=excluded.effective_from,recorded_by=actor,reason=excluded.reason,updated_at=now()
  returning to_jsonb(staff_compensation_terms.*) into after_data;
 else raise exception 'Unknown workforce action.';end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,correlation_id)
 values(actor,'STAFF_WORKFORCE',sid::text,action,reason,before_data,after_data,request);
 result:=jsonb_build_object('id',sid,'ok',true);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(request,actor,p_input,result);return result;
end $$;
revoke all on function public.workforce_command(jsonb) from public,anon;
grant execute on function public.workforce_command(jsonb) to authenticated;

create function public.staff_work_workspace(p_month date default null,p_staff_id uuid default null,p_page integer default 1) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=auth.uid();manager boolean:=public.has_permission('workforce.manage');sid uuid;first_day date:=date_trunc('month',coalesce(p_month,(now() at time zone 'Asia/Dhaka')::date))::date;last_day date;rows jsonb;terms jsonb;total integer;present integer;hours numeric;effective_hours numeric;pay_date date;
begin
 if actor is null or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') or not(manager or public.has_permission('workforce.self.view')) then raise exception 'Workforce access required.';end if;
 select id into sid from public.staff where profile_id=actor and status='ACTIVE';
 if p_staff_id is not null then if not manager and p_staff_id is distinct from sid then raise exception 'Only your own workforce records are available.';end if;sid:=p_staff_id;end if;
 if p_page<1 or p_page>10000 or p_page is null then raise exception 'Invalid page.';end if;
 last_day:=(first_day+interval '1 month')::date;
 select count(*),count(*) filter(where status='PRESENT'),coalesce(sum(case when status='PRESENT' then extract(epoch from ended_at-started_at)/3600-break_minutes/60.0 else 0 end),0)
 into total,present,hours from public.staff_attendance_records where staff_id=sid and work_date>=first_day and work_date<last_day;
 select coalesce(jsonb_agg(to_jsonb(a) order by a.work_date desc),'[]'::jsonb) into rows from(select id,work_date,status,started_at,ended_at,break_minutes,reason,round(case when status='PRESENT' then extract(epoch from ended_at-started_at)/3600-break_minutes/60.0 else 0 end,2) hours from public.staff_attendance_records where staff_id=sid and work_date>=first_day and work_date<last_day order by work_date desc limit 25 offset (p_page-1)*25) a;
 select to_jsonb(t) into terms from public.staff_compensation_terms t where staff_id=sid;
 select coalesce(sum(extract(epoch from ended_at-started_at)/3600-break_minutes/60.0),0) into effective_hours from public.staff_attendance_records where staff_id=sid and status='PRESENT' and work_date>=greatest(first_day,(terms->>'effective_from')::date) and work_date<last_day;
 if terms is not null then pay_date:=date_trunc('month',now() at time zone 'Asia/Dhaka')::date+((terms->>'pay_day')::integer-1);if pay_date<(now() at time zone 'Asia/Dhaka')::date then pay_date:=(date_trunc('month',now() at time zone 'Asia/Dhaka')+interval '1 month')::date+((terms->>'pay_day')::integer-1);end if;end if;
 return jsonb_build_object('manager',manager,'staffId',sid,'name',(select full_name from public.staff where id=sid),'month',first_day,'total',total,'presentDays',present,'hours',round(hours,2),'records',rows,'terms',terms,'scheduledPayDate',pay_date,
 'previousMonthPaid',(select coalesce(sum(s.amount),0) from public.finance_payable_settlements s join public.finance_payables p on p.id=s.payable_id where (p.staff_id=sid or p.referrer_id in(select id from public.referral_people where staff_id=sid)) and (p.payable_type='TEACHER_COMPENSATION' or p.referrer_id is not null) and s.payment_account_id is not null and s.advance_id is null and s.settled_at>=((date_trunc('month',now() at time zone 'Asia/Dhaka')-interval '1 month') at time zone 'Asia/Dhaka') and s.settled_at<(date_trunc('month',now() at time zone 'Asia/Dhaka') at time zone 'Asia/Dhaka')),
 'hourlyEstimate',round(effective_hours*coalesce((terms->>'hourly_rate')::numeric,0),2),
 'people',case when manager then(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',full_name,'number',staff_no) order by full_name),'[]'::jsonb) from public.staff where status in('ACTIVE','ON_LEAVE')) else '[]'::jsonb end);
end $$;
revoke all on function public.staff_work_workspace(date,uuid,integer) from public,anon;
grant execute on function public.staff_work_workspace(date,uuid,integer) to authenticated;

-- Upstream 18_staff_tasks_and_completion_review.sql
create table public.staff_work_tasks(
 id uuid primary key default gen_random_uuid(),staff_id uuid not null references public.staff(id),title text not null check(length(btrim(title)) between 3 and 160),
 instructions text not null default '' check(length(instructions)<=4000),due_on date not null,
 status text not null default 'OPEN' check(status in('OPEN','IN_PROGRESS','SUBMITTED','COMPLETED','CANCELLED')),
 progress integer not null default 0 check(progress between 0 and 100),blocker text not null default '' check(length(blocker)<=2000),
 review_note text,created_by uuid not null references public.profiles(id),updated_by uuid not null references public.profiles(id),
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),completed_at timestamptz,
 check(status not in('SUBMITTED','COMPLETED') or progress=100),check((status='COMPLETED')=(completed_at is not null))
);
create index work_task_queue_idx on public.staff_work_tasks(staff_id,status,due_on,id);
alter table public.staff_work_tasks enable row level security;
create policy staff_work_tasks_scope on public.staff_work_tasks for select to authenticated using(public.has_permission('workforce.manage') or (public.has_permission('workforce.self.view') and staff_id in(select id from public.staff where profile_id=auth.uid() and status='ACTIVE')));
grant select on public.staff_work_tasks to authenticated;
revoke insert,update,delete on public.staff_work_tasks from anon,authenticated;
create trigger work_tasks_no_delete before delete on public.staff_work_tasks for each row execute function public.prevent_permanent_record_delete();

create function public.staff_task_command(p_input jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid();manager boolean:=public.has_permission('workforce.manage');own_staff uuid;task public.staff_work_tasks;req uuid:=(p_input->>'request_id')::uuid;old_key public.admission_command_keys;action text:=p_input->>'action';reason text:=btrim(p_input->>'reason');before_data jsonb;result jsonb;progress_value integer;
begin
 if actor is null or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') or not(manager or public.has_permission('workforce.self.view')) then raise exception 'Workforce access required.';end if;
 select id into own_staff from public.staff where profile_id=actor and status='ACTIVE';
 if req is null or coalesce(length(reason),0)<5 then raise exception 'Request ID and reason are required.';end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));select * into old_key from public.admission_command_keys where request_id=req;
 if found then if old_key.actor_id<>actor or old_key.payload<>p_input then raise exception 'Request identity conflict.';end if;return old_key.result;end if;
 if action='CREATE' then
  if not manager then raise exception 'Only an administrator assigns work.';end if;
  perform 1 from public.staff where id=(p_input->>'staff_id')::uuid and status='ACTIVE' for update;if not found then raise exception 'Choose active staff.';end if;
  insert into public.staff_work_tasks(staff_id,title,instructions,due_on,created_by,updated_by) values((p_input->>'staff_id')::uuid,btrim(p_input->>'title'),coalesce(p_input->>'instructions',''),(p_input->>'due_on')::date,actor,actor) returning * into task;
 else
  select * into task from public.staff_work_tasks where id=(p_input->>'id')::uuid for update;
  if task.id is null or (not manager and task.staff_id is distinct from own_staff) then raise exception 'Task unavailable.';end if;
  before_data:=to_jsonb(task);
  if action in('REPORT','SUBMIT') then
   if task.staff_id is distinct from own_staff then raise exception 'Only the assigned person reports their progress.';end if;
   if task.status not in('OPEN','IN_PROGRESS') then raise exception 'This task is not open for progress changes.';end if;
   progress_value:=case when action='SUBMIT' then 100 else (p_input->>'progress')::integer end;
   if progress_value is null or progress_value<0 or progress_value>100 or (action='REPORT' and progress_value=100) then raise exception 'Use Submit completion for 100%% progress.';end if;
   update public.staff_work_tasks set progress=progress_value,blocker=coalesce(p_input->>'blocker',''),status=case when action='SUBMIT' then 'SUBMITTED' else 'IN_PROGRESS' end,updated_by=actor,updated_at=now() where id=task.id returning * into task;
  elsif action in('ACCEPT','RETURN') then
   if not manager or task.status<>'SUBMITTED' then raise exception 'Administrator reviews submitted completion only.';end if;
   update public.staff_work_tasks set status=case when action='ACCEPT' then 'COMPLETED' else 'IN_PROGRESS' end,review_note=reason,completed_at=case when action='ACCEPT' then now() else null end,updated_by=actor,updated_at=now() where id=task.id returning * into task;
  elsif action='EDIT' then
   if not manager or task.status not in('OPEN','IN_PROGRESS') then raise exception 'Only open tasks can be edited by an administrator.';end if;
   perform 1 from public.staff where id=(p_input->>'staff_id')::uuid and status='ACTIVE' for update;if not found then raise exception 'Choose active staff.';end if;
   if task.staff_id is distinct from (p_input->>'staff_id')::uuid then raise exception 'Cancel and create a new assignment to change the responsible person.';end if;
   update public.staff_work_tasks set title=btrim(p_input->>'title'),instructions=coalesce(p_input->>'instructions',''),due_on=(p_input->>'due_on')::date,updated_by=actor,updated_at=now() where id=task.id returning * into task;
  elsif action='CANCEL' then
   if not manager or task.status in('COMPLETED','CANCELLED') then raise exception 'Only an open assignment can be cancelled.';end if;
   update public.staff_work_tasks set status='CANCELLED',review_note=reason,updated_by=actor,updated_at=now() where id=task.id returning * into task;
  else raise exception 'Unknown task action.';end if;
 end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,correlation_id) values(actor,'STAFF_TASK',task.id::text,action,reason,before_data,to_jsonb(task),req);
 result:=jsonb_build_object('id',task.id,'ok',true);insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);return result;
end $$;
revoke all on function public.staff_task_command(jsonb) from public,anon;
grant execute on function public.staff_task_command(jsonb) to authenticated;

create function public.staff_tasks_workspace(p_staff_id uuid default null,p_history boolean default false,p_page integer default 1) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=auth.uid();manager boolean:=public.has_permission('workforce.manage');sid uuid;rows jsonb;total integer;stats jsonb;
begin
 if actor is null or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') or not(manager or public.has_permission('workforce.self.view')) then raise exception 'Workforce access required.';end if;
 select id into sid from public.staff where profile_id=actor and status='ACTIVE';
 if p_staff_id is not null then if not manager and p_staff_id is distinct from sid then raise exception 'Only your own tasks are available.';end if;sid:=p_staff_id;end if;
 if p_page is null or p_page<1 or p_page>10000 then raise exception 'Invalid page.';end if;
 select jsonb_build_object('open',count(*) filter(where status in('OPEN','IN_PROGRESS')),'review',count(*) filter(where status='SUBMITTED'),'completed',count(*) filter(where status='COMPLETED'),'blocked',count(*) filter(where status in('OPEN','IN_PROGRESS') and length(btrim(blocker))>0),'overdue',count(*) filter(where status in('OPEN','IN_PROGRESS','SUBMITTED') and due_on<(now() at time zone 'Asia/Dhaka')::date)) into stats from public.staff_work_tasks where staff_id=sid;
 select count(*) into total from public.staff_work_tasks where staff_id=sid and (status in('COMPLETED','CANCELLED'))=coalesce(p_history,false);
 select coalesce(jsonb_agg(to_jsonb(t) order by t.due_on,t.id),'[]'::jsonb) into rows from(select * from public.staff_work_tasks where staff_id=sid and (status in('COMPLETED','CANCELLED'))=coalesce(p_history,false) order by due_on,id limit 25 offset (p_page-1)*25) t;
 return jsonb_build_object('manager',manager,'staffId',sid,'ownStaffId',(select id from public.staff where profile_id=actor and status='ACTIVE'),'total',total,'stats',stats,'tasks',rows);
end $$;
revoke all on function public.staff_tasks_workspace(uuid,boolean,integer) from public,anon;
grant execute on function public.staff_tasks_workspace(uuid,boolean,integer) to authenticated;

-- Upstream 19_monthly_staff_payroll_and_payslips.sql
insert into public.permissions(code,name,description) values('payroll.manage','Manage staff payroll','Preview, post and settle staff payroll') on conflict(code) do nothing;
insert into public.role_permissions(role_id,permission_id) select r.id,p.id from public.system_roles r cross join public.permissions p where r.code in('ADMIN','ACCOUNTANT') and p.code='payroll.manage' on conflict do nothing;
insert into public.finance_accounts(organization_id,code,name,account_type,account_subtype,is_control_account)
select id,'2140','Staff Salary Payable','LIABILITY','STAFF_SALARY_PAYABLE',true from public.organizations where is_active on conflict(organization_id,code) do nothing;
insert into public.finance_accounts(organization_id,code,name,account_type,account_subtype,is_control_account)
select id,'5300','Staff Fixed and Hourly Payroll','EXPENSE','STAFF_PAYROLL_EXPENSE',true from public.organizations where is_active on conflict(organization_id,code) do nothing;
alter table public.finance_payables drop constraint finance_payables_payable_type_check;
alter table public.finance_payables add constraint finance_payables_payable_type_check check(payable_type in('TEACHER_COMPENSATION','VENDOR','STAFF_REIMBURSEMENT','OTHER','STAFF_PAYROLL'));
create sequence public.staff_payroll_no_seq;
create table public.staff_payroll_records(
 id uuid primary key default gen_random_uuid(),payroll_no text not null unique default ('SAL-'||lpad(nextval('public.staff_payroll_no_seq')::text,6,'0')),staff_id uuid not null references public.staff(id),month date not null check(extract(day from month)=1),
 payable_id uuid not null unique references public.finance_payables(id),snapshot jsonb not null,
 gross numeric(14,2) not null check(gross>0),corrections numeric(14,2) not null check(corrections>=0),net numeric(14,2) not null check(net>0 and net=gross-corrections),
 due_on date not null,posted_by uuid not null references public.profiles(id),posted_at timestamptz not null default now(),reason text not null,unique(staff_id,month)
);
alter table public.staff_payroll_records enable row level security;
create policy payroll_read_scope on public.staff_payroll_records for select to authenticated using(public.has_permission('payroll.manage') or (public.has_permission('workforce.self.view') and staff_id in(select id from public.staff where profile_id=auth.uid())));
grant select on public.staff_payroll_records to authenticated;
revoke insert,update,delete on public.staff_payroll_records from authenticated,anon;
create trigger payroll_no_change before update or delete on public.staff_payroll_records for each row execute function public.prevent_permanent_record_delete();

create function public.staff_payroll_preview(p_input jsonb) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare sid uuid:=(p_input->>'staff_id')::uuid;month_value date:=(p_input->>'month')::date;last_day date;eligible date;terms public.staff_compensation_terms;person public.staff;hours numeric:=0;base numeric:=0;hourly numeric:=0;allowance numeric:=0;corrections numeric:=0;item jsonb;attendance jsonb;snapshot jsonb;
begin
 if auth.uid() is null or not public.has_permission('payroll.manage') or not exists(select 1 from public.profiles where id=auth.uid() and status='ACTIVE') then raise exception 'Payroll management permission required.';end if;
 if month_value is null or extract(day from month_value)<>1 or month_value>date_trunc('month',now() at time zone 'Asia/Dhaka')::date then raise exception 'Choose a current or previous payroll month.';end if;
 last_day:=(month_value+interval '1 month')::date;
 select * into person from public.staff where id=sid and status in('ACTIVE','ON_LEAVE');if person.id is null then raise exception 'Choose current staff.';end if;
 select * into terms from public.staff_compensation_terms where staff_id=sid;if terms.staff_id is null then raise exception 'Configure agreed compensation terms before payroll.';end if;
 if terms.model='REVENUE_SHARE' then raise exception 'Revenue-share-only earnings use the teaching compensation and referral workflows.';end if;
 eligible:=greatest(month_value,terms.effective_from,coalesce(person.joined_on,month_value));
 if eligible>=last_day then raise exception 'Current agreement or join date does not cover this month. Resolve historical terms before posting.';end if;
 if jsonb_typeof(coalesce(p_input->'allowances','[]'::jsonb))<>'array' or jsonb_typeof(coalesce(p_input->'corrections','[]'::jsonb))<>'array' then raise exception 'Provide itemised allowances and corrections.';end if;
 if jsonb_array_length(coalesce(p_input->'allowances','[]'::jsonb))>20 or jsonb_array_length(coalesce(p_input->'corrections','[]'::jsonb))>20 then raise exception 'Too many payroll items.';end if;
 for item in select value from jsonb_array_elements(coalesce(p_input->'allowances','[]'::jsonb)) loop
 if coalesce(length(btrim(item->>'label')),0)<3 or coalesce((item->>'amount')::numeric,0)<=0 or (item->>'amount')::numeric<>round((item->>'amount')::numeric,2) then raise exception 'Each allowance needs an explanation and positive amount.';end if;allowance:=allowance+round((item->>'amount')::numeric,2);end loop;
 for item in select value from jsonb_array_elements(coalesce(p_input->'corrections','[]'::jsonb)) loop
 if coalesce(length(btrim(item->>'label')),0)<5 or item->>'kind' not in('UNPAID_LEAVE','ABSENCE','EARNING_CORRECTION') or coalesce((item->>'amount')::numeric,0)<=0 or (item->>'amount')::numeric<>round((item->>'amount')::numeric,2) then raise exception 'Each earning correction needs a supported type, explanation and positive amount.';end if;corrections:=corrections+round((item->>'amount')::numeric,2);end loop;
 select coalesce(sum(case when status='PRESENT' then extract(epoch from ended_at-started_at)/3600-break_minutes/60.0 else 0 end),0),coalesce(jsonb_agg(to_jsonb(a) order by work_date),'[]'::jsonb) into hours,attendance from public.staff_attendance_records a where staff_id=sid and work_date>=eligible and work_date<last_day;
 base:=round(terms.monthly_base*(last_day-eligible)::numeric/(last_day-month_value),2);hourly:=round(hours*terms.hourly_rate,2);
 snapshot:=jsonb_build_object('staffId',sid,'name',person.full_name,'number',person.staff_no,'month',month_value,'eligibleFrom',eligible,'terms',to_jsonb(terms),'hours',round(hours,4),'base',base,'hourly',hourly,'allowances',coalesce(p_input->'allowances','[]'::jsonb),'correctionItems',coalesce(p_input->'corrections','[]'::jsonb),'allowanceTotal',allowance,'gross',base+hourly+allowance,'corrections',corrections,'net',base+hourly+allowance-corrections,'attendance',attendance,'dueOn',last_day+(terms.pay_day-1),'canPost',last_day<=(now() at time zone 'Asia/Dhaka')::date);
 if (snapshot->>'net')::numeric<=0 then raise exception 'Net payroll must be positive. Review the agreement, hours and earning corrections.';end if;
 return snapshot||jsonb_build_object('token',md5(snapshot::text));
end $$;
revoke all on function public.staff_payroll_preview(jsonb) from public,anon;
grant execute on function public.staff_payroll_preview(jsonb) to authenticated;

create function public.staff_payroll_command(p_input jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid();request uuid:=(p_input->>'request_id')::uuid;action text:=p_input->>'action';reason text:=btrim(p_input->>'reason');key public.admission_command_keys;preview jsonb;org uuid;expense_account uuid;salary_account uuid;advance_account uuid;record public.staff_payroll_records;payable public.finance_payables;advance public.finance_advances;cash numeric;offset_amount numeric;remaining numeric;account uuid;journal_lines jsonb;result jsonb;
begin
 if actor is null or not public.has_permission('payroll.manage') or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') then raise exception 'Payroll management permission required.';end if;
 if request is null or coalesce(length(reason),0)<5 then raise exception 'Request identity and reason are required.';end if;
 perform pg_advisory_xact_lock(hashtextextended(request::text,0));select * into key from public.admission_command_keys where request_id=request;
 if found then if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity conflict.';end if;return key.result;end if;
 select id into org from public.organizations where is_active;
 select id into salary_account from public.finance_accounts where organization_id=org and account_subtype='STAFF_SALARY_PAYABLE' and is_active;
 select id into expense_account from public.finance_accounts where organization_id=org and account_subtype='STAFF_PAYROLL_EXPENSE' and is_active;
 if action='POST' then
  perform 1 from public.staff where id=(p_input->>'staff_id')::uuid for update;
  preview:=public.staff_payroll_preview(p_input);
  if not (preview->>'canPost')::boolean then raise exception 'A current-month preview is provisional. Post after the month has ended; use advances for earlier payments.';end if;
  if preview->>'token' is distinct from p_input->>'preview_token' then raise exception 'Attendance or agreed terms changed. Review a fresh preview before posting.';end if;
  if preview->'terms'->>'model' in('FIXED','HOURLY') and exists(select 1 from public.teacher_compensation_lines l join public.teacher_compensation_runs r on r.id=l.run_id where l.teacher_id=(p_input->>'staff_id')::uuid and r.status='APPROVED' and l.line_type='TEACHING_REMUNERATION' and r.period_start<(preview->>'month')::date+interval '1 month' and r.period_end>=(preview->>'month')::date) then raise exception 'Teaching-pool remuneration was already posted for this period. Resolve the agreement; use HYBRID only when both bases were agreed.';end if;
  if exists(select 1 from public.staff_payroll_records where staff_id=(p_input->>'staff_id')::uuid and month=(p_input->>'month')::date) then raise exception 'Payroll is already posted for this staff and month.';end if;
  record.id:=gen_random_uuid();
  insert into public.finance_payables(organization_id,payable_type,staff_id,source_type,source_id,payable_account_id,original_amount,due_on,created_by)
  values(org,'STAFF_PAYROLL',(p_input->>'staff_id')::uuid,'STAFF_PAYROLL',record.id::text,salary_account,(preview->>'net')::numeric,(preview->>'dueOn')::date,actor) returning * into payable;
  insert into public.staff_payroll_records(id,staff_id,month,payable_id,snapshot,gross,corrections,net,due_on,posted_by,reason)
  values(record.id,(p_input->>'staff_id')::uuid,(p_input->>'month')::date,payable.id,preview,(preview->>'gross')::numeric,(preview->>'corrections')::numeric,(preview->>'net')::numeric,(preview->>'dueOn')::date,actor,reason) returning * into record;
  perform public.finance_post_journal(org,(now() at time zone 'Asia/Dhaka')::date,'COMPENSATION_RUN','STAFF_PAYROLL',record.id::text,'Staff payroll '||(preview->>'number')||' '||(preview->>'month'),actor,jsonb_build_array(jsonb_build_object('account_id',expense_account,'debit',record.net,'credit',0),jsonb_build_object('account_id',salary_account,'debit',0,'credit',record.net)));
 elsif action='SETTLE' then
  select * into record from public.staff_payroll_records where id=(p_input->>'id')::uuid for update;if record.id is null then raise exception 'Payroll record unavailable.';end if;
  select * into payable from public.finance_payables where id=record.payable_id for update;
  remaining:=payable.original_amount-coalesce((select sum(amount) from public.finance_payable_settlements where payable_id=payable.id),0);
  cash:=coalesce((p_input->>'cash')::numeric,0);offset_amount:=coalesce((p_input->>'advance_offset')::numeric,0);
  if cash<>round(cash,2) or offset_amount<>round(offset_amount,2) or cash<0 or offset_amount<0 or cash+offset_amount<=0 or cash+offset_amount>remaining then raise exception 'Cash plus advance offset must fit the remaining payable.';end if;
  journal_lines:=jsonb_build_array(jsonb_build_object('account_id',payable.payable_account_id,'debit',cash+offset_amount,'credit',0));
  if cash>0 then
   select id into account from public.finance_accounts where id=(p_input->>'account_id')::uuid and organization_id=org and is_active and account_subtype in('CASH','BANK','MOBILE_BANK');
   if account is null or coalesce(length(btrim(p_input->>'reference')),0)<3 then raise exception 'Choose the actual payment account and payment reference.';end if;
   insert into public.finance_payable_settlements(payable_id,amount,payment_account_id,external_reference,settled_by,reason) values(payable.id,cash,account,p_input->>'reference',actor,reason);
   journal_lines:=journal_lines||jsonb_build_array(jsonb_build_object('account_id',account,'debit',0,'credit',cash));
  end if;
  if offset_amount>0 then
   select * into advance from public.finance_advances where id=(p_input->>'advance_id')::uuid for update;
   if advance.id is null or advance.staff_id is distinct from record.staff_id or advance.beneficiary_type<>'STAFF' or advance.status not in('PAID','PARTIALLY_SETTLED') or public.advance_balance(advance.id)<offset_amount then raise exception 'Choose a paid advance belonging to this staff member with enough balance.';end if;
   select id into advance_account from public.finance_accounts where organization_id=org and account_subtype='STAFF_ADVANCE' and is_active;
   insert into public.finance_payable_settlements(payable_id,amount,advance_id,settled_by,reason) values(payable.id,offset_amount,advance.id,actor,reason);
   insert into public.finance_advance_movements(advance_id,movement_type,amount,source_type,source_id,created_by,reason) values(advance.id,'SETTLEMENT',offset_amount,'STAFF_PAYROLL',request::text,actor,reason);
   update public.finance_advances set status=case when public.advance_balance(id)=0 then 'SETTLED' else 'PARTIALLY_SETTLED' end where id=advance.id;
   journal_lines:=journal_lines||jsonb_build_array(jsonb_build_object('account_id',advance_account,'debit',0,'credit',offset_amount));
  end if;
  perform public.finance_post_journal(org,(now() at time zone 'Asia/Dhaka')::date,'COMPENSATION_SETTLEMENT','STAFF_PAYROLL_SETTLEMENT',request::text,'Payroll settlement '||record.id::text,actor,journal_lines);
  update public.finance_payables set status=case when cash+offset_amount=remaining then 'SETTLED' else 'PARTIALLY_SETTLED' end where id=payable.id;
 else raise exception 'Unknown payroll action.';end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,after_data,correlation_id) values(actor,'STAFF_PAYROLL',record.id::text,action,reason,jsonb_build_object('net',record.net,'cash',cash,'advanceOffset',offset_amount),request);
 result:=jsonb_build_object('id',record.id,'ok',true);insert into public.admission_command_keys(request_id,actor_id,payload,result) values(request,actor,p_input,result);return result;
end $$;
revoke all on function public.staff_payroll_command(jsonb) from public,anon;
grant execute on function public.staff_payroll_command(jsonb) to authenticated;

create function public.staff_payroll_workspace(p_id uuid default null,p_page integer default 1) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare manager boolean:=public.has_permission('payroll.manage');sid uuid;rows jsonb;total integer;
begin
 if auth.uid() is null or not exists(select 1 from public.profiles where id=auth.uid() and status='ACTIVE') or not(manager or public.has_permission('workforce.self.view')) then raise exception 'Payroll access required.';end if;
 select id into sid from public.staff where profile_id=auth.uid();
 if p_page is null or p_page<1 or p_page>10000 then raise exception 'Invalid page.';end if;
 if p_id is not null and not exists(select 1 from public.staff_payroll_records where id=p_id and (manager or staff_id=sid)) then raise exception 'Payslip unavailable.';end if;
 select count(*) into total from public.staff_payroll_records where (manager or staff_id=sid) and (p_id is null or id=p_id);
 select coalesce(jsonb_agg(to_jsonb(r) order by r.month desc,r.id),'[]'::jsonb) into rows from(select r.*,p.status,coalesce((select sum(amount) from public.finance_payable_settlements where payable_id=r.payable_id),0) settled,
 (select coalesce(jsonb_agg(jsonb_build_object('date',s.settled_at,'amount',s.amount,'offset',s.advance_id is not null,'reference',s.external_reference) order by s.settled_at),'[]'::jsonb) from public.finance_payable_settlements s where s.payable_id=r.payable_id) payments
 from public.staff_payroll_records r join public.finance_payables p on p.id=r.payable_id where (manager or r.staff_id=sid) and (p_id is null or r.id=p_id) order by r.month desc,r.id limit 25 offset (p_page-1)*25) r;
 return jsonb_build_object('manager',manager,'total',total,'records',rows,
 'people',case when manager then(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',full_name||' · '||staff_no) order by full_name),'[]'::jsonb) from public.staff where status in('ACTIVE','ON_LEAVE')) else '[]'::jsonb end,
 'accounts',case when manager then(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name) order by code),'[]'::jsonb) from public.finance_accounts where is_active and account_subtype in('CASH','BANK','MOBILE_BANK')) else '[]'::jsonb end,
 'advances',case when manager then(select coalesce(jsonb_agg(jsonb_build_object('id',id,'staffId',staff_id,'name',advance_no,'balance',public.advance_balance(id))),'[]'::jsonb) from public.finance_advances where beneficiary_type='STAFF' and public.advance_balance(id)>0) else '[]'::jsonb end);
end $$;
revoke all on function public.staff_payroll_workspace(uuid,integer) from public,anon;
grant execute on function public.staff_payroll_workspace(uuid,integer) to authenticated;

-- Fixed/hourly contracts do not accrue a second teaching-pool salary. Retention and acquisition remain independent.
CREATE OR REPLACE FUNCTION public.teacher_compensation_preview(p_from date, p_to date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid:=auth.uid();
  policy public.business_rule_versions;
  rows jsonb:='[]'::jsonb;
  teacher_row record;
  batch_row record;
  event_amount numeric;
  pool_percent numeric;
  acquisition_percent numeric;
  retention3_percent numeric;
  retention6_percent numeric;
  first_period date;
  first_collected numeric;
  month3 date;
  month6 date;
  month_paid boolean;
  continuous3 boolean;
  continuous6 boolean;
begin
  if actor is null or not public.has_permission('staff.compensation.view') then
    raise exception 'Compensation access denied.';
  end if;
  if p_from is null or p_to is null or p_to<p_from then
    raise exception 'Choose a valid compensation period.';
  end if;

  select * into policy
  from public.business_rule_versions
  where domain='teacher_compensation'
    and rule_key='default_policy'
    and status='ACTIVE'
  order by version desc
  limit 1;

  if policy.id is null
     or not public.validate_business_rule_payload('teacher_compensation','default_policy',policy.payload) then
    raise exception 'A valid teacher compensation policy is required.';
  end if;

  pool_percent:=(policy.payload->>'teaching_pool_percent')::numeric;
  acquisition_percent:=(policy.payload->>'acquisition_bonus_percent')::numeric;
  retention3_percent:=(policy.payload->>'retention_3_month_percent')::numeric;
  retention6_percent:=(policy.payload->>'retention_6_month_percent')::numeric;

  -- Teaching pool is calculated per batch from Net Collected Tuition and
  -- allocated by approved attendance/session workload within that batch.
  for batch_row in
    with batch_revenue as (
      select batch_id,sum(tuition_collected) net_collected
      from public.finance_net_collected_tuition(p_from,p_to)
      group by batch_id
    ),
    session_weights as (
      select
        cs.batch_id,
        cs.teacher_id,
        count(*) filter(
          where exists(
            select 1 from public.attendance_submissions aa
            where aa.id=(
              select z.id from public.attendance_submissions z
              where z.session_id=cs.id
              order by z.revision desc limit 1
            )
            and aa.status='APPROVED'
          )
        )::numeric as session_count
      from public.class_sessions cs
      where cs.session_date between p_from and p_to
        and cs.status='SCHEDULED'
      group by cs.batch_id,cs.teacher_id
    )
    select
      r.batch_id,
      r.net_collected,
      r.net_collected*pool_percent/100 as pool_amount,
      w.teacher_id,
      w.session_count,
      sum(w.session_count) over(partition by w.batch_id) total_sessions
    from batch_revenue r
    join session_weights w on w.batch_id=r.batch_id
    where r.net_collected>0 and w.session_count>0
  loop
    event_amount:=round(batch_row.pool_amount*batch_row.session_count/nullif(batch_row.total_sessions,0),2);
    if event_amount>0 and not exists(select 1 from public.staff_compensation_terms t where t.staff_id=batch_row.teacher_id and t.model in('FIXED','HOURLY') and t.effective_from<=p_to) and not exists(select 1 from public.staff_payroll_records r where r.staff_id=batch_row.teacher_id and r.month between date_trunc('month',p_from)::date and p_to and r.snapshot->'terms'->>'model' in('FIXED','HOURLY')) and not exists (select 1 from public.teacher_compensation_claims c
      where c.teacher_id=batch_row.teacher_id and c.source_type='BATCH_PERIOD'
        and c.source_id=batch_row.batch_id::text||':'||p_from::text||':'||p_to::text) then
    rows:=rows||jsonb_build_array(
      jsonb_build_object(
        'teacherId',batch_row.teacher_id,
        'lineType','TEACHING_REMUNERATION',
        'amount',event_amount,
        'sourceType','BATCH_PERIOD',
        'sourceId',batch_row.batch_id::text||':'||p_from::text||':'||p_to::text,
        'calculation',jsonb_build_object(
          'batchId',batch_row.batch_id,
          'netCollectedTuition',batch_row.net_collected,
          'poolPercent',pool_percent,
          'poolAmount',batch_row.pool_amount,
          'approvedSessions',batch_row.session_count,
          'batchApprovedSessions',batch_row.total_sessions
        )
      )
    );
    end if;
  end loop;

  -- Acquisition/retention bonuses require a structured teacher referral.
  for teacher_row in
    select
      tr.teacher_id,
      tr.admission_id,
      min(n.billing_period) first_billing_period
    from public.teacher_referrals tr
    join public.admission_cases a on a.id=tr.admission_id and a.status='ACTIVE_ENROLLMENT'
    join public.finance_net_collected_tuition(date '2000-01-01',p_to) n
      on n.admission_id=tr.admission_id and n.tuition_collected>0
    group by tr.teacher_id,tr.admission_id
  loop
    first_period:=teacher_row.first_billing_period;

    select coalesce(sum(n.tuition_collected),0)
    into first_collected
    from public.finance_net_collected_tuition(first_period,(first_period+interval '1 month - 1 day')::date) n
    where n.admission_id=teacher_row.admission_id;

    -- Acquisition is accrued by the unified referrer collection workflow.
    month3:=(first_period+interval '2 months')::date;
    month6:=(first_period+interval '5 months')::date;

    select bool_and(tuition_collected>0)
    into continuous3
    from (
      select
        m.month_start,
        coalesce((
          select sum(n.tuition_collected)
          from public.finance_net_collected_tuition(m.month_start,(m.month_start+interval '1 month - 1 day')::date) n
          where n.admission_id=teacher_row.admission_id
        ),0) tuition_collected
      from generate_series(first_period,month3,interval '1 month') g
      cross join lateral(select g::date month_start) m
    ) x;

    if month3 between p_from and p_to and continuous3 is true
      and not exists(select 1 from public.teacher_compensation_claims c
        where c.teacher_id=teacher_row.teacher_id and c.source_type='RETENTION_3'
          and c.source_id=teacher_row.admission_id::text) then
      select coalesce(sum(n.tuition_collected),0)
      into event_amount
      from public.finance_net_collected_tuition(month3,(month3+interval '1 month - 1 day')::date) n
      where n.admission_id=teacher_row.admission_id;

      if event_amount>0 then
        rows:=rows||jsonb_build_array(
          jsonb_build_object(
            'teacherId',teacher_row.teacher_id,
            'admissionId',teacher_row.admission_id,
            'lineType','RETENTION_3_MONTH',
            'amount',round(event_amount*retention3_percent/100,2),
            'sourceType','RETENTION_3',
            'sourceId',teacher_row.admission_id::text,
            'calculation',jsonb_build_object(
              'milestoneMonth',month3,
              'monthNetCollectedTuition',event_amount,
              'bonusPercent',retention3_percent
            )
          )
        );
      end if;
    end if;

    select bool_and(tuition_collected>0)
    into continuous6
    from (
      select
        m.month_start,
        coalesce((
          select sum(n.tuition_collected)
          from public.finance_net_collected_tuition(m.month_start,(m.month_start+interval '1 month - 1 day')::date) n
          where n.admission_id=teacher_row.admission_id
        ),0) tuition_collected
      from generate_series(first_period,month6,interval '1 month') g
      cross join lateral(select g::date month_start) m
    ) x;

    if month6 between p_from and p_to and continuous6 is true
      and not exists(select 1 from public.teacher_compensation_claims c
        where c.teacher_id=teacher_row.teacher_id and c.source_type='RETENTION_6'
          and c.source_id=teacher_row.admission_id::text) then
      select coalesce(sum(n.tuition_collected),0)
      into event_amount
      from public.finance_net_collected_tuition(month6,(month6+interval '1 month - 1 day')::date) n
      where n.admission_id=teacher_row.admission_id;

      if event_amount>0 then
        rows:=rows||jsonb_build_array(
          jsonb_build_object(
            'teacherId',teacher_row.teacher_id,
            'admissionId',teacher_row.admission_id,
            'lineType','RETENTION_6_MONTH',
            'amount',round(event_amount*retention6_percent/100,2),
            'sourceType','RETENTION_6',
            'sourceId',teacher_row.admission_id::text,
            'calculation',jsonb_build_object(
              'milestoneMonth',month6,
              'monthNetCollectedTuition',event_amount,
              'bonusPercent',retention6_percent
            )
          )
        );
      end if;
    end if;
  end loop;

  for teacher_row in
    select teacher_id,adjustment_type,id,amount
    from public.teacher_compensation_adjustments
    where status='APPROVED'
      and effective_period between p_from and p_to
      and not exists(select 1 from public.teacher_compensation_claims c
        where c.teacher_id=teacher_compensation_adjustments.teacher_id
          and c.source_type='ADJUSTMENT' and c.source_id=teacher_compensation_adjustments.id::text)
  loop
    rows:=rows||jsonb_build_array(
      jsonb_build_object(
        'teacherId',teacher_row.teacher_id,
        'lineType',case when teacher_row.adjustment_type='GROWTH_BONUS'
          then 'GROWTH_BONUS' else 'ADJUSTMENT' end,
        'amount',teacher_row.amount,
        'sourceType','ADJUSTMENT',
        'sourceId',teacher_row.id::text,
        'calculation',jsonb_build_object(
          'adjustmentType',teacher_row.adjustment_type
        )
      )
    );
  end loop;

  return jsonb_build_object(
    'periodStart',p_from,
    'periodEnd',p_to,
    'policyVersion',policy.version,
    'rows',rows,
    'total',coalesce((select sum((x->>'amount')::numeric) from jsonb_array_elements(rows) x),0)
  );
end;
$function$;

-- Staff identities are scoped by campus; the clean staff table has no organization_id column.
CREATE OR REPLACE FUNCTION public.post_accounting_operation(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid:=auth.uid();
  action text:=p_input->>'action';
  req uuid:=nullif(p_input->>'request_id','')::uuid;
  reason text:=btrim(coalesce(p_input->>'reason',''));
  key public.admission_command_keys;
  org uuid;
  result jsonb;
  amount numeric;
  payment_account uuid;
  advance public.finance_advances;
  expense public.finance_expenses;
  category public.finance_expense_categories;
  payable public.finance_payables;
  compensation public.teacher_compensation_runs;
  policy public.business_rule_versions;
  preview jsonb;
  line jsonb;
  v_teacher_id uuid;
  teacher_total numeric;
  decision text;
  adjustment_id uuid;
begin
  if actor is null then
    raise exception 'Sign in to continue.';
  end if;

  if req is null or length(reason)<5 then
    raise exception 'A request identity and reason of at least five characters are required.';
  end if;

  if action not in (
    'CREATE_ADVANCE',
    'CREATE_EXPENSE_DIRECT',
    'RUN_COMPENSATION',
    'APPLY_COMP_ADJUSTMENT'
  ) then
    raise exception 'Unsupported V3 accounting action.';
  end if;

  if action='CREATE_ADVANCE'
    and not public.has_permission('finance.advances.manage') then
    raise exception 'Advance management permission required.';
  end if;

  if action='CREATE_EXPENSE_DIRECT'
    and not public.has_permission('accounting.expense.manage') then
    raise exception 'Expense management permission required.';
  end if;

  if action in ('RUN_COMPENSATION','APPLY_COMP_ADJUSTMENT')
    and not public.has_permission('staff.compensation.manage') then
    raise exception 'Teacher compensation management permission required.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(req::text,9));

  select * into key
  from public.admission_command_keys
  where request_id=req;

  if found then
    if key.actor_id<>actor or key.payload<>p_input then
      raise exception 'Request identity already used for different input.';
    end if;
    return key.result;
  end if;

  select id into org
  from public.organizations
  where is_active
  limit 1;

  if action='CREATE_ADVANCE' then
    if p_input->>'beneficiary_type' not in ('STAFF','VENDOR','PROJECT') then
      raise exception 'Choose staff, vendor or project as the advance beneficiary.';
    end if;

    amount:=(p_input->>'requested_amount')::numeric;

    if amount is null or amount<=0 or amount<>round(amount,2) then
      raise exception 'Advance amount must be a positive two-decimal amount.';
    end if;

    if p_input->>'beneficiary_type'='STAFF' and not exists(
      select 1 from public.staff
      where id=nullif(p_input->>'staff_id','')::uuid
        and coalesce((select b.organization_id from public.branches b where b.id=staff.branch_id),org)=org
        and status='ACTIVE'
    ) then
      raise exception 'Choose an active staff member.';
    end if;

    if p_input->>'beneficiary_type'='VENDOR' and not exists(
      select 1 from public.vendors
      where id=nullif(p_input->>'vendor_id','')::uuid
        and organization_id=org
        and is_active
    ) then
      raise exception 'Choose an active vendor.';
    end if;

    if p_input->>'beneficiary_type'='PROJECT'
      and nullif(btrim(p_input->>'project_reference'),'') is null then
      raise exception 'Project reference is required for a project advance.';
    end if;

    if length(btrim(coalesce(p_input->>'purpose','')))<5 then
      raise exception 'Advance purpose must be at least five characters.';
    end if;

    insert into public.finance_advances(
      organization_id,
      beneficiary_type,
      staff_id,
      vendor_id,
      project_reference,
      purpose,
      requested_amount,
      approved_amount,
      expected_settlement_date,
      requested_by,
      authorized_by,
      authorization_reason,
      status
    )
    values(
      org,
      p_input->>'beneficiary_type',
      nullif(p_input->>'staff_id','')::uuid,
      nullif(p_input->>'vendor_id','')::uuid,
      nullif(btrim(p_input->>'project_reference'),''),
      btrim(p_input->>'purpose'),
      amount,
      amount,
      nullif(p_input->>'expected_settlement_date','')::date,
      actor,
      actor,
      reason,
      'APPROVED'
    )
    returning * into advance;

    result:=jsonb_build_object(
      'id',advance.id,
      'advanceNo',advance.advance_no,
      'message','Advance authorized and recorded.'
    );

    insert into public.audit_events(
      correlation_id,
      actor_profile_id,
      actor_staff_id,
      entity_type,
      entity_id,
      action,
      reason,
      after_data,
      metadata
    )
    values(
      req,
      actor,
      (select id from public.staff where profile_id=actor limit 1),
      'FINANCE_ADVANCE',
      advance.id::text,
      'CREATE_ADVANCE',
      reason,
      jsonb_build_object(
        'advance_no',advance.advance_no,
        'beneficiary_type',advance.beneficiary_type,
        'requested_amount',advance.requested_amount,
        'approved_amount',advance.approved_amount,
        'status',advance.status
      ),
      jsonb_build_object('finance_flow','V3_DIRECT_ADMIN')
    );

  elsif action='CREATE_EXPENSE_DIRECT' then
    amount:=(p_input->>'amount')::numeric;

    if amount is null or amount<=0 or amount<>round(amount,2) then
      raise exception 'Expense amount must be a positive two-decimal amount.';
    end if;

    select * into category
    from public.finance_expense_categories
    where id=nullif(p_input->>'category_id','')::uuid
      and organization_id=org
      and is_active;

    if category.id is null then
      raise exception 'Choose an active expense category.';
    end if;

    if p_input->>'payment_mode' not in ('PAID_NOW','ON_ACCOUNT') then
      raise exception 'Choose whether the expense is paid now or payable later.';
    end if;

    if length(btrim(coalesce(p_input->>'description','')))<3 then
      raise exception 'Expense description is required.';
    end if;

    if p_input->>'payment_mode'='PAID_NOW' then
      select id into payment_account
      from public.finance_accounts
      where id=nullif(p_input->>'payment_account_id','')::uuid
        and organization_id=org
        and account_subtype in ('CASH','BANK','MOBILE_BANK')
        and is_active;

      if payment_account is null then
        raise exception 'Choose an active cash or bank account for a paid expense.';
      end if;
    else
      payment_account:=null;
    end if;

    insert into public.finance_expenses(organization_id, expense_date, category_id, expense_account_id, payment_mode, payment_account_id, vendor_id, staff_id, amount, description, receipt_reference, status, authorized_by, authorization_reason, submitted_by, posted_by, posted_at)
    values(org, coalesce(nullif(p_input->>'expense_date','')::date,current_date), category.id, category.expense_account_id, p_input->>'payment_mode', payment_account, nullif(p_input->>'vendor_id','')::uuid, nullif(p_input->>'staff_id','')::uuid, amount, btrim(p_input->>'description'), nullif(btrim(p_input->>'receipt_reference'),''), 'POSTED', actor, reason, actor, actor, now())
    returning * into expense;

    if expense.payment_mode='PAID_NOW' then
      perform public.finance_post_journal(
        org,
        expense.expense_date,
        'EXPENSE',
        'EXPENSE',
        expense.id::text,
        'Expense '||expense.expense_no,
        actor,
        jsonb_build_array(
          jsonb_build_object(
            'account_id',expense.expense_account_id,
            'debit',expense.amount,
            'credit',0,
            'memo',expense.description
          ),
          jsonb_build_object(
            'account_id',payment_account,
            'debit',0,
            'credit',expense.amount,
            'memo',coalesce(expense.receipt_reference,'Paid expense')
          )
        )
      );
    else
      insert into public.finance_payables(
        organization_id,
        payable_type,
        staff_id,
        vendor_id,
        source_type,
        source_id,
        payable_account_id,
        original_amount,
        due_on,
        created_by
      )
      values(
        org,
        case
          when expense.vendor_id is not null then 'VENDOR'
          when expense.staff_id is not null then 'STAFF_REIMBURSEMENT'
          else 'OTHER'
        end,
        expense.staff_id,
        expense.vendor_id,
        'EXPENSE',
        expense.id::text,
        case
          when expense.vendor_id is not null then
            (select id from public.finance_accounts where organization_id=org and account_subtype='VENDOR_PAYABLE' limit 1)
          else
            (select id from public.finance_accounts where organization_id=org and account_subtype='STAFF_PAYABLE' limit 1)
        end,
        expense.amount,
        expense.expense_date+30,
        actor
      )
      returning * into payable;

      update public.finance_expenses
      set payable_id=payable.id
      where id=expense.id;

      perform public.finance_post_journal(
        org,
        expense.expense_date,
        'EXPENSE',
        'EXPENSE',
        expense.id::text,
        'Expense payable '||expense.expense_no,
        actor,
        jsonb_build_array(
          jsonb_build_object(
            'account_id',expense.expense_account_id,
            'debit',expense.amount,
            'credit',0,
            'memo',expense.description
          ),
          jsonb_build_object(
            'account_id',payable.payable_account_id,
            'debit',0,
            'credit',expense.amount,
            'memo','Payable for expense '||expense.expense_no
          )
        )
      );
    end if;

    result:=jsonb_build_object(
      'id',expense.id,
      'expenseNo',expense.expense_no,
      'message','Expense posted to the ledger.'
    );

    insert into public.audit_events(
      correlation_id,
      actor_profile_id,
      actor_staff_id,
      entity_type,
      entity_id,
      action,
      reason,
      after_data,
      metadata
    )
    values(
      req,
      actor,
      (select id from public.staff where profile_id=actor limit 1),
      'FINANCE_EXPENSE',
      expense.id::text,
      'CREATE_EXPENSE_DIRECT',
      reason,
      jsonb_build_object(
        'expense_no',expense.expense_no,
        'amount',expense.amount,
        'payment_mode',expense.payment_mode,
        'status',expense.status
      ),
      jsonb_build_object('finance_flow','V3_DIRECT_ADMIN')
    );

  elsif action='RUN_COMPENSATION' then
    preview:=public.teacher_compensation_preview(
      (p_input->>'period_start')::date,
      (p_input->>'period_end')::date
    );

    if jsonb_array_length(preview->'rows')=0 then
      raise exception 'No eligible compensation lines for this period.';
    end if;

    select * into policy
    from public.business_rule_versions
    where domain='teacher_compensation'
      and rule_key='default_policy'
      and status='ACTIVE'
    order by version desc
    limit 1;

    if policy.id is null then
      raise exception 'No active teacher compensation policy is configured.';
    end if;

    insert into public.teacher_compensation_runs(
      organization_id,
      period_start,
      period_end,
      policy_version_id,
      status,
      total_amount,
      submitted_by,
      approved_by,
      approved_at,
      authorized_by,
      authorization_reason
    )
    values(
      org,
      (p_input->>'period_start')::date,
      (p_input->>'period_end')::date,
      policy.id,
      'APPROVED',
      (preview->>'total')::numeric,
      actor,
      actor,
      now(),
      actor,
      reason
    )
    returning * into compensation;

    for line in
      select value
      from jsonb_array_elements(preview->'rows')
    loop
      insert into public.teacher_compensation_lines(
        run_id,
        teacher_id,
        admission_id,
        line_type,
        source_type,
        source_id,
        amount,
        calculation
      )
      values(
        compensation.id,
        (line->>'teacherId')::uuid,
        nullif(line->>'admissionId','')::uuid,
        line->>'lineType',
        line->>'sourceType',
        line->>'sourceId',
        (line->>'amount')::numeric,
        coalesce(line->'calculation','{}'::jsonb)
      )
      on conflict(run_id,source_type,source_id) do nothing;
    end loop;

    for v_teacher_id in
      select distinct l.teacher_id
      from public.teacher_compensation_lines l
      where l.run_id=compensation.id
    loop
      select coalesce(sum(l.amount),0)
      into teacher_total
      from public.teacher_compensation_lines l
      where l.run_id=compensation.id
        and l.teacher_id=v_teacher_id;

      if teacher_total>0 then
        insert into public.finance_payables(
          organization_id,
          payable_type,
          staff_id,
          source_type,
          source_id,
          payable_account_id,
          original_amount,
          due_on,
          created_by
        )
        values(
          org,
          'TEACHER_COMPENSATION',
          v_teacher_id,
          'COMPENSATION_RUN',
          compensation.id::text||':'||v_teacher_id::text,
          (
            select id
            from public.finance_accounts
            where organization_id=org
              and account_subtype='TEACHER_PAYABLE'
            limit 1
          ),
          teacher_total,
          compensation.period_end,
          actor
        )
        on conflict(source_type,source_id) do nothing;
      end if;
    end loop;

    perform public.finance_post_journal(
      org,
      compensation.period_end,
      'COMPENSATION_RUN',
      'COMPENSATION_RUN',
      compensation.id::text,
      'Teacher compensation run '||compensation.run_no,
      actor,
      (
        select jsonb_build_array(
          jsonb_build_object(
            'account_id',(
              select id
              from public.finance_accounts
              where organization_id=org
                and account_subtype='TEACHING_COMPENSATION'
              limit 1
            ),
            'debit',compensation.total_amount,
            'credit',0,
            'memo','Teaching compensation expense'
          )
        ) ||
        coalesce((
          select jsonb_agg(
            jsonb_build_object(
              'account_id',(
                select id
                from public.finance_accounts
                where organization_id=org
                  and account_subtype='TEACHER_PAYABLE'
                limit 1
              ),
              'debit',0,
              'credit',sum(l.amount),
              'memo','Payable for teacher '||l.teacher_id::text
            )
          )
          from public.teacher_compensation_lines l
          where l.run_id=compensation.id
          group by l.teacher_id
        ),'[]'::jsonb)
      )
    );

    result:=jsonb_build_object(
      'id',compensation.id,
      'runNo',compensation.run_no,
      'message','Teacher compensation run approved and posted.',
      'total',compensation.total_amount
    );

    insert into public.audit_events(
      correlation_id,
      actor_profile_id,
      actor_staff_id,
      entity_type,
      entity_id,
      action,
      reason,
      after_data,
      metadata
    )
    values(
      req,
      actor,
      (select id from public.staff where profile_id=actor limit 1),
      'TEACHER_COMPENSATION_RUN',
      compensation.id::text,
      'RUN_COMPENSATION',
      reason,
      jsonb_build_object(
        'run_no',compensation.run_no,
        'status',compensation.status,
        'total_amount',compensation.total_amount
      ),
      jsonb_build_object('finance_flow','V3_DIRECT_ADMIN')
    );

  else
    if not exists(
      select 1
      from public.staff
      where id=nullif(p_input->>'teacher_id','')::uuid
        and status='ACTIVE'
    ) then
      raise exception 'Choose an active teacher.';
    end if;

    amount:=(p_input->>'amount')::numeric;

    if amount is null or amount<=0 or amount<>round(amount,2) then
      raise exception 'Adjustment amount must be a positive two-decimal amount.';
    end if;

    if (p_input->>'effective_period')::date is null then
      raise exception 'Choose an effective period.';
    end if;

    insert into public.teacher_compensation_adjustments(teacher_id, amount, adjustment_type, effective_period, reason, authorized_by, authorization_reason, status, requested_by, approved_by, approved_at)
    values((p_input->>'teacher_id')::uuid, amount, coalesce(p_input->>'adjustment_type','ADJUSTMENT'), (p_input->>'effective_period')::date, reason, actor, reason, 'APPROVED', actor, actor, now())
    returning id into adjustment_id;

    result:=jsonb_build_object(
      'id',adjustment_id,
      'message','Teacher compensation adjustment authorized and recorded.'
    );

    insert into public.audit_events(
      correlation_id,
      actor_profile_id,
      actor_staff_id,
      entity_type,
      entity_id,
      action,
      reason,
      after_data,
      metadata
    )
    values(
      req,
      actor,
      (select id from public.staff where profile_id=actor limit 1),
      'TEACHER_COMPENSATION_ADJUSTMENT',
      adjustment_id::text,
      'APPLY_COMP_ADJUSTMENT',
      reason,
      jsonb_build_object(
        'teacher_id',(p_input->>'teacher_id')::uuid,
        'amount',amount,
        'effective_period',(p_input->>'effective_period')::date,
        'status','APPROVED'
      ),
      jsonb_build_object('finance_flow','V3_DIRECT_ADMIN')
    );
  end if;

  insert into public.admission_command_keys(
    request_id,actor_id,payload,result
  )
  values(req,actor,p_input,result);

  return result;
end;
$function$;

-- Include salary settlements in the actual prior-month pay card; leave does not revoke own attendance reads.
create or replace function public.staff_work_workspace(p_month date default null,p_staff_id uuid default null,p_page integer default 1) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=auth.uid();manager boolean:=public.has_permission('workforce.manage');sid uuid;first_day date:=date_trunc('month',coalesce(p_month,(now() at time zone 'Asia/Dhaka')::date))::date;last_day date;rows jsonb;terms jsonb;total integer;present integer;hours numeric;effective_hours numeric;pay_date date;
begin
 if actor is null or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') or not(manager or public.has_permission('workforce.self.view')) then raise exception 'Workforce access required.';end if;
 select id into sid from public.staff where profile_id=actor and status in('ACTIVE','ON_LEAVE');
 if p_staff_id is not null then if not manager and p_staff_id is distinct from sid then raise exception 'Only your own workforce records are available.';end if;sid:=p_staff_id;end if;
 if p_page<1 or p_page>10000 or p_page is null then raise exception 'Invalid page.';end if;
 last_day:=(first_day+interval '1 month')::date;
 select count(*),count(*) filter(where status='PRESENT'),coalesce(sum(case when status='PRESENT' then extract(epoch from ended_at-started_at)/3600-break_minutes/60.0 else 0 end),0)
 into total,present,hours from public.staff_attendance_records where staff_id=sid and work_date>=first_day and work_date<last_day;
 select coalesce(jsonb_agg(to_jsonb(a) order by a.work_date desc),'[]'::jsonb) into rows from(select id,work_date,status,started_at,ended_at,break_minutes,reason,round(case when status='PRESENT' then extract(epoch from ended_at-started_at)/3600-break_minutes/60.0 else 0 end,2) hours from public.staff_attendance_records where staff_id=sid and work_date>=first_day and work_date<last_day order by work_date desc limit 25 offset (p_page-1)*25) a;
 select to_jsonb(t) into terms from public.staff_compensation_terms t where staff_id=sid;
 select coalesce(sum(extract(epoch from ended_at-started_at)/3600-break_minutes/60.0),0) into effective_hours from public.staff_attendance_records where staff_id=sid and status='PRESENT' and work_date>=greatest(first_day,(terms->>'effective_from')::date) and work_date<last_day;
 if terms is not null then pay_date:=date_trunc('month',now() at time zone 'Asia/Dhaka')::date+((terms->>'pay_day')::integer-1);if pay_date<(now() at time zone 'Asia/Dhaka')::date then pay_date:=(date_trunc('month',now() at time zone 'Asia/Dhaka')+interval '1 month')::date+((terms->>'pay_day')::integer-1);end if;end if;
 return jsonb_build_object('manager',manager,'staffId',sid,'name',(select full_name from public.staff where id=sid),'month',first_day,'total',total,'presentDays',present,'hours',round(hours,2),'records',rows,'terms',terms,'scheduledPayDate',pay_date,
 'previousMonthPaid',(select coalesce(sum(s.amount),0) from public.finance_payable_settlements s join public.finance_payables p on p.id=s.payable_id where (p.staff_id=sid or p.referrer_id in(select id from public.referral_people where staff_id=sid)) and (p.payable_type in('TEACHER_COMPENSATION','STAFF_PAYROLL') or p.referrer_id is not null) and s.payment_account_id is not null and s.advance_id is null and s.settled_at>=((date_trunc('month',now() at time zone 'Asia/Dhaka')-interval '1 month') at time zone 'Asia/Dhaka') and s.settled_at<(date_trunc('month',now() at time zone 'Asia/Dhaka') at time zone 'Asia/Dhaka')),
 'hourlyEstimate',round(effective_hours*coalesce((terms->>'hourly_rate')::numeric,0),2),
 'people',case when manager then(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',full_name,'number',staff_no) order by full_name),'[]'::jsonb) from public.staff where status in('ACTIVE','ON_LEAVE')) else '[]'::jsonb end);
end $$;
revoke all on function public.staff_work_workspace(date,uuid,integer) from public,anon;
grant execute on function public.staff_work_workspace(date,uuid,integer) to authenticated;

create function public.my_salary_summary() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare sid uuid;last_record public.staff_payroll_records;
begin
 if auth.uid() is null or not public.has_permission('workforce.self.view') or not exists(select 1 from public.profiles where id=auth.uid() and status='ACTIVE') then raise exception 'Own workforce access required.';end if;
 select id into sid from public.staff where profile_id=auth.uid();
 select * into last_record from public.staff_payroll_records where staff_id=sid order by month desc limit 1;
 return jsonb_build_object('latestMonth',last_record.month,'latestNet',last_record.net,
 'outstanding',(select coalesce(sum(r.net-coalesce((select sum(amount) from public.finance_payable_settlements where payable_id=r.payable_id),0)),0) from public.staff_payroll_records r where r.staff_id=sid),
 'nextDue',(select min(r.due_on) from public.staff_payroll_records r where r.staff_id=sid and r.net>coalesce((select sum(amount) from public.finance_payable_settlements where payable_id=r.payable_id),0)));
end $$;
revoke all on function public.my_salary_summary() from public,anon;
grant execute on function public.my_salary_summary() to authenticated;

-- Upstream 20_daily_cash_count_statement_close.sql
create sequence public.daily_close_no_seq;
create table public.finance_daily_closes(
 id uuid primary key default gen_random_uuid(),close_no text not null unique default ('CLS-'||lpad(nextval('public.daily_close_no_seq')::text,6,'0')),
 account_id uuid not null references public.finance_accounts(id),close_date date not null,opening numeric(14,2) not null,receipts numeric(14,2) not null,payments numeric(14,2) not null,
 expected numeric(14,2) not null,actual numeric(14,2) not null,variance numeric(14,2) not null,ledger_token text not null,denominations jsonb,
 statement_reference text not null,explanation text not null,handed_to uuid references public.staff(id),recorded_by uuid not null references public.profiles(id),recorded_at timestamptz not null default now(),
 check(expected=opening+receipts-payments),check(variance=actual-expected)
);
create index finance_daily_close_lookup on public.finance_daily_closes(close_date desc,account_id,recorded_at desc);
create table public.finance_close_resolutions(
 id uuid primary key default gen_random_uuid(),event_order bigint generated always as identity,ledger_token text not null,close_id uuid not null references public.finance_daily_closes(id),action text not null check(action in('NOTE','RESOLVE','REOPEN')),
 reason text not null check(length(btrim(reason))>=5),journal_id uuid references public.general_ledger_journals(id),actor_id uuid not null references public.profiles(id),created_at timestamptz not null default now()
);
alter table public.finance_daily_closes enable row level security;
alter table public.finance_close_resolutions enable row level security;
create policy daily_close_read on public.finance_daily_closes for select to authenticated using(public.has_permission('accounting.reconcile'));
create policy close_resolution_read on public.finance_close_resolutions for select to authenticated using(public.has_permission('accounting.reconcile'));
grant select on public.finance_daily_closes,public.finance_close_resolutions to authenticated;
revoke insert,update,delete on public.finance_daily_closes,public.finance_close_resolutions from authenticated,anon;
create trigger daily_close_immutable before update or delete on public.finance_daily_closes for each row execute function public.prevent_permanent_record_delete();
create trigger close_resolution_immutable before update or delete on public.finance_close_resolutions for each row execute function public.prevent_permanent_record_delete();

create function public.daily_close_preview(p_account_id uuid,p_date date) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare account public.finance_accounts;opening numeric;receipts numeric;payments numeric;token text;
begin
 if auth.uid() is null or not public.has_permission('accounting.reconcile') or not exists(select 1 from public.profiles where id=auth.uid() and status='ACTIVE') then raise exception 'Reconciliation permission required.';end if;
 if p_date is null or p_date>(now() at time zone 'Asia/Dhaka')::date then raise exception 'Choose today or a previous close date.';end if;
 select * into account from public.finance_accounts where id=p_account_id and account_subtype in('CASH','BANK','MOBILE_BANK');if account.id is null then raise exception 'Choose an active cash, bank or mobile account.';end if;
 select coalesce(sum(l.debit-l.credit) filter(where j.journal_date<p_date),0),coalesce(sum(l.debit) filter(where j.journal_date=p_date),0),coalesce(sum(l.credit) filter(where j.journal_date=p_date),0),md5(count(*)::text||':'||coalesce(sum(l.debit),0)::text||':'||coalesce(sum(l.credit),0)::text)
 into opening,receipts,payments,token from public.general_ledger_lines l join public.general_ledger_journals j on j.id=l.journal_id where l.account_id=account.id and j.status='POSTED' and j.journal_date<=p_date;
 return jsonb_build_object('accountId',account.id,'name',account.name,'subtype',account.account_subtype,'date',p_date,'opening',opening,'receipts',receipts,'payments',payments,'expected',opening+receipts-payments,'token',token);
end $$;
revoke all on function public.daily_close_preview(uuid,date) from public,anon;
grant execute on function public.daily_close_preview(uuid,date) to authenticated;

create function public.daily_close_command(p_input jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid();request uuid:=(p_input->>'request_id')::uuid;key public.admission_command_keys;preview jsonb;record public.finance_daily_closes;reason text:=btrim(p_input->>'reason');action text:=p_input->>'action';actual numeric;item jsonb;counted numeric:=0;result jsonb;receiver uuid:=nullif(p_input->>'handed_to','')::uuid;
begin
 if actor is null or not public.has_permission('accounting.reconcile') or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') then raise exception 'Reconciliation permission required.';end if;
 if request is null or coalesce(length(reason),0)<5 then raise exception 'Request identity and explanation are required.';end if;
 perform pg_advisory_xact_lock(hashtextextended(request::text,0));select * into key from public.admission_command_keys where request_id=request;
 if found then if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity conflict.';end if;return key.result;end if;
 if action='COUNT' then
  perform 1 from public.finance_accounts where id=(p_input->>'account_id')::uuid and is_active for update;
  if not found then raise exception 'Choose an active cash or statement account.';end if;
  preview:=public.daily_close_preview((p_input->>'account_id')::uuid,(p_input->>'date')::date);
  if preview->>'token' is distinct from p_input->>'preview_token' then raise exception 'The ledger changed. Review a fresh balance before closing.';end if;
  if coalesce(length(btrim(p_input->>'statement_reference')),0)<3 then raise exception 'Record the cash count or bank statement reference.';end if;
  actual:=(p_input->>'actual')::numeric;
  if actual is null or actual<>round(actual,2) then raise exception 'Enter an actual balance with at most two decimal places.';end if;
  if preview->>'subtype'='CASH' then
   if actual<0 or jsonb_typeof(p_input->'denominations')<>'array' or jsonb_array_length(p_input->'denominations')<>10 then raise exception 'Complete the physical cash denomination count.';end if;
   if (select count(distinct (value->>'value')::numeric) from jsonb_array_elements(p_input->'denominations'))<>10 then raise exception 'Each cash denomination must appear once.';end if;
   for item in select value from jsonb_array_elements(p_input->'denominations') loop
    if (item->>'value')::numeric not in(1000,500,200,100,50,20,10,5,2,1) or (item->>'count')::numeric<0 or (item->>'count')::numeric<>trunc((item->>'count')::numeric) or item->>'count' is null then raise exception 'Cash denomination counts must be nonnegative whole numbers.';end if;
    counted:=counted+(item->>'value')::numeric*(item->>'count')::numeric;
   end loop;
   if counted<>actual then raise exception 'Physical denomination total does not match the actual cash balance.';end if;
  end if;
  if receiver is not null and not exists(select 1 from public.staff where id=receiver and status='ACTIVE') then raise exception 'Choose an active handover recipient.';end if;
  if actual<>(preview->>'expected')::numeric and coalesce(length(btrim(p_input->>'variance_note')),0)<10 then raise exception 'Explain the cash or statement difference before recording it.';end if;
  insert into public.finance_daily_closes(account_id,close_date,opening,receipts,payments,expected,actual,variance,ledger_token,denominations,statement_reference,explanation,handed_to,recorded_by)
  values((p_input->>'account_id')::uuid,(p_input->>'date')::date,(preview->>'opening')::numeric,(preview->>'receipts')::numeric,(preview->>'payments')::numeric,(preview->>'expected')::numeric,actual,actual-(preview->>'expected')::numeric,preview->>'token',case when preview->>'subtype'='CASH' then p_input->'denominations' else null end,p_input->>'statement_reference',reason||case when actual<>(preview->>'expected')::numeric then ' · Variance: '||(p_input->>'variance_note') else '' end,receiver,actor) returning * into record;
 elsif action in('NOTE','RESOLVE','REOPEN') then
  select * into record from public.finance_daily_closes where id=(p_input->>'id')::uuid for update;if record.id is null then raise exception 'Close record unavailable.';end if;
  if nullif(p_input->>'journal_id','') is not null and not exists(select 1 from public.general_ledger_journals j join public.general_ledger_lines l on l.journal_id=j.id where j.id=(p_input->>'journal_id')::uuid and l.account_id=record.account_id and j.status='POSTED') then raise exception 'Choose posted correction evidence for this account.';end if;
  preview:=public.daily_close_preview(record.account_id,record.close_date);
  if action='RESOLVE' then
   if not(record.variance=0 and preview->>'token'=record.ledger_token) and not exists(select 1 from public.finance_daily_closes c where c.account_id=record.account_id and c.close_date=record.close_date and substring(c.close_no from 5)::bigint>substring(record.close_no from 5)::bigint and c.variance=0 and c.ledger_token=preview->>'token') then raise exception 'Record a fresh matching physical count or statement before resolution. Original evidence stays intact.';end if;
  end if;
  insert into public.finance_close_resolutions(close_id,action,reason,journal_id,actor_id,ledger_token) values(record.id,action,reason,nullif(p_input->>'journal_id','')::uuid,actor,preview->>'token');
 else raise exception 'Unknown close action.';end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,after_data,correlation_id) values(actor,'DAILY_FINANCE_CLOSE',record.id::text,action,reason,to_jsonb(record),request);
 result:=jsonb_build_object('id',record.id,'ok',true);insert into public.admission_command_keys(request_id,actor_id,payload,result) values(request,actor,p_input,result);return result;
end $$;
revoke all on function public.daily_close_command(jsonb) from public,anon;
grant execute on function public.daily_close_command(jsonb) to authenticated;

create function public.daily_close_workspace(p_page integer default 1) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare rows jsonb;total integer;
begin
 if auth.uid() is null or not public.has_permission('accounting.reconcile') or not exists(select 1 from public.profiles where id=auth.uid() and status='ACTIVE') then raise exception 'Reconciliation permission required.';end if;
 if p_page is null or p_page<1 or p_page>10000 then raise exception 'Invalid page.';end if;
 select count(*) into total from public.finance_daily_closes;
 select coalesce(jsonb_agg(to_jsonb(r) order by r.recorded_at desc,r.id),'[]'::jsonb) into rows from(select c.*,a.name,public.daily_close_preview(c.account_id,c.close_date)->>'token'<>c.ledger_token stale,
 coalesce((select ledger_token is distinct from public.daily_close_preview(c.account_id,c.close_date)->>'token' from public.finance_close_resolutions where close_id=c.id and action in('RESOLVE','REOPEN') and action='RESOLVE' order by event_order desc limit 1),false) resolution_stale,
 coalesce((select action from public.finance_close_resolutions where close_id=c.id and action in('RESOLVE','REOPEN') order by event_order desc limit 1),'') resolution,
 (select coalesce(jsonb_agg(jsonb_build_object('action',action,'reason',reason,'date',created_at,'journalId',journal_id) order by created_at),'[]'::jsonb) from public.finance_close_resolutions where close_id=c.id) notes,
 (select full_name from public.staff where id=c.handed_to) receiver,
 (select display_name from public.profiles where id=c.recorded_by) actor
 from public.finance_daily_closes c join public.finance_accounts a on a.id=c.account_id order by c.recorded_at desc,c.id limit 25 offset (p_page-1)*25) r;
 return jsonb_build_object('total',total,'records',rows,
 'people',(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',full_name||' · '||staff_no) order by full_name),'[]'::jsonb) from public.staff where status='ACTIVE'),
 'accounts',(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'subtype',account_subtype) order by code),'[]'::jsonb) from public.finance_accounts where is_active and account_subtype in('CASH','BANK','MOBILE_BANK')));
end $$;
revoke all on function public.daily_close_workspace(integer) from public,anon;
grant execute on function public.daily_close_workspace(integer) to authenticated;

-- Upstream 21_monthly_accounts_and_period_lock.sql
insert into public.permissions(code,name,description) values('accounting.period.manage','Close and reopen accounting months','Controlled period close with immutable evidence') on conflict(code) do nothing;
insert into public.role_permissions(role_id,permission_id) select r.id,p.id from public.system_roles r cross join public.permissions p where r.code in('ADMIN','ACCOUNTANT') and p.code='accounting.period.manage' on conflict do nothing;
create table public.finance_period_events(
 id uuid primary key default gen_random_uuid(),event_order bigint generated always as identity,month date not null check(extract(day from month)=1),
 action text not null check(action in('CLOSE','REOPEN')),snapshot jsonb not null,reason text not null check(length(btrim(reason))>=10),actor_id uuid not null references public.profiles(id),created_at timestamptz not null default now()
);
create index finance_period_latest on public.finance_period_events(month,event_order desc);
alter table public.finance_period_events enable row level security;
create policy finance_period_read on public.finance_period_events for select to authenticated using(public.has_permission('accounting.view'));
grant select on public.finance_period_events to authenticated;
revoke insert,update,delete on public.finance_period_events from authenticated,anon;
create trigger finance_period_immutable before update or delete on public.finance_period_events for each row execute function public.prevent_permanent_record_delete();

create function public.guard_closed_financial_month() returns trigger language plpgsql security definer set search_path='' as $$
declare day date;month_value date;state text;
begin
 if tg_table_name='general_ledger_journals' then day:=new.journal_date;else select journal_date into day from public.general_ledger_journals where id=new.journal_id;end if;
 month_value:=date_trunc('month',day)::date;
 perform pg_advisory_xact_lock_shared(hashtextextended('finance-period:'||month_value::text,37));
 select action into state from public.finance_period_events where month=month_value order by event_order desc limit 1;
 if state='CLOSE' then raise exception 'Accounting month % is closed. An authorised reopen with a reason is required.',to_char(month_value,'YYYY-MM');end if;
 return new;
end $$;
revoke all on function public.guard_closed_financial_month() from public,anon,authenticated;
create trigger closed_month_journal_guard before insert on public.general_ledger_journals for each row execute function public.guard_closed_financial_month();
create trigger closed_month_line_guard before insert on public.general_ledger_lines for each row execute function public.guard_closed_financial_month();

create function public.finance_account_ledger_token(p_account uuid,p_date date) returns text language sql stable security definer set search_path='' as $$
 select md5(count(*)::text||':'||coalesce(sum(l.debit),0)::text||':'||coalesce(sum(l.credit),0)::text) from public.general_ledger_lines l join public.general_ledger_journals j on j.id=l.journal_id where l.account_id=p_account and j.status='POSTED' and j.journal_date<=p_date
$$;
revoke all on function public.finance_account_ledger_token(uuid,date) from public,anon,authenticated;

create function public.monthly_financial_report(p_month date default null) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare first_day date:=coalesce(p_month,date_trunc('month',now() at time zone 'Asia/Dhaka')::date);next_month date;accounts jsonb;cash jsonb;checks jsonb;revenue numeric;reductions numeric;expenses numeric;assets numeric;liabilities numeric;equity numeric;earnings numeric;cash_open numeric;cash_end numeric;snapshot jsonb;
begin
 if auth.uid() is null or not public.has_permission('accounting.view') or not exists(select 1 from public.profiles where id=auth.uid() and status='ACTIVE') then raise exception 'Accounting report permission required.';end if;
 if extract(day from first_day)<>1 or first_day>date_trunc('month',now() at time zone 'Asia/Dhaka')::date then raise exception 'Choose a current or previous accounting month.';end if;
 next_month:=(first_day+interval '1 month')::date;
 with totals as(select a.id,a.code,a.name,a.account_type,a.account_subtype,
 coalesce(sum(l.debit-l.credit) filter(where l.journal_date<first_day),0) opening,
 coalesce(sum(l.debit) filter(where l.journal_date>=first_day),0) debit,
 coalesce(sum(l.credit) filter(where l.journal_date>=first_day),0) credit,
 coalesce(sum(l.debit-l.credit),0) closing
 from public.finance_accounts a left join(select l.*,j.journal_date from public.general_ledger_lines l join public.general_ledger_journals j on j.id=l.journal_id where j.status='POSTED' and j.journal_date<next_month) l on l.account_id=a.id group by a.id,a.code,a.name,a.account_type,a.account_subtype)
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'code',code,'name',name,'type',account_type,'subtype',account_subtype,'opening',opening,'debit',debit,'credit',credit,'closing',closing,'endingDebit',greatest(closing,0),'endingCredit',greatest(-closing,0)) order by code),'[]'::jsonb),
 coalesce(sum(credit-debit) filter(where account_type='REVENUE'),0),coalesce(sum(debit-credit) filter(where account_type='CONTRA_REVENUE'),0),coalesce(sum(debit-credit) filter(where account_type='EXPENSE'),0),
 coalesce(sum(closing) filter(where account_type='ASSET'),0),coalesce(sum(-closing) filter(where account_type='LIABILITY'),0),coalesce(sum(-closing) filter(where account_type='EQUITY'),0),
 coalesce(sum(-closing) filter(where account_type in('REVENUE','CONTRA_REVENUE','EXPENSE')),0),
 coalesce(sum(opening) filter(where account_subtype in('CASH','BANK','MOBILE_BANK')),0),coalesce(sum(closing) filter(where account_subtype in('CASH','BANK','MOBILE_BANK')),0)
 into accounts,revenue,reductions,expenses,assets,liabilities,equity,earnings,cash_open,cash_end from totals;
 select coalesce(jsonb_agg(jsonb_build_object('type',journal_type,'source',source_type,'net',amount) order by journal_type,source_type),'[]'::jsonb) into cash from(select j.journal_type,j.source_type,sum(l.debit-l.credit) amount from public.general_ledger_lines l join public.finance_accounts a on a.id=l.account_id join public.general_ledger_journals j on j.id=l.journal_id where a.account_subtype in('CASH','BANK','MOBILE_BANK') and j.status='POSTED' and j.journal_date>=first_day and j.journal_date<next_month group by j.journal_type,j.source_type having sum(l.debit-l.credit)<>0) x;
 select coalesce(jsonb_agg(jsonb_build_object('id',a.id,'name',a.name,'matched',exists(select 1 from public.finance_daily_closes c where c.account_id=a.id and c.close_date=next_month-1 and c.variance=0 and c.ledger_token=public.finance_account_ledger_token(a.id,next_month-1))) order by a.code),'[]'::jsonb) into checks from public.finance_accounts a where a.is_active and a.account_subtype in('CASH','BANK','MOBILE_BANK');
 snapshot:=jsonb_build_object('month',first_day,'through',next_month-1,'accounts',accounts,'revenue',revenue,'reductions',reductions,'expenses',expenses,'profit',revenue-reductions-expenses,'assets',assets,'liabilities',liabilities,'equity',equity,'retainedResult',earnings,'balanceDifference',assets-liabilities-equity-earnings,'cashOpening',cash_open,'cashClosing',cash_end,'cashMovements',cash,'closeChecks',checks,
 'status',coalesce((select action from public.finance_period_events where month=first_day order by event_order desc limit 1),'OPEN'),
 'canClose',next_month<=(now() at time zone 'Asia/Dhaka')::date,'canManage',public.has_permission('accounting.period.manage'),
 'events',(select coalesce(jsonb_agg(jsonb_build_object('action',action,'reason',reason,'date',created_at,'actor',(select display_name from public.profiles where id=actor_id)) order by event_order),'[]'::jsonb) from public.finance_period_events where month=first_day));
 return snapshot||jsonb_build_object('token',md5(snapshot::text),'generatedAt',now());
end $$;
revoke all on function public.monthly_financial_report(date) from public,anon;
grant execute on function public.monthly_financial_report(date) to authenticated;

create function public.finance_period_command(p_input jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid();req uuid:=(p_input->>'request_id')::uuid;month_value date:=(p_input->>'month')::date;action text:=p_input->>'action';reason text:=btrim(p_input->>'reason');state text;key public.admission_command_keys;report jsonb;result jsonb;rid uuid;
begin
 if actor is null or not public.has_permission('accounting.period.manage') or not public.has_permission('accounting.view') or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') then raise exception 'Accounting period management permission required.';end if;
 if req is null or coalesce(length(reason),0)<10 or month_value is null then raise exception 'Request identity, month and clear explanation are required.';end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));select * into key from public.admission_command_keys where request_id=req;
 if found then if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity conflict.';end if;return key.result;end if;
 perform pg_advisory_xact_lock(hashtextextended('finance-period:'||month_value::text,37));
 report:=public.monthly_financial_report(month_value);
 select e.action into state from public.finance_period_events e where month=month_value order by event_order desc limit 1;
 if action='CLOSE' then
  if state='CLOSE' then raise exception 'This month is already closed.';end if;
  if not (report->>'canClose')::boolean then raise exception 'Close a completed month only.';end if;
  if report->>'token' is distinct from p_input->>'preview_token' then raise exception 'The financial preview changed. Refresh and review before closing.';end if;
  if (report->>'balanceDifference')::numeric<>0 or exists(select 1 from jsonb_array_elements(report->'closeChecks') c where not(c->>'matched')::boolean) then raise exception 'Resolve the balance difference and verify all active cash/bank/mobile month-end counts or statements first.';end if;
  if exists(select 1 from public.general_ledger_journals j left join public.general_ledger_lines l on l.journal_id=j.id where j.status='POSTED' and j.journal_date between month_value and (report->>'through')::date group by j.id having count(l.id)<2 or sum(l.debit)<>sum(l.credit)) then raise exception 'Unbalanced or incomplete journals prevent closing.';end if;
 elsif action='REOPEN' then
  if state is distinct from 'CLOSE' then raise exception 'Only a closed month can be reopened.';end if;
 else raise exception 'Choose close or reopen.';end if;
 insert into public.finance_period_events(month,action,snapshot,reason,actor_id) values(month_value,action,report,reason,actor) returning id into rid;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,after_data,correlation_id) values(actor,'ACCOUNTING_PERIOD',month_value::text,action,reason,jsonb_build_object('eventId',rid,'profit',report->'profit'),req);
 result:=jsonb_build_object('id',rid,'ok',true);insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);return result;
end $$;
revoke all on function public.finance_period_command(jsonb) from public,anon;
grant execute on function public.finance_period_command(jsonb) to authenticated;

-- Fixed salary belongs to the earned month; settlement remains on the actual payment date.
create or replace function public.staff_payroll_command(p_input jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid();request uuid:=(p_input->>'request_id')::uuid;action text:=p_input->>'action';reason text:=btrim(p_input->>'reason');key public.admission_command_keys;preview jsonb;org uuid;expense_account uuid;salary_account uuid;advance_account uuid;record public.staff_payroll_records;payable public.finance_payables;advance public.finance_advances;cash numeric;offset_amount numeric;remaining numeric;account uuid;journal_lines jsonb;result jsonb;
begin
 if actor is null or not public.has_permission('payroll.manage') or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') then raise exception 'Payroll management permission required.';end if;
 if request is null or coalesce(length(reason),0)<5 then raise exception 'Request identity and reason are required.';end if;
 perform pg_advisory_xact_lock(hashtextextended(request::text,0));select * into key from public.admission_command_keys where request_id=request;
 if found then if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity conflict.';end if;return key.result;end if;
 select id into org from public.organizations where is_active;
 select id into salary_account from public.finance_accounts where organization_id=org and account_subtype='STAFF_SALARY_PAYABLE' and is_active;
 select id into expense_account from public.finance_accounts where organization_id=org and account_subtype='STAFF_PAYROLL_EXPENSE' and is_active;
 if action='POST' then
  perform 1 from public.staff where id=(p_input->>'staff_id')::uuid for update;
  preview:=public.staff_payroll_preview(p_input);
  if not (preview->>'canPost')::boolean then raise exception 'A current-month preview is provisional. Post after the month has ended; use advances for earlier payments.';end if;
  if preview->>'token' is distinct from p_input->>'preview_token' then raise exception 'Attendance or agreed terms changed. Review a fresh preview before posting.';end if;
  if preview->'terms'->>'model' in('FIXED','HOURLY') and exists(select 1 from public.teacher_compensation_lines l join public.teacher_compensation_runs r on r.id=l.run_id where l.teacher_id=(p_input->>'staff_id')::uuid and r.status='APPROVED' and l.line_type='TEACHING_REMUNERATION' and r.period_start<(preview->>'month')::date+interval '1 month' and r.period_end>=(preview->>'month')::date) then raise exception 'Teaching-pool remuneration was already posted for this period. Resolve the agreement; use HYBRID only when both bases were agreed.';end if;
  if exists(select 1 from public.staff_payroll_records where staff_id=(p_input->>'staff_id')::uuid and month=(p_input->>'month')::date) then raise exception 'Payroll is already posted for this staff and month.';end if;
  record.id:=gen_random_uuid();
  insert into public.finance_payables(organization_id,payable_type,staff_id,source_type,source_id,payable_account_id,original_amount,due_on,created_by)
  values(org,'STAFF_PAYROLL',(p_input->>'staff_id')::uuid,'STAFF_PAYROLL',record.id::text,salary_account,(preview->>'net')::numeric,(preview->>'dueOn')::date,actor) returning * into payable;
  insert into public.staff_payroll_records(id,staff_id,month,payable_id,snapshot,gross,corrections,net,due_on,posted_by,reason)
  values(record.id,(p_input->>'staff_id')::uuid,(p_input->>'month')::date,payable.id,preview,(preview->>'gross')::numeric,(preview->>'corrections')::numeric,(preview->>'net')::numeric,(preview->>'dueOn')::date,actor,reason) returning * into record;
  perform public.finance_post_journal(org,(record.month+interval '1 month - 1 day')::date,'COMPENSATION_RUN','STAFF_PAYROLL',record.id::text,'Staff payroll '||(preview->>'number')||' '||(preview->>'month'),actor,jsonb_build_array(jsonb_build_object('account_id',expense_account,'debit',record.net,'credit',0),jsonb_build_object('account_id',salary_account,'debit',0,'credit',record.net)));
 elsif action='SETTLE' then
  select * into record from public.staff_payroll_records where id=(p_input->>'id')::uuid for update;if record.id is null then raise exception 'Payroll record unavailable.';end if;
  select * into payable from public.finance_payables where id=record.payable_id for update;
  remaining:=payable.original_amount-coalesce((select sum(amount) from public.finance_payable_settlements where payable_id=payable.id),0);
  cash:=coalesce((p_input->>'cash')::numeric,0);offset_amount:=coalesce((p_input->>'advance_offset')::numeric,0);
  if cash<>round(cash,2) or offset_amount<>round(offset_amount,2) or cash<0 or offset_amount<0 or cash+offset_amount<=0 or cash+offset_amount>remaining then raise exception 'Cash plus advance offset must fit the remaining payable.';end if;
  journal_lines:=jsonb_build_array(jsonb_build_object('account_id',payable.payable_account_id,'debit',cash+offset_amount,'credit',0));
  if cash>0 then
   select id into account from public.finance_accounts where id=(p_input->>'account_id')::uuid and organization_id=org and is_active and account_subtype in('CASH','BANK','MOBILE_BANK');
   if account is null or coalesce(length(btrim(p_input->>'reference')),0)<3 then raise exception 'Choose the actual payment account and payment reference.';end if;
   insert into public.finance_payable_settlements(payable_id,amount,payment_account_id,external_reference,settled_by,reason) values(payable.id,cash,account,p_input->>'reference',actor,reason);
   journal_lines:=journal_lines||jsonb_build_array(jsonb_build_object('account_id',account,'debit',0,'credit',cash));
  end if;
  if offset_amount>0 then
   select * into advance from public.finance_advances where id=(p_input->>'advance_id')::uuid for update;
   if advance.id is null or advance.staff_id is distinct from record.staff_id or advance.beneficiary_type<>'STAFF' or advance.status not in('PAID','PARTIALLY_SETTLED') or public.advance_balance(advance.id)<offset_amount then raise exception 'Choose a paid advance belonging to this staff member with enough balance.';end if;
   select id into advance_account from public.finance_accounts where organization_id=org and account_subtype='STAFF_ADVANCE' and is_active;
   insert into public.finance_payable_settlements(payable_id,amount,advance_id,settled_by,reason) values(payable.id,offset_amount,advance.id,actor,reason);
   insert into public.finance_advance_movements(advance_id,movement_type,amount,source_type,source_id,created_by,reason) values(advance.id,'SETTLEMENT',offset_amount,'STAFF_PAYROLL',request::text,actor,reason);
   update public.finance_advances set status=case when public.advance_balance(id)=0 then 'SETTLED' else 'PARTIALLY_SETTLED' end where id=advance.id;
   journal_lines:=journal_lines||jsonb_build_array(jsonb_build_object('account_id',advance_account,'debit',0,'credit',offset_amount));
  end if;
  perform public.finance_post_journal(org,(now() at time zone 'Asia/Dhaka')::date,'COMPENSATION_SETTLEMENT','STAFF_PAYROLL_SETTLEMENT',request::text,'Payroll settlement '||record.id::text,actor,journal_lines);
  update public.finance_payables set status=case when cash+offset_amount=remaining then 'SETTLED' else 'PARTIALLY_SETTLED' end where id=payable.id;
 else raise exception 'Unknown payroll action.';end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,after_data,correlation_id) values(actor,'STAFF_PAYROLL',record.id::text,action,reason,jsonb_build_object('net',record.net,'cash',cash,'advanceOffset',offset_amount),request);
 result:=jsonb_build_object('id',record.id,'ok',true);insert into public.admission_command_keys(request_id,actor_id,payload,result) values(request,actor,p_input,result);return result;
end $$;
revoke all on function public.staff_payroll_command(jsonb) from public,anon;
grant execute on function public.staff_payroll_command(jsonb) to authenticated;


-- Upstream 22_purchase_drafts_receipt_and_expense_posting.sql
-- Purchasing is evidence first. Saving a draft never moves cash or creates a liability.
create sequence public.purchase_no_seq;
create table public.finance_purchases(
 id uuid primary key default gen_random_uuid(), purchase_no text not null unique default ('PUR-'||lpad(nextval('public.purchase_no_seq')::text,6,'0')),
 organization_id uuid not null references public.organizations(id),vendor_id uuid not null references public.vendors(id),category_id uuid not null references public.finance_expense_categories(id),
 description text not null,items jsonb not null,total numeric(14,2) not null check(total>0),expected_on date,
 status text not null default 'DRAFT' check(status in('DRAFT','CANCELLED','POSTED')),revision integer not null default 1,
 invoice_reference text,received_on date,expense_id uuid unique references public.finance_expenses(id),
 created_by uuid not null references public.profiles(id),created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 check((status='POSTED')=(expense_id is not null))
);
create unique index purchase_supplier_invoice on public.finance_purchases(organization_id,vendor_id,lower(btrim(invoice_reference))) where status='POSTED';
create index purchase_register_lookup on public.finance_purchases(organization_id,created_at desc,id);
alter table public.finance_purchases enable row level security;
create policy purchase_read on public.finance_purchases for select to authenticated using(public.has_permission('accounting.expense.manage') and organization_id=(select id from public.organizations where is_active));
grant select on public.finance_purchases to authenticated;
revoke insert,update,delete on public.finance_purchases from anon,authenticated;
create function public.guard_purchase_history() returns trigger language plpgsql set search_path='' as $$
begin if tg_op='DELETE' then raise exception 'Purchases cannot be deleted. Cancel an unused draft.';end if;
 if old.status<>'DRAFT' then raise exception 'Final purchase evidence is immutable.';end if;return new;end $$;
create trigger purchase_history before update or delete on public.finance_purchases for each row execute function public.guard_purchase_history();

create function public.purchase_command(p_input jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid();req uuid:=(p_input->>'request_id')::uuid;key public.admission_command_keys;org uuid;action text:=p_input->>'action';reason text:=btrim(p_input->>'reason');r public.finance_purchases;before_value jsonb;item jsonb;total_value numeric:=0;quantity numeric;price numeric;result jsonb;expense_result jsonb;vendor uuid;category uuid;received date;amount numeric;
begin
 if actor is null or not public.has_permission('accounting.expense.manage') or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') then raise exception 'Expense management access required.';end if;
 if req is null or coalesce(length(reason),0)<5 then raise exception 'Request identity and a clear reason are required.';end if;
 select id into org from public.organizations where is_active;if org is null then raise exception 'Active public unavailable.';end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));select * into key from public.admission_command_keys where request_id=req;
 if found then if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity conflict.';end if;return key.result;end if;
 if action='CREATE_VENDOR' then
  if coalesce(length(btrim(p_input->>'name')),0)<2 then raise exception 'Supplier name is required.';end if;
  perform pg_advisory_xact_lock(hashtextextended(org::text||lower(btrim(p_input->>'name')),22));
  if exists(select 1 from public.vendors where organization_id=org and lower(btrim(name))=lower(btrim(p_input->>'name')) and is_active) then raise exception 'An active supplier with this name already exists. Select the existing supplier.';end if;
  insert into public.vendors(organization_id,name,mobile,email,address,created_by) values(org,btrim(p_input->>'name'),nullif(btrim(p_input->>'mobile'),''),nullif(lower(btrim(p_input->>'email')),''),nullif(btrim(p_input->>'address'),''),actor) returning id into vendor;
  result:=jsonb_build_object('id',vendor,'message','Supplier added. Select the supplier to continue your purchase.');
 elsif action in('SAVE','CANCEL','RECEIVE','PAY') then
  if nullif(p_input->>'id','') is not null then
   select * into r from public.finance_purchases where id=(p_input->>'id')::uuid and organization_id=org for update;
   if r.id is null then raise exception 'Purchase unavailable.';end if;
   if r.revision is distinct from (p_input->>'revision')::integer then raise exception 'This purchase changed. Refresh it before continuing.';end if;
   before_value:=to_jsonb(r);
  elsif action<>'SAVE' then raise exception 'Select a purchase first.';end if;
  if action='SAVE' then
   if r.id is not null and r.status<>'DRAFT' then raise exception 'Only drafts can be edited.';end if;
   vendor:=(p_input->>'vendor_id')::uuid;category:=(p_input->>'category_id')::uuid;
   if not exists(select 1 from public.vendors where id=vendor and organization_id=org and is_active) then raise exception 'Select an active supplier.';end if;
   if not exists(select 1 from public.finance_expense_categories c join public.finance_accounts a on a.id=c.expense_account_id where c.id=category and c.organization_id=org and c.is_active and a.is_active and a.account_type='EXPENSE') then raise exception 'Select an active operating expense category.';end if;
   if coalesce(length(btrim(p_input->>'description')),0)<3 or jsonb_typeof(p_input->'items') is distinct from 'array' or jsonb_array_length(p_input->'items') not between 1 and 30 then raise exception 'Describe the purchase and add one to thirty items.';end if;
   for item in select value from jsonb_array_elements(p_input->'items') loop
    quantity:=(item->>'quantity')::numeric;price:=(item->>'price')::numeric;
    if coalesce(length(btrim(item->>'name')),0)<2 or quantity is null or quantity<=0 or quantity>100000 or quantity<>round(quantity,3) or price is null or price<=0 or price>999999999999.99 or price<>round(price,2) then raise exception 'Each item needs a name, positive quantity and a positive two-decimal unit price.';end if;
    total_value:=total_value+round(quantity*price,2);
   end loop;
   if total_value>999999999999.99 then raise exception 'Purchase total exceeds the supported amount.';end if;
   if r.id is null then
    insert into public.finance_purchases(organization_id,vendor_id,category_id,description,items,total,expected_on,created_by) values(org,vendor,category,btrim(p_input->>'description'),p_input->'items',total_value,nullif(p_input->>'expected_on','')::date,actor) returning * into r;
   else
    update public.finance_purchases set vendor_id=vendor,category_id=category,description=btrim(p_input->>'description'),items=p_input->'items',total=total_value,expected_on=nullif(p_input->>'expected_on','')::date,revision=revision+1,updated_at=now() where id=r.id returning * into r;
   end if;
   result:=jsonb_build_object('id',r.id,'message','Purchase draft saved. No expense, payment or payable has been posted.');
  elsif action='CANCEL' then
   if r.status<>'DRAFT' then raise exception 'Only unused drafts can be cancelled.';end if;
   update public.finance_purchases set status='CANCELLED',revision=revision+1,updated_at=now() where id=r.id returning * into r;
   result:=jsonb_build_object('id',r.id,'message','Draft cancelled; its history remains available.');
  elsif action='RECEIVE' then
   if r.status<>'DRAFT' then raise exception 'This purchase has already been completed or cancelled.';end if;
   received:=(p_input->>'received_on')::date;
   if received is null or received>(now() at time zone 'Asia/Dhaka')::date or coalesce(length(btrim(p_input->>'invoice_reference')),0)<3 or p_input->>'confirmed_received' is distinct from 'true' then raise exception 'Confirm full receipt, a valid receipt date and supplier invoice reference.';end if;
   perform pg_advisory_xact_lock(hashtextextended(org::text||r.vendor_id::text||lower(btrim(p_input->>'invoice_reference')),23));
   if exists(select 1 from public.finance_purchases where organization_id=org and vendor_id=r.vendor_id and status='POSTED' and lower(btrim(invoice_reference))=lower(btrim(p_input->>'invoice_reference'))) then raise exception 'This supplier invoice is already recorded. Check the purchase register instead of posting it again.';end if;
   if p_input->>'payment_mode'='PAID_NOW' and not public.has_permission('finance.payments.post') then raise exception 'Payment posting access required for paid-now receipt.';end if;
   if p_input->>'payment_mode' not in('PAID_NOW','ON_ACCOUNT') or p_input->>'payment_mode' is null then raise exception 'Choose paid now or payable later.';end if;
   if not exists(select 1 from public.vendors where id=r.vendor_id and organization_id=org and is_active) then raise exception 'Supplier is inactive. Edit the draft and select an active supplier.';end if;
   -- Use a separate request identity for the internal expense engine; the outer identity owns purchase retries.
   expense_result:=public.post_accounting_operation(jsonb_build_object('action','CREATE_EXPENSE_DIRECT','request_id',gen_random_uuid(),'reason',reason,'amount',r.total,'category_id',r.category_id,'vendor_id',r.vendor_id,'expense_date',received,'payment_mode',p_input->>'payment_mode','payment_account_id',p_input->>'payment_account_id','description',r.purchase_no||' · '||r.description,'receipt_reference',btrim(p_input->>'invoice_reference')));
   update public.finance_purchases set status='POSTED',expense_id=(expense_result->>'id')::uuid,received_on=received,invoice_reference=btrim(p_input->>'invoice_reference'),revision=revision+1,updated_at=now() where id=r.id returning * into r;
   result:=jsonb_build_object('id',r.id,'message','Receipt verified and expense posted. Unpaid charges remain supplier payable.');
  elsif action='PAY' then
   if not public.has_permission('finance.payments.post') then raise exception 'Payment posting access required.';end if;
   if r.status<>'POSTED' then raise exception 'Receive and post the purchase before paying a supplier payable.';end if;
   amount:=(p_input->>'amount')::numeric;
   if amount is null or amount<=0 or amount<>round(amount,2) or coalesce(length(btrim(p_input->>'external_reference')),0)<3 then raise exception 'Enter a positive two-decimal payment and its reference.';end if;
   result:=public.finance_accounting_command(jsonb_build_object('action','SETTLE_PAYABLE','request_id',gen_random_uuid(),'reason',reason,'payable_id',(select payable_id from public.finance_expenses where id=r.expense_id),'amount',amount,'payment_account_id',p_input->>'payment_account_id','external_reference',btrim(p_input->>'external_reference')));
   result:=jsonb_build_object('id',r.id,'message','Supplier payment posted; any remaining balance stays due.');
  end if;
 else raise exception 'Unknown purchasing action.';end if;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data) values(req,actor,case when action='CREATE_VENDOR' then 'VENDOR' else 'PURCHASE' end,result->>'id',action,reason,before_value,case when action='CREATE_VENDOR' then result else to_jsonb(r) end);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);
 return result;
end $$;
revoke all on function public.purchase_command(jsonb) from public,anon;
grant execute on function public.purchase_command(jsonb) to authenticated;

create function public.purchase_workspace(p_page integer default 1,p_status text default 'ALL',p_search text default '') returns jsonb language plpgsql stable security definer set search_path='' as $$
declare org uuid;result jsonb;
begin
 if auth.uid() is null or not public.has_permission('accounting.expense.manage') or not exists(select 1 from public.profiles where id=auth.uid() and status='ACTIVE') then raise exception 'Expense management access required.';end if;
 if p_page<1 or p_page>100000 or p_status not in('ALL','DRAFT','POSTED','CANCELLED') or length(p_search)>100 then raise exception 'Invalid register filters.';end if;
 select id into org from public.organizations where is_active;
 select jsonb_build_object('page',p_page,'total',(select count(*) from public.finance_purchases p join public.vendors v on v.id=p.vendor_id where p.organization_id=org and (p_status='ALL' or p.status=p_status) and (p_search='' or p.purchase_no ilike '%'||p_search||'%' or p.description ilike '%'||p_search||'%' or v.name ilike '%'||p_search||'%')),
 'rows',coalesce((select jsonb_agg(to_jsonb(x)) from(select p.*,v.name supplier,c.name category,e.expense_no,e.payment_mode,e.payable_id,case when e.payable_id is null then 0 else coalesce(e.amount-(select coalesce(sum(s.amount),0) from public.finance_payable_settlements s where s.payable_id=e.payable_id),0) end remaining
 from public.finance_purchases p join public.vendors v on v.id=p.vendor_id join public.finance_expense_categories c on c.id=p.category_id left join public.finance_expenses e on e.id=p.expense_id
 where p.organization_id=org and (p_status='ALL' or p.status=p_status) and (p_search='' or p.purchase_no ilike '%'||p_search||'%' or p.description ilike '%'||p_search||'%' or v.name ilike '%'||p_search||'%') order by p.created_at desc,p.id limit 25 offset (p_page-1)*25)x),'[]'::jsonb),
 'vendors',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.vendors where organization_id=org and is_active),'[]'::jsonb),
 'categories',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.finance_expense_categories where organization_id=org and is_active),'[]'::jsonb),
 'accounts',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.finance_accounts where organization_id=org and is_active and account_subtype in('CASH','BANK','MOBILE_BANK')),'[]'::jsonb),
 'canPay',public.has_permission('finance.payments.post')) into result;return result;
end $$;
revoke all on function public.purchase_workspace(integer,text,text) from public,anon;
grant execute on function public.purchase_workspace(integer,text,text) to authenticated;

reset search_path;

-- Branch isolation is enforced even inside legacy SECURITY DEFINER workflows.
set search_path=public,extensions;
create schema academy_private;
revoke all on schema academy_private from public,anon,authenticated;
create role academy_executor nologin nobypassrls;
-- Hosted Supabase migrations run without SUPERUSER. Ownership transfers need
-- SET ROLE membership and CREATE on the target schema. Only the migration
-- administrator receives membership; API roles must never receive it.
do $$ begin execute format('grant academy_executor to %I',current_user); end $$;
grant create on schema public to academy_executor;
grant usage on schema public,academy_private,auth to academy_executor;
grant execute on function auth.uid() to academy_executor;
create table public.branch_owners(organization_id uuid primary key references public.organizations(id),user_id uuid not null references auth.users(id));
create table public.branch_memberships(branch_id uuid references public.branches(id),user_id uuid references auth.users(id),is_active boolean not null default true,primary key(branch_id,user_id));
create table public.branch_open_commands(user_id uuid references auth.users(id),request_id uuid,payload jsonb not null,result jsonb not null,primary key(user_id,request_id));
create function academy_private.current_branch_id() returns uuid language plpgsql stable security definer set search_path=pg_catalog,public as $$
declare chosen uuid; begin
 chosen:=nullif(current_setting('public.branch_override',true),'')::uuid;
 if chosen is null then chosen:=nullif(coalesce(nullif(current_setting('request.headers',true),''),'{}')::jsonb->>'x-academy-branch','')::uuid; end if;
 if chosen is null or auth.uid() is null or not exists(select 1 from public.branch_memberships m join public.branches b on b.id=m.branch_id where m.user_id=auth.uid() and m.branch_id=chosen and m.is_active and b.is_active) then return null; end if;
 return chosen;
 exception when invalid_text_representation then return null;
end $$;
grant usage on schema academy_private to authenticated;
grant execute on function academy_private.current_branch_id() to authenticated,academy_executor;
-- Financial stores are removed. Empty compatibility views preserve read-only response shapes
-- in retained academic code; they cannot store money or accept inserts/updates.
do $$ declare r record; cols text; begin
 for r in select tablename from pg_tables where schemaname='public' and (tablename like 'finance_%' or tablename like 'general_ledger_%' or tablename like 'teacher_compensation_%' or tablename like 'referral_%' or tablename in('teacher_referrals','admission_referrals','vendors','payment_methods','admission_invoices','admission_invoice_lines','admission_payments','admission_payment_allocations','billing_terms','admission_discounts','invoice_credits','refund_authorizations','refund_payouts','admission_cancellations','billing_runs','fee_plan_versions','fee_plan_components','staff_compensation_terms','staff_payroll_records')) loop
  select string_agg(format('NULL::%s as %I',format_type(atttypid,atttypmod),attname),',' order by attnum) into cols from pg_attribute where attrelid=format('public.%I',r.tablename)::regclass and attnum>0 and not attisdropped;
  execute format('drop table public.%I cascade',r.tablename);
  execute format('create view public.%I as select %s where false',r.tablename,cols);
 end loop;
end $$;
do $$ declare r record;begin for r in select t.tgname,c.relname from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace join pg_proc p on p.oid=t.tgfoid where n.nspname='public' and not t.tgisinternal and p.proname ~ '(finance|billing|payment|discount|refund|compensation|payroll|fee_plan|referr)' loop execute format('drop trigger %I on public.%I',r.tgname,r.relname);end loop;end $$;
-- Global profile/branch bootstrap is audited explicitly, after membership exists.
do $$ declare r record; begin for r in select t.tgname,c.relname from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname in('profiles','organizations','branches') and not t.tgisinternal and t.tgname ilike '%audit%' loop execute format('drop trigger %I on public.%I',r.tgname,r.relname); end loop; end $$;
-- No migration template is a real branch. It remains inaccessible as a seed reference.
update public.branches set is_active=false;
create function academy_private.protect_branch_scope() returns trigger language plpgsql set search_path=pg_catalog as $$ begin
 if TG_OP='UPDATE' and new.scope_branch_id is distinct from old.scope_branch_id then raise exception 'A record cannot move to another branch.'; end if;
 if to_jsonb(new) ? 'branch_id' and nullif(to_jsonb(new)->>'branch_id','') is not null and (to_jsonb(new)->>'branch_id')::uuid<>new.scope_branch_id then raise exception 'Branch placement must match record scope.'; end if;
 return new; end $$;
-- All operational tables are scoped, including command keys and audit history.
do $$ declare r record; u record; begin
 for r in select tablename from pg_tables where schemaname='public' and tablename not in('organizations','branches','profiles','system_roles','permissions','role_permissions','staff_roles','branch_owners','branch_memberships','branch_open_commands') loop
  execute format('alter table public.%I add column scope_branch_id uuid',r.tablename);
  execute format('update public.%I set scope_branch_id=''87a7d34b-4c6d-43ba-96b9-3dcf22da2c7c''',r.tablename);
  execute format('alter table public.%I alter column scope_branch_id set default academy_private.current_branch_id(),alter column scope_branch_id set not null,add foreign key(scope_branch_id) references public.branches(id)',r.tablename);
  -- Organization-level directory names/codes are independently editable in each branch.
  for u in select conname,pg_get_constraintdef(oid) def from pg_constraint where conrelid=format('public.%I',r.tablename)::regclass and contype='u' and (pg_get_constraintdef(oid) like '%organization_id%' or pg_get_constraintdef(oid) like '%profile_id%' or pg_get_constraintdef(oid) like '%domain%' or pg_get_constraintdef(oid) like '%code%' or pg_get_constraintdef(oid) like '%name%') and pg_get_constraintdef(oid) not like '%(id,%' loop
   execute format('alter table public.%I drop constraint %I',r.tablename,u.conname);
   execute format('alter table public.%I add constraint %I %s',r.tablename,u.conname,replace(u.def,'UNIQUE (','UNIQUE (scope_branch_id, '));
  end loop;
  execute format('alter table public.%I enable row level security',r.tablename);
  execute format('alter table public.%I force row level security',r.tablename);
  execute format('create policy executor_workflows on public.%I for all to academy_executor using(true) with check(true)',r.tablename);
  execute format('create policy branch_scope on public.%I as restrictive for all to authenticated,academy_executor using(scope_branch_id=academy_private.current_branch_id()) with check(scope_branch_id=academy_private.current_branch_id())',r.tablename);
  execute format('create trigger protect_branch_scope before insert or update on public.%I for each row execute function academy_private.protect_branch_scope()',r.tablename);
  if exists(select 1 from information_schema.columns where table_schema='public' and table_name=r.tablename and column_name='id') then execute format('alter table public.%I add unique(scope_branch_id,id)',r.tablename); end if;
 end loop;
end $$;
drop index public.one_active_business_rule;
create unique index one_active_business_rule on public.business_rule_versions(scope_branch_id,domain,rule_key) where status='ACTIVE';
drop index public.staff_access_open_email;
create unique index staff_access_open_email on public.staff_access_requests(scope_branch_id,lower(email)) where status in('PENDING','VERIFIED','INVITED');
drop index public.areas_name_parent_uniq;
create unique index areas_name_parent_uniq on public.areas(scope_branch_id,organization_id,lower(name),coalesce(parent_id,'00000000-0000-0000-0000-000000000000'::uuid));
-- Composite foreign keys prevent cross-branch links even for a user belonging to both branches.
do $$ declare r record; begin
 for r in select c.conrelid::regclass as src,c.confrelid::regclass as dst,a.attname as col,b.attname as target,c.conname from pg_constraint c join pg_attribute a on a.attrelid=c.conrelid and a.attnum=c.conkey[1] join pg_attribute b on b.attrelid=c.confrelid and b.attnum=c.confkey[1] where c.contype='f' and array_length(c.conkey,1)=1 and b.attname='id' and a.attname<>'scope_branch_id' and exists(select 1 from pg_attribute where attrelid=c.conrelid and attname='scope_branch_id') and exists(select 1 from pg_attribute where attrelid=c.confrelid and attname='scope_branch_id') loop
  execute format('alter table %s add constraint %I foreign key(scope_branch_id,%I) references %s(scope_branch_id,id)',r.src,'scope_'||substr(md5(r.src::text||r.conname),1,24),r.col,r.dst);
 end loop;
end $$;
-- Global identity and immutable permission templates are the only shared records.
alter table public.organizations force row level security;
alter table public.branches force row level security;
alter table public.profiles force row level security;
create policy executor_workflows on public.organizations for all to academy_executor using(true) with check(true);
create policy executor_workflows on public.branches for all to academy_executor using(true) with check(true);
create policy executor_workflows on public.profiles for all to academy_executor using(true) with check(true);
create policy organization_scope on public.organizations as restrictive for all to authenticated,academy_executor using(id=(select organization_id from public.branches where id=academy_private.current_branch_id())) with check(id=(select organization_id from public.branches where id=academy_private.current_branch_id()));
create policy branch_registry_scope on public.branches as restrictive for all to authenticated,academy_executor using(id=academy_private.current_branch_id()) with check(id=academy_private.current_branch_id());
create function academy_private.is_branch_member(p_profile uuid) returns boolean language sql stable security definer set search_path=pg_catalog,public as $$ select academy_private.current_branch_id() is not null and exists(select 1 from public.branch_memberships where user_id=p_profile and branch_id=academy_private.current_branch_id() and is_active); $$;
grant execute on function academy_private.is_branch_member(uuid) to authenticated,academy_executor;
create policy profile_scope on public.profiles as restrictive for all to authenticated,academy_executor using(id=auth.uid() or academy_private.is_branch_member(id)) with check(id=auth.uid() or academy_private.is_branch_member(id));
alter table public.branch_memberships enable row level security;
create policy own_memberships on public.branch_memberships for select to authenticated,academy_executor using(user_id=auth.uid());
alter table public.branch_owners enable row level security;
alter table public.branch_open_commands enable row level security;
grant select on public.branch_memberships to authenticated,academy_executor;
do $$ declare item text;begin foreach item in array array['system_roles','permissions','role_permissions','staff_roles'] loop execute format('create policy executor_catalogue_read on public.%I for select to academy_executor using(academy_private.current_branch_id() is not null)',item);end loop;end $$;
-- Permission evaluation avoids RLS recursion and always validates branch membership.
create or replace function public.has_permission(p_permission_code text) returns boolean language sql stable security definer set search_path=pg_catalog,public as $$
 select auth.uid() is not null and academy_private.current_branch_id() is not null and exists(select 1 from public.user_role_assignments ura join public.system_roles sr on sr.id=ura.role_id join public.role_permissions rp on rp.role_id=sr.id join public.permissions p on p.id=rp.permission_id join public.profiles pr on pr.id=ura.profile_id where ura.profile_id=auth.uid() and ura.scope_branch_id=academy_private.current_branch_id() and ura.is_active and sr.is_active and pr.status='ACTIVE' and ura.effective_from<=current_date and(ura.effective_to is null or ura.effective_to>=current_date) and p.code=p_permission_code);
$$;
-- Remove all financial permissions, preventing retained legacy commands from posting money.
delete from public.role_permissions where permission_id in(select id from public.permissions where code ~ '^(finance|accounting|compensation|referrals)\.' or code='system.roles.manage');
-- All legacy definer functions run as an RLS-bound executor, never as postgres.
grant all on all tables in schema public to academy_executor;
grant usage,select on all sequences in schema public to academy_executor;
grant execute on all functions in schema public to academy_executor;
grant execute on all functions in schema academy_private to academy_executor;
do $$ declare r record; begin for r in select p.oid::regprocedure as signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname<>'has_permission' loop execute format('alter function %s owner to academy_executor',r.signature); end loop; end $$;
-- Read-only compatibility views have no public write grants. Financial/bootstrap RPCs are inaccessible.
revoke all on all functions in schema public from anon;
revoke all on all tables in schema public from anon;
do $$ declare r record; begin
 for r in select p.oid::regprocedure as signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and (p.proname ~ '(finance|invoice|billing|payment|discount|refund|compensation|payroll|fee_plan|referr)' or p.proname in('bootstrap_admin','set_role_permissions','handle_new_auth_user','request_staff_access','review_staff_access','set_user_operational_roles','save_academy_identity')) loop execute format('revoke execute on function %s from authenticated,anon,public',r.signature); end loop;
 for r in select viewname from pg_views where schemaname='public' loop execute format('revoke insert,update,delete on public.%I from authenticated,anon,academy_executor',r.viewname); end loop;
end $$;
reset search_path;

set search_path=public,extensions;
alter table public.branches add column slug text unique;
create or replace function public.list_my_branches() returns jsonb language sql stable security definer set search_path=pg_catalog,public as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',b.id,'name',b.name,'slug',b.slug,'organizationName',o.name,'isOwner',ow.user_id=auth.uid()) order by b.created_at),'[]') from public.branches b join public.branch_memberships m on m.branch_id=b.id and m.user_id=auth.uid() and m.is_active join public.organizations o on o.id=b.organization_id left join public.branch_owners ow on ow.organization_id=o.id where b.is_active;
$$;
create or replace function public.open_academy_branch(p_request_id uuid,p_name text,p_slug text,p_organization_name text default null,p_demo boolean default true) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare actor uuid:=auth.uid(); org uuid; branch uuid; yr uuid; cl uuid; prog uuid; offering uuid; rule uuid; entry record; subject uuid; payload jsonb; result jsonb; old public.branch_open_commands; prior text:=current_setting('public.branch_override',true); begin
 if actor is null or not exists(select 1 from auth.users where id=actor and email_confirmed_at is not null) then raise exception 'Verify your email before opening a branch.'; end if;
 if p_request_id is null or length(btrim(p_name)) not between 2 and 120 or p_slug!~'^[a-z0-9][a-z0-9-]{2,62}$' then raise exception 'Enter a branch name and a unique URL slug (3–63 lowercase letters, digits or hyphens).'; end if;
 payload:=jsonb_build_object('name',btrim(p_name),'slug',p_slug,'organizationName',p_organization_name,'demo',p_demo);
 perform pg_advisory_xact_lock(hashtextextended(actor::text,7));
 select * into old from public.branch_open_commands where user_id=actor and request_id=p_request_id;
 if found then if old.payload<>payload then raise exception 'Request already used for different input.'; end if; return old.result; end if;
 select organization_id into org from public.branch_owners where user_id=actor;
 if org is null then
  if exists(select 1 from public.branch_memberships where user_id=actor) then raise exception 'Only the institution owner can open branches.'; end if;
  if length(btrim(coalesce(p_organization_name,''))) not between 2 and 120 then raise exception 'Enter your institution name for the first branch.'; end if;
  insert into public.organizations(code,name,setup_completed_at,setup_identity_confirmed_at) values('ORG-'||substr(replace(gen_random_uuid()::text,'-',''),1,12),btrim(p_organization_name),now(),now()) returning id into org;
  insert into public.branch_owners values(org,actor);
 end if;
 insert into public.profiles(id,display_name) select actor,coalesce(nullif(raw_user_meta_data->>'full_name',''),email) from auth.users where id=actor on conflict(id) do nothing;
 insert into public.branches(organization_id,code,name,slug) values(org,upper(p_slug),btrim(p_name),p_slug) returning id into branch;
 insert into public.branch_memberships values(branch,actor,true);
 perform set_config('public.branch_override',branch::text,true);
 insert into public.user_role_assignments(profile_id,role_id,branch_id,assigned_by) select actor,id,branch,actor from public.system_roles where code='ADMIN';
 insert into public.academic_years(organization_id,name,starts_on,ends_on) values(org,extract(year from current_date)::text,date_trunc('year',current_date)::date,(date_trunc('year',current_date)+interval '1 year - 1 day')::date) returning id into yr;
 insert into public.classes(organization_id,code,name,sort_order) values(org,'CLASS_8','Class 8',8),(org,'CLASS_9','Class 9',9),(org,'CLASS_10','Class 10',10),(org,'CLASS_11','Class 11',11),(org,'CLASS_12','Class 12',12),(org,'JOB','Job Preparation',20);
 insert into public.programs(organization_id,code,name,description) values(org,'JR_SCHOLARSHIP','Junior Scholarship Programme','Starter academic template; review before opening intake.'),(org,'SSC','SSC Preparation Programme','Secondary school preparation.'),(org,'HSC','HSC Preparation Programme','Higher secondary preparation.'),(org,'JOB','Job Preparation Programme','Competitive examination preparation.');
 insert into public.subjects(organization_id,code,name) values(org,'BANGLA','Bangla'),(org,'ENGLISH','English'),(org,'MATH','Mathematics'),(org,'SCIENCE','General Science'),(org,'PHYSICS','Physics'),(org,'CHEMISTRY','Chemistry'),(org,'BIOLOGY','Biology'),(org,'ICT','ICT'),(org,'GK','General Knowledge'),(org,'REASONING','Reasoning'),(org,'BANGLADESH','Bangladesh Affairs');
 insert into public.academic_groups(organization_id,code,name) values(org,'GENERAL','General'),(org,'SCIENCE','Science'),(org,'HUMANITIES','Humanities'),(org,'BUSINESS','Business Studies');
 insert into public.guardian_relationships(organization_id,code,name) values(org,'FATHER','Father'),(org,'MOTHER','Mother'),(org,'GUARDIAN','Guardian');
 insert into public.lead_sources(organization_id,code,name) values(org,'WEB','Website'),(org,'WALK_IN','Walk-in'),(org,'REFERRAL','Referral');
 insert into public.business_rule_versions(domain,rule_key,version,status,payload,change_reason) values('academics','batch_capacity_policy',1,'ACTIVE','{"max_students":12}','Starter capacity; edit after branch review') returning id into rule;
 for entry in select * from(values('JR_SCHOLARSHIP','CLASS_8'),('SSC','CLASS_10'),('HSC','CLASS_12'),('JOB','JOB')) as starter(program_code,class_code) loop
  select id into cl from public.classes where scope_branch_id=branch and code=entry.class_code;
  select id into prog from public.programs where scope_branch_id=branch and code=entry.program_code;
  insert into public.programme_offerings(organization_id,branch_id,academic_year_id,class_id,program_id,code,name,status,is_website_visible,is_accepting_applications,created_by)
   select org,branch,yr,cl,prog,entry.program_code||'-'||extract(year from current_date),name,'ACTIVE',false,false,actor from public.programs where id=prog returning id into offering;
  insert into public.batches(organization_id,branch_id,academic_year_id,class_id,program_id,code,name,capacity,created_by,offering_id,capacity_policy_version_id) values(org,branch,yr,cl,prog,entry.program_code||'-A',entry.program_code||' Starter Batch',12,actor,offering,rule);
  insert into public.programme_offering_subjects(offering_id,subject_id,sort_order) select offering,id,row_number() over(order by code) from public.subjects where scope_branch_id=branch and(case entry.program_code when 'JR_SCHOLARSHIP' then code in('BANGLA','ENGLISH','MATH','SCIENCE') when 'SSC' then code in('BANGLA','ENGLISH','MATH','SCIENCE','ICT') when 'HSC' then code in('BANGLA','ENGLISH','PHYSICS','CHEMISTRY','BIOLOGY','ICT') else code in('BANGLA','ENGLISH','MATH','GK','REASONING','BANGLADESH') end);
 end loop;
 insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason) values(actor,branch,'BRANCH',branch::text,'OPEN_BRANCH','Opened with editable academic templates; no fictional people or finance.');
 result:=jsonb_build_object('id',branch,'slug',p_slug,'name',btrim(p_name));
 insert into public.branch_open_commands values(actor,p_request_id,payload,result);
 if p_demo then perform public.seed_demo_branch(); end if;
 perform set_config('public.branch_override',coalesce(prior,''),true);
 return result;
end $$;
create or replace function public.add_branch_member(p_email text,p_role_code text) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare branch uuid:=academy_private.current_branch_id(); target uuid; role uuid; begin
 if branch is null or not public.has_permission('system.users.manage') then raise exception 'Branch user management permission required.'; end if;
 if p_role_code not in('ADMIN','ACADEMIC_DIRECTOR','OPERATOR','TEACHER') then raise exception 'Choose an operational role.'; end if;
 select id into target from auth.users where lower(email)=lower(btrim(p_email)) and email_confirmed_at is not null;
 if target is null then raise exception 'This person must sign up and verify their email first.'; end if;
 select id into role from public.system_roles where code=p_role_code and is_active;
 if role is null then raise exception 'Role is unavailable.'; end if;
 insert into public.profiles(id,display_name) select id,coalesce(nullif(raw_user_meta_data->>'full_name',''),email) from auth.users where id=target on conflict(id) do nothing;
 insert into public.branch_memberships values(branch,target,true) on conflict(branch_id,user_id) do update set is_active=true;
 if exists(select 1 from public.branch_owners ow join public.branches b on b.organization_id=ow.organization_id where b.id=branch and ow.user_id=target) and p_role_code<>'ADMIN' then raise exception 'The institution owner must retain admin access.';end if;
 update public.user_role_assignments set is_active=false,effective_to=current_date where profile_id=target and scope_branch_id=branch and is_active;
 insert into public.user_role_assignments(profile_id,role_id,branch_id,assigned_by) values(target,role,branch,auth.uid());
 insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason) values(auth.uid(),branch,'USER',target::text,'ADD_BRANCH_MEMBER','Verified user added to this branch only.');
 return jsonb_build_object('id',target,'branchId',branch);
end $$;
revoke all on function public.list_my_branches(),public.open_academy_branch(uuid,text,text,text,boolean),public.add_branch_member(text,text) from public,anon;
grant execute on function public.list_my_branches(),public.open_academy_branch(uuid,text,text,text,boolean),public.add_branch_member(text,text) to authenticated;
reset search_path;

set search_path=public,extensions;
alter table public.admission_cases alter column fee_plan_version_id drop not null,alter column consent_required set default false;
drop trigger if exists admission_referral_choice_gate on public.admission_cases;
drop trigger if exists admission_workflow_evidence_gate on public.admission_cases;
create or replace function public.admission_command(p_input jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare actor uuid:=auth.uid();req uuid:=nullif(p_input->>'request_id','')::uuid;action text:=p_input->>'action';a public.admission_cases;b public.batches;o public.programme_offerings;p public.prospects;k public.admission_command_keys;student uuid;guardian uuid;enrollment uuid;result jsonb; begin
 if actor is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if req is null or length(btrim(coalesce(p_input->>'reason','')))<5 then raise exception 'A request identity and a verification note are required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));select * into k from public.admission_command_keys where request_id=req;
 if found then if k.actor_id<>actor or k.payload<>p_input then raise exception 'Request identity already used.'; end if; return k.result; end if;
 if action='CREATE' then
  select * into p from public.prospects where id=(p_input->>'prospect_id')::uuid for update;
  select * into b from public.batches where id=(p_input->>'batch_id')::uuid and is_active for update;
  select * into o from public.programme_offerings where id=b.offering_id and status='ACTIVE';
  if p.id is null or p.status in('LOST','CONVERTED') or o.id is null or o.id is distinct from(p_input->>'offering_id')::uuid or(p.current_class_id is not null and p.current_class_id<>o.class_id) then raise exception 'Choose an open enquiry and its matching active offering and batch.'; end if;
  if exists(select 1 from public.admission_cases where prospect_id=p.id and status<>'CANCELLED') then raise exception 'This enquiry already has an admission case.'; end if;
  if(select count(*) from public.enrollments where batch_id=b.id and status='ACTIVE')>=b.capacity then raise exception 'Selected batch is full.'; end if;
  insert into public.admission_cases(prospect_id,batch_id,identity_snapshot,created_by,consent_required,origin_prospect_id,origin)
   values(p.id,b.id,coalesce(p.application_snapshot,'{}'::jsonb)||jsonb_build_object('student_name',p.student_name,'student_name_bn',p.student_name_bn,'guardian_name',p.guardian_name,'mobile',p.mobile,'guardian_relationship',coalesce(p.guardian_relationship_snapshot,'Guardian'),'school_id',p.school_id,'school_name',p.school_name_snapshot,'gender',p.gender,'date_of_birth',p.date_of_birth,'guardian_address',p.guardian_address),actor,false,p.id,case when p.submitted_via='PUBLIC_WEB' then 'PUBLIC_APPLICATION' else 'PROSPECT_CONVERSION' end) returning * into a;
 else
  select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
  if a.id is null then raise exception 'Admission case is unavailable in this branch.'; end if;
  select * into b from public.batches where id=a.batch_id and is_active for update;
  select * into o from public.programme_offerings where id=b.offering_id and status='ACTIVE';
  if o.id is null then raise exception 'Choose an active academic placement.'; end if;
  if action='EDIT_DRAFT' and a.status in('DRAFT','READY') then
   if length(btrim(coalesce(p_input->>'student_name','')))<2 or length(btrim(coalesce(p_input->>'guardian_name','')))<2 or coalesce(p_input->>'mobile','')!~'^01[3-9][0-9]{8}$' then raise exception 'Enter valid student, guardian and mobile details.'; end if;
   update public.admission_cases set identity_snapshot=identity_snapshot||jsonb_build_object('student_name',btrim(p_input->>'student_name'),'guardian_name',btrim(p_input->>'guardian_name'),'mobile',p_input->>'mobile'),status='DRAFT' where id=a.id;
  elsif action='READY' and a.status='DRAFT' then
   if length(btrim(coalesce(a.identity_snapshot->>'student_name','')))<2 or length(btrim(coalesce(a.identity_snapshot->>'guardian_name','')))<2 or coalesce(a.identity_snapshot->>'mobile','')!~'^01[3-9][0-9]{8}$' then raise exception 'Verify student and guardian details first.'; end if;
   update public.admission_cases set status='READY' where id=a.id;
  elsif action='RETURN_TO_DRAFT' and a.status='READY' then update public.admission_cases set status='DRAFT' where id=a.id;
  elsif action in('FINALIZE','ACCEPT','ACTIVATE') and a.status='READY' then
   if(select count(*) from public.enrollments where batch_id=b.id and status='ACTIVE')>=b.capacity then raise exception 'Selected batch is full.'; end if;
   if a.existing_student then
    student:=a.student_id;
    if not exists(select 1 from public.students where id=student and status='ACTIVE' and merged_into_id is null) or exists(select 1 from public.enrollments where student_id=student and academic_year_id=b.academic_year_id and status='ACTIVE') then raise exception 'Existing student is unavailable or already enrolled in this academic year.';end if;
   else
   select * into p from public.prospects where id=a.prospect_id for update;
   if p.id is null or p.status in('CONVERTED','LOST') then raise exception 'Enquiry is no longer eligible.'; end if;
   if exists(select 1 from public.students s join public.student_guardians sg on sg.student_id=s.id join public.guardians g on g.id=sg.guardian_id where lower(s.full_name)=lower(a.identity_snapshot->>'student_name') and g.mobile=a.identity_snapshot->>'mobile') then raise exception 'A matching student already exists. Review the existing identity before continuing.'; end if;
   insert into public.students(organization_id,branch_id,full_name,name_bn,gender,date_of_birth,created_from_prospect_id,created_by) values(b.organization_id,b.branch_id,a.identity_snapshot->>'student_name',a.identity_snapshot->>'student_name_bn',a.identity_snapshot->>'gender',nullif(a.identity_snapshot->>'date_of_birth','')::date,p.id,actor) returning id into student;
   insert into public.guardians(organization_id,full_name,mobile,address,created_by) values(b.organization_id,a.identity_snapshot->>'guardian_name',a.identity_snapshot->>'mobile',a.identity_snapshot->>'guardian_address',actor) returning id into guardian;
   insert into public.student_guardians(student_id,guardian_id,relationship_snapshot,is_primary) values(student,guardian,a.identity_snapshot->>'guardian_relationship',true);
   end if;
   insert into public.enrollments(student_id,organization_id,branch_id,academic_year_id,class_id,program_id,batch_id,created_by) values(student,b.organization_id,b.branch_id,b.academic_year_id,b.class_id,b.program_id,b.id,actor) returning id into enrollment;
   update public.admission_cases set student_id=student,enrollment_id=enrollment,capacity_policy_version_id=b.capacity_policy_version_id,status='ACTIVE_ENROLLMENT' where id=a.id;
   update public.prospects set status='CONVERTED',converted_student_id=student,converted_at=now() where id=p.id;
  else raise exception 'This action is unavailable at the current admission stage.'; end if;
 end if;
 select jsonb_build_object('id',id,'status',status) into result from public.admission_cases where id=a.id;
 insert into public.audit_events(correlation_id,actor_profile_id,branch_id,entity_type,entity_id,action,reason,after_data) values(req,actor,academy_private.current_branch_id(),'ADMISSION',a.id::text,action,p_input->>'reason',result);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);return result;
end $$;
alter function public.admission_command(jsonb) owner to academy_executor;
-- The old stage dispatcher cannot bypass the new academic-only state machine.
revoke execute on function public.execute_admission_stage(jsonb) from authenticated,anon,public;
create or replace function public.academy_setup_status() returns jsonb language sql stable security definer set search_path=pg_catalog,public as $$
 select jsonb_build_object('completed',true,'ready',true,'academyName',o.name,'steps',jsonb_build_array(jsonb_build_object('id','directory','title','Review classes, subjects and programmes','href','/dashboard/crm/manage','done',exists(select 1 from public.classes)),jsonb_build_object('id','offering','title','Review programme offerings and public intake','href','/dashboard/academics/offerings','done',exists(select 1 from public.programme_offerings)),jsonb_build_object('id','batches','title','Review batch capacity','href','/dashboard/academics/batches','done',exists(select 1 from public.batches)))) from public.organizations o where public.has_permission('dashboard.view');
$$;
alter function public.academy_setup_status() owner to academy_executor;
reset search_path;

set search_path=public,extensions;
CREATE OR REPLACE FUNCTION public.admission_workspace()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_view boolean:=public.has_permission('admissions.view'); v_result jsonb;
begin
 if auth.uid() is null or not (v_view or public.has_permission('academics.view')) then raise exception 'Workspace access denied.'; end if;
 select jsonb_build_object(
  'offerings',coalesce((select jsonb_agg(jsonb_build_object('id',o.id,'name',o.name,'code',o.code,
      'classId',o.class_id,'className',c.name,'yearName',ay.name,'branchName',br.name))
    from public.programme_offerings o join public.classes c on c.id=o.class_id
    join public.academic_years ay on ay.id=o.academic_year_id left join public.branches br on br.id=o.branch_id
    join public.organizations org on org.id=o.organization_id
    where o.status='ACTIVE' ),'[]'::jsonb),
  'capacityLimit',(select (payload->>'max_students')::integer from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE'),
  'batches',coalesce((select jsonb_agg(jsonb_build_object(
    'id',b.id,'name',b.name,'code',b.code,'offeringId',b.offering_id,
    'offeringName',o.name,'classId',b.class_id,'className',c.name,
    'yearName',y.name,'branchName',br.name,'capacity',b.capacity,
    'isActive',b.is_active,
    'occupied',(select count(*) from public.enrollments e where e.batch_id=b.id and e.status='ACTIVE')
  ) order by y.starts_on desc,o.name,b.name)
    from public.batches b
    join public.programme_offerings o on o.id=b.offering_id
    join public.classes c on c.id=b.class_id
    join public.academic_years y on y.id=b.academic_year_id
    left join public.branches br on br.id=b.branch_id
  ),'[]'::jsonb),
  'prospects',case when v_view then coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.student_name,'number',p.prospect_no,'classId',p.current_class_id,'interestedOfferingId',p.interested_offering_id,'guardian',p.guardian_name,'mobile',p.mobile)) from public.prospects p where p.status not in ('CONVERTED','LOST') and not exists(select 1 from public.admission_cases a where a.prospect_id=p.id and a.status<>'CANCELLED')),'[]'::jsonb) else '[]'::jsonb end,
  'cases',case when v_view then coalesce((select jsonb_agg(x order by x->>'createdAt' desc) from (
    select jsonb_build_object('id',a.id,'number',a.admission_no,'status',a.status,'createdAt',a.created_at,
      'existingStudent',a.existing_student,'batchId',a.batch_id,'studentNo',s.student_no,'studentId',s.id,'name',a.identity_snapshot->>'student_name','nameBn',a.identity_snapshot->>'student_name_bn',
      'gender',a.identity_snapshot->>'gender','dateOfBirth',a.identity_snapshot->>'date_of_birth',
      'schoolName',a.identity_snapshot->>'school_name','schoolRoll',a.identity_snapshot->>'school_roll',
      'guardianAddress',a.identity_snapshot->>'guardian_address','alternateMobile',a.identity_snapshot->>'alternate_mobile',
      'guardianRelationship',a.identity_snapshot->>'guardian_relationship',
      'guardian',a.identity_snapshot->>'guardian_name','mobile',a.identity_snapshot->>'mobile',
      'feeVersion',f.version,'feePlanId',f.id,'policyVersion',r.version,'paymentRequirement',r.payload->>'payment_requirement',
      'components',coalesce((select jsonb_agg(jsonb_build_object('name',fc.name,'amount',fc.amount,'recurrence',fc.recurrence)) from public.fee_plan_components fc where fc.fee_plan_version_id=f.id),'[]'::jsonb),
      'invoice',case when i.id is null then null else jsonb_build_object('number',i.invoice_no,'total',i.total,'dueOn',i.due_on,'paid',bal.paid,'credits',bal.credits,'net',bal.net,'refunded',bal.refunded,'due',bal.due,'credit',bal.credit_balance) end,
      'receipts',coalesce((select jsonb_agg(jsonb_build_object('number',p.receipt_no,'amount',pa.amount,'postedAt',p.posted_at,'method',pm.name,'refunded',coalesce((select sum(ra.amount) from public.refund_authorizations ra join public.refund_payouts rp on rp.authorization_id=ra.id where ra.payment_id=p.id),0))) from public.admission_payment_allocations pa join public.admission_payments p on p.id=pa.payment_id join public.payment_methods pm on pm.id=p.payment_method_id where pa.invoice_id=i.id),'[]'::jsonb)
    ) as x
    from public.admission_cases a left join public.fee_plan_versions f on f.id=a.fee_plan_version_id
    left join public.students s on s.id=a.student_id left join public.business_rule_versions r on r.id=a.activation_policy_version_id
    left join public.admission_invoices i on i.admission_id=a.id and i.invoice_kind='INITIAL'
    left join lateral public.invoice_balance(i.id) bal on true
  ) rows),'[]'::jsonb) else '[]'::jsonb end,
  'paymentMethods',case when public.has_permission('finance.payments.post') then coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name)) from public.payment_methods where is_active),'[]'::jsonb) else '[]'::jsonb end
 ) into v_result;
 return v_result;
end; $function$;
alter function public.admission_workspace() owner to academy_executor;
CREATE OR REPLACE FUNCTION public.admission_offering_options()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case
    when auth.uid() is null or not public.has_permission('admissions.view')
      then '[]'::jsonb
    else coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',o.id,'name',o.name,'code',o.code,
        'classId',o.class_id,'className',c.name,
        'yearName',ay.name,'branchName',br.name,
        'feeReady',true
      ) order by ay.starts_on desc,o.name)
      from public.programme_offerings o
      join public.classes c on c.id=o.class_id
      join public.academic_years ay on ay.id=o.academic_year_id
      join public.organizations org on org.id=o.organization_id
      left join public.branches br on br.id=o.branch_id
      where o.status='ACTIVE'
    ),'[]'::jsonb)
  end;
$function$;
alter function public.admission_offering_options() owner to academy_executor;
CREATE OR REPLACE FUNCTION public.admission_case_detail(p_admission_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  result jsonb; charges jsonb; extras jsonb;
begin
  if auth.uid() is null or not public.has_permission('admissions.view') then
    raise exception 'Admission workspace access denied.';
  end if;

  select jsonb_build_object(
    'id', a.id,
    'number', a.admission_no,
    'status', a.status,
    'createdAt', a.created_at,
    'existingStudent', a.existing_student,
    'origin', a.origin,
    'originProspectId', a.origin_prospect_id,
    'batchId', a.batch_id,
    'batchName', b.name,
    'batchCode', b.code,
    'batchCapacity', b.capacity,
    'batchOccupied', (
      select count(*)
      from public.enrollments e
      where e.batch_id = b.id
        and e.status = 'ACTIVE'
    ),
    'offeringId', o.id,
    'offeringName', o.name,
    'className', cl.name,
    'yearName', ay.name,
    'branchName', br.name,
    'studentNo', s.student_no,
    'studentId', s.id,
    'name', a.identity_snapshot->>'student_name',
    'nameBn', a.identity_snapshot->>'student_name_bn',
    'gender', a.identity_snapshot->>'gender',
    'dateOfBirth', a.identity_snapshot->>'date_of_birth',
    'schoolName', a.identity_snapshot->>'school_name',
    'schoolRoll', a.identity_snapshot->>'school_roll',
    'guardianAddress', a.identity_snapshot->>'guardian_address',
    'alternateMobile', a.identity_snapshot->>'alternate_mobile',
    'guardianRelationship', a.identity_snapshot->>'guardian_relationship',
    'guardian', a.identity_snapshot->>'guardian_name',
    'mobile', a.identity_snapshot->>'mobile',
    'feeVersion', f.version,
    'feePlanId', f.id,
    'policyVersion', r.version,
    'paymentRequirement', r.payload->>'payment_requirement',
    'components', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'name', fc.name,
          'amount', fc.amount,
          'recurrence', fc.recurrence
        )
        order by fc.sort_order, fc.id
      )
      from public.fee_plan_components fc
      where fc.fee_plan_version_id = f.id
    ), '[]'::jsonb),
    'invoice', case
      when i.id is null then null
      else jsonb_build_object(
        'number', i.invoice_no,
        'total', i.total,
        'dueOn', i.due_on,
        'paid', bal.paid,
        'credits', bal.credits,
        'net', bal.net,
        'refunded', bal.refunded,
        'due', bal.due,
        'credit', bal.credit_balance
      )
    end,
    'receipts', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'number', p.receipt_no,
          'amount', pa.amount,
          'postedAt', p.posted_at,
          'method', pm.name,
          'refunded', coalesce((
            select sum(ra.amount)
            from public.refund_authorizations ra
            join public.refund_payouts rp
              on rp.authorization_id = ra.id
            where ra.payment_id = p.id
          ), 0)
        )
        order by p.posted_at, p.receipt_no
      )
      from public.admission_payment_allocations pa
      join public.admission_payments p
        on p.id = pa.payment_id
      join public.payment_methods pm
        on pm.id = p.payment_method_id
      where pa.invoice_id = i.id
    ), '[]'::jsonb)
  )
  into result
  from public.admission_cases a
  left join public.fee_plan_versions f
    on f.id = a.fee_plan_version_id
  join public.batches b
    on b.id = a.batch_id
  join public.programme_offerings o
    on o.id = b.offering_id
  join public.classes cl
    on cl.id = b.class_id
  join public.academic_years ay
    on ay.id = b.academic_year_id
  left join public.branches br
    on br.id = b.branch_id
  left join public.students s
    on s.id = a.student_id
  left join public.business_rule_versions r
    on r.id = a.activation_policy_version_id
  left join public.admission_invoices i
    on i.admission_id = a.id
   and i.invoice_kind = 'INITIAL'
  left join lateral public.invoice_balance(i.id) bal
    on true
  where a.id = p_admission_id;

  if result is null then
    raise exception 'Admission Case not found.';
  end if;

  result:=result||(select jsonb_build_object('academyRoll',s.academy_roll::text,'discountPercent',a.selected_discount_percent,'discountReason',a.discount_reason,'additionalDetails',
 jsonb_build_object('father_name',a.identity_snapshot->>'father_name','mother_name',a.identity_snapshot->>'mother_name',
 'birth_registration',a.identity_snapshot->>'birth_registration','permanent_address',a.identity_snapshot->>'permanent_address',
 'emergency_contact',a.identity_snapshot->>'emergency_contact','emergency_mobile',a.identity_snapshot->>'emergency_mobile',
 'previous_result',a.identity_snapshot->>'previous_result','learning_needs',a.identity_snapshot->>'learning_needs'))
 from public.admission_cases a left join public.students s on s.id=a.student_id where a.id=p_admission_id);

 select additional_charges into charges from public.admission_cases where id=p_admission_id;
 select coalesce(jsonb_agg(jsonb_build_object('name',value->>'name','amount',(value->>'amount')::numeric,'recurrence','ONE_TIME')),'[]') into extras from jsonb_array_elements(charges) where (value->>'is_active')::boolean;
 return result||jsonb_build_object('tuitionTotal',(select coalesce(sum(c.amount),0) from public.fee_plan_components c join public.admission_cases a on a.fee_plan_version_id=c.fee_plan_version_id where a.id=p_admission_id and c.charge_type='TUITION'),'additionalCharges',charges,'components',(result->'components')||extras);
end;
$function$;
alter function public.admission_case_detail (uuid) owner to academy_executor;
reset search_path;
set search_path=public,extensions;
create or replace function public.create_staff_admission_intake(p_input jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare actor uuid:=auth.uid();req uuid:=nullif(p_input->>'request_id','')::uuid;old public.staff_admission_intake_requests;prospect uuid;offering public.programme_offerings;result jsonb; begin
 if actor is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if req is null or octet_length(p_input::text)>16000 or length(btrim(coalesce(p_input->>'reason','')))<5 or length(btrim(coalesce(p_input->>'student_name','')))<2 or length(btrim(coalesce(p_input->>'guardian_name','')))<2 or coalesce(p_input->>'mobile','')!~'^01[3-9][0-9]{8}$' or not coalesce((p_input->>'consent_to_contact')::boolean,false) then raise exception 'Enter verified student, guardian, mobile and contact consent details.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));select * into old from public.staff_admission_intake_requests where request_id=req;
 if found then if old.actor_id<>actor or old.payload<>p_input then raise exception 'Request already used for different input.';end if;return jsonb_build_object('admission_id',old.admission_id);end if;
 select * into offering from public.programme_offerings where id=(p_input->>'offering_id')::uuid and status='ACTIVE';
 if offering.id is null then raise exception 'Choose an active programme offering.';end if;
 insert into public.prospects(organization_id,branch_id,student_name,student_name_bn,guardian_name,mobile,current_class_id,interested_offering_id,guardian_address,guardian_relationship_snapshot,date_of_birth,gender,school_name_snapshot,school_roll,alternate_mobile,consent_to_contact,submitted_via,application_snapshot)
 values(offering.organization_id,offering.branch_id,btrim(p_input->>'student_name'),nullif(p_input->>'student_name_bn',''),btrim(p_input->>'guardian_name'),p_input->>'mobile',offering.class_id,offering.id,nullif(p_input->>'guardian_address',''),p_input->>'guardian_relationship',nullif(p_input->>'date_of_birth','')::date,nullif(p_input->>'gender',''),nullif(p_input->>'school_name',''),nullif(p_input->>'school_roll',''),nullif(p_input->>'alternate_mobile',''),true,'STAFF_INTAKE',p_input) returning id into prospect;
 result:=public.admission_command(jsonb_build_object('request_id',req,'action','CREATE','prospect_id',prospect,'batch_id',p_input->>'batch_id','offering_id',offering.id,'reason',p_input->>'reason'));
 update public.admission_cases set origin='DIRECT_STAFF',origin_prospect_id=null where id=(result->>'id')::uuid;
 insert into public.staff_admission_intake_requests(request_id,actor_id,payload,prospect_id,admission_id) values(req,actor,p_input,prospect,(result->>'id')::uuid);
 return jsonb_build_object('admission_id',result->>'id','admission_no',(select admission_no from public.admission_cases where id=(result->>'id')::uuid));
end $$;
alter function public.create_staff_admission_intake(jsonb) owner to academy_executor;
-- Global account state must not change when one branch retires a staff placement.

set search_path=public,extensions;
create function academy_private.public_branch_id() returns uuid language sql stable security definer set search_path=pg_catalog,public as $$
 select id from public.branches where slug=coalesce(nullif(current_setting('request.headers',true),''),'{}')::jsonb->>'x-academy-public-branch' and is_active;
$$;
create function public.public_academic_directory() returns jsonb language sql stable security definer set search_path=pg_catalog,public as $$
 select jsonb_build_object('classes',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by sort_order) from public.classes where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'programs',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.programs where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'subjects',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.subjects where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'schools',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.schools where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'sources',coalesce((select jsonb_agg(jsonb_build_object('code',code,'name',name)) from public.lead_sources where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'relationships',coalesce((select jsonb_agg(jsonb_build_object('code',code,'name',name)) from public.guardian_relationships where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'));
$$;
create or replace function public.submit_public_interest(p_payload jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare branch public.branches;chosen public.programme_offerings;prospect public.prospects;mobile_value text;item text;today date;prior text:=current_setting('public.branch_override',true);begin
 select * into branch from public.branches where id=academy_private.public_branch_id() and is_active;
 if branch.id is null then raise exception 'The public is not accepting applications yet.';end if;
 if jsonb_typeof(p_payload) is distinct from 'object' or octet_length(p_payload::text)>16000 or length(btrim(coalesce(p_payload->>'student_name','')))<2 or length(btrim(coalesce(p_payload->>'guardian_name','')))<2 then raise exception 'Enter valid student and guardian names.';end if;
 mobile_value:=regexp_replace(coalesce(p_payload->>'mobile',''),'\D','','g');if mobile_value!~'^01[3-9][0-9]{8}$' then raise exception 'A valid mobile number is required.';end if;
 if not coalesce((p_payload->>'consent_to_contact')::boolean,false) then raise exception 'Consent to contact is required.';end if;
 if not exists(select 1 from public.classes where id=nullif(p_payload->>'class_id','')::uuid and scope_branch_id=branch.id and is_active) then raise exception 'Selected class is not available.';end if;
 if nullif(p_payload->>'school_id','') is not null and not exists(select 1 from public.schools where id=(p_payload->>'school_id')::uuid and scope_branch_id=branch.id and is_active) then raise exception 'Selected school is not available.';end if;
 for item in select jsonb_array_elements_text(coalesce(p_payload->'program_ids','[]')) loop if not exists(select 1 from public.programs where id=item::uuid and scope_branch_id=branch.id and is_active) then raise exception 'One selected program is not available.';end if;end loop;
 for item in select jsonb_array_elements_text(coalesce(p_payload->'subject_ids','[]')) loop if not exists(select 1 from public.subjects where id=item::uuid and scope_branch_id=branch.id and is_active) then raise exception 'One selected subject is not available.';end if;end loop;
 if nullif(p_payload->>'offering_id','') is not null or p_payload->>'intent'='admission' then
  select * into chosen from public.programme_offerings where id=nullif(p_payload->>'offering_id','')::uuid and scope_branch_id=branch.id and status='ACTIVE' and is_website_visible;
  if chosen.id is null then raise exception 'Selected programme offering is not available.';end if;
  today:=timezone(branch.timezone,now())::date;
  if not chosen.is_accepting_applications or chosen.applications_open_on>today or chosen.applications_close_on<today then raise exception 'Applications are closed for this programme offering.';end if;
  if chosen.class_id<>(p_payload->>'class_id')::uuid then raise exception 'Selected class does not match the chosen programme offering.';end if;
  for item in select jsonb_array_elements_text(coalesce(p_payload->'subject_ids','[]')) loop if not exists(select 1 from public.programme_offering_subjects where offering_id=chosen.id and subject_id=item::uuid) then raise exception 'One selected subject is not part of the chosen programme offering.';end if;end loop;
 end if;
 perform pg_advisory_xact_lock(hashtextextended(branch.id::text||mobile_value,3));
 if exists(select 1 from public.prospects where scope_branch_id=branch.id and mobile=mobile_value and lower(student_name)=lower(btrim(p_payload->>'student_name')) and created_at>now()-interval '2 minutes') then raise exception 'A similar interest request was submitted recently. Please wait before submitting again.';end if;
 -- Explicit scope is mandatory for anonymous projection/intake; no operational read grants.
 insert into public.prospects(scope_branch_id,organization_id,branch_id,student_name,student_name_bn,guardian_name,guardian_relationship_snapshot,mobile,alternate_mobile,current_class_id,interested_offering_id,school_id,school_name_snapshot,area_snapshot,guardian_address,notes,referral_note,consent_to_contact,submitted_via,submission_intent,application_snapshot,date_of_birth,gender,school_roll)
 values(branch.id,branch.organization_id,branch.id,btrim(p_payload->>'student_name'),nullif(p_payload->>'student_name_bn',''),btrim(p_payload->>'guardian_name'),p_payload->>'guardian_relationship',mobile_value,nullif(p_payload->>'alternate_mobile',''),(p_payload->>'class_id')::uuid,chosen.id,nullif(p_payload->>'school_id','')::uuid,nullif(p_payload->>'school_name_snapshot',''),p_payload->>'area',p_payload->>'guardian_address',p_payload->>'notes',p_payload->>'referral_note',true,'PUBLIC_WEB',case when p_payload->>'intent'='admission' then 'admission' else 'interest' end,p_payload||'{"verification":"UNVERIFIED"}'::jsonb,nullif(p_payload->>'date_of_birth','')::date,nullif(p_payload->>'gender',''),nullif(p_payload->>'school_roll','')) returning * into prospect;
 insert into public.audit_events(scope_branch_id,branch_id,entity_type,entity_id,action,metadata) values(branch.id,branch.id,'PROSPECT',prospect.id::text,'RECEIVE_UNVERIFIED_APPLICATION','{"verification":"UNVERIFIED"}');
 return jsonb_build_object('prospect_no',prospect.prospect_no);
end $$;
revoke all on function public.public_academic_directory(),public.submit_public_interest(jsonb) from public;
grant execute on function public.public_academic_directory(),public.submit_public_interest(jsonb) to anon,authenticated;
reset search_path;

set search_path=public,extensions;
CREATE OR REPLACE FUNCTION public.list_public_programme_offerings()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(jsonb_agg(to_jsonb(x) order by x.showcase_sort_order, x.created_at), '[]'::jsonb)
  from (
    select o.id, o.code, o.name, o.class_id, o.program_id, o.group_id,
      o.branch_id, o.academic_year_id, ay.name as academic_year_name,
      b.name as branch_name, c.name as class_name, ag.name as group_name,
      o.showcase_title, o.showcase_title_bn, o.showcase_description,
      o.showcase_description_bn, o.showcase_eyebrow, o.showcase_eyebrow_bn,
      o.showcase_icon, o.showcase_sort_order,
      o.public_schedule, o.public_schedule_bn, o.public_requirements,
      o.public_requirements_bn, o.admission_policy, o.admission_policy_bn,
      (select count(*)::integer from public.batches bb where bb.offering_id=o.id and bb.is_active) as active_batch_count,
      (select coalesce(sum(bb.capacity),0)::integer from public.batches bb where bb.offering_id=o.id and bb.is_active) as current_total_seats,
      (select coalesce(sum(greatest(bb.capacity-(select count(*) from public.enrollments e where e.batch_id=bb.id and e.status='ACTIVE'),0)),0)::integer
       from public.batches bb where bb.offering_id=o.id and bb.is_active) as current_open_seats,
      (o.is_accepting_applications
        and (o.applications_open_on is null or o.applications_open_on <= local_day.today)
        and (o.applications_close_on is null or o.applications_close_on >= local_day.today)
      ) as is_accepting_applications,
      case when not o.is_accepting_applications then 'CLOSED'
        when o.applications_open_on > local_day.today then 'UPCOMING'
        when o.applications_close_on < local_day.today then 'CLOSED'
        else 'OPEN' end as application_state,
      o.applications_open_on, o.applications_close_on, o.created_at,
      (select coalesce(jsonb_agg(jsonb_build_object('id', s.id, 'code', s.code, 'name', s.name)
        order by pos.sort_order), '[]'::jsonb)
       from public.programme_offering_subjects pos
       join public.subjects s on s.id = pos.subject_id
       where pos.offering_id = o.id and s.is_active) as subjects,
      (select jsonb_build_object('billing_cycle', fp.billing_cycle,
        'currency_code', fp.currency_code,
        'components', coalesce((select jsonb_agg(jsonb_build_object(
          'code', fc.code, 'name', fc.name, 'amount', fc.amount,
          'charge_type', fc.charge_type, 'recurrence', fc.recurrence)
          order by fc.sort_order) from public.fee_plan_components fc
          where fc.fee_plan_version_id = fp.id), '[]'::jsonb))
       from public.fee_plan_versions fp
       where fp.offering_id = o.id and fp.status = 'ACTIVE' limit 1) as fee_plan
    from public.programme_offerings o
    join public.organizations org on org.id = o.organization_id
    join public.academic_years ay on ay.id = o.academic_year_id
    join public.branches b on b.id = o.branch_id
    join public.classes c on c.id = o.class_id
    left join public.academic_groups ag on ag.id = o.group_id
    cross join lateral (select timezone(org.timezone, now())::date as today) local_day
    where o.scope_branch_id=academy_private.public_branch_id() and b.is_active and o.is_website_visible and o.status = 'ACTIVE'
    order by o.showcase_sort_order, o.created_at limit 24
  ) x;
$function$;
alter function public.list_public_programme_offerings() owner to postgres;
grant execute on function public.list_public_programme_offerings() to anon,authenticated;
reset search_path;

set search_path=public,extensions;
-- Internal staff lookup can resolve an existing verified account, without granting API clients auth table access.
grant select on auth.users to academy_executor;
create or replace function public.save_academy_identity(p_input jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare branch uuid:=academy_private.current_branch_id();org uuid;owner uuid;before_data jsonb;begin
 if branch is null or not public.has_permission('system.settings.manage') then raise exception 'Branch settings permission required.';end if;
 if length(btrim(coalesce(p_input->>'name',''))) not between 2 and 160 or length(btrim(coalesce(p_input->>'branch_name',''))) not between 2 and 160 then raise exception 'Enter institution and branch names.';end if;
 select organization_id into org from public.branches where id=branch;select user_id into owner from public.branch_owners where organization_id=org;
 if (select name from public.organizations where id=org)<>btrim(p_input->>'name') then
  if owner is distinct from auth.uid() then raise exception 'Only the institution owner can change the institution name.';end if;
  update public.organizations set name=btrim(p_input->>'name') where id=org;
 end if;
 select to_jsonb(b) into before_data from public.branches b where id=branch;
 update public.branches set name=btrim(p_input->>'branch_name') where id=branch;
 insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason,before_data,after_data) values(auth.uid(),branch,'BRANCH',branch::text,'UPDATE_IDENTITY','Reviewed institution and branch names',before_data,p_input);
 return jsonb_build_object('id',branch);
end $$;
revoke all on function public.save_academy_identity(jsonb) from public,anon;
grant execute on function public.save_academy_identity(jsonb) to authenticated;
-- Keep the approved attendance command; compensation is outside this version.
alter function public.workforce_command(jsonb) rename to legacy_attendance_command;
revoke execute on function public.legacy_attendance_command(jsonb) from authenticated,anon,public;
create function public.workforce_command(p_input jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$ begin
 if p_input->>'action' is distinct from 'RECORD_ATTENDANCE' then raise exception 'Only attendance is available in this version.';end if;
 return public.legacy_attendance_command(p_input);
end $$;
alter function public.workforce_command(jsonb) owner to academy_executor;
revoke execute on function public.workforce_command(jsonb) from public,anon;
grant execute on function public.workforce_command(jsonb) to authenticated;
-- Avoid changing a shared login's status when a branch retires a staff record.
-- Shared role templates remain immutable; membership controls branch access.
create function public.remove_branch_member(p_email text) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare branch uuid:=academy_private.current_branch_id();target uuid;begin
 if branch is null or not public.has_permission('system.users.manage') then raise exception 'Branch user management permission required.';end if;
 select u.id into target from auth.users u join public.branch_memberships m on m.user_id=u.id and m.branch_id=branch where lower(u.email)=lower(btrim(p_email));
 if target is null then raise exception 'This person is not a member of this branch.';end if;
 if target=auth.uid() or exists(select 1 from public.branch_owners o join public.branches b on b.organization_id=o.organization_id where b.id=branch and o.user_id=target) then raise exception 'The owner and your own active membership cannot be removed.';end if;
 update public.branch_memberships set is_active=false where user_id=target and branch_id=branch;
 update public.user_role_assignments set is_active=false,effective_to=current_date where profile_id=target and scope_branch_id=branch;
 insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason) values(auth.uid(),branch,'USER',target::text,'REMOVE_BRANCH_MEMBER','Access removed from this branch only.');return jsonb_build_object('id',target);
end $$;
revoke all on function public.remove_branch_member(text) from public,anon;
grant execute on function public.remove_branch_member(text) to authenticated;
reset search_path;
update public.system_roles set is_active=false where code not in('ADMIN','ACADEMIC_DIRECTOR','OPERATOR','TEACHER');
update public.system_roles set description='Admissions, CRM and routine academic operations.' where code='OPERATOR';
delete from public.permissions where code ~ '^(finance|accounting|compensation|referrals)\.';
alter function public.save_academy_identity(jsonb) owner to postgres;
alter function public.submit_public_interest(jsonb) owner to postgres;

set search_path=public,extensions;
CREATE OR REPLACE FUNCTION public.student_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 actor uuid:=auth.uid();req uuid:=(p_input->>'request_id')::uuid;action text:=p_input->>'action';reason text:=btrim(coalesce(p_input->>'reason',''));
 key public.admission_command_keys;s public.students;target public.students;a public.admission_cases;b public.batches;dest public.batches;
 fee public.fee_plan_versions;guardian record;policy public.business_rule_versions;e public.enrollments;
 sid uuid:=(p_input->>'student_id')::uuid;tid uuid:=(p_input->>'target_id')::uuid;eid uuid;aid uuid;today date;result jsonb;snapshot jsonb;
begin
 if actor is null or not public.has_permission('students.view') then raise exception 'Student access required.'; end if;
 if req is null or length(reason) not between 5 and 500 then raise exception 'Request identity and a reason of 5–500 characters required.'; end if;
 if action='CREATE_EXISTING' then
  if not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 elsif action in('TRANSFER','MERGE') then
  if not public.has_permission('students.manage') then raise exception 'Student management permission required.'; end if;
 else raise exception 'Unsupported student action.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into key from public.admission_command_keys where request_id=req;
 if found then
  if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity already used.'; end if;
  return key.result;
 end if;
 if action='TRANSFER' then
  aid:=(p_input->>'admission_id')::uuid;
  select * into a from public.admission_cases where id=aid for update;
  if a.id is null or a.student_id is distinct from sid then raise exception 'Admission does not belong to this student.'; end if;
 end if;
 perform 1 from public.students where id in(sid,tid) order by id for update;
 select * into s from public.students where id=sid;
 if s.id is null or s.merged_into_id is not null or s.status='ARCHIVED' then raise exception 'Use an existing canonical student.'; end if;
 select timezone(timezone,now())::date into today from public.organizations where id=s.organization_id;
  if action='CREATE_EXISTING' then
   select * into b from public.batches where id=(p_input->>'batch_id')::uuid and is_active for update;
   if b.id is null or b.organization_id<>s.organization_id or not exists(select 1 from public.programme_offerings where id=b.offering_id and status='ACTIVE') then raise exception 'Select an active offering-linked batch in this organization.';end if;
   if exists(select 1 from public.enrollments where student_id=s.id and academic_year_id=b.academic_year_id and status='ACTIVE')
    or exists(select 1 from public.admission_cases ac join public.batches ba on ba.id=ac.batch_id where ac.student_id=s.id and ba.academic_year_id=b.academic_year_id and ac.status<>'CANCELLED') then
    raise exception 'An open admission or active enrollment already exists for this academic year. Use transfer or finish cancellation first.';end if;
   select * into policy from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE';
   if policy.id is null then raise exception 'Capacity policy missing.';end if;
   if (select count(*) from public.enrollments where batch_id=b.id and status='ACTIVE')>=least(b.capacity,(policy.payload->>'max_students')::integer) then raise exception 'Selected batch is full.';end if;
   select g.full_name,g.mobile,sg.relationship_snapshot into guardian from public.student_guardians sg join public.guardians g on g.id=sg.guardian_id where sg.student_id=s.id and sg.is_primary;
   if guardian.full_name is null then raise exception 'A primary guardian is required.';end if;
   insert into public.admission_cases(batch_id,fee_plan_version_id,student_id,existing_student,identity_snapshot,created_by,origin,consent_required)
   values(b.id,fee.id,s.id,true,jsonb_build_object('student_name',s.full_name,'guardian_name',guardian.full_name,'mobile',guardian.mobile,'guardian_relationship',coalesce(guardian.relationship_snapshot,'Guardian'),'school_id',s.school_id,'school_name',s.school_name_snapshot),actor,'EXISTING_STUDENT',false) returning id into aid;
   result:=jsonb_build_object('id',aid,'message','Enrollment draft created using the existing Student ID. Review and accept it in Admissions.');
  elsif action='TRANSFER' then
   if a.status<>'ACTIVE_ENROLLMENT' then raise exception 'Only an active enrollment can transfer.';end if;
   select * into e from public.enrollments where id=a.enrollment_id and status='ACTIVE';
   if e.id is null then raise exception 'Active enrollment not found.';end if;
   eid:=(p_input->>'batch_id')::uuid;
   perform 1 from public.batches where id in(a.batch_id,eid) order by id for update;
   select * into b from public.batches where id=a.batch_id;
   select * into dest from public.batches where id=eid and is_active;
   if dest.id is null or dest.id=b.id or dest.offering_id is distinct from b.offering_id or dest.organization_id<>b.organization_id then raise exception 'Transfer requires a different active batch in the same offering. Academic placement remains unchanged.';end if;
   select * into policy from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE';
   if policy.id is null then raise exception 'Capacity policy missing.';end if;
   if (select count(*) from public.enrollments where batch_id=dest.id and status='ACTIVE')>=least(dest.capacity,(policy.payload->>'max_students')::integer) then raise exception 'Destination batch is full under the current capacity policy.';end if;
    update public.enrollments set status='WITHDRAWN',ended_on=today where id=e.id;
    insert into public.enrollments(student_id,organization_id,branch_id,academic_year_id,class_id,program_id,batch_id,admission_date,status,created_by)
    values(s.id,dest.organization_id,dest.branch_id,dest.academic_year_id,dest.class_id,dest.program_id,dest.id,today,'ACTIVE',actor) returning id into eid;
    insert into public.enrollment_transfers(student_id,admission_id,from_enrollment_id,to_enrollment_id,from_batch_id,to_batch_id,authorized_by,authorization_reason,capacity_policy_version_id,transferred_on)
    values(s.id,a.id,e.id,eid,b.id,dest.id,actor,reason,policy.id,today);
    update public.admission_cases set batch_id=dest.id,enrollment_id=eid,capacity_policy_version_id=policy.id where id=a.id;
   result:=jsonb_build_object('id',a.id,'message','Batch transfer completed; academic history preserved.');
  elsif action='MERGE' then
   select * into target from public.students where id=tid;
   if target.id is null or target.id=s.id or target.organization_id<>s.organization_id or target.merged_into_id is not null or target.status='ARCHIVED' then raise exception 'Select a different canonical student in this organization.';end if;
   if exists(select 1 from public.students where merged_into_id=s.id) then raise exception 'A canonical identity with linked duplicates cannot be merged again.';end if;
   if exists(select 1 from public.enrollments where student_id=s.id and status='ACTIVE') or exists(select 1 from public.admission_cases where student_id=s.id and status<>'CANCELLED') then raise exception 'Resolve the duplicate identity’s open admissions and enrollments before merging.';end if;
   if lower(btrim(s.full_name))<>lower(btrim(target.full_name)) and not exists(
    select 1 from public.student_guardians x join public.guardians gx on gx.id=x.guardian_id cross join public.student_guardians y join public.guardians gy on gy.id=y.guardian_id
    where x.student_id=s.id and y.student_id=target.id and gx.mobile=gy.mobile) then raise exception 'No matching name or guardian mobile. Verify the identities before requesting a merge.';end if;
   if p_input->>'confirmed_same_person' is distinct from 'true' then raise exception 'Confirm these identities belong to the same student.'; end if;
    insert into public.student_merges(source_id,target_id,authorized_by,authorization_reason,source_snapshot,target_snapshot) values(s.id,target.id,actor,reason,to_jsonb(s),to_jsonb(target));
    update public.students set merged_into_id=target.id,status='ARCHIVED' where id=s.id;
    -- History and guardian links retain their original IDs and appear in the canonical profile.
   result:=jsonb_build_object('id',target.id,'message','Duplicate archived; original records and academic history preserved.');
  end if;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,metadata)
 values(req,actor,'STUDENT',s.id::text,action,reason,to_jsonb(s),result,p_input);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);
 return result;
end;
$function$;
alter function public.student_command(jsonb) owner to academy_executor;
reset search_path;

set search_path=public,extensions;
CREATE OR REPLACE FUNCTION public.create_staff_member(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_staff public.staff;
  v_role public.staff_roles;
  v_branch public.branches;
  v_subject_id uuid;
  v_subjects jsonb;
  v_mobile text;
  v_joined_on date;
  v_correlation_id uuid := gen_random_uuid();
  v_actor_role text;
begin
  if v_actor is null or not public.has_permission('staff.manage') then
    raise exception 'You are not authorized to create Staff identities.';
  end if;

  if p_input is null or jsonb_typeof(p_input) <> 'object' then
    raise exception 'Staff request must be a JSON object.';
  end if;

  if nullif(btrim(coalesce(p_input->>'full_name','')), '') is null then
    raise exception 'Full name is required.';
  end if;

  select * into v_role
  from public.staff_roles
  where code=upper(btrim(coalesce(p_input->>'staff_role_code','')))
    and is_active;

  if v_role.id is null then
    raise exception 'Select a valid Staff role.';
  end if;

  if nullif(p_input->>'branch_id','') is not null then
    begin
      select * into v_branch
      from public.branches
      where id=(p_input->>'branch_id')::uuid
        and is_active;
    exception when others then
      raise exception 'Selected branch is invalid.';
    end;
  else
    select * into v_branch
    from public.branches
    where id=academy_private.current_branch_id() and is_active
    order by created_at asc
    limit 1;
  end if;

  if v_branch.id is null then
    raise exception 'An active branch is required.';
  end if;

  begin
    v_joined_on := coalesce(
      nullif(p_input->>'joined_on','')::date,
      current_date
    );
  exception when others then
    raise exception 'Joining date is invalid.';
  end;

  v_mobile := nullif(btrim(coalesce(p_input->>'mobile','')), '');

  if v_mobile is not null and exists (
    select 1
    from public.staff s
    where regexp_replace(coalesce(s.mobile,''), '\D', '', 'g')
        = regexp_replace(v_mobile, '\D', '', 'g')
      and s.status in ('ACTIVE','ON_LEAVE')
  ) then
    raise exception 'Another active Staff identity already uses this mobile number.';
  end if;

  insert into public.staff(
    branch_id,
    full_name,
    mobile,
    alternate_mobile,
    email,
    address,
    emergency_contact_name,
    emergency_contact_mobile,
    joined_on,
    status,
    notes,
    created_by
  )
  values(
    v_branch.id,
    btrim(p_input->>'full_name'),
    v_mobile,
    nullif(btrim(coalesce(p_input->>'alternate_mobile','')), ''),
    nullif(lower(btrim(coalesce(p_input->>'email',''))), ''),
    nullif(btrim(coalesce(p_input->>'address','')), ''),
    nullif(btrim(coalesce(p_input->>'emergency_contact_name','')), ''),
    nullif(btrim(coalesce(p_input->>'emergency_contact_mobile','')), ''),
    v_joined_on,
    'ACTIVE',
    nullif(btrim(coalesce(p_input->>'notes','')), ''),
    v_actor
  )
  returning * into v_staff;

  insert into public.staff_role_assignments(
    staff_id,
    staff_role_id,
    branch_id,
    effective_from,
    is_primary,
    assigned_by
  )
  values(
    v_staff.id,
    v_role.id,
    v_branch.id,
    v_joined_on,
    true,
    v_actor
  );

  v_subjects := coalesce(p_input->'subject_ids','[]'::jsonb);

  if jsonb_typeof(v_subjects) <> 'array' then
    raise exception 'Teaching subject selection must be an array.';
  end if;

  if not v_role.is_teaching_role
     and jsonb_array_length(v_subjects) > 0 then
    raise exception 'Teaching subjects can only be selected for a teaching Staff role.';
  end if;

  for v_subject_id in
    select value::text::uuid
    from jsonb_array_elements_text(v_subjects)
  loop
    if not exists (
      select 1 from public.subjects
      where id=v_subject_id and is_active
    ) then
      raise exception 'One selected subject is not available.';
    end if;

    insert into public.staff_subject_assignments(
      staff_id,
      subject_id,
      effective_from,
      assigned_by
    )
    values(
      v_staff.id,
      v_subject_id,
      v_joined_on,
      v_actor
    );
  end loop;

  select sr.code into v_actor_role
  from public.user_role_assignments ura
  join public.system_roles sr on sr.id=ura.role_id
  where ura.profile_id=v_actor
    and ura.is_active
    and ura.effective_from<=current_date
    and (ura.effective_to is null or ura.effective_to>=current_date)
  order by case when sr.code='ADMIN' then 0 else 1 end, sr.code
  limit 1;

  insert into public.audit_events(
    correlation_id,
    actor_profile_id,
    actor_staff_id,
    actor_role_code,
    branch_id,
    entity_type,
    entity_id,
    action,
    after_data,
    metadata
  )
  values(
    v_correlation_id,
    v_actor,
    (select id from public.staff where profile_id=v_actor limit 1),
    v_actor_role,
    v_branch.id,
    'STAFF',
    v_staff.id::text,
    'CREATE',
    jsonb_build_object(
      'staff_no',v_staff.staff_no,
      'full_name',v_staff.full_name,
      'staff_role_code',v_role.code,
      'joined_on',v_staff.joined_on,
      'status',v_staff.status
    ),
    jsonb_build_object(
      'workflow','CREATE_STAFF_MEMBER',
      'subject_count',jsonb_array_length(v_subjects)
    )
  );

  return jsonb_build_object(
    'staff_id',v_staff.id,
    'staff_no',v_staff.staff_no,
    'correlation_id',v_correlation_id
  );
end;
$function$;
alter function public.create_staff_member(jsonb) owner to academy_executor;
grant execute on function public.create_staff_member(jsonb) to authenticated;
reset search_path;
update public.staff_roles set is_active=false where code='ACCOUNTANT';

delete from public.role_permissions where permission_id in(select id from public.permissions where code like '%compensation%' or code like '%payroll%');
delete from public.permissions where code like '%compensation%' or code like '%payroll%';

set search_path=public,extensions;
CREATE OR REPLACE FUNCTION public.admission_case_detail(p_admission_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  result jsonb; charges jsonb; extras jsonb;
begin
  if auth.uid() is null or not public.has_permission('admissions.view') then
    raise exception 'Admission workspace access denied.';
  end if;

  select jsonb_build_object(
    'id', a.id,
    'number', a.admission_no,
    'status', a.status,
    'createdAt', a.created_at,
    'existingStudent', a.existing_student,
    'origin', a.origin,
    'originProspectId', a.origin_prospect_id,
    'batchId', a.batch_id,
    'batchName', b.name,
    'batchCode', b.code,
    'batchCapacity', b.capacity,
    'batchOccupied', (
      select count(*)
      from public.enrollments e
      where e.batch_id = b.id
        and e.status = 'ACTIVE'
    ),
    'offeringId', o.id,
    'offeringName', o.name,
    'className', cl.name,
    'yearName', ay.name,
    'branchName', br.name,
    'studentNo', s.student_no,
    'studentId', s.id,
    'name', a.identity_snapshot->>'student_name',
    'nameBn', a.identity_snapshot->>'student_name_bn',
    'gender', a.identity_snapshot->>'gender',
    'dateOfBirth', a.identity_snapshot->>'date_of_birth',
    'schoolName', a.identity_snapshot->>'school_name',
    'schoolRoll', a.identity_snapshot->>'school_roll',
    'guardianAddress', a.identity_snapshot->>'guardian_address',
    'alternateMobile', a.identity_snapshot->>'alternate_mobile',
    'guardianRelationship', a.identity_snapshot->>'guardian_relationship',
    'guardian', a.identity_snapshot->>'guardian_name',
    'mobile', a.identity_snapshot->>'mobile',
    'feeVersion', f.version,
    'feePlanId', f.id,
    'policyVersion', r.version,
    'paymentRequirement', r.payload->>'payment_requirement',
    'components', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'name', fc.name,
          'amount', fc.amount,
          'recurrence', fc.recurrence
        )
        order by fc.sort_order, fc.id
      )
      from public.fee_plan_components fc
      where fc.fee_plan_version_id = f.id
    ), '[]'::jsonb),
    'invoice', case
      when i.id is null then null
      else jsonb_build_object(
        'id', i.id, 'number', i.invoice_no,
        'total', i.total,
        'dueOn', i.due_on,
        'paid', bal.paid,
        'credits', bal.credits,
        'net', bal.net,
        'refunded', bal.refunded,
        'due', bal.due,
        'credit', bal.credit_balance
      )
    end,
    'receipts', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'number', p.receipt_no,
          'amount', pa.amount,
          'postedAt', p.posted_at,
          'method', pm.name,
          'refunded', coalesce((
            select sum(ra.amount)
            from public.refund_authorizations ra
            join public.refund_payouts rp
              on rp.authorization_id = ra.id
            where ra.payment_id = p.id
          ), 0)
        )
        order by p.posted_at, p.receipt_no
      )
      from public.admission_payment_allocations pa
      join public.admission_payments p
        on p.id = pa.payment_id
      join public.payment_methods pm
        on pm.id = p.payment_method_id
      where pa.invoice_id = i.id
    ), '[]'::jsonb)
  )
  into result
  from public.admission_cases a
  left join public.fee_plan_versions f
    on f.id = a.fee_plan_version_id
  join public.batches b
    on b.id = a.batch_id
  join public.programme_offerings o
    on o.id = b.offering_id
  join public.classes cl
    on cl.id = b.class_id
  join public.academic_years ay
    on ay.id = b.academic_year_id
  left join public.branches br
    on br.id = b.branch_id
  left join public.students s
    on s.id = a.student_id
  left join public.business_rule_versions r
    on r.id = a.activation_policy_version_id
  left join public.admission_invoices i
    on i.admission_id = a.id
   and i.invoice_kind = 'INITIAL'
  left join lateral public.invoice_balance(i.id) bal
    on true
  where a.id = p_admission_id;

  if result is null then
    raise exception 'Admission Case not found.';
  end if;

  result:=result||(select jsonb_build_object('academyRoll',s.academy_roll::text,'discountPercent',a.selected_discount_percent,'discountReason',a.discount_reason,'additionalDetails',
 jsonb_build_object('student_mobile',a.identity_snapshot->>'student_mobile','student_email',a.identity_snapshot->>'student_email','present_landmark',a.identity_snapshot->>'present_landmark','permanent_same_as_present',a.identity_snapshot->>'permanent_same_as_present','father_name',a.identity_snapshot->>'father_name','mother_name',a.identity_snapshot->>'mother_name',
 'birth_registration',a.identity_snapshot->>'birth_registration','permanent_address',a.identity_snapshot->>'permanent_address',
 'emergency_contact',a.identity_snapshot->>'emergency_contact','emergency_mobile',a.identity_snapshot->>'emergency_mobile',
 'previous_result',a.identity_snapshot->>'previous_result','learning_needs',a.identity_snapshot->>'learning_needs'))
 from public.admission_cases a left join public.students s on s.id=a.student_id where a.id=p_admission_id);

 select additional_charges into charges from public.admission_cases where id=p_admission_id;
 select coalesce(jsonb_agg(jsonb_build_object('name',value->>'name','amount',(value->>'amount')::numeric,'recurrence','ONE_TIME')),'[]') into extras from jsonb_array_elements(charges) where (value->>'is_active')::boolean;
 return result||jsonb_build_object('tuitionTotal',(select coalesce(sum(c.amount),0) from public.fee_plan_components c join public.admission_cases a on a.fee_plan_version_id=c.fee_plan_version_id where a.id=p_admission_id and c.charge_type='TUITION'),'additionalCharges',charges,'components',(result->'components')||extras);
end;
$function$;
alter function public.admission_case_detail(uuid) owner to academy_executor;
reset search_path;

-- Demo records are created atomically when a verified owner opens a branch.
-- No synthetic Auth users, passwords, financial records or cross-branch IDs.
create function public.seed_demo_branch() returns void language plpgsql security definer set search_path=pg_catalog,public as $$
declare branch uuid:=academy_private.current_branch_id(); b record; i integer; n integer:=0; intake jsonb; aid uuid; teacher jsonb; tid uuid; room jsonb; subject uuid; subjects jsonb; begin
 if branch is null or not public.has_permission('system.users.manage') then raise exception 'Branch administrator required.';end if;
 if exists(select 1 from public.audit_events where scope_branch_id=branch and action='SEED_DEMO') then return;end if;
 select jsonb_agg(id) into subjects from public.subjects where scope_branch_id=branch;
 teacher:=public.create_staff_member(jsonb_build_object('full_name','DEMO — Ayesha Rahman','staff_role_code','TEACHER','mobile','01900000001','subject_ids',subjects,'notes','Demo record for testing; no login account.'));
 tid:=(teacher->>'staff_id')::uuid;
 perform public.create_staff_member(jsonb_build_object('full_name','DEMO — Hasan Ahmed','staff_role_code','TEACHER','mobile','01900000002','subject_ids',subjects,'notes','Demo record for testing; no login account.'));
 room:=public.academic_command(jsonb_build_object('request_id',gen_random_uuid(),'action','CREATE_ROOM','reason','Demo academic setup','branch_id',branch,'name','DEMO Classroom','capacity',12));
 for b in select * from public.batches where scope_branch_id=branch order by code loop
  for i in 1..2 loop
   n:=n+1;
   intake:=public.create_staff_admission_intake(jsonb_build_object('request_id',gen_random_uuid(),'student_name','DEMO Student '||n,'guardian_name','DEMO Guardian '||n,'mobile','017000000'||lpad(n::text,2,'0'),'guardian_address','Demo address — replace before real use','consent_to_contact',true,'offering_id',b.offering_id,'batch_id',b.id,'reason','Demo seed for testing'));
   aid:=(intake->>'admission_id')::uuid;
   perform public.admission_command(jsonb_build_object('request_id',gen_random_uuid(),'action','READY','admission_id',aid,'reason','Demo verified placement'));
   perform public.admission_command(jsonb_build_object('request_id',gen_random_uuid(),'action','FINALIZE','admission_id',aid,'reason','Demo academic enrollment'));
  end loop;
  select subject_id into subject from public.programme_offering_subjects where offering_id=b.offering_id order by sort_order limit 1;
  perform public.academic_command(jsonb_build_object('request_id',gen_random_uuid(),'action','CREATE_SESSION','reason','Demo lesson','batch_id',b.id,'subject_id',subject,'teacher_id',tid,'room_id',room->>'id','starts_on',current_date+n/2,'start_time','18:00','end_time','19:00','planned_scope','DEMO lesson — edit before real use'));
 end loop;
 update public.programme_offerings set is_website_visible=true,is_accepting_applications=true where scope_branch_id=branch;
 insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason) values(auth.uid(),branch,'BRANCH',branch::text,'SEED_DEMO','Demo students, teachers, room and lessons; no finance or login accounts.');
end $$;
revoke all on function public.seed_demo_branch() from public,anon,authenticated;
