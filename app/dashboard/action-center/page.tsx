import { platformClient } from "@/modules/platform/rpc-client";
import Link from "next/link";
import { ClipboardCheck, PhoneCall, UserRoundSearch } from "lucide-react";
import { EmptyState } from "@/components/erp/empty-state";
import { PageHeader } from "@/components/erp/page-header";
import { StatusBadge } from "@/components/erp/status-badge";
import { getActionCenterData } from "@/modules/action-center/queries";
import { requirePermission } from "@/modules/platform/auth/erp-context";

export default async function ActionCenterPage() {
  const context = await requirePermission("action_center.view");
  const data = await getActionCenterData(context);
  const db = await platformClient();
  const staffRequests = context.permissions.includes("system.users.manage")
    ? await db
        .from("staff_access_requests")
        .select("id", { count: "exact", head: true })
        .in("status", ["PENDING", "VERIFIED"])
    : null;
  if (staffRequests?.error) throw new Error(staffRequests.error.message);
  const schoolReviewCount = data.verificationQueue.filter(
    (item) => item.schoolNeedsReview,
  ).length;

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="Exceptions first"
        title="Action Center"
        description="Approvals, public-admission verification, and CRM follow-ups that need a person — not reports that can wait."
      />

      {staffRequests && (
        <Link
          className="block rounded-2xl border bg-card p-5"
          href="/dashboard/staff#staff-access"
        >
          <strong>{staffRequests.count ?? 0} staff access requests</strong>
          <p className="mt-1 text-sm text-muted-foreground">
            Verify role and identity, then send secure account setup instructions.
          </p>
        </Link>
      )}
      <div className="grid gap-6 xl:grid-cols-2">
        <section className="overflow-hidden rounded-2xl border bg-card">
          <div className="border-b px-5 py-4">
            <h2 className="font-semibold">Pending approvals</h2>
            <p className="mt-1 text-xs text-muted-foreground">
              Sensitive workflows remain unsettled until an authorized reviewer
              makes a maker-checker decision.
            </p>
          </div>

          {data.approvals.length ? (
            <div className="divide-y">
              {data.approvals.map((item) => (
                <div key={item.id} className="px-5 py-4">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-medium">{item.workflowType}</p>
                      <p className="mt-1 text-xs text-muted-foreground">
                        {item.entityType} • {item.requestedAction}
                      </p>
                    </div>
                    <StatusBadge value="PENDING" />
                  </div>
                  {item.requestNote && (
                    <p className="mt-3 text-sm leading-6 text-muted-foreground">
                      {item.requestNote}
                    </p>
                  )}
                  <p className="mt-2 text-xs text-muted-foreground">
                    Requested {new Date(item.requestedAt).toLocaleString()}
                  </p>
                </div>
              ))}
              <div className="p-4">
                <Link
                  href="/dashboard/governance/approvals"
                  className="text-sm font-semibold text-blue-700 hover:underline dark:text-blue-300"
                >
                  Open approval register
                </Link>
              </div>
            </div>
          ) : (
            <div className="p-5">
              <EmptyState
                icon={ClipboardCheck}
                title="No approval decisions are waiting"
                description="New requests will appear here when a controlled workflow is submitted for review."
              />
            </div>
          )}
        </section>

        <section className="overflow-hidden rounded-2xl border bg-card">
          <div className="border-b px-5 py-4">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <h2 className="font-semibold">Verification queue</h2>
                <p className="mt-1 text-xs text-muted-foreground">
                  Recent public interest and admission submissions still in
                  early CRM states.
                </p>
              </div>
              <div className="flex flex-wrap gap-2 text-xs">
                <span className="rounded-full bg-blue-50 px-2.5 py-1 font-medium text-blue-800 dark:bg-blue-950/40 dark:text-blue-200">
                  Queue: {data.verificationQueue.length}
                </span>
                <span className="rounded-full bg-amber-50 px-2.5 py-1 font-medium text-amber-900 dark:bg-amber-950/40 dark:text-amber-100">
                  School review: {schoolReviewCount}
                </span>
              </div>
            </div>
          </div>

          {data.verificationQueue.length ? (
            <div className="divide-y">
              {data.verificationQueue.map((item) => (
                <div
                  key={item.id}
                  className="flex items-start justify-between gap-4 px-5 py-4"
                >
                  <div className="min-w-0">
                    <Link
                      href={`/dashboard/crm/prospects/${item.id}`}
                      className="font-medium hover:underline"
                    >
                      {item.studentName}
                    </Link>
                    <p className="mt-1 text-xs text-muted-foreground">
                      {item.prospectNo} • {item.mobile}
                    </p>
                    <p className="mt-1 text-xs text-muted-foreground">
                      School: {item.schoolName}
                      {item.schoolNeedsReview ? " • needs review" : ""}
                    </p>
                    <p className="mt-1 text-xs text-muted-foreground">
                      Received {new Date(item.createdAt).toLocaleString()}
                    </p>
                  </div>
                  <StatusBadge value={item.status} />
                </div>
              ))}
              <div className="p-4">
                <Link
                  href="/dashboard/crm/prospects"
                  className="text-sm font-semibold text-blue-700 hover:underline dark:text-blue-300"
                >
                  Open CRM prospects
                </Link>
              </div>
            </div>
          ) : (
            <div className="p-5">
              <EmptyState
                icon={UserRoundSearch}
                title="Verification queue is clear"
                description="New public interest and admission submissions will appear here while they are still NEW, CONTACTED, or in counselling."
              />
            </div>
          )}
        </section>

        <section className="overflow-hidden rounded-2xl border bg-card xl:col-span-2">
          <div className="border-b px-5 py-4">
            <h2 className="font-semibold">CRM follow-ups due</h2>
            <p className="mt-1 text-xs text-muted-foreground">
              Prospect follow-ups whose scheduled time has arrived.
            </p>
          </div>

          {data.dueProspects.length ? (
            <div className="divide-y sm:grid sm:grid-cols-2 sm:divide-y-0">
              {data.dueProspects.map((item) => (
                <div
                  key={item.id}
                  className="flex items-start justify-between gap-4 border-b px-5 py-4 sm:border-b-0 sm:border-r"
                >
                  <div>
                    <Link
                      href={`/dashboard/crm/prospects/${item.id}`}
                      className="font-medium hover:underline"
                    >
                      {item.studentName}
                    </Link>
                    <p className="mt-1 text-xs text-muted-foreground">
                      {item.prospectNo} • {item.mobile}
                    </p>
                    <p className="mt-2 text-xs text-muted-foreground">
                      Due {new Date(item.nextFollowUpAt).toLocaleString()}
                    </p>
                  </div>
                  <StatusBadge value={item.status} />
                </div>
              ))}
            </div>
          ) : (
            <div className="p-5">
              <EmptyState
                icon={PhoneCall}
                title="No CRM follow-ups are overdue"
                description="Scheduled follow-ups will appear here automatically when they become due."
              />
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
