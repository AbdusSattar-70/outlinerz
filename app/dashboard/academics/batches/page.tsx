import Link from "next/link";
import { PageHeader } from "@/components/erp/page-header";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { getAdmissionWorkspace } from "@/modules/admissions/queries";
import { BatchRegister } from "@/modules/admissions/components/batch-register";

export default async function BatchesPage() {
  const context = await requirePermission("academics.view");
  const data = await getAdmissionWorkspace();
  return <div className="space-y-6">
    <PageHeader eyebrow="Academic Setup" title="Batches" description="Manage programme cohorts, seat capacity and placement. Existing admissions keep their batch history when you update a batch." />
    <p className="text-sm text-muted-foreground"><Link className="underline" href="/dashboard/academics/offerings">Programme Offerings</Link> <span aria-hidden="true">→</span> Fee Plan → Batch → Admission</p>
    <BatchRegister data={data} canManage={context.permissions.includes("academics.manage")}/>
  </div>;
}
