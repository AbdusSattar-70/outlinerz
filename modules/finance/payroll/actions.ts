"use server";
import {z} from "zod";
import {platformClient} from "@/modules/platform/rpc-client";
import {requirePermission} from "@/modules/platform/auth/erp-context";
import {runCommandAction} from "@/modules/platform/command-action";
import {snapshotSchema} from "./queries";
const item=z.object({label:z.string().trim().min(3).max(300),amount:z.coerce.number().positive(),kind:z.enum(["UNPAID_LEAVE","ABSENCE","EARNING_CORRECTION"]).optional()});
const basis=z.object({staff_id:z.string().uuid(),month:z.string().regex(/^\d{4}-\d{2}-01$/),allowances:z.array(item).max(20),corrections:z.array(item).max(20)});
const common={request_id:z.string().uuid(),reason:z.string().trim().min(5).max(1000)};
const schema=z.discriminatedUnion("action",[basis.extend({...common,action:z.literal("POST"),preview_token:z.string().min(1)}),z.object({...common,action:z.literal("SETTLE"),id:z.string().uuid(),cash:z.coerce.number().min(0),advance_offset:z.coerce.number().min(0),account_id:z.string().uuid().optional(),advance_id:z.string().uuid().optional(),reference:z.string().max(300)})]);
export async function previewPayroll(input:unknown){const parsed=basis.safeParse(input);if(!parsed.success)return {ok:false as const,message:parsed.error.issues[0].message};try{await requirePermission("payroll.manage");const db=await platformClient();const {data,error}=await db.rpc("staff_payroll_preview",{p_input:parsed.data});if(error)return {ok:false as const,message:error.message};return {ok:true as const,preview:snapshotSchema.parse(data)};}catch{return {ok:false as const,message:"Preview unavailable. Check your connection and agreed compensation terms."};}}
export async function payrollAction(input:unknown){try{return await runCommandAction({schema,input,client:platformClient,rpc:"staff_payroll_command",permission:"payroll.manage",revalidate:["/dashboard/finance/payroll","/dashboard/my-work","/dashboard/finance/accounting"],mapResult:()=>({message:"Payroll action posted with balanced accounting and audit evidence."})});}catch{return {ok:false as const,message:"Result could not be confirmed. Inspect the payroll before changing inputs; unchanged retries reuse the request ID."};}}
