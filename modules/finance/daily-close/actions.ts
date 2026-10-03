"use server";
import {z} from "zod";
import {platformClient} from "@/modules/platform/rpc-client";
import {requirePermission} from "@/modules/platform/auth/erp-context";
import {runCommandAction} from "@/modules/platform/command-action";
import {closePreviewSchema} from "./queries";
const basis=z.object({account_id:z.string().uuid(),date:z.string().regex(/^\d{4}-\d{2}-\d{2}$/)});
const common={request_id:z.string().uuid(),reason:z.string().trim().min(5).max(1000)};
const review={...common,id:z.string().uuid(),journal_id:z.string().uuid().optional()};
const schema=z.discriminatedUnion("action",[basis.extend({...common,action:z.literal("COUNT"),actual:z.coerce.number(),denominations:z.array(z.object({value:z.number(),count:z.coerce.number().int().min(0)})).optional(),preview_token:z.string().min(1),statement_reference:z.string().trim().min(3).max(300),variance_note:z.string().max(1000),handed_to:z.string().uuid().optional()}),z.object({...review,action:z.literal("NOTE")}),z.object({...review,action:z.literal("RESOLVE")}),z.object({...review,action:z.literal("REOPEN")})]);
export async function previewClose(input:unknown){const parsed=basis.safeParse(input);if(!parsed.success)return {ok:false as const,message:parsed.error.issues[0].message};try{await requirePermission("accounting.reconcile");const db=await platformClient();const {data,error}=await db.rpc("daily_close_preview",{p_account_id:parsed.data.account_id,p_date:parsed.data.date});if(error)return {ok:false as const,message:error.message};return {ok:true as const,preview:closePreviewSchema.parse(data)};}catch{return {ok:false as const,message:"Balance preview unavailable. Check the connection and selected account."};}}
export async function closeAction(input:unknown){try{return await runCommandAction({schema,input,client:platformClient,rpc:"daily_close_command",permission:"accounting.reconcile",revalidate:["/dashboard/finance/daily-close"],mapResult:()=>({message:"Close evidence recorded. Ledger balances were not overwritten."})});}catch{return {ok:false as const,message:"Could not confirm the save. Inspect the register before changing inputs; an unchanged retry uses the same request identity."};}}
