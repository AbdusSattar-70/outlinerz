import Link from "next/link";
import { ExternalLink } from "lucide-react";
import { PageHeader } from "@/components/erp/page-header";
import { ProspectTable } from "@/modules/crm/components/prospect-table";
import { getProspectList } from "@/modules/crm/queries";
import { crmAccess } from "@/modules/crm/access";
import { LocalizedText as L } from "@/components/shared/localized-text";

export default async function ProspectsPage() {
  const { organization } = await crmAccess();
  const rows = await getProspectList();

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow={<L en="CRM & Student Bank" bn="যোগাযোগ ও শিক্ষার্থী তথ্য" />}
        title={<L en="Prospects" bn="সম্ভাব্য শিক্ষার্থী" />}
        description={
          <L
            en="Review enquiries, assign follow-up and verify student details before admission."
            bn="অনুসন্ধান পর্যালোচনা করুন, ফলো-আপের দায়িত্ব দিন এবং ভর্তির আগে শিক্ষার্থীর তথ্য যাচাই করুন।"
          />
        }
        actions={
          <div className="flex flex-wrap gap-2">
            <Link
              href="/dashboard/crm/manage"
              className="inline-flex min-h-11 items-center gap-2 rounded-xl border bg-background px-4 text-sm font-semibold hover:bg-muted"
            >
              <L en="Manage CRM" bn="যোগাযোগ ব্যবস্থাপনা" />
            </Link>
            <Link
              href={`/interest?organization=${organization.slug}`}
              target="_blank"
              className="inline-flex min-h-11 items-center gap-2 rounded-xl border bg-background px-4 text-sm font-semibold hover:bg-muted"
            >
              <L en="Public interest form" bn="আগ্রহ নিবন্ধনের ফর্ম" />
              <ExternalLink className="size-4" aria-hidden="true" />
            </Link>
          </div>
        }
      />

      <ProspectTable rows={rows} />
    </div>
  );
}
