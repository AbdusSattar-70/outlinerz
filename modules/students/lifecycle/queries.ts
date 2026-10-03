import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database, Json } from "@/types/database";
import { createClient } from "@/lib/supabase/server";
import { profileSchema } from "./schema";
type StudentDatabase = Database & {
  public: {
    Functions: {
      student_command: { Args: { p_input: Json }; Returns: Json };
      student_profile_workspace: {
        Args: { p_student_id: string };
        Returns: Json;
      };
    };
  };
};
export async function studentClient() {
  return (await createClient()) as unknown as SupabaseClient<StudentDatabase>;
}
export async function getStudentProfile(studentId: string) {
  const db = await studentClient();
  const { data, error } = await db.rpc("student_profile_workspace", {
    p_student_id: studentId,
  });
  if (error) throw new Error(error.message);
  return data ? profileSchema.parse(data) : null;
}
