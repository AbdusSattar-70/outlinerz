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
 await getMyBranches();
 const parsed=z.object({
  requestId:z.string().uuid("Reload this page and try again."),
  name:z.string().trim().min(2,"Enter a branch name with at least two characters.").max(120),
  slug:z.string().trim().transform(value=>value.toLowerCase().replace(/[\s_]+/g,"-").replace(/-+/g,"-").replace(/^-|-$/g,""))
   .pipe(z.string().regex(/^[a-z0-9][a-z0-9-]{2,62}$/, "Enter a URL slug with 3–63 English letters, numbers or hyphens, for example dhaka-branch.")),
  organizationName:z.string().trim().max(120)
 }).safeParse(Object.fromEntries(form));
 if(!parsed.success) redirect(`/branches?error=${encodeURIComponent(parsed.error.issues[0]?.message??"Check the branch details and try again.")}`);
 const input=parsed.data;
 const db=await platformClient();const{data,error}=await db.rpc("open_academy_branch",{p_request_id:input.requestId,p_name:input.name,p_slug:input.slug,p_organization_name:input.organizationName||null,p_demo:form.get("demo")==="on"});
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
