import {z} from "zod";
import {platformClient} from "@/modules/platform/rpc-client";
const id=z.string().uuid();
const item=z.object({label:z.string(),amount:z.number(),kind:z.string().optional()});
export const snapshotSchema=z.object({name:z.string(),number:z.string(),month:z.string(),eligibleFrom:z.string(),hours:z.number(),base:z.number(),hourly:z.number(),allowanceTotal:z.number(),gross:z.number(),corrections:z.number(),net:z.number(),dueOn:z.string(),canPost:z.boolean(),token:z.string(),allowances:z.array(item),correctionItems:z.array(item),terms:z.object({model:z.string(),monthly_base:z.number(),hourly_rate:z.number(),pay_day:z.number()})});
export type PayrollPreview=z.infer<typeof snapshotSchema>;
export const payrollSchema=z.object({manager:z.boolean(),total:z.number(),people:z.array(z.object({id,name:z.string()})),accounts:z.array(z.object({id,name:z.string()})),advances:z.array(z.object({id,staffId:id,name:z.string(),balance:z.number()})),records:z.array(z.object({id,payroll_no:z.string(),staff_id:id,month:z.string(),net:z.number(),gross:z.number(),corrections:z.number(),due_on:z.string(),posted_at:z.string(),status:z.string(),settled:z.number(),snapshot:snapshotSchema,payments:z.array(z.object({date:z.string(),amount:z.number(),offset:z.boolean(),reference:z.string().nullable()}))}))});
export type PayrollData=z.infer<typeof payrollSchema>;
export async function getPayrollData(payrollId?:string,page=1){const db=await platformClient();const {data,error}=await db.rpc("staff_payroll_workspace",{p_id:payrollId??null,p_page:page});if(error)throw Error(error.message);return payrollSchema.parse(data);}
export async function getMySalarySummary(){const db=await platformClient();const {data,error}=await db.rpc("my_salary_summary");if(error)throw Error(error.message);return z.object({latestMonth:z.string().nullable(),latestNet:z.number().nullable(),outstanding:z.number(),nextDue:z.string().nullable()}).parse(data);}
