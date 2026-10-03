import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database, Json } from "@/types/database";
import { createClient } from "@/lib/supabase/server";
import { financeWorkspaceSchema } from "./schema";
type FinanceDatabase = Database & {
  public: {
    Functions: {
      finance_workspace: { Args: Record<string, never>; Returns: Json };
      finance_command: { Args: { p_input: Json }; Returns: Json };
      post_admission_payment: { Args: { p_input: Json }; Returns: Json };
      billing_preview: {
        Args: { p_period: string; p_term_id?: string };
        Returns: Json;
      };
    };
  };
};
export async function financeClient() {
  return (await createClient()) as unknown as SupabaseClient<FinanceDatabase>;
}
export async function getFinanceWorkspace() {
  const db = await financeClient();
  const { data, error } = await db.rpc("finance_workspace", {});
  if (error) throw new Error(error.message);
  return financeWorkspaceSchema.parse(data);
}
