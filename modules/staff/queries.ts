import { createClient } from "@/lib/supabase/server";

export type StaffListRow = {
  id: string;
  staffNo: string;
  fullName: string;
  mobile: string | null;
  email: string | null;
  roleName: string;
  status: string;
  joinedOn: string | null;
  details: {alternate_mobile:string|null;address:string|null;emergency_contact_name:string|null;emergency_contact_mobile:string|null;notes:string|null;profile_id:string|null;branch_id:string|null;left_on:string|null};
};

export async function getStaffList(): Promise<StaffListRow[]> {
  const supabase = await createClient();
  const [staffQ, assignmentsQ, rolesQ] = await Promise.all([
    supabase
      .from("staff")
      .select("id,staff_no,full_name,mobile,email,status,joined_on,alternate_mobile,address,emergency_contact_name,emergency_contact_mobile,notes,profile_id,branch_id,left_on")
      .order("full_name"),
    supabase
      .from("staff_role_assignments")
      .select("staff_id,staff_role_id,is_primary,effective_to")
      .is("effective_to", null),
    supabase.from("staff_roles").select("id,name"),
  ]);

  const roles = new Map((rolesQ.data ?? []).map((row) => [row.id, row.name]));
  const primaryRoleByStaff = new Map<string, string>();

  for (const assignment of assignmentsQ.data ?? []) {
    if (!assignment.is_primary || primaryRoleByStaff.has(assignment.staff_id)) {
      continue;
    }
    primaryRoleByStaff.set(
      assignment.staff_id,
      roles.get(assignment.staff_role_id) ?? "Staff"
    );
  }

  return (staffQ.data ?? []).map((row) => ({
    id: row.id,
    staffNo: row.staff_no,
    fullName: row.full_name,
    mobile: row.mobile,
    email: row.email,
    roleName: primaryRoleByStaff.get(row.id) ?? "Staff",
    status: row.status,
    joinedOn: row.joined_on,
    details: {alternate_mobile:row.alternate_mobile,address:row.address,emergency_contact_name:row.emergency_contact_name,emergency_contact_mobile:row.emergency_contact_mobile,notes:row.notes,profile_id:row.profile_id,branch_id:row.branch_id,left_on:row.left_on},
  }));
}


