import Link from "next/link";
import { PageHeader } from "@/components/erp/page-header";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { getSettingsOverview } from "@/modules/settings/queries";
import { can } from "@/types/erp";

export default async function AccessSecurityPage() {
  const context = await requirePermission("system.settings.view");
  const data = await getSettingsOverview();
  const canManageUsers = can(context, "system.users.manage");

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="Academy Setup"
        title="Settings"
        description="Choose the area you need to change. Each register saves the current value with an audit trail; access controls stay protected."
      />
      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Academy setup</h2>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {can(context, "system.master_data.manage") && (
            <SetupLink
              href="/dashboard/crm/manage"
              title="Academic Directory"
              description="Years, classes, subjects, schools and programmes."
            />
          )}
          {can(context, "academics.view") && (
            <SetupLink
              href="/dashboard/academics/offerings"
              title="Programme Offerings"
              description="Academic context, public content and application intake."
            />
          )}

          {can(context, "system.rules.view") && (
            <SetupLink
              href="/dashboard/governance/rules"
              title="Operating Rules"
              description="Academic batch capacity and policy history."
            />
          )}
        </div>
      </section>
      <div className="flex flex-wrap gap-3">
        <Link
          className="rounded-xl border px-4 py-3 text-sm"
          href="/dashboard/setup"
        >
          Guided academy setup
        </Link>
        <Link
          className="rounded-xl border px-4 py-3 text-sm"
          href="/dashboard/account"
        >
          My password and email
        </Link>
        {canManageUsers && (
          <Link
            className="rounded-xl border px-4 py-3 text-sm"
            href="/branches"
          >
            Branch membership
          </Link>
        )}
      </div>
      <h2 className="text-lg font-semibold">Access & Security</h2>
      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Staff access</h2>
        <p className="text-sm text-muted-foreground">
          Assign a role only after checking the staff member. Teacher access is
          limited to assigned work; admin actions require admin permission.
        </p>
        {canManageUsers ? (
          <div className="rounded-2xl border bg-card p-5 sm:p-6">
            <Link href="/branches" className="font-semibold text-primary underline">Manage access to this branch →</Link>
          </div>
        ) : (
          <p className="rounded-2xl border border-dashed p-5 text-sm text-muted-foreground">
            You can view this page, but only an authorized admin can change
            staff access.
          </p>
        )}
      </section>
      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Role permissions</h2>
        <p className="text-sm text-muted-foreground">
          Review the abilities attached to each role. Server and database checks
          enforce these permissions.
        </p>
        <div className="grid gap-3 sm:grid-cols-2">{data.roles.filter(role=>role.isActive).map(role=><article key={role.id} className="rounded-xl border p-4"><h3 className="font-semibold">{role.name}</h3><p className="mt-2 text-sm text-muted-foreground">{role.permissions.map(permission=>permission.name).join(", ")}</p></article>)}</div>
        <p className="text-sm text-muted-foreground">Role templates are fixed. Assign branch member roles from Branches.</p>
      </section>
    </div>
  );
}

function SetupLink({
  href,
  title,
  description,
}: {
  href: string;
  title: string;
  description: string;
}) {
  return (
    <Link
      href={href}
      className="rounded-2xl border bg-card p-5 transition hover:border-primary/50 hover:bg-muted/30"
    >
      <span className="font-semibold">{title}</span>
      <span className="mt-2 block text-sm leading-6 text-muted-foreground">
        {description}
      </span>
    </Link>
  );
}
