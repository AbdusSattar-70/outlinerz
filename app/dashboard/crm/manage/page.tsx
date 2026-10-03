import Link from "next/link";
import { PageHeader } from "@/components/erp/page-header";
import { MasterDataWorkspace } from "@/modules/crm/manage/components/master-data-workspace";
import { getManageCrmOverview } from "@/modules/crm/manage/queries";
import { crmAccess } from "@/modules/crm/access";
import { LocalizedText as L } from "@/components/shared/localized-text";

export default async function ManageCrmPage() {
  const { crmEnabled } = await crmAccess();
  const data = await getManageCrmOverview();
  const canManage = crmEnabled;

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow={<L en="CRM & Student Bank" bn="যোগাযোগ ও শিক্ষার্থী তথ্য" />}
        title={<L en="Manage CRM" bn="যোগাযোগ ব্যবস্থাপনা" />}
        description={
          <L
            en="Maintain academic and registration directories. Deactivate records to preserve their history."
            bn="একাডেমিক ও নিবন্ধনের তথ্যতালিকা পরিচালনা করুন। ইতিহাস সংরক্ষণ করতে তথ্য মুছে না দিয়ে নিষ্ক্রিয় করুন।"
          />
        }
      />

      <Link
        href="/dashboard/crm/prospects"
        className="inline-flex rounded-xl border bg-background px-4 py-3 text-sm font-semibold"
      >
        <L en="Open prospects" bn="সম্ভাব্য শিক্ষার্থীর তালিকা খুলুন" />
      </Link>

      <MasterDataWorkspace data={data} canManage={canManage} />
    </div>
  );
}
