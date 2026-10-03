"use server";
import { z } from "zod";
import { platformClient } from "@/modules/platform/rpc-client";
import { runCommandAction } from "@/modules/platform/command-action";
const common={staff_id:z.string().uuid(),request_id:z.string().uuid(),reason:z.string().trim().min(5).max(1000)};
const date=z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
const schema=z.discriminatedUnion("action",[
 z.object({...common,action:z.literal("RECORD_ATTENDANCE"),work_date:date,status:z.enum(["PRESENT","ABSENT","LEAVE","HOLIDAY"]),started_at:z.string().optional(),ended_at:z.string().optional(),break_minutes:z.coerce.number().int().min(0).max(1440)}),
 z.object({...common,action:z.literal("SAVE_TERMS"),model:z.enum(["FIXED","HOURLY","REVENUE_SHARE","HYBRID"]),monthly_base:z.coerce.number().min(0),hourly_rate:z.coerce.number().min(0),pay_day:z.coerce.number().int().min(1).max(28),effective_from:date})]);
export async function workforceAction(input:unknown){try{return await runCommandAction({schema,input,client:platformClient,rpc:"workforce_command",permission:"workforce.manage",revalidate:["/dashboard/my-work","/dashboard/staff/operations"],mapResult:()=>({message:"Saved. Attendance and terms remain in the audit history."})});}catch{return {ok:false as const,message:"Could not confirm the save. Refresh the record before retrying."};}}
