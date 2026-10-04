"use server";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { z } from "zod";
import { platformClient } from "@/modules/platform/rpc-client";
import { getMyBranches,requireSelectedBranch } from "./server";
async function select(id:string,slug:string){
 const store=await cookies();const options={httpOnly:true,secure:process.env.NODE_ENV==="production",sameSite:"lax" as const,path:"/",maxAge:60*60*24*30};
 store.set("academy-branch",id,options);store.set("academy-public-branch",slug,options);
}
export async function selectBranch(form:FormData){
 const id=z.string().uuid().parse(form.get("branchId"));const branch=(await getMyBranches()).find(b=>b.id===id);
 if(!branch) throw new Error("You do not have access to this branch.");await select(branch.id,branch.slug);redirect("/dashboard");
}
export async function openBranch(form:FormData){
 await getMyBranches();const input=z.object({requestId:z.string().uuid(),name:z.string().trim().min(2).max(120),slug:z.string().regex(/^[a-z0-9][a-z0-9-]{2,62}$/),organizationName:z.string().trim().max(120)}).parse(Object.fromEntries(form));
 const db=await platformClient();const{data,error}=await db.rpc("open_academy_branch",{p_request_id:input.requestId,p_name:input.name,p_slug:input.slug,p_organization_name:input.organizationName||null});
 if(error) redirect(`/branches?error=${encodeURIComponent(error.message)}`);
 const branch=z.object({id:z.string().uuid(),slug:z.string()}).parse(data);await select(branch.id,branch.slug);redirect("/dashboard");
}
export async function addBranchMember(form:FormData){
 await requireSelectedBranch();const email=z.string().email().parse(form.get("email"));const role=z.enum(["ADMIN","ACADEMIC_DIRECTOR","OPERATOR","TEACHER"]).parse(form.get("role"));
 const db=await platformClient();const {error}=await db.rpc("add_branch_member",{p_email:email,p_role_code:role});
 if(error) redirect(`/branches?error=${encodeURIComponent(error.message)}`);redirect("/branches?added=1");
}
export async function removeBranchMember(form:FormData){
 await requireSelectedBranch();const email=z.string().email().parse(form.get("email"));
 const db=await platformClient();const {error}=await db.rpc("remove_branch_member",{p_email:email});
 if(error)redirect(`/branches?error=${encodeURIComponent(error.message)}`);redirect("/branches?removed=1");
}
