-- Final academic model; fresh database only.
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create schema academy_private;
-- Installed before table defaults; replaced by the membership-aware helper below.
create function academy_private.current_branch_id() returns uuid language sql stable as $$select null::uuid$$;
create type public."approval_status" as enum ('PENDING','APPROVED','REJECTED','CANCELLED');
create type public."enrollment_status" as enum ('ACTIVE','COMPLETED','WITHDRAWN','CANCELLED');
create type public."offering_status" as enum ('DRAFT','ACTIVE','RETIRED');
create type public."profile_status" as enum ('ACTIVE','SUSPENDED','ARCHIVED');
create type public."prospect_status" as enum ('NEW','CONTACTED','COUNSELLING','TRIAL_SCHEDULED','TRIAL_ATTENDED','REGISTERED','CONVERTED','FUTURE_FOLLOW_UP','LOST');
create type public."rule_status" as enum ('DRAFT','ACTIVE','RETIRED');
create type public."staff_status" as enum ('ACTIVE','ON_LEAVE','RESIGNED','TERMINATED','ARCHIVED');
create type public."student_status" as enum ('ACTIVE','INACTIVE','WITHDRAWN','GRADUATED','ARCHIVED');
create sequence public."staff_no_seq";
create sequence public."prospect_no_seq";
create sequence public."student_no_seq";
create sequence public."admission_no_seq";
create sequence public."students_academy_roll_seq";

CREATE OR REPLACE FUNCTION public.generate_prospect_no()
 RETURNS text
 LANGUAGE sql
AS $function$
  select 'PR-' || lpad(nextval('public.prospect_no_seq')::text, 6, '0');
$function$
;
CREATE OR REPLACE FUNCTION public.generate_staff_no()
 RETURNS text
 LANGUAGE sql
AS $function$
  select 'SA-STF-' || lpad(nextval('public.staff_no_seq')::text, 6, '0');
$function$
;
CREATE OR REPLACE FUNCTION public.generate_student_no()
 RETURNS text
 LANGUAGE sql
AS $function$
  select 'SA-' || lpad(nextval('public.student_no_seq')::text, 6, '0');
$function$
;
create table public."academic_assessments" (
  "id" uuid default gen_random_uuid() not null,
  "batch_id" uuid not null,
  "subject_id" uuid not null,
  "title" text not null,
  "assessment_date" date not null,
  "max_marks" numeric(8,2) not null,
  "status" text default 'DRAFT'::text not null,
  "author_id" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "published_at" timestamp with time zone,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."academic_groups" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "code" text not null,
  "name" text not null,
  "is_active" boolean default true not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."academic_rooms" (
  "id" uuid default gen_random_uuid() not null,
  "branch_id" uuid not null,
  "name" text not null,
  "capacity" integer not null,
  "created_by" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."academic_routines" (
  "id" uuid default gen_random_uuid() not null,
  "batch_id" uuid not null,
  "subject_id" uuid not null,
  "teacher_id" uuid not null,
  "room_id" uuid not null,
  "weekday" integer not null,
  "start_time" time without time zone not null,
  "end_time" time without time zone not null,
  "starts_on" date not null,
  "ends_on" date not null,
  "created_by" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "retired_at" timestamp with time zone,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."academic_years" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "name" text not null,
  "starts_on" date not null,
  "ends_on" date not null,
  "is_active" boolean default false not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."admission_cases" (
  "id" uuid default gen_random_uuid() not null,
  "admission_no" text default ('ADM-'::text || lpad((nextval('admission_no_seq'::regclass))::text, 6, '0'::text)) not null,
  "prospect_id" uuid,
  "batch_id" uuid not null,
  "activation_policy_version_id" uuid,
  "capacity_policy_version_id" uuid,
  "student_id" uuid,
  "enrollment_id" uuid,
  "status" text default 'DRAFT'::text not null,
  "identity_snapshot" jsonb not null,
  "created_by" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "existing_student" boolean default false not null,
  "consent_required" boolean default false not null,
  "origin" text default 'PROSPECT_CONVERSION'::text not null,
  "origin_prospect_id" uuid,
  "identity_revision" integer default 1 not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."admission_command_keys" (
  "request_id" uuid not null,
  "actor_id" uuid not null,
  "payload" jsonb not null,
  "result" jsonb not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."admission_physical_consent_receipts" (
  "id" uuid default gen_random_uuid() not null,
  "request_id" uuid not null,
  "request_payload" jsonb not null,
  "admission_id" uuid not null,
  "version" integer not null,
  "guardian_signed_on" date not null,
  "student_signed" boolean default false not null,
  "physical_copy_reference" text,
  "received_by" uuid not null,
  "received_at" timestamp with time zone default now() not null,
  "reason" text not null,
  "identity_revision" integer default 1 not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."approval_requests" (
  "id" uuid default gen_random_uuid() not null,
  "correlation_id" uuid default gen_random_uuid() not null,
  "workflow_type" text not null,
  "entity_type" text not null,
  "entity_id" text not null,
  "requested_action" text not null,
  "payload_snapshot" jsonb default '{}'::jsonb not null,
  "request_note" text,
  "status" approval_status default 'PENDING'::approval_status not null,
  "requested_by" uuid not null,
  "requested_at" timestamp with time zone default now() not null,
  "decided_by" uuid,
  "decided_at" timestamp with time zone,
  "decision_note" text,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."areas" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "name" text not null,
  "parent_id" uuid,
  "is_active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."assessment_result_submissions" (
  "id" uuid default gen_random_uuid() not null,
  "assessment_id" uuid not null,
  "revision" integer not null,
  "entries" jsonb not null,
  "status" text default 'DRAFT'::text not null,
  "author_id" uuid not null,
  "reviewer_id" uuid,
  "review_note" text,
  "created_at" timestamp with time zone default now() not null,
  "submitted_at" timestamp with time zone,
  "reviewed_at" timestamp with time zone,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."attendance_submissions" (
  "id" uuid default gen_random_uuid() not null,
  "session_id" uuid not null,
  "revision" integer not null,
  "entries" jsonb not null,
  "reason" text not null,
  "status" text default 'DRAFT'::text not null,
  "recorded_by" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "approval_id" uuid,
  "reviewer_id" uuid,
  "review_note" text,
  "reviewed_at" timestamp with time zone,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."audit_events" (
  "id" uuid default gen_random_uuid() not null,
  "correlation_id" uuid default gen_random_uuid() not null,
  "occurred_at" timestamp with time zone default now() not null,
  "actor_profile_id" uuid,
  "actor_staff_id" uuid,
  "actor_role_code" text,
  "branch_id" uuid,
  "entity_type" text not null,
  "entity_id" text not null,
  "action" text not null,
  "reason" text,
  "before_data" jsonb,
  "after_data" jsonb,
  "metadata" jsonb default '{}'::jsonb not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."batches" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "branch_id" uuid,
  "academic_year_id" uuid not null,
  "class_id" uuid not null,
  "program_id" uuid,
  "code" text not null,
  "name" text not null,
  "capacity" integer not null,
  "is_active" boolean default true not null,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "offering_id" uuid,
  "capacity_policy_version_id" uuid,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."branch_memberships" (
  "branch_id" uuid not null,
  "user_id" uuid not null,
  "is_active" boolean default true not null
);

create table public."branch_open_commands" (
  "user_id" uuid not null,
  "request_id" uuid not null,
  "payload" jsonb not null,
  "result" jsonb not null
);

create table public."branch_owners" (
  "organization_id" uuid not null,
  "user_id" uuid not null
);

create table public."branches" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "code" text not null,
  "name" text not null,
  "address" text,
  "timezone" text default 'Asia/Dhaka'::text not null,
  "is_active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "slug" text
);

create table public."business_rule_versions" (
  "id" uuid default gen_random_uuid() not null,
  "domain" text not null,
  "rule_key" text not null,
  "version" integer not null,
  "status" rule_status default 'DRAFT'::rule_status not null,
  "effective_from" date default CURRENT_DATE not null,
  "effective_to" date,
  "payload" jsonb not null,
  "change_reason" text not null,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."class_logs" (
  "id" uuid default gen_random_uuid() not null,
  "session_id" uuid not null,
  "revision" integer not null,
  "previous_log_id" uuid,
  "status" text not null,
  "unit_progress" jsonb default '[]'::jsonb not null,
  "class_summary" text not null,
  "unfinished_reason" text default ''::text not null,
  "homework" text default ''::text not null,
  "next_session_plan" text default ''::text not null,
  "reason" text not null,
  "authored_by" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "submitted_at" timestamp with time zone,
  "reviewer_id" uuid,
  "review_note" text,
  "reviewed_at" timestamp with time zone,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."class_sessions" (
  "id" uuid default gen_random_uuid() not null,
  "routine_id" uuid,
  "batch_id" uuid not null,
  "subject_id" uuid not null,
  "teacher_id" uuid not null,
  "room_id" uuid not null,
  "curriculum_version_id" uuid,
  "planned_scope" text not null,
  "session_date" date not null,
  "starts_at" timestamp with time zone not null,
  "ends_at" timestamp with time zone not null,
  "status" text default 'SCHEDULED'::text not null,
  "cancellation_reason" text,
  "cancelled_by" uuid,
  "cancelled_at" timestamp with time zone,
  "created_by" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."classes" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "code" text not null,
  "name" text not null,
  "sort_order" integer default 0 not null,
  "is_active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."curriculum_versions" (
  "id" uuid default gen_random_uuid() not null,
  "batch_id" uuid not null,
  "subject_id" uuid not null,
  "version" integer not null,
  "title" text not null,
  "units" jsonb not null,
  "reason" text not null,
  "published_by" uuid not null,
  "published_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."enrollment_transfers" (
  "id" uuid default gen_random_uuid() not null,
  "student_id" uuid not null,
  "admission_id" uuid not null,
  "from_enrollment_id" uuid not null,
  "to_enrollment_id" uuid not null,
  "from_batch_id" uuid not null,
  "to_batch_id" uuid not null,
  "capacity_policy_version_id" uuid not null,
  "transferred_on" date not null,
  "created_at" timestamp with time zone default now() not null,
  "authorized_by" uuid not null,
  "authorization_reason" text not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."enrollments" (
  "id" uuid default gen_random_uuid() not null,
  "student_id" uuid not null,
  "organization_id" uuid not null,
  "branch_id" uuid,
  "academic_year_id" uuid not null,
  "class_id" uuid not null,
  "program_id" uuid,
  "batch_id" uuid,
  "admission_date" date default CURRENT_DATE not null,
  "status" enrollment_status default 'ACTIVE'::enrollment_status not null,
  "ended_on" date,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."guardian_relationships" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "code" text not null,
  "name" text not null,
  "is_active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."guardians" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "full_name" text not null,
  "mobile" text not null,
  "alternate_mobile" text,
  "email" text,
  "address" text,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."homework_checks" (
  "id" uuid default gen_random_uuid() not null,
  "class_log_id" uuid not null,
  "enrollment_id" uuid not null,
  "revision" integer not null,
  "status" text not null,
  "submitted_on" date,
  "feedback" text default ''::text not null,
  "recorded_by" uuid not null,
  "recorded_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."lead_sources" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "code" text not null,
  "name" text not null,
  "is_active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."organizations" (
  "id" uuid default gen_random_uuid() not null,
  "code" text not null,
  "name" text not null,
  "timezone" text default 'Asia/Dhaka'::text not null,
  "currency_code" text default 'BDT'::text not null,
  "is_active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "setup_completed_at" timestamp with time zone,
  "setup_completed_by" uuid,
  "setup_identity_confirmed_at" timestamp with time zone
);

create table public."permissions" (
  "id" uuid default gen_random_uuid() not null,
  "code" text not null,
  "name" text not null,
  "description" text,
  "created_at" timestamp with time zone default now() not null
);

create table public."profiles" (
  "id" uuid not null,
  "display_name" text not null,
  "status" profile_status default 'ACTIVE'::profile_status not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);

create table public."programme_offering_subjects" (
  "offering_id" uuid not null,
  "subject_id" uuid not null,
  "sort_order" integer default 0 not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."programme_offerings" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "branch_id" uuid not null,
  "academic_year_id" uuid not null,
  "class_id" uuid not null,
  "program_id" uuid not null,
  "group_id" uuid,
  "code" text not null,
  "name" text not null,
  "status" offering_status default 'DRAFT'::offering_status not null,
  "created_by" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "showcase_title" text,
  "showcase_title_bn" text,
  "showcase_description" text,
  "showcase_description_bn" text,
  "showcase_eyebrow" text,
  "showcase_eyebrow_bn" text,
  "showcase_icon" text,
  "showcase_sort_order" integer default 100 not null,
  "is_website_visible" boolean default false not null,
  "is_accepting_applications" boolean default false not null,
  "applications_open_on" date,
  "applications_close_on" date,
  "public_schedule" text,
  "public_requirements" text,
  "admission_policy" text,
  "public_schedule_bn" text,
  "public_requirements_bn" text,
  "admission_policy_bn" text,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."programs" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "code" text not null,
  "name" text not null,
  "description" text,
  "is_active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."prospect_followups" (
  "id" uuid default gen_random_uuid() not null,
  "prospect_id" uuid not null,
  "followup_type" text not null,
  "occurred_at" timestamp with time zone default now() not null,
  "outcome" text,
  "notes" text not null,
  "next_follow_up_at" timestamp with time zone,
  "recorded_by" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."prospect_program_interests" (
  "prospect_id" uuid not null,
  "program_id" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."prospect_subject_interests" (
  "prospect_id" uuid not null,
  "subject_id" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."prospects" (
  "id" uuid default gen_random_uuid() not null,
  "prospect_no" text default generate_prospect_no() not null,
  "organization_id" uuid not null,
  "branch_id" uuid,
  "student_name" text not null,
  "student_name_bn" text,
  "guardian_name" text not null,
  "guardian_relationship_id" uuid,
  "guardian_relationship_snapshot" text,
  "mobile" text not null,
  "alternate_mobile" text,
  "current_class_id" uuid,
  "school_id" uuid,
  "school_name_snapshot" text,
  "area_id" uuid,
  "area_snapshot" text,
  "preferred_schedule" text,
  "preferred_days" text[] default '{}'::text[] not null,
  "trial_interest" boolean default false not null,
  "source_id" uuid,
  "referral_note" text,
  "notes" text,
  "consent_to_contact" boolean default false not null,
  "status" prospect_status default 'NEW'::prospect_status not null,
  "assigned_to_staff_id" uuid,
  "next_follow_up_at" timestamp with time zone,
  "lost_reason" text,
  "converted_student_id" uuid,
  "converted_at" timestamp with time zone,
  "submitted_via" text default 'PUBLIC_WEB'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "interested_offering_id" uuid,
  "submission_intent" text default 'interest'::text not null,
  "date_of_birth" date,
  "gender" text,
  "school_roll" text,
  "guardian_address" text,
  "application_snapshot" jsonb,
  "application_verified_at" timestamp with time zone,
  "application_verified_by" uuid,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."question_bank_items" (
  "id" uuid default gen_random_uuid() not null,
  "root_id" uuid,
  "revision" integer default 1 not null,
  "batch_id" uuid not null,
  "subject_id" uuid not null,
  "curriculum_version_id" uuid,
  "topic" text not null,
  "difficulty" text not null,
  "question_type" text not null,
  "prompt" text not null,
  "choices" jsonb default '[]'::jsonb not null,
  "answer_key" text not null,
  "explanation" text,
  "status" text default 'DRAFT'::text not null,
  "author_id" uuid not null,
  "reviewer_id" uuid,
  "review_note" text,
  "created_at" timestamp with time zone default now() not null,
  "submitted_at" timestamp with time zone,
  "reviewed_at" timestamp with time zone,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."role_permissions" (
  "role_id" uuid not null,
  "permission_id" uuid not null,
  "created_at" timestamp with time zone default now() not null
);

create table public."schools" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "area_id" uuid,
  "name" text not null,
  "is_verified" boolean default false not null,
  "is_active" boolean default true not null,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."staff" (
  "id" uuid default gen_random_uuid() not null,
  "staff_no" text default generate_staff_no() not null,
  "profile_id" uuid,
  "branch_id" uuid,
  "full_name" text not null,
  "mobile" text,
  "alternate_mobile" text,
  "email" text,
  "address" text,
  "emergency_contact_name" text,
  "emergency_contact_mobile" text,
  "joined_on" date,
  "left_on" date,
  "status" staff_status default 'ACTIVE'::staff_status not null,
  "notes" text,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."staff_access_requests" (
  "id" uuid default gen_random_uuid() not null,
  "full_name" text not null,
  "email" text not null,
  "mobile" text not null,
  "requested_role" text not null,
  "purpose" text not null,
  "status" text default 'PENDING'::text not null,
  "assigned_role" text,
  "profile_id" uuid,
  "reviewed_by" uuid,
  "reviewed_at" timestamp with time zone,
  "invitation_sent_at" timestamp with time zone,
  "review_note" text,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."staff_admission_intake_requests" (
  "request_id" uuid not null,
  "actor_id" uuid not null,
  "payload" jsonb not null,
  "prospect_id" uuid,
  "admission_id" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."staff_attendance_records" (
  "id" uuid default gen_random_uuid() not null,
  "staff_id" uuid not null,
  "work_date" date not null,
  "status" text not null,
  "started_at" timestamp with time zone,
  "ended_at" timestamp with time zone,
  "break_minutes" integer default 0 not null,
  "recorded_by" uuid not null,
  "reason" text not null,
  "updated_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."staff_role_assignments" (
  "id" uuid default gen_random_uuid() not null,
  "staff_id" uuid not null,
  "staff_role_id" uuid not null,
  "branch_id" uuid,
  "effective_from" date default CURRENT_DATE not null,
  "effective_to" date,
  "is_primary" boolean default false not null,
  "assigned_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."staff_roles" (
  "id" uuid default gen_random_uuid() not null,
  "code" text not null,
  "name" text not null,
  "is_teaching_role" boolean default false not null,
  "is_active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null
);

create table public."staff_subject_assignments" (
  "id" uuid default gen_random_uuid() not null,
  "staff_id" uuid not null,
  "subject_id" uuid not null,
  "effective_from" date default CURRENT_DATE not null,
  "effective_to" date,
  "is_primary" boolean default false not null,
  "assigned_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."staff_work_tasks" (
  "id" uuid default gen_random_uuid() not null,
  "staff_id" uuid not null,
  "title" text not null,
  "instructions" text default ''::text not null,
  "due_on" date not null,
  "status" text default 'OPEN'::text not null,
  "progress" integer default 0 not null,
  "blocker" text default ''::text not null,
  "review_note" text,
  "created_by" uuid not null,
  "updated_by" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "completed_at" timestamp with time zone,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."student_guardians" (
  "id" uuid default gen_random_uuid() not null,
  "student_id" uuid not null,
  "guardian_id" uuid not null,
  "relationship_id" uuid,
  "relationship_snapshot" text,
  "is_primary" boolean default false not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."student_merges" (
  "id" uuid default gen_random_uuid() not null,
  "source_id" uuid not null,
  "target_id" uuid not null,
  "source_snapshot" jsonb not null,
  "target_snapshot" jsonb not null,
  "created_at" timestamp with time zone default now() not null,
  "authorized_by" uuid not null,
  "authorization_reason" text not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."students" (
  "id" uuid default gen_random_uuid() not null,
  "student_no" text default generate_student_no() not null,
  "organization_id" uuid not null,
  "branch_id" uuid,
  "full_name" text not null,
  "name_bn" text,
  "gender" text,
  "date_of_birth" date,
  "school_id" uuid,
  "school_name_snapshot" text,
  "school_roll" text,
  "status" student_status default 'ACTIVE'::student_status not null,
  "created_from_prospect_id" uuid,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "merged_into_id" uuid,
  "academy_roll" bigint default nextval('public.students_academy_roll_seq'::regclass) not null,
  "mobile" text,
  "email" text,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."subjects" (
  "id" uuid default gen_random_uuid() not null,
  "organization_id" uuid not null,
  "code" text not null,
  "name" text not null,
  "is_active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

create table public."system_roles" (
  "id" uuid default gen_random_uuid() not null,
  "code" text not null,
  "name" text not null,
  "description" text,
  "is_system" boolean default true not null,
  "is_active" boolean default true not null,
  "created_at" timestamp with time zone default now() not null
);

create table public."user_role_assignments" (
  "id" uuid default gen_random_uuid() not null,
  "profile_id" uuid not null,
  "role_id" uuid not null,
  "branch_id" uuid,
  "effective_from" date default CURRENT_DATE not null,
  "effective_to" date,
  "is_active" boolean default true not null,
  "assigned_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "scope_branch_id" uuid default academy_private.current_branch_id() not null
);

-- Keep the model private between migration transactions until access policies are installed.
revoke all on all tables in schema public from anon,authenticated;
revoke all on all sequences in schema public from anon,authenticated;
