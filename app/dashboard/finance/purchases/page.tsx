import { requirePermission } from "@/modules/platform/auth/erp-context";
import { PageHeader } from "@/components/erp/page-header";
import { getPurchases } from "@/modules/finance/purchases/queries";
import { PurchaseRegister } from "@/modules/finance/purchases/register";
export default async function Purchases({ searchParams }: {
    searchParams: Promise<{
        page?: string;
        status?: string;
        q?: string;
    }>;
}) { await requirePermission("accounting.expense.manage"); const q = await searchParams; const page = Math.min(100000, Math.max(1, Number.parseInt(q.page ?? "1", 10) || 1)); const status = ["DRAFT", "POSTED", "CANCELLED"].includes(q.status ?? "") ? q.status! : "ALL"; const search = (q.q ?? "").slice(0, 100); return <div className="space-y-6"><PageHeader eyebrow="Finance" title="Purchases & supplier expenses" description="Draft → verify full receipt → post expense → settle supplier balance. Drafts do not move money."/><PurchaseRegister data={await getPurchases(page, status, search)} status={status} search={search}/></div>; }
