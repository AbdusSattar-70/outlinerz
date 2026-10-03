"use server";
import {z} from "zod";
import {platformClient} from "@/modules/platform/rpc-client";
import {runCommandAction} from "@/modules/platform/command-action";
const schema=z.object({action:z.enum(["CLOSE","REOPEN"]),month:z.string().regex(/^\d{4}-\d{2}-01$/),request_id:z.string().uuid(),preview_token:z.string().min(1),reason:z.string().trim().min(10).max(1000)});
export async function periodAction(input:unknown){try{return await runCommandAction({schema,input,client:platformClient,rpc:"finance_period_command",permission:"accounting.period.manage",revalidate:["/dashboard/finance/reports"],mapResult:()=>({message:"Accounting period action recorded with its reviewed financial snapshot."})});}catch{return {ok:false as const,message:"Could not confirm the result. Inspect the period before changing inputs; unchanged retries reuse the request identity."};}}
