import { PageHeader } from "@/components/erp/page-header";
import { OfferingRegister } from "@/modules/offerings/components/offering-register";
import { getOfferingOverview } from "@/modules/offerings/queries";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { can } from "@/types/erp";

export default async function ProgrammeOfferingsPage() {
  const context = await requirePermission("academics.view");
  const data = await getOfferingOverview();
  return <div className="space-y-7">
    <PageHeader eyebrow="Academics" title="Programme Offerings"
      description="Manage academic offerings from one register. Create or edit an offering from its row; use Public settings for website presentation and application intake."/>
    <OfferingRegister data={data} canManage={can(context,"academics.manage")} canViewFees={can(context,"finance.view")}/>
  </div>;
}
