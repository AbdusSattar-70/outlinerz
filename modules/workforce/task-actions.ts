"use server";
import {z} from "zod";
import {platformClient} from "@/modules/platform/rpc-client";
import {runCommandAction} from "@/modules/platform/command-action";
const common={request_id:z.string().uuid(),reason:z.string().trim().min(5).max(1000)};
const identity={id:z.string().uuid()};
const assignment={staff_id:z.string().uuid(),title:z.string().trim().min(3).max(160),instructions:z.string().max(4000),due_on:z.string().regex(/^\d{4}-\d{2}-\d{2}$/)};
const schema=z.discriminatedUnion("action",[
 z.object({...common,...assignment,action:z.literal("CREATE")}),z.object({...common,...identity,...assignment,action:z.literal("EDIT")}),
 z.object({...common,...identity,action:z.literal("REPORT"),progress:z.coerce.number().int().min(0).max(99),blocker:z.string().max(2000)}),
 z.object({...common,...identity,action:z.literal("SUBMIT"),blocker:z.string().max(2000)}),
 z.object({...common,...identity,action:z.literal("ACCEPT")}),z.object({...common,...identity,action:z.literal("RETURN")}),z.object({...common,...identity,action:z.literal("CANCEL")})]);
export async function taskAction(input:unknown){try{return await runCommandAction({schema,input,client:platformClient,rpc:"staff_task_command",permission:["workforce.manage","workforce.self.view"],revalidate:["/dashboard/my-work","/dashboard/staff/operations"],mapResult:()=>({message:"Task saved. Reported completion requires administrative acceptance."})});}catch{return {ok:false as const,message:"Could not confirm the save. Refresh this task before retrying."};}}
