import { PageHeader } from "@/components/erp/page-header";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { getFinanceAccountingWorkspace } from "@/modules/finance/accounting/queries";
import { FinanceAccountingWorkspace } from "@/modules/finance/accounting/workspace";

export default async function FinanceAccountingPage() {
  await requirePermission("accounting.view");
  const data = await getFinanceAccountingWorkspace();
  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="Finance & Accounting"
        title="Accounting & Settlements"
        description="General ledger, advances, payables, expenses, reconciliation and teacher compensation."
      />
      <FinanceAccountingWorkspace initialData={data} />
    </div>
  );
}
