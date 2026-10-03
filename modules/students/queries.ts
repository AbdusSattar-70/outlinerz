import { createClient } from "@/lib/supabase/server";

export type StudentListRow = {
  id: string;
  studentNo: string;
  fullName: string;
  schoolName: string;
  status: string;
  createdAt: string;
};

export async function getStudentList(): Promise<StudentListRow[]> {
  const supabase = await createClient();
  const [studentsQ, schoolsQ] = await Promise.all([
    supabase
      .from("students")
      .select(
        "id,student_no,full_name,school_id,school_name_snapshot,status,created_at"
      )
      .order("created_at", { ascending: false })
      .limit(500),
    supabase.from("schools").select("id,name"),
  ]);

  const schoolNames = new Map(
    (schoolsQ.data ?? []).map((row) => [row.id, row.name])
  );

  return (studentsQ.data ?? []).map((row) => ({
    id: row.id,
    studentNo: row.student_no,
    fullName: row.full_name,
    schoolName:
      (row.school_id ? schoolNames.get(row.school_id) : null) ??
      row.school_name_snapshot ??
      "—",
    status: row.status,
    createdAt: row.created_at,
  }));
}
