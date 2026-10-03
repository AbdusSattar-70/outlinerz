// Narrow, reviewed contract for this feature; legacy types/database.ts is not used.
export type Role =
  "OWNER" | "ADMIN" | "ACADEMIC" | "FINANCE" | "OPERATOR" | "TEACHER";
export type Table<Row> = {
  Row: Row;
  Insert: Partial<Row>;
  Update: Partial<Row>;
  Relationships: [];
};
export type OrganizationDatabase = {
  public: {
    Tables: {
      organizations: Table<{
        id: string;
        name: string;
        slug: string;
        currency: string;
        timezone: string;
        created_at: string;
      }>;
      memberships: Table<{
        organization_id: string;
        user_id: string;
        role: Role;
        active: boolean;
        created_at: string;
      }>;
      organization_modules: Table<{
        organization_id: string;
        module: string;
        enabled: boolean;
      }>;
      branches: Table<{
        id: string;
        organization_id: string;
        name: string;
        code: string;
        active: boolean;
        created_at: string;
      }>;
      academic_years: Table<{
        id: string;
        organization_id: string;
        name: string;
        starts_on: string;
        ends_on: string;
        active: boolean;
        created_at: string;
      }>;
      class_levels: Table<{
        code: string | null;
        sort_order: number;
        id: string;
        organization_id: string;
        name: string;
        active: boolean;
        created_at: string;
      }>;
      subjects: Table<{
        code: string | null;
        id: string;
        organization_id: string;
        name: string;
        active: boolean;
        created_at: string;
      }>;
      class_groups: Table<Directory>;
      programmes: Table<Directory & { description: string | null }>;
      areas: Table<Directory>;
      schools: Table<
        Directory & { area_id: string | null; is_verified: boolean }
      >;
      lead_sources: Table<Directory>;
      guardian_relationships: Table<Directory>;
      offerings: Table<{
        id: string;
        organization_id: string;
        name: string;
        code: string;
        programme_id: string;
        class_level_id: string;
        branch_id: string;
        academic_year_id: string;
        active: boolean;
        intake_open: boolean;
        public_visible: boolean;
        public_copy: Record<string, unknown>;
      }>;
      prospects: Table<Prospect>;
      followups: Table<Followup>;
    };
    Views: Record<string, never>;
    Functions: {
      crm_master: {
        Args: {
          p_org: string;
          p_request: string;
          p_input: Record<string, unknown>;
        };
        Returns: { id: string };
      };
      crm_followup: {
        Args: {
          p_org: string;
          p_request: string;
          p_input: Record<string, unknown>;
        };
        Returns: { stage: string };
      };
      crm_assign: {
        Args: { p_org: string; p_prospect: string; p_user: string | null };
        Returns: undefined;
      };
      crm_public_catalogue: {
        Args: { p_slug: string };
        Returns: import("@/modules/offerings/queries").PublicOfferingCard[];
      };
      crm_public_options: { Args: { p_slug: string }; Returns: PublicOptions };
      crm_public_interest: {
        Args: {
          p_slug: string;
          p_request: string;
          p_payload: Record<string, unknown>;
        };
        Returns: { prospect_no: string };
      };
      onboard_organization: {
        Args: {
          p_request: string;
          p_name: string;
          p_slug: string;
          p_branch_name: string;
        };
        Returns: { organization_id: string; branch_id: string };
      };
    };
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};

export type Directory = {
  id: string;
  organization_id: string;
  code: string | null;
  name: string;
  active: boolean;
  created_at: string;
};
export type Prospect = {
  id: string;
  organization_id: string;
  student_name: string;
  guardian_name: string | null;
  phone: string;
  class_level_id: string | null;
  offering_id: string | null;
  source: string;
  stage: "NEW" | "CONTACTED" | "INTERESTED" | "LOST" | "ADMITTED";
  lost_reason: string | null;
  notes: string | null;
  created_at: string;
  assigned_user_id: string | null;
  next_follow_up_at: string | null;
  application_snapshot: Record<string, unknown>;
  school_id: string | null;
  submission_intent: "interest" | "admission";
};
export type Followup = {
  id: string;
  organization_id: string;
  prospect_id: string;
  assigned_user_id: string;
  due_at: string;
  note: string | null;
  completed_at: string | null;
  created_at: string;
  followup_type: string;
  outcome: string | null;
  recorded_by: string | null;
  next_follow_up_at: string | null;
};
export type PublicOptions = {
  organization: { name: string; slug: string };
  classes: { id: string; name: string }[];
  programs: { id: string; name: string }[];
  subjects: { id: string; name: string }[];
  schools: { id: string; name: string }[];
  sources: { code: string; name: string }[];
  relationships: { code: string; name: string }[];
};
