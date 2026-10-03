import { LocalizedText as L } from "@/components/shared/localized-text";
import { redirect } from "next/navigation";
import { requireOrganization } from "@/modules/organizations/server";
import { SetupRecordForm } from "@/modules/organizations/forms";
export default async function SetupPage() {
  const { db, organization } = await requireOrganization();
  if (!["OWNER", "ADMIN"].includes(organization.role)) redirect("/dashboard");
  const results = await Promise.all([
    db
      .from("branches")
      .select("id,name")
      .eq("organization_id", organization.id)
      .eq("active", true)
      .order("name"),
    db
      .from("academic_years")
      .select("id,name")
      .eq("organization_id", organization.id)
      .eq("active", true)
      .order("name"),
    db
      .from("class_levels")
      .select("id,name")
      .eq("organization_id", organization.id)
      .eq("active", true)
      .order("name"),
    db
      .from("subjects")
      .select("id,name")
      .eq("organization_id", organization.id)
      .eq("active", true)
      .order("name"),
  ]);
  if (results.some((r) => r.error))
    throw new Error("Setup records could not be loaded.");
  return (
    <div className="space-y-7">
      <h1 className="text-3xl font-bold">
        <L en="Organization setup" bn="প্রতিষ্ঠানের প্রস্তুতি" />
      </h1>
      <p className="text-muted-foreground">
        <L
          en="Several academic years may be active. Accounting setup is optional."
          bn="একাধিক শিক্ষাবর্ষ সক্রিয় থাকতে পারে। হিসাবরক্ষণের প্রস্তুতি ঐচ্ছিক।"
        />
      </p>
      <div className="grid gap-4 sm:grid-cols-2">
        {[
          { en: "Branches", bn: "শাখা" },
          { en: "Academic years", bn: "শিক্ষাবর্ষ" },
          { en: "Classes", bn: "শ্রেণি" },
          { en: "Subjects", bn: "বিষয়" },
        ].map((title, i) => (
          <section key={title.en} className="rounded-2xl border p-5">
            <h2 className="font-semibold">
              <L en={title.en} bn={title.bn} />
            </h2>
            <ul className="mt-3 space-y-1 text-sm">
              {results[i].data?.map((r) => (
                <li key={r.id}>{r.name}</li>
              ))}
            </ul>
            {!results[i].data?.length && (
              <p className="mt-3 text-sm text-muted-foreground">
                <L en="No records yet." bn="এখনও যোগ করা হয়নি।" />
              </p>
            )}
          </section>
        ))}
      </div>
      <div className="grid gap-5 lg:grid-cols-3">
        <SetupRecordForm kind="year" title="Add academic year" />
        <SetupRecordForm kind="class" title="Add class" />
        <SetupRecordForm kind="subject" title="Add subject" />
      </div>
    </div>
  );
}
