"use server";
import { z } from "zod";
import { platformClient } from "@/modules/platform/rpc-client";
import { runCommandAction } from "@/modules/platform/command-action";
const common={staff_id:z.string().uuid(),request_id:z.string().uuid(),reason:z.string().trim().min(5).max(1000)};
const date=z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
const schema=z.discriminatedUnion("action",[
 z.object({...common,action:z.literal("RECORD_ATTENDANCE"),work_date:date,status:z.enum(["PRESENT","ABSENT","LEAVE","HOLIDAY"]),started_at:z.string().optional(),ended_at:z.string().optional(),break_minutes:z.coerce.number().int().min(0).max(1440)})]);
export async function workforceAction(input:unknown){try{return await runCommandAction({schema,input,client:platformClient,rpc:"workforce_command",permission:"workforce.manage",revalidate:["/dashboard/my-work","/dashboard/staff/operations"],mapResult:()=>({message:"Saved. Attendance remains in the audit history."})});}catch{return {ok:false as const,message:"Could not confirm the save. Refresh the record before retrying."};}}
