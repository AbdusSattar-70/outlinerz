import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database, Json } from "@/types/database";
import { createClient } from "@/lib/supabase/server";
import {
  academicWorkspaceSchema,
  sessionWorkspaceSchema,
  classLogWorkspaceSchema,
} from "./schema";
type AcademicDatabase = Database & {
  academy: {
    Functions: {
      academic_command: { Args: { p_input: Json }; Returns: Json };
      academic_workspace: {
        Args: { p_from: string; p_to: string };
        Returns: Json;
      };
      class_session_workspace: {
        Args: { p_session_id: string };
        Returns: Json;
      };
      class_log_workspace: { Args: { p_session_id: string }; Returns: Json };
      class_log_command: { Args: { p_input: Json }; Returns: Json };
    };
  };
};
export async function academicClient() {
  return (await createClient()) as unknown as SupabaseClient<AcademicDatabase>;
}
export async function getAcademicWorkspace(from: string, to: string) {
  const db = await academicClient();
  const { data, error } = await db.rpc("academic_workspace", {
    p_from: from,
    p_to: to,
  });
  if (error) throw new Error(error.message);
  return academicWorkspaceSchema.parse(data);
}
export async function getSessionWorkspace(id: string) {
  const db = await academicClient();
  const { data, error } = await db.rpc("class_session_workspace", {
    p_session_id: id,
  });
  if (error) throw new Error(error.message);
  return sessionWorkspaceSchema.parse(data);
}

export async function getClassLogWorkspace(id: string) {
  const db = await academicClient();
  const { data, error } = await db.rpc("class_log_workspace", {
    p_session_id: id,
  });
  if (error) throw new Error(error.message);
  return classLogWorkspaceSchema.parse(data);
}
