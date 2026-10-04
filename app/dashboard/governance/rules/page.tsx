import { PolicyControlCenter } from "@/modules/settings/components/policy-control-center";
import { ShieldCheck } from "lucide-react";
import { EmptyState } from "@/components/erp/empty-state";
import { PageHeader } from "@/components/erp/page-header";
import { StatusBadge } from "@/components/erp/status-badge";
import { getBusinessRules } from "@/modules/governance/queries";
import { requirePermission } from "@/modules/platform/auth/erp-context";

export default async function BusinessRulesPage() {
  const context = await requirePermission("system.rules.view");
  const rows = await getBusinessRules();

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="Governance"
        title="Business Rules"
        description="Set academic batch capacity. Changes apply to future operations; historical records remain auditable."
      />

      {context.permissions.includes("system.settings.manage") && (
        <PolicyControlCenter
          rules={rows
            .filter((r) => r.status === "ACTIVE")
            .map((r) => ({
              id: r.id,
              domain: r.domain,
              ruleKey: r.rule_key,
              version: r.version,
              status: r.status,
              payload: r.payload,
              changeReason: r.change_reason,
              effectiveFrom: r.effective_from,
            }))}
        />
      )}
      <details className="rounded-xl border p-5">
        <summary className="cursor-pointer font-semibold">
          View current settings and history
        </summary>
        {rows.length ? (
          <div className="grid gap-4 lg:grid-cols-2">
            {rows.map((row) => (
              <section key={row.id} className="rounded-2xl border bg-card p-5">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <p className="text-xs font-bold uppercase tracking-[0.16em] text-muted-foreground">
                      {row.domain}
                    </p>
                    <h2 className="mt-1 font-semibold">{row.rule_key}</h2>
                  </div>
                  <StatusBadge value={row.status} />
                </div>

                <div className="mt-4 rounded-xl bg-muted/50 p-4">
                  <pre className="overflow-x-auto whitespace-pre-wrap text-xs leading-5">
                    {JSON.stringify(row.payload, null, 2)}
                  </pre>
                </div>

                <div className="mt-4 grid gap-2 text-xs text-muted-foreground sm:grid-cols-2">
                  <p>Version {row.version}</p>
                  <p>Effective {row.effective_from}</p>
                </div>
                <p className="mt-3 text-sm leading-6 text-muted-foreground">
                  {row.change_reason}
                </p>
              </section>
            ))}
          </div>
        ) : (
          <EmptyState
            icon={ShieldCheck}
            title="No business rules configured"
            description="Versioned policies such as batch capacity and teacher compensation will appear here."
          />
        )}
      </details>
    </div>
  );
}
