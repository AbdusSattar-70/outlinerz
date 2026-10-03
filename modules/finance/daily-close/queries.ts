import {z} from "zod";
import {platformClient} from "@/modules/platform/rpc-client";
const id=z.string().uuid();
export const closePreviewSchema=z.object({accountId:id,name:z.string(),subtype:z.string(),date:z.string(),opening:z.number(),receipts:z.number(),payments:z.number(),expected:z.number(),token:z.string()});
export type ClosePreview=z.infer<typeof closePreviewSchema>;
export const closeSchema=z.object({total:z.number(),people:z.array(z.object({id,name:z.string()})),accounts:z.array(z.object({id,name:z.string(),subtype:z.string()})),records:z.array(z.object({id,close_no:z.string(),name:z.string(),close_date:z.string(),expected:z.number(),actual:z.number(),variance:z.number(),recorded_at:z.string(),actor:z.string().nullable(),receiver:z.string().nullable(),explanation:z.string(),statement_reference:z.string(),stale:z.boolean(),resolution:z.string(),resolution_stale:z.boolean(),notes:z.array(z.object({action:z.string(),reason:z.string(),date:z.string(),journalId:id.nullable()}))}))});
export type CloseData=z.infer<typeof closeSchema>;
export async function getCloseData(page=1){const db=await platformClient();const {data,error}=await db.rpc("daily_close_workspace",{p_page:page});if(error)throw Error(error.message);return closeSchema.parse(data);}
