import "server-only";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";
/** Explicit boundary for newly added RPCs until linked database types are regenerated. */
export async function platformClient() {
  return (await createClient()) as unknown as SupabaseClient;
}
