import {z} from "zod";
import {platformClient} from "@/modules/platform/rpc-client";
const id=z.string().uuid();
export const taskSchema=z.object({manager:z.boolean(),staffId:id.nullable(),ownStaffId:id.nullable(),total:z.number(),stats:z.object({open:z.number(),review:z.number(),completed:z.number(),blocked:z.number(),overdue:z.number()}),tasks:z.array(z.object({id,staff_id:id,title:z.string(),instructions:z.string(),due_on:z.string(),status:z.string(),progress:z.number(),blocker:z.string(),review_note:z.string().nullable()}))});
export type TaskData=z.infer<typeof taskSchema>;
export async function getTaskData(staffId?:string,history=false,page=1){const db=await platformClient();const {data,error}=await db.rpc("staff_tasks_workspace",{p_staff_id:staffId??null,p_history:history,p_page:page});if(error)throw Error(error.message);return taskSchema.parse(data);}
