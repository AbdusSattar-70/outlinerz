import Link from "next/link";
import { ClipboardCheck } from "lucide-react";
import { EmptyState } from "@/components/erp/empty-state";
import { PageHeader } from "@/components/erp/page-header";
import { StatusBadge } from "@/components/erp/status-badge";
import { getApprovalList } from "@/modules/governance/queries";
import { requirePermission } from "@/modules/platform/auth/erp-context";

export default async function ApprovalsPage() {
  await requirePermission("approvals.view");
  const rows = await getApprovalList();

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="Governance"
        title="Approval Register"
        description="Teacher submissions remain traceable through administrative review. Admin admission and finance actions post directly with audit evidence."
      />

      <Link href="/dashboard/action-center" className="inline-block text-sm underline">
        Open teacher academic review tasks
      </Link>
      {rows.length ? (
        <section className="overflow-hidden rounded-2xl border bg-card">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[980px] text-sm">
              <thead>
                <tr className="border-b bg-muted/40 text-left">
                  <th className="px-4 py-3 font-semibold">Workflow</th>
                  <th className="px-4 py-3 font-semibold">Entity</th>
                  <th className="px-4 py-3 font-semibold">Requested action</th>
                  <th className="px-4 py-3 font-semibold">Requested</th>
                  <th className="px-4 py-3 font-semibold">Status</th>
                  <th className="px-4 py-3 font-semibold">Notes</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.id} className="border-b align-top">
                    <td className="px-4 py-3 font-medium">
                      {row.workflow_type}
                    </td>
                    <td className="px-4 py-3">
                      <p>{row.entity_type}</p>
                      <p className="mt-1 max-w-48 truncate text-xs text-muted-foreground">
                        {row.entity_id}
                      </p>
                    </td>
                    <td className="px-4 py-3">
                      {row.requested_action}
                      {row.workflow_type === "ATTENDANCE" && (
                        <Link
                          className="mt-2 block underline"
                          href={`/dashboard/academics/sessions/${row.entity_id}`}
                        >
                          Review class attendance
                        </Link>
                      )}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {new Date(row.requested_at).toLocaleString()}
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge value={row.status} />
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {row.decision_note ?? row.request_note ?? "—"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      ) : (
        <EmptyState
          icon={ClipboardCheck}
          title="Approval register is empty"
          description="Approval requests will appear here when a controlled workflow is submitted."
        />
      )}
    </div>
  );
}
