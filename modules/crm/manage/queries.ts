import { createClient } from "@/lib/supabase/server";

function dataOrThrow<T>(data: T | null, error: { message: string } | null): T {
  if (error) throw new Error(error.message);
  if (data === null) throw new Error("The requested data is unavailable.");
  return data;
}

type GroupRow = { id: string; code: string; name: string; is_active: boolean };

export async function getManageCrmOverview() {
  const db = await createClient();
  // academic_groups is created in migration 0008; generated types may lag until regen.
  const groupsClient = db as unknown as {
    from: (table: "academic_groups") => {
      select: (cols: string) => {
        order: (col: string) => Promise<{ data: GroupRow[] | null; error: { message: string } | null }>;
      };
    };
  };

  const [
    yearsQ,
    classesQ,
    groupsQ,
    subjectsQ,
    programsQ,
    schoolsQ,
    areasQ,
    sourcesQ,
    relationshipsQ,
  ] = await Promise.all([
    db.from("academic_years").select("id,name,starts_on,ends_on,is_active,created_at").order("starts_on", { ascending: false }),
    db.from("classes").select("id,code,name,sort_order,is_active,created_at").order("sort_order"),
    groupsClient.from("academic_groups").select("id,code,name,is_active").order("name"),
    db.from("subjects").select("id,code,name,is_active,created_at").order("name"),
    db.from("programs").select("id,code,name,description,is_active,created_at").order("name"),
    db.from("schools").select("id,name,area_id,is_verified,is_active,created_at,updated_at").order("name"),
    db.from("areas").select("id,name,is_active").eq("is_active", true).order("name"),
    db.from("lead_sources").select("id,code,name,is_active,created_at").order("name"),
    db.from("guardian_relationships").select("id,code,name,is_active,created_at").order("name"),
  ]);

  return {
    years: dataOrThrow(yearsQ.data, yearsQ.error),
    classes: dataOrThrow(classesQ.data, classesQ.error),
    groups: dataOrThrow(groupsQ.data, groupsQ.error),
    subjects: dataOrThrow(subjectsQ.data, subjectsQ.error),
    programs: dataOrThrow(programsQ.data, programsQ.error),
    schools: dataOrThrow(schoolsQ.data, schoolsQ.error),
    areas: dataOrThrow(areasQ.data, areasQ.error),
    leadSources: dataOrThrow(sourcesQ.data, sourcesQ.error),
    relationships: dataOrThrow(relationshipsQ.data, relationshipsQ.error),
  };
}

export type ManageCrmOverview = Awaited<ReturnType<typeof getManageCrmOverview>>;
