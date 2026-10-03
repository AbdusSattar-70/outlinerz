import { createClient } from "@/lib/supabase/server";
import { assessmentWorkspaceSchema } from "./schema";

export async function getAssessmentWorkspace() {
  const db = await createClient();
  const { data, error } = await db.rpc("assessment_workspace" as never);
  if (error) throw new Error(error.message);
  return assessmentWorkspaceSchema.parse(data);
}
