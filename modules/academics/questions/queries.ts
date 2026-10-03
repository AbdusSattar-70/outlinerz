import { createClient } from "@/lib/supabase/server";
import { questionWorkspaceSchema } from "./schema";

export async function getQuestionWorkspace() {
  const db = await createClient();
  const { data, error } = await db.rpc("question_bank_workspace" as never);
  if (error) throw new Error(error.message);
  return questionWorkspaceSchema.parse(data);
}
