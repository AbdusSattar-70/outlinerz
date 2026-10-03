import { z } from "zod";
import { platformClient } from "@/modules/platform/rpc-client";
const uuid=z.string().uuid();
export const workSchema=z.object({manager:z.boolean(),staffId:uuid.nullable(),name:z.string().nullable(),month:z.string(),total:z.number(),presentDays:z.number(),hours:z.number(),previousMonthPaid:z.number(),scheduledPayDate:z.string().nullable(),hourlyEstimate:z.number(),
 people:z.array(z.object({id:uuid,name:z.string(),number:z.string()})),
 terms:z.object({model:z.enum(["FIXED","HOURLY","REVENUE_SHARE","HYBRID"]),monthly_base:z.number(),hourly_rate:z.number(),pay_day:z.number(),effective_from:z.string()}).nullable(),
 records:z.array(z.object({id:uuid,work_date:z.string(),status:z.string(),started_at:z.string().nullable(),ended_at:z.string().nullable(),break_minutes:z.number(),reason:z.string(),hours:z.number()}))});
export type WorkData=z.infer<typeof workSchema>;
export async function getWorkData(month?:string,staffId?:string,page=1){const db=await platformClient();const {data,error}=await db.rpc("staff_work_workspace",{p_month:month??null,p_staff_id:staffId??null,p_page:page});if(error)throw Error(error.message);return workSchema.parse(data);}
