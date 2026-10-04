import { redirect } from "next/navigation";
import Link from "next/link";
import {
  ClipboardCheck,
  Clock3,
  UserRoundSearch,
  UsersRound,
  GraduationCap,
} from "lucide-react";
import { PageHeader } from "@/components/erp/page-header";
import { StatCard } from "@/components/erp/stat-card";
import { StatusBadge } from "@/components/erp/status-badge";
import { getDashboardOverview } from "@/modules/dashboard/queries";
import { requirePermission } from "@/modules/platform/auth/erp-context";

export default async function DashboardPage({
  searchParams,
}: {
  searchParams: Promise<{ access?: string }>;
}) {
  const context = await requirePermission("dashboard.view");
  if (!context.roles.includes("ADMIN") && context.permissions.includes("workforce.self.view")) redirect("/dashboard/my-work");
  const overview = await getDashboardOverview(context);
  const { access } = await searchParams;

  const cards = [
    overview.activeProspects !== null && {
      label: "Active prospects",
      href: "/dashboard/crm/prospects",
      value: overview.activeProspects,
      description: "Open CRM opportunities not yet converted or lost.",
      icon: UserRoundSearch,
    },
    overview.activeStudents !== null && {
      label: "Active students",
      href: "/dashboard/students",
      value: overview.activeStudents,
      description:
        "Current Student Master records with active lifecycle status.",
      icon: GraduationCap,
    },
    overview.pendingApprovals !== null && {
      label: "Pending reviews",
      href: "/dashboard/governance/approvals",
      value: overview.pendingApprovals,
      description: "Teacher submissions and any outstanding review decisions.",
      icon: ClipboardCheck,
    },
    overview.activeStaff !== null && {
      label: "Active staff",
      href: "/dashboard/staff",
      value: overview.activeStaff,
      description: "Active and on-leave Staff identities in the organization.",
      icon: UsersRound,
    },
  ].filter(Boolean) as Array<{
    label: string;
    value: number;
    description: string;
    icon: typeof UserRoundSearch;
    href: string;
  }>;

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="Operational overview"
        title="Digital Campus"
        description="A concise view of work that needs attention. Every number comes from the same governed ERP records used by the underlying workflows."
      />

      {context.permissions.includes("system.settings.view") && (
        <div className="flex flex-wrap items-center gap-3 rounded-2xl border bg-card px-5 py-4 text-sm">
          <span className="font-medium">Manage academy setup</span>
          <Link
            href="/dashboard/settings"
            className="rounded-lg border px-3 py-2 font-semibold text-primary hover:bg-muted"
          >
            Open Settings
          </Link>
        </div>
      )}

      {access === "denied" && (
        <div
          role="status"
          className="rounded-2xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-900 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-100"
        >
          The requested module is outside your current permissions. No data was
          exposed or changed.
        </div>
      )}

      <nav aria-label="Quick actions" className="flex flex-wrap gap-3">
        {[
          [
            "admissions.create",
            "/dashboard/admissions?start=staff",
            "New admission",
          ],
          [
            "crm.prospects.view",
            "/dashboard/crm/prospects",
            "Verify applications",
          ],

          [
            "academics.manage",
            "/dashboard/academics/offerings",
            "Manage offerings",
          ],
          [
            "system.users.manage",
            "/branches",
            "Branch membership",
          ],
        ]
          .filter(([permission]) => context.permissions.includes(permission))
          .map(([, href, label]) => (
            <Link
              key={href}
              href={href}
              className="rounded-lg border px-4 py-3 text-sm hover:bg-muted"
            >
              {label}
            </Link>
          ))}
      </nav>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {cards.map((card) => (
          <StatCard key={card.label} {...card} />
        ))}
      </div>

      <div className="grid gap-5 xl:grid-cols-[1.5fr_1fr]">
        <section className="overflow-hidden rounded-2xl border bg-card">
          <div className="flex items-center justify-between gap-4 border-b px-5 py-4">
            <div>
              <h2 className="font-semibold">Recent prospects</h2>
              <p className="mt-1 text-xs text-muted-foreground">
                Latest Student Bank entries from public and staff channels.
              </p>
            </div>
            {overview.recentProspects.length > 0 && (
              <Link
                href="/dashboard/crm/prospects"
                className="text-sm font-semibold text-blue-700 hover:underline dark:text-blue-300"
              >
                View all
              </Link>
            )}
          </div>

          <div className="divide-y">
            {overview.recentProspects.length ? (
              overview.recentProspects.map((prospect) => (
                <Link
                  href={`/dashboard/crm/prospects/${prospect.id}`}
                  key={prospect.id}
                  className="flex items-center justify-between gap-4 px-5 py-4 hover:bg-muted"
                >
                  <div className="min-w-0">
                    <p className="truncate font-medium">
                      {prospect.studentName}
                    </p>
                    <p className="mt-1 text-xs text-muted-foreground">
                      {prospect.prospectNo} •{" "}
                      {new Date(prospect.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                  <StatusBadge value={prospect.status} />
                </Link>
              ))
            ) : (
              <p className="px-5 py-8 text-sm text-muted-foreground">
                No prospect records are available yet.
              </p>
            )}
          </div>
        </section>

        <section className="rounded-2xl border bg-card p-5">
          <div className="flex items-start gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-muted">
              <Clock3 className="size-5" aria-hidden="true" />
            </div>
            <div>
              <h2 className="font-semibold">Action Center</h2>
              <p className="mt-1 text-xs leading-5 text-muted-foreground">
                Exceptions and due work are surfaced here instead of being
                hidden inside individual modules.
              </p>
            </div>
          </div>

          <div className="mt-5 space-y-3">
            {overview.dueFollowups !== null && (
              <Link
                href="/dashboard/action-center"
                className="block rounded-xl border p-4 hover:bg-muted"
              >
                <p className="text-2xl font-bold">{overview.dueFollowups}</p>
                <p className="mt-1 text-sm text-muted-foreground">
                  CRM follow-ups due
                </p>
              </Link>
            )}
            {overview.pendingApprovals !== null && (
              <Link
                href="/dashboard/governance/approvals"
                className="block rounded-xl border p-4 hover:bg-muted"
              >
                <p className="text-2xl font-bold">
                  {overview.pendingApprovals}
                </p>
                <p className="mt-1 text-sm text-muted-foreground">
                  review decisions pending
                </p>
              </Link>
            )}
          </div>

          <Link
            href="/dashboard/action-center"
            className="mt-5 inline-flex min-h-11 w-full items-center justify-center rounded-xl border px-4 text-sm font-semibold hover:bg-muted"
          >
            Open Action Center
          </Link>
        </section>
      </div>
    </div>
  );
}
