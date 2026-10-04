"use server";
import {z} from "zod";
import {revalidatePath} from "next/cache";
import {platformClient} from "@/modules/platform/rpc-client";
import {getErpContext} from "@/modules/platform/auth/erp-context";
const schema=z.object({full_name:z.string().trim().min(2).max(160),mobile:z.string().regex(/^01[3-9][0-9]{8}$/),email:z.union([z.string().email(),z.literal("")]),staff_role_code:z.string().min(1),subject_ids:z.array(z.string().uuid()).max(30)});
export async function createBranchStaff(input:unknown){
 const parsed=schema.safeParse(input);if(!parsed.success)return {ok:false,message:parsed.error.issues[0].message};
 if(!(await getErpContext())?.permissions.includes("staff.manage"))return {ok:false,message:"Staff management permission required."};
 const db=await platformClient();const{error}=await db.rpc("create_staff_member",{p_input:parsed.data});
 if(error)return {ok:false,message:error.message};revalidatePath("/dashboard/staff");revalidatePath("/dashboard");return {ok:true,message:"Staff identity created in this branch."};
}
