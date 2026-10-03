import Link from "next/link";
import { PageHeader } from "@/components/erp/page-header";
import { StatusBadge } from "@/components/erp/status-badge";
import { FeePlanForm } from "@/modules/offerings/components/fee-plan-form";
import { getOfferingOverview } from "@/modules/offerings/queries";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { can } from "@/types/erp";

function todayInDhaka() {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: "Asia/Dhaka",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date());
  const part = (name: string) =>
    parts.find((item) => item.type === name)?.value ?? "";
  return `${part("year")}-${part("month")}-${part("day")}`;
}

export default async function FeePlansPage({
  searchParams,
}: {
  searchParams: Promise<{ offering?: string; returnTo?: string }>;
}) {
  const params = await searchParams;
  const context = await requirePermission("finance.view");
  const data = await getOfferingOverview();
  const today = todayInDhaka();
  const offering = (id: string) =>
    data.offerings.find((item) => item.id === id);

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="Finance / Control Center"
        title="Fee Plans"
        description="Manage current standard charges and permitted admission discounts. Historical admission terms remain preserved."
      />
      {can(context, "finance.billing.manage") && (
        <FeePlanForm
          key={params.offering ?? "new"}
          data={data}
          today={today}
          initialOfferingId={params.offering}
        />
      )}
      <section className="rounded-2xl border bg-card p-5 sm:p-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h2 className="font-semibold">Current Fee Plans</h2>
            <p className="text-sm text-muted-foreground">
              Amounts shown here are standard fees, before any authorized
              student discount.
            </p>
          </div>
          {can(context, "academics.view") && (
            <Link
              href="/dashboard/academics/offerings"
              className="text-sm font-semibold text-primary underline-offset-4 hover:underline"
            >
              View Offerings →
            </Link>
          )}
        </div>
        {data.plans.length ? (
          <div className="mt-4 space-y-3">
            {data.plans
              .filter((plan) => plan.status === "ACTIVE")
              .map((plan) => (
                <article key={plan.id} className="rounded-xl border p-4">
                  <div className="flex flex-wrap items-start justify-between gap-2">
                    <div>
                      <h3 className="font-semibold">
                        {offering(plan.offering_id)?.name ?? "Offering"} ·
                        Standard fees
                      </h3>
                      <p className="text-xs text-muted-foreground">
                        {offering(plan.offering_id)?.code} ·{" "}
                        {plan.billing_cycle.replaceAll("_", " ")} · effective{" "}
                        {plan.effective_from}
                        {plan.effective_to
                          ? ` through ${plan.effective_to}`
                          : ""}{" "}
                        · {plan.currency_code}
                      </p>
                    </div>
                    <div className="flex items-center gap-3">
                      <StatusBadge value={plan.status} />
                      {can(context, "finance.billing.manage") && (
                        <Link
                          className="rounded-lg border px-3 py-2 text-sm"
                          href={`/dashboard/finance/fee-plans?offering=${plan.offering_id}${params.returnTo ? `&returnTo=${encodeURIComponent(params.returnTo)}` : ""}`}
                        >
                          Edit fees / discounts
                        </Link>
                      )}
                    </div>
                  </div>
                  <ul className="mt-3 grid gap-2 text-sm sm:grid-cols-2 lg:grid-cols-3">
                    {data.components
                      .filter((item) => item.fee_plan_version_id === plan.id)
                      .map((item) => (
                        <li
                          key={item.id}
                          className="rounded-lg bg-muted/50 px-3 py-2"
                        >
                          {item.name}{" "}
                          <strong className="float-right">
                            {Number(item.amount).toLocaleString("en-BD", {
                              minimumFractionDigits: 2,
                            })}
                          </strong>
                          <span className="block text-xs text-muted-foreground">
                            {item.charge_type} ·{" "}
                            {item.recurrence.replaceAll("_", " ")}
                          </span>
                        </li>
                      ))}
                  </ul>
                  <p className="mt-3 text-xs text-muted-foreground">
                    Reason: {plan.change_reason}
                  </p>
                </article>
              ))}
          </div>
        ) : (
          <p className="mt-5 rounded-xl border border-dashed p-6 text-sm text-muted-foreground">
            No Fee Plans published. Create a Programme Offering, then publish
            its standard charges.
          </p>
        )}
      </section>
    </div>
  );
}
