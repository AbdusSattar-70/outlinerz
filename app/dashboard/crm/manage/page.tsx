import Link from "next/link";
import { PageHeader } from "@/components/erp/page-header";
import { MasterDataWorkspace } from "@/modules/crm/manage/components/master-data-workspace";
import { getManageCrmOverview } from "@/modules/crm/manage/queries";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { can } from "@/types/erp";

export default async function ManageCrmPage() {
  const context = await requirePermission("system.master_data.manage");
  const data = await getManageCrmOverview();
  const canManage = can(context, "system.master_data.manage");

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="CRM & Student Bank"
        title="Manage CRM"
        description="Edit branch academic and registration master data used by public forms, programme offerings and admissions. Deactivate rather than delete so history stays intact."
      />

      <section className="grid gap-3 rounded-2xl border bg-card p-5 sm:grid-cols-2 lg:grid-cols-4 sm:p-6">
        <SetupLink
          href="/dashboard/academics/offerings"
          title="Programme offerings"
          body="Year, branch, eligibility and public showcase content."
        />

        <SetupLink
          href="/dashboard/academics/batches"
          title="Batches"
          body="Capacity and placement options for active offerings."
        />
        <SetupLink
          href="/dashboard/crm/prospects"
          title="Prospects"
          body="Verification queue for interest and admission submissions."
        />
      </section>

      <MasterDataWorkspace data={data} canManage={canManage} />
    </div>
  );
}

function SetupLink({
  href,
  title,
  body,
}: {
  href: string;
  title: string;
  body: string;
}) {
  return (
    <Link
      href={href}
      className="rounded-xl border bg-background p-4 transition hover:border-primary/40 hover:bg-muted/40"
    >
      <p className="text-sm font-semibold">{title}</p>
      <p className="mt-1 text-xs leading-5 text-muted-foreground">{body}</p>
    </Link>
  );
}
