import Link from "next/link";
import { LocalizedText } from "@/components/shared/localized-text";
import { platformClient } from "@/modules/platform/rpc-client";
import { AccessRequestRegister } from "@/modules/platform/access/request-register";

import { StaffRegister } from "@/modules/staff/components/staff-register";
import { RecordStateButton } from "@/components/erp/record-state-button";
import { StaffEditButton } from "@/components/erp/staff-edit-button";
import { UsersRound } from "lucide-react";
import { EmptyState } from "@/components/erp/empty-state";
import { PageHeader } from "@/components/erp/page-header";
import { StatusBadge } from "@/components/erp/status-badge";

import { getStaffList } from "@/modules/staff/queries";
import { can } from "@/types/erp";
import { requirePermission } from "@/modules/platform/auth/erp-context";

export default async function StaffPage({searchParams}:{searchParams:Promise<{requestsPage?:string;requestsView?:string}>}) {
  const context = await requirePermission("staff.view");
  const rows = await getStaffList();

  const query=await searchParams;const page=Math.max(1,Math.min(10000,Number.parseInt(query.requestsPage??"1",10)||1));
  const history=query.requestsView==="history";
  const db=await platformClient();const requests=can(context,"system.users.manage")?await db.from("staff_access_requests").select("id,full_name,email,mobile,requested_role,purpose,status,assigned_role",{count:"exact"}).in("status",history?["ACTIVE","DECLINED","INACTIVE"]:["PENDING","VERIFIED","INVITED"]).order("created_at",{ascending:false}).order("id",{ascending:false}).range((page-1)*25,page*25-1):null;
  if(requests?.error)throw Error(requests.error.message);

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow={<LocalizedText en="People" bn="ব্যক্তিবর্গ"/>}
        title={<LocalizedText en="Staff" bn="স্টাফ"/>}
        description={<LocalizedText en="Manage staff identity, access requests and teaching assignments together. Roles describe responsibilities on the same person record." bn="একই জায়গায় স্টাফের পরিচয়, প্রবেশাধিকারের অনুরোধ ও পাঠদানের দায়িত্ব পরিচালনা করুন। একই ব্যক্তির রেকর্ডে ভূমিকা অনুযায়ী দায়িত্ব নির্ধারিত হয়।"/>}
      />

      {requests&&<section id="staff-access" className="space-y-4 rounded-xl border p-5"><h2 className="text-lg font-semibold"><LocalizedText en="Staff access requests" bn="স্টাফ প্রবেশাধিকারের অনুরোধ"/></h2><p className="text-sm text-muted-foreground"><LocalizedText en="Verify identity and responsibilities, choose the permitted role, then send secure account setup instructions. Requested roles never grant access automatically." bn="পরিচয় ও দায়িত্ব যাচাই করে অনুমোদিত ভূমিকা নির্বাচন করুন, তারপর নিরাপদ অ্যাকাউন্ট চালুর নির্দেশনা পাঠান। অনুরোধ করলেই প্রবেশাধিকার দেওয়া হয় না।"/></p><Link className="text-sm underline" href="https://github.com/AbdusSattar-70/sohoj-academy/blob/feature/redesign_refactor/docs/architecture/ACCOUNT_SETUP_CONFIGURATION.md" target="_blank" rel="noopener noreferrer"><LocalizedText en="Account setup and role assignment guide" bn="অ্যাকাউন্ট চালু ও ভূমিকা নির্ধারণের নির্দেশনা"/></Link><nav className="flex gap-4"><Link href="/dashboard/staff#staff-access">Pending setup</Link><Link href="/dashboard/staff?requestsView=history#staff-access">Completed / closed requests</Link></nav><AccessRequestRegister rows={requests.data??[]}/><nav className="flex gap-4 text-sm">{page>1&&<Link href={`/dashboard/staff?requestsView=${history?"history":"queue"}&requestsPage=${page-1}#staff-access`}><LocalizedText en="Previous" bn="পেছনে"/></Link>}{page*25<(requests.count??0)&&<Link href={`/dashboard/staff?requestsView=${history?"history":"queue"}&requestsPage=${page+1}#staff-access`}><LocalizedText en="Next" bn="পরবর্তী"/></Link>}<span>{requests.count??0} <LocalizedText en="requests" bn="অনুরোধ"/></span></nav></section>}
      {rows.length ? (
        <StaffRegister rows={rows} canManage={can(context,"staff.manage")} />
      ) : (
        <EmptyState
          icon={UsersRound}
          title="No Staff identities yet"
          description="The first administrator bootstrap creates the initial Staff identity. Additional staff request access on the website; verify their identity here before granting access."
        />
      )}
    </div>
  );
}
