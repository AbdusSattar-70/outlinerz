import {z} from "zod";
import {platformClient} from "@/modules/platform/rpc-client";
export const reportSchema=z.object({month:z.string(),through:z.string(),generatedAt:z.string(),token:z.string(),status:z.string(),canClose:z.boolean(),canManage:z.boolean(),revenue:z.number(),reductions:z.number(),expenses:z.number(),profit:z.number(),assets:z.number(),liabilities:z.number(),equity:z.number(),retainedResult:z.number(),balanceDifference:z.number(),cashOpening:z.number(),cashClosing:z.number(),
 accounts:z.array(z.object({id:z.string().uuid(),code:z.string(),name:z.string(),type:z.string(),subtype:z.string(),opening:z.number(),debit:z.number(),credit:z.number(),closing:z.number(),endingDebit:z.number(),endingCredit:z.number()})),
 cashMovements:z.array(z.object({type:z.string(),source:z.string(),net:z.number()})),closeChecks:z.array(z.object({id:z.string().uuid(),name:z.string(),matched:z.boolean()})),events:z.array(z.object({action:z.string(),reason:z.string(),date:z.string(),actor:z.string().nullable()}))});
export type ReportData=z.infer<typeof reportSchema>;
export async function getMonthlyReport(month?:string){const db=await platformClient();const {data,error}=await db.rpc("monthly_financial_report",{p_month:month??null});if(error)throw Error(error.message);return reportSchema.parse(data);}
