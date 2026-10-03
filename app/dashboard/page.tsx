import Link from "next/link";
import { requireOrganization } from "@/modules/organizations/server";
import { LocalizedText as L } from "@/components/shared/localized-text";
export default async function DashboardPage() {
  const { db, organization } = await requireOrganization();
  const { data: modules, error } = await db
    .from("organization_modules")
    .select("module,enabled")
    .eq("organization_id", organization.id)
    .order("module");
  if (error) throw new Error("Module settings could not be loaded.");
  const names: Record<string, { en: string; bn: string }> = {
    CRM: { en: "CRM", bn: "যোগাযোগ ব্যবস্থাপনা" },
    ACADEMIC: { en: "Academic", bn: "একাডেমিক" },
    FINANCE: { en: "Finance", bn: "আর্থিক কার্যক্রম" },
    BUSINESS: { en: "Business", bn: "ব্যবসা পরিচালনা" },
    ACCOUNTING: { en: "Accounting", bn: "হিসাবরক্ষণ" },
  };
  return (
    <div className="space-y-8">
      <div>
        <p className="text-sm text-muted-foreground">
          {organization.currency} · {organization.timezone}
        </p>
        <h1 className="mt-2 text-3xl font-bold">{organization.name}</h1>
        <p className="mt-3 text-muted-foreground">
          <L
            en="Your education operations workspace."
            bn="আপনার শিক্ষা প্রতিষ্ঠানের নিজস্ব কর্মপরিসর।"
          />
        </p>
      </div>
      {["OWNER", "ADMIN"].includes(organization.role) && (
        <section className="rounded-2xl border bg-card p-6">
          <h2 className="text-xl font-semibold">
            <L
              en="Complete your organization setup"
              bn="প্রতিষ্ঠানের প্রস্তুতি সম্পূর্ণ করুন"
            />
          </h2>
          <p className="mt-2 text-muted-foreground">
            <L
              en="Add academic years, classes and subjects, then maintain your CRM directories."
              bn="শিক্ষাবর্ষ, শ্রেণি ও বিষয় যোগ করুন। এরপর যোগাযোগ ব্যবস্থাপনার তথ্যতালিকা পরিচালনা করুন।"
            />
          </p>
          <div className="mt-5 flex flex-wrap gap-3">
            <Link
              href="/dashboard/setup"
              className="rounded-xl bg-primary px-5 py-3 text-primary-foreground"
            >
              <L en="Open setup" bn="প্রস্তুতি শুরু করুন" />
            </Link>
            {modules?.some((m) => m.module === "CRM" && m.enabled) && (
              <Link
                href="/dashboard/crm/manage"
                className="rounded-xl border px-5 py-3"
              >
                <L en="Manage CRM" bn="যোগাযোগ ব্যবস্থাপনা" />
              </Link>
            )}
          </div>
        </section>
      )}
      <section>
        <h2 className="mb-4 text-xl font-semibold">
          <L en="Modules" bn="কার্যক্রম" />
        </h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {modules?.map((m) => (
            <div key={m.module} className="rounded-2xl border bg-card p-5">
              <p className="font-semibold">
                <L {...names[m.module]} />
              </p>
              <p className="mt-2 text-sm text-muted-foreground">
                {m.enabled ? (
                  <L en="Enabled" bn="চালু" />
                ) : (
                  <L en="Disabled" bn="বন্ধ" />
                )}
              </p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
