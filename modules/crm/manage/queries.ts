import { crmAccess } from "../access";
export async function getManageCrmOverview() {
  const { db, organization } = await crmAccess();
  if (!["OWNER", "ADMIN"].includes(organization.role))
    throw new Error("Master data access denied.");
  const [
    years,
    classes,
    groups,
    subjects,
    programs,
    schools,
    areas,
    sources,
    relationships,
  ] = await Promise.all([
    db
      .from("academic_years")
      .select("*")
      .eq("organization_id", organization.id)
      .order("starts_on", { ascending: false }),
    db
      .from("class_levels")
      .select("*")
      .eq("organization_id", organization.id)
      .order("sort_order"),
    db
      .from("class_groups")
      .select("*")
      .eq("organization_id", organization.id)
      .order("name"),
    db
      .from("subjects")
      .select("*")
      .eq("organization_id", organization.id)
      .order("name"),
    db
      .from("programmes")
      .select("*")
      .eq("organization_id", organization.id)
      .order("name"),
    db
      .from("schools")
      .select("*")
      .eq("organization_id", organization.id)
      .order("name"),
    db
      .from("areas")
      .select("*")
      .eq("organization_id", organization.id)
      .order("name"),
    db
      .from("lead_sources")
      .select("*")
      .eq("organization_id", organization.id)
      .order("name"),
    db
      .from("guardian_relationships")
      .select("*")
      .eq("organization_id", organization.id)
      .order("name"),
  ]);
  for (const q of [
    years,
    classes,
    groups,
    subjects,
    programs,
    schools,
    areas,
    sources,
    relationships,
  ])
    if (q.error) throw new Error("CRM directory could not be loaded.");
  const adapt = <T extends { active: boolean }>(q: { data: T[] | null }) =>
    (q.data ?? []).map((r) => ({ ...r, is_active: r.active }));
  return {
    years: adapt(years),
    classes: adapt(classes),
    groups: adapt(groups),
    subjects: adapt(subjects),
    programs: adapt(programs),
    schools: adapt(schools),
    areas: adapt(areas),
    leadSources: adapt(sources),
    relationships: adapt(relationships),
  };
}
export type ManageCrmOverview = Awaited<
  ReturnType<typeof getManageCrmOverview>
>;
