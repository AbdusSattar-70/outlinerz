import { platformClient } from "@/modules/platform/rpc-client";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database, Json } from "@/types/database";
import { createClient } from "@/lib/supabase/server";
import { admissionCaseDetailSchema, workspaceSchema } from "./schema";
// Narrow RPC contract until linked database types are regenerated.
type AdmissionDatabase = Database & {
  public: {
    Functions: {
      admission_workspace: { Args: Record<string, never>; Returns: Json };
      admission_offering_options: {
        Args: Record<string, never>;
        Returns: Json;
      };
      admission_command: { Args: { p_input: Json }; Returns: Json };
      create_prospect_admission: { Args: { p_input: Json }; Returns: Json };
      batch_command: { Args: { p_input: Json }; Returns: Json };
      admission_case_detail: {
        Args: { p_admission_id: string };
        Returns: Json;
      };
    };
  };
};
export async function admissionClient() {
  return (await createClient()) as unknown as SupabaseClient<AdmissionDatabase>;
}
export async function getAdmissionWorkspace() {
  const db = await admissionClient();
  const newDb = await platformClient();
  const [workspace, options, directory] = await Promise.all([
    db.rpc("admission_workspace"),
    db.rpc("admission_offering_options"),
    newDb.rpc("admission_directory_options"),
  ]);
  if (workspace.error) throw new Error(workspace.error.message);
  if (options.error) throw new Error(options.error.message);
  if (directory.error) throw new Error(directory.error.message);
  if (
    !workspace.data ||
    typeof workspace.data !== "object" ||
    Array.isArray(workspace.data)
  )
    throw new Error("Admission workspace returned an invalid response.");
  return workspaceSchema.parse({
    ...workspace.data,
    offerings: options.data,
    directory: directory.data,
  });
}

export async function getAdmissionCase(admissionId: string) {
  const db = await admissionClient();
  const { data, error } = await db.rpc("admission_case_detail", {
    p_admission_id: admissionId,
  });
  if (error) throw new Error(error.message);
  return admissionCaseDetailSchema.parse(data);
}
