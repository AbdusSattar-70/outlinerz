import { AcademyIdentityForm } from "@/modules/platform/setup/identity-form";
import { platformClient } from "@/modules/platform/rpc-client";
import Link from "next/link";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { getAcademySetup } from "@/modules/platform/setup/queries";
import { CompleteSetupButton } from "@/modules/platform/setup/complete-button";
export default async function SetupPage() {
  const context = await requirePermission("dashboard.view");
  const setup = await getAcademySetup();
  const first = setup.steps.findIndex((s) => !s.done);
  const db = await platformClient();
  const { data: branch } = await db
    .from("branches")
    .select("name")
    .eq("code", "MAIN")
    .limit(1)
    .maybeSingle();
  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <header>
        <p className="text-sm text-muted-foreground">Academy setup</p>
        <h1 className="mt-2 text-3xl font-bold">
          Prepare {setup.academyName} for admissions
        </h1>
        <p className="mt-3 text-muted-foreground">
          Review these settings in order. Go back to correct any completed step.
          Operations open after all prerequisites are ready and you confirm the
          setup.
        </p>
      </header>
      {context.permissions.includes("system.settings.manage") && (
        <AcademyIdentityForm
          name={setup.academyName}
          branchName={branch?.name ?? "Main Campus"}
        />
      )}
      <ol className="space-y-3">
        {setup.steps.map((s, i) => {
          const unlocked = setup.completed || first === -1 || i <= first;
          return (
            <li
              key={s.id}
              className="flex items-center justify-between gap-4 rounded-2xl border bg-card p-5"
            >
              <div>
                <span className="mr-3">{s.done ? "✓" : i + 1}</span>
                <strong>{s.title}</strong>
                <p className="mt-1 text-xs text-muted-foreground">
                  {s.done
                    ? "Configured — review or correct before continuing"
                    : unlocked
                      ? "Next required setup"
                      : "Finish the preceding step first"}
                </p>
              </div>
              {unlocked && s.id !== "academy" ? (
                <Link
                  className="rounded-lg border px-4 py-2 text-sm"
                  href={`${s.href}?returnTo=${encodeURIComponent("/dashboard/setup")}`}
                >
                  {s.done ? "Review / edit" : "Configure"}
                </Link>
              ) : s.id === "academy" ? (
                <span className="text-sm">{setup.academyName}</span>
              ) : (
                <span className="text-xs text-muted-foreground">Locked</span>
              )}
            </li>
          );
        })}
      </ol>
      {context.permissions.includes("system.settings.manage") ? (
        <CompleteSetupButton ready={setup.ready} />
      ) : (
        <p>Ask the super admin to complete academy setup.</p>
      )}
      {setup.completed && (
        <Link className="block underline" href="/dashboard">
          Return to operations
        </Link>
      )}
    </div>
  );
}
