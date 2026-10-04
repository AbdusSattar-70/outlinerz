import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database, Json } from "@/types/database";
import { createClient } from "@/lib/supabase/server";

type ReadonlyTable<T> = {
  Row: T;
  Insert: never;
  Update: never;
  Relationships: [];
};

type Offering = {
  id: string;
  organization_id: string;
  branch_id: string;
  academic_year_id: string;
  class_id: string;
  program_id: string;
  group_id: string | null;
  code: string;
  name: string;
  status: "DRAFT" | "ACTIVE" | "RETIRED";
  allowed_discount_percentages: number[];
  showcase_title: string | null;
  showcase_title_bn: string | null;
  showcase_description: string | null;
  showcase_description_bn: string | null;
  showcase_eyebrow: string | null;
  showcase_eyebrow_bn: string | null;
  showcase_icon: string | null;
  showcase_sort_order: number;
  is_website_visible: boolean;
  /** @deprecated Prefer is_website_visible */
  is_public_showcase?: boolean;
  is_accepting_applications: boolean;
  applications_open_on: string | null;
  applications_close_on: string | null;
  public_schedule: string | null;
  public_schedule_bn: string | null;
  public_requirements: string | null;
  public_requirements_bn: string | null;
  admission_policy: string | null;
  admission_policy_bn: string | null;
  created_by: string;
  created_at: string;
  updated_at: string;
};
type Plan = {
  id: string;
  offering_id: string;
  version: number;
  status: "DRAFT" | "ACTIVE" | "RETIRED";
  billing_cycle: "ONE_TIME" | "MONTHLY" | "TERM";
  due_day: number | null;
  currency_code: string;
  effective_from: string;
  effective_to: string | null;
  change_reason: string;
  created_by: string;
  created_at: string;
};
type Component = {
  id: string;
  fee_plan_version_id: string;
  code: string;
  name: string;
  amount: number;
  charge_type: string;
  recurrence: string;
  sort_order: number;
};
type Group = {
  id: string;
  organization_id: string;
  code: string;
  name: string;
  is_active: boolean;
};
type OfferingSubject = {
  offering_id: string;
  subject_id: string;
  sort_order: number;
};

type ExtendedDatabase = Omit<Database, "public"> & {
  public: Omit<Database["public"], "Tables" | "Functions"> & {
    Tables: Database["public"]["Tables"] & {
      academic_groups: ReadonlyTable<Group>;
      programme_offerings: ReadonlyTable<Offering>;
      fee_plan_versions: ReadonlyTable<Plan>;
      fee_plan_components: ReadonlyTable<Component>;
      programme_offering_subjects: ReadonlyTable<OfferingSubject>;
    };
    Functions: Database["public"]["Functions"] & {
      create_programme_offering: { Args: { p_input: Json }; Returns: Json };
      update_programme_offering: { Args: { p_input: Json }; Returns: Json };
      update_programme_offering_public_controls: {
        Args: { p_input: Json };
        Returns: Json;
      };
      list_public_programme_offerings: {
        Args: Record<string, never>;
        Returns: Json;
      };
    };
  };
};

export async function createOfferingClient() {
  return (await createClient()) as unknown as SupabaseClient<ExtendedDatabase>;
}
