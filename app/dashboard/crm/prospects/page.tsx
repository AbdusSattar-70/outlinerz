import Link from "next/link";
import { ExternalLink } from "lucide-react";
import { PageHeader } from "@/components/erp/page-header";
import { ProspectTable } from "@/modules/crm/components/prospect-table";
import { getProspectList } from "@/modules/crm/queries";
import { requirePermission } from "@/modules/platform/auth/erp-context";

export default async function ProspectsPage() {
  await requirePermission("crm.prospects.view");
  const rows = await getProspectList();

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="CRM & Student Bank"
        title="Prospects"
        description="Verification queue for public interest and admission submissions. Filter by queue status, intent and schools that still need review before counselling or admission."
        actions={
          <div className="flex flex-wrap gap-2">
            <Link
              href="/dashboard/crm/manage"
              className="inline-flex min-h-11 items-center gap-2 rounded-xl border bg-background px-4 text-sm font-semibold hover:bg-muted"
            >
              Manage CRM
            </Link>
            <Link
              href="/interest"
              target="_blank"
              className="inline-flex min-h-11 items-center gap-2 rounded-xl border bg-background px-4 text-sm font-semibold hover:bg-muted"
            >
              Public interest form
              <ExternalLink className="size-4" aria-hidden="true" />
            </Link>
          </div>
        }
      />

      <ProspectTable rows={rows} />
    </div>
  );
}
