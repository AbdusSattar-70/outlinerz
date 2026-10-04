import "server-only";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { z } from "zod";
import { createClient, getVerifiedUser } from "@/lib/supabase/server";
import { platformClient } from "@/modules/platform/rpc-client";
const branchSchema = z.object({id:z.string().uuid(),name:z.string(),slug:z.string(),organizationName:z.string(),isOwner:z.boolean()});
export async function getMyBranches(){
 const client=await createClient();const {data:{user}}=await getVerifiedUser(client);
 if(!user) redirect("/auth/sign-in");
 const db=await platformClient();const {data,error}=await db.rpc("list_my_branches");
 if(error) throw new Error(error.message);
 return z.array(branchSchema).parse(data);
}
export async function requireSelectedBranch(){
 const branches=await getMyBranches();const selected=(await cookies()).get("academy-branch")?.value;
 const branch=branches.find(b=>b.id===selected);if(!branch) redirect("/branches");return branch;
}
