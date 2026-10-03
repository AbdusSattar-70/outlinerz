import { createClient } from "@/lib/supabase/server";

export type SettingsPolicyRow = {
  id: string;
  domain: string;
  ruleKey: string;
  version: number;
  status: string;
  payload: unknown;
  changeReason: string;
  effectiveFrom: string;
};

export type SettingsRoleRow = {
  id: string;
  code: string;
  name: string;
  isSystem: boolean;
  isActive: boolean;
  permissions: Array<{
    code: string;
    name: string;
    description: string | null;
  }>;
};

export type SettingsPermissionRow = {
  id: string;
  code: string;
  name: string;
  description: string | null;
};

export type SettingsAccessUserRow = {
  profileId: string;
  displayName: string;
  staffNo: string | null;
  staffName: string | null;
  protectedAdmin: boolean;
  operationalRoleCodes: string[];
};

export async function getSettingsOverview() {
  const supabase = await createClient();

  const [
    rulesQ,
    rolesQ,
    permissionsQ,
    rolePermissionsQ,
    profilesQ,
    staffQ,
    assignmentsQ,
  ] = await Promise.all([
      supabase
        .from("business_rule_versions")
        .select(
          "id,domain,rule_key,version,status,payload,change_reason,effective_from"
        )
        .eq("status", "ACTIVE")
        .order("domain")
        .order("rule_key"),
      supabase
        .from("system_roles")
        .select("id,code,name,is_system,is_active")
        .eq("is_active", true)
        .order("name"),
      supabase
        .from("permissions")
        .select("id,code,name,description")
        .order("code"),
      supabase.from("role_permissions").select("role_id,permission_id"),
      supabase
        .from("profiles")
        .select("id,display_name,status")
        .eq("status", "ACTIVE")
        .order("display_name"),
      supabase
        .from("staff")
        .select("profile_id,staff_no,full_name,status")
        .in("status", ["ACTIVE", "ON_LEAVE"]),
      supabase
        .from("user_role_assignments")
        .select("profile_id,role_id,branch_id,is_active,effective_to")
        .eq("is_active", true)
        .is("effective_to", null)
        .is("branch_id", null),
    ]);

  const permissions: SettingsPermissionRow[] = (permissionsQ.data ?? []).map(
    (permission) => ({
      id: permission.id,
      code: permission.code,
      name: permission.name,
      description: permission.description,
    })
  );

  const permissionsById = new Map(
    permissions.map((permission) => [permission.id, permission])
  );
  const permissionsByRole = new Map<string, SettingsRoleRow["permissions"]>();

  for (const link of rolePermissionsQ.data ?? []) {
    const permission = permissionsById.get(link.permission_id);
    if (!permission) continue;

    const list = permissionsByRole.get(link.role_id) ?? [];
    list.push({
      code: permission.code,
      name: permission.name,
      description: permission.description,
    });
    permissionsByRole.set(link.role_id, list);
  }

  const staffByProfile = new Map(
    (staffQ.data ?? [])
      .filter((row) => row.profile_id)
      .map((row) => [
        row.profile_id as string,
        { staffNo: row.staff_no, staffName: row.full_name },
      ])
  );

  const roleCodeById = new Map(
    (rolesQ.data ?? []).map((role) => [role.id, role.code])
  );
  const assignmentCodesByProfile = new Map<string, string[]>();

  for (const assignment of assignmentsQ.data ?? []) {
    const roleCode = roleCodeById.get(assignment.role_id);
    if (!roleCode) continue;

    const list = assignmentCodesByProfile.get(assignment.profile_id) ?? [];
    list.push(roleCode);
    assignmentCodesByProfile.set(assignment.profile_id, list);
  }

  const accessUsers: SettingsAccessUserRow[] = (profilesQ.data ?? []).map(
    (profile) => {
      const staff = staffByProfile.get(profile.id);
      const roleCodes = assignmentCodesByProfile.get(profile.id) ?? [];

      return {
        profileId: profile.id,
        displayName: profile.display_name,
        staffNo: staff?.staffNo ?? null,
        staffName: staff?.staffName ?? null,
        protectedAdmin: roleCodes.includes("ADMIN"),
        operationalRoleCodes: roleCodes
          .filter((code) => code !== "ADMIN")
          .sort(),
      };
    }
  );

  return {
    rules: (rulesQ.data ?? []).map(
      (rule): SettingsPolicyRow => ({
        id: rule.id,
        domain: rule.domain,
        ruleKey: rule.rule_key,
        version: rule.version,
        status: rule.status,
        payload: rule.payload,
        changeReason: rule.change_reason,
        effectiveFrom: rule.effective_from,
      })
    ),
    roles: (rolesQ.data ?? []).map(
      (role): SettingsRoleRow => ({
        id: role.id,
        code: role.code,
        name: role.name,
        isSystem: role.is_system,
        isActive: role.is_active,
        permissions: (permissionsByRole.get(role.id) ?? []).sort((a, b) =>
          a.code.localeCompare(b.code)
        ),
      })
    ),
    permissions,
    accessUsers,

  };
}
