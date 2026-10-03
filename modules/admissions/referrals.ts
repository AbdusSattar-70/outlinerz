import type { SupabaseClient } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";

export async function getAdmissionReferrals() {
  const db = (await createClient()) as unknown as SupabaseClient;
  const [people, staff, choices] = await Promise.all([
    db.from("referral_people").select("id,full_name,mobile,staff_id").eq("is_active",true).order("full_name"),
    db.from("staff").select("id,full_name").eq("status","ACTIVE").order("full_name"),
    db.from("admission_referrals").select("admission_id,source,referrer_id"),
  ]);
  for (const result of [people,staff,choices]) if (result.error) throw new Error(result.error.message);
  return {
    people:(people.data??[]) as Array<{id:string;full_name:string;mobile:string|null;staff_id:string|null}>,
    staff:(staff.data??[]) as Array<{id:string;full_name:string}>,
    choices:(choices.data??[]) as Array<{admission_id:string;source:string;referrer_id:string|null}>,
  };
}
