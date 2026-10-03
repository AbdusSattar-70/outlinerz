import { z } from "zod";
import { platformClient } from "@/modules/platform/rpc-client";
const id = z.string().uuid();
export const referrerWorkspaceSchema = z.object({
  ownReferrerId:id.nullable(), teacher:z.boolean(),
  policy:z.object({acquisitionPercent:z.number().nullable(),teachingPoolPercent:z.number().nullable(),teachingReviewMaxPercent:z.number().nullable(),retention3Percent:z.number().nullable(),retention6Percent:z.number().nullable()}),
  teachingEarned:z.number(),teachingSettled:z.number(),advanceOutstanding:z.number(),
  teachingLines:z.array(z.object({id,run:z.string(),from:z.string(),to:z.string(),type:z.string(),amount:z.number(),netTuition:z.number().nullable(),poolPercent:z.number().nullable(),approvedSessions:z.number().nullable(),batchApprovedSessions:z.number().nullable()})),
  teachingPayments:z.array(z.object({date:z.string(),run:z.string(),gross:z.number(),cash:z.number(),advanceOffset:z.number(),reference:z.string().nullable()})),
  manager: z.boolean(), selected: id.nullable(), name: z.string().nullable(), earned: z.number(), settled: z.number(),
  people: z.array(z.object({id,name:z.string(),mobile:z.string().nullable(),email:z.string().nullable(),staffId:id.nullable(),profileId:id.nullable(),active:z.boolean(),relationship:z.string().nullable(),notes:z.string().nullable()})),
  students: z.array(z.object({id,number:z.string(),name:z.string(),studentNo:z.string().nullable(),programme:z.string(),status:z.string(),discountPercent:z.number(),discountAmount:z.number(),netTuition:z.number(),reward:z.number(),rate:z.number().nullable(),collections:z.array(z.object({receipt:z.string(),receivedOn:z.string(),allocated:z.number(),billingPeriod:z.string(),tuitionCollected:z.number()}))})),
  entries:z.array(z.object({id,admissionId:id,amount:z.number(),collected:z.number(),rate:z.number(),date:z.string()})),
  settlements:z.array(z.object({amount:z.number(),date:z.string(),reference:z.string().nullable()})),
  accounts:z.array(z.object({id,name:z.string()})),
});
export type ReferrerWorkspace = z.infer<typeof referrerWorkspaceSchema>;
export async function getReferrerWorkspace(id?:string){const db=await platformClient();const {data,error}=await db.rpc("referrer_workspace",{p_referrer_id:id??null});if(error)throw new Error(error.message);return referrerWorkspaceSchema.parse(data);}
