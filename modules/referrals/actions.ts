"use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { sendAccountSetup } from "@/lib/supabase/account-setup";
import { getErpContext } from "@/modules/platform/auth/erp-context";
import { platformClient } from "@/modules/platform/rpc-client";

const inputSchema=z.object({action:z.enum(["SAVE","SET_ACTIVE","INVITE","SETTLE"]),id:z.string().uuid().optional(),request_id:z.string().uuid(),reason:z.string().trim().min(5).max(500),name:z.string().trim().min(2).max(160).optional(),mobile:z.string().max(30).optional(),email:z.string().max(254).optional(),relationship:z.string().max(160).optional(),notes:z.string().max(500).optional(),active:z.boolean().optional(),amount:z.number().positive().optional(),account_id:z.string().uuid().optional(),reference:z.string().max(120).optional()});
export async function referrerAction(input:unknown){
 const parsed=inputSchema.safeParse(input);if(!parsed.success)return {ok:false,message:parsed.error.issues[0]?.message??"Check the details."};
 const context=await getErpContext();if(!context?.permissions.includes(parsed.data.action==="SETTLE"?"staff.compensation.manage":"admissions.create"))return {ok:false,message:"Referrer management permission required."};
 const v=parsed.data;const db=await platformClient();
 try{
 if(v.action==="INVITE"){
  if(!context.permissions.includes("system.users.manage"))return {ok:false,message:"Account management permission required."};
  const {data,error}=await db.from("referral_people").select("id,email,full_name,is_active,staff_id,profile_id").eq("id",v.id!).single();
  if(error||!data?.is_active||!data.email)return {ok:false,message:"Save and verify the referrer email first."};
  const sent=await sendAccountSetup(data.email,data.full_name);if(!sent.ok)return sent;
  const linked=await db.rpc("manage_referrer",{p_input:{...v,action:"LINK_ACCOUNT"}});if(linked.error)return {ok:false,message:`Setup email sent; account linking needs attention: ${linked.error.message}`};
 }else{
  const {error}=await db.rpc(v.action==="SETTLE"?"settle_referrer_reward":"manage_referrer",{p_input:{...v,referrer_id:v.id}});if(error)return {ok:false,message:error.message};
 }
 revalidatePath("/dashboard/referrals");revalidatePath("/dashboard/finance/accounting");return {ok:true,message:v.action==="INVITE"?"Secure account setup instructions sent. Access is limited to this referrer’s own records.":"Saved successfully.",messageBn:v.action==="INVITE"?"নিরাপদ অ্যাকাউন্ট চালুর নির্দেশনা পাঠানো হয়েছে। কেবল নিজের রেফারেলের তথ্য দেখা যাবে।":"সফলভাবে সংরক্ষণ হয়েছে।"};
 }catch{return {ok:false,message:"The connection was interrupted. Reload the record to check whether it saved before retrying."};}
}
