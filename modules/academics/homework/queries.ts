import { createClient } from "@/lib/supabase/server";
import { homeworkWorkspaceSchema } from "./schema";

export async function getHomeworkWorkspace(sessionId: string) {
  const db = await createClient();
  const { data, error } = await db.rpc("homework_workspace" as never, { p_session_id: sessionId } as never);
  if (error) throw new Error(error.message);
  return homeworkWorkspaceSchema.parse(data);
}
