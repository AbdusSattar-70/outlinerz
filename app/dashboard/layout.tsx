import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { getAcademySetup } from "@/modules/platform/setup/queries";
import type { ReactNode } from "react";
import Link from "next/link";
import { ShieldX } from "lucide-react";
import { ErpShell } from "@/components/erp/erp-shell";
import { getErpContext } from "@/modules/platform/auth/erp-context";

export default async function DashboardLayout({
  children,
}: {
  children: ReactNode;
}) {
  const context = await getErpContext();

  if (!context) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-background px-5 text-foreground">
        <div className="w-full max-w-lg rounded-3xl border bg-card p-8 text-center shadow-sm">
          <div className="mx-auto flex size-12 items-center justify-center rounded-2xl bg-muted">
            <ShieldX className="size-6" aria-hidden="true" />
          </div>
          <h1 className="mt-5 text-2xl font-bold">
            ERP access is not configured
          </h1>
          <p className="mt-3 text-sm leading-6 text-muted-foreground">
            Your sign-in is valid, but this account does not yet have an active
            Sohoj Academy ERP profile and permission assignment.
          </p>
          <Link
            href="/auth/sign-in"
            className="mt-6 inline-flex min-h-11 items-center justify-center rounded-xl bg-primary px-5 text-sm font-semibold text-primary-foreground"
          >
            Return to sign in
          </Link>
        </div>
      </main>
    );
  }

  const pathname = (await headers()).get("x-erp-pathname") ?? "/dashboard";
  const portalOnly = context.permissions.includes("referrals.portal.view") && !context.permissions.includes("dashboard.view");
  if (context.status === "ACTIVE" && portalOnly) {
    if (!["/dashboard/referrals", "/dashboard/account"].some(p => pathname === p || pathname.startsWith(`${p}/`))) redirect("/dashboard/referrals");
    return <ErpShell context={context}>{children}</ErpShell>;
  }
  if (
    context.status !== "ACTIVE" ||
    !context.permissions.includes("dashboard.view")
  ) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-background px-5 text-foreground">
        <div className="w-full max-w-lg rounded-3xl border bg-card p-8 text-center shadow-sm">
          <div className="mx-auto flex size-12 items-center justify-center rounded-2xl bg-muted">
            <ShieldX className="size-6" aria-hidden="true" />
          </div>
          <h1 className="mt-5 text-2xl font-bold">ERP access is restricted</h1>
          <p className="mt-3 text-sm leading-6 text-muted-foreground">
            This account is signed in but does not have permission to open the
            operational ERP. Ask an administrator to review the user-role
            assignment instead of creating another account.
          </p>
        </div>
      </main>
    );
  }

  const setup = await getAcademySetup();
  if (!setup.completed) {
    const path = (await headers()).get("x-erp-pathname") ?? "/dashboard";
    const first = setup.steps.findIndex((step) => !step.done);
    const unlocked =
      first === -1 ? setup.steps : setup.steps.slice(0, first + 1);
    const allowed = [
      "/dashboard/setup",
      "/dashboard/settings",
      "/dashboard/account",
      "/dashboard/help",
      ...unlocked.map((step) => step.href),
    ];
    if (
      !allowed.some((route) => path === route || path.startsWith(`${route}/`))
    )
      redirect("/dashboard/setup");
  }
  return (
    <ErpShell context={context} setupPending={!setup.completed}>
      {children}
    </ErpShell>
  );
}
