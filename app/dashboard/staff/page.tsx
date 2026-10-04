import Link from "next/link";
import {LocalizedText} from "@/components/shared/localized-text";
import {platformClient} from "@/modules/platform/rpc-client";
import {StaffRegister} from "@/modules/staff/components/staff-register";
import {CreateStaffForm} from "@/modules/staff/components/create-form";
import {UsersRound} from "lucide-react";
import {EmptyState} from "@/components/erp/empty-state";
import {PageHeader} from "@/components/erp/page-header";
import {getStaffList} from "@/modules/staff/queries";
import {can} from "@/types/erp";
import {requirePermission} from "@/modules/platform/auth/erp-context";
export default async function StaffPage(){
 const context=await requirePermission("staff.view");const db=await platformClient();const[rows,roles,subjects]=await Promise.all([getStaffList(),db.from("staff_roles").select("code,name").eq("is_active",true),db.from("subjects").select("id,name").eq("is_active",true).order("name")]);if(roles.error||subjects.error)throw new Error("Staff directory could not be loaded.");
 return <div className="space-y-7"><PageHeader eyebrow={<LocalizedText en="People" bn="ব্যক্তিবর্গ"/>} title={<LocalizedText en="Staff" bn="স্টাফ"/>} description={<LocalizedText en="Manage staff identity and teaching assignments in this branch. Roles describe responsibilities on the same person record." bn="এই শাখায় স্টাফের পরিচয় ও পাঠদানের দায়িত্ব পরিচালনা করুন। একই ব্যক্তির রেকর্ডে ভূমিকা অনুযায়ী দায়িত্ব নির্ধারিত হয়।"/>}/>{can(context,"system.users.manage")&&<Link href="/branches" className="inline-flex rounded-xl border px-4 py-3 font-semibold"><LocalizedText en="Manage branch account access →" bn="শাখার অ্যাকাউন্ট প্রবেশাধিকার পরিচালনা করুন →"/></Link>}{can(context,"staff.manage")&&<CreateStaffForm roles={roles.data??[]} subjects={subjects.data??[]}/>} {rows.length?<StaffRegister rows={rows} canManage={can(context,"staff.manage")}/>:<EmptyState icon={UsersRound} title="No Staff identities yet" description="Add verified account access under Branches, then create the staff identity and teaching subjects here."/>}</div>;
}
