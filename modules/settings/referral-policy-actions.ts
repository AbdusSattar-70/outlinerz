"use server";
import { z } from "zod";
import { platformClient } from "@/modules/platform/rpc-client";
import { revalidatePath } from "next/cache";
const percent=z.number().min(0).max(100);const schema=z.object({bonusPercent:percent,discountMax:percent,scholarshipMax:percent,reason:z.string().trim().min(5).max(500)});
export async function saveReferralOperatingRules(input:unknown){const p=schema.safeParse(input);if(!p.success)return {ok:false,message:"Check percentages (0–100) and a reason of at least five characters."};const db=await platformClient();const {error}=await db.rpc("save_referral_operating_rules",{p_input:p.data});if(error)return {ok:false,message:error.message};revalidatePath("/dashboard/governance/rules");revalidatePath("/dashboard/settings");return {ok:true,message:"Referrer and collection settings saved."};}
