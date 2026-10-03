// Narrow, reviewed contract for this feature; legacy types/database.ts is not used.
export type Role = 'OWNER' | 'ADMIN' | 'ACADEMIC' | 'FINANCE' | 'OPERATOR' | 'TEACHER';
type Table<Row> = { Row: Row; Insert: Partial<Row>; Update: Partial<Row>; Relationships: [] };
export type OrganizationDatabase = {
  public: {
    Tables: {
      organizations: Table<{ id: string; name: string; slug: string; currency: string; timezone: string; created_at: string }>;
      memberships: Table<{ organization_id: string; user_id: string; role: Role; active: boolean; created_at: string }>;
      organization_modules: Table<{ organization_id: string; module: string; enabled: boolean }>;
      branches: Table<{ id: string; organization_id: string; name: string; code: string; active: boolean; created_at: string }>;
      academic_years: Table<{ id: string; organization_id: string; name: string; starts_on: string; ends_on: string; active: boolean; created_at: string }>;
      class_levels: Table<{ id: string; organization_id: string; name: string; active: boolean; created_at: string }>;
      subjects: Table<{ id: string; organization_id: string; name: string; active: boolean; created_at: string }>;
    };
    Views: Record<string, never>;
    Functions: { onboard_organization: { Args: { p_request: string; p_name: string; p_slug: string; p_branch_name: string }; Returns: { organization_id: string; branch_id: string } } };
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};
