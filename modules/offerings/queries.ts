import { createClient } from "@/lib/supabase/server";
import { createOfferingClient } from "@/modules/offerings/database-contract";

function dataOrThrow<T>(data: T | null, error: { message: string } | null): T {
  if (error) throw new Error(error.message);
  if (data === null) throw new Error("The requested data is unavailable.");
  return data;
}

export async function getOfferingOverview() {
  const db = await createOfferingClient();
  const base = await createClient();
  const [
    offeringsQ,
    groupsQ,
    yearsQ,
    branchesQ,
    classesQ,
    programsQ,
    plansQ,
    componentsQ,
    subjectsQ,
  ] = await Promise.all([
    db
      .from("programme_offerings")
      .select("*")
      .order("created_at", { ascending: false }),
    db
      .from("academic_groups")
      .select("id,code,name")
      .eq("is_active", true)
      .order("name"),
    base
      .from("academic_years")
      .select("id,name,is_active")
      .order("starts_on", { ascending: false }),
    base.from("branches").select("id,name").eq("is_active", true).order("name"),
    base
      .from("classes")
      .select("id,name,sort_order")
      .eq("is_active", true)
      .order("sort_order"),
    base.from("programs").select("id,name").eq("is_active", true).order("name"),
    db
      .from("fee_plan_versions")
      .select("*")
      .order("version", { ascending: false }),
    db.from("fee_plan_components").select("*").order("sort_order"),
    base
      .from("subjects")
      .select("id,code,name")
      .eq("is_active", true)
      .order("name"),
  ]);

  let offeringSubjects: {
    offering_id: string;
    subject_id: string;
    sort_order: number;
  }[] = [];
  try {
    const offeringSubjectsQ = await db
      .from("programme_offering_subjects")
      .select("offering_id,subject_id,sort_order");
    if (!offeringSubjectsQ.error && offeringSubjectsQ.data) {
      offeringSubjects = offeringSubjectsQ.data;
    }
  } catch {
    offeringSubjects = [];
  }

  return {
    offerings: dataOrThrow(offeringsQ.data, offeringsQ.error),
    groups: dataOrThrow(groupsQ.data, groupsQ.error),
    years: dataOrThrow(yearsQ.data, yearsQ.error),
    branches: dataOrThrow(branchesQ.data, branchesQ.error),
    classes: dataOrThrow(classesQ.data, classesQ.error),
    programs: dataOrThrow(programsQ.data, programsQ.error),
    plans: dataOrThrow(plansQ.data, plansQ.error),
    components: dataOrThrow(componentsQ.data, componentsQ.error),
    subjects: dataOrThrow(subjectsQ.data, subjectsQ.error),
    offeringSubjects,
  };
}
export type OfferingOverview = Awaited<ReturnType<typeof getOfferingOverview>>;

export type PublicOfferingCard = {
  id: string;
  code: string;
  name: string;
  class_id: string;
  program_id: string;
  group_id: string | null;
  branch_id: string;
  academic_year_id: string;
  academic_year_name: string;
  branch_name: string;
  class_name: string;
  group_name: string | null;
  showcase_title: string | null;
  showcase_title_bn: string | null;
  showcase_description: string | null;
  showcase_description_bn: string | null;
  showcase_eyebrow: string | null;
  showcase_eyebrow_bn: string | null;
  showcase_icon: string | null;
  public_schedule: string | null;
  public_schedule_bn: string | null;
  public_requirements: string | null;
  public_requirements_bn: string | null;
  admission_policy: string | null;
  admission_policy_bn: string | null;
  active_batch_count: number;
  current_total_seats: number;
  current_open_seats: number;
  showcase_sort_order: number;
  is_accepting_applications: boolean;
  application_state: "OPEN" | "UPCOMING" | "CLOSED";
  applications_open_on: string | null;
  applications_close_on: string | null;
  created_at: string;
  subjects: { id: string; code: string; name: string }[];
  fee_plan: {
    billing_cycle: string;
    currency_code: string;
    components: {
      code: string;
      name: string;
      amount: number;
      charge_type: string;
      recurrence: string;
    }[];
  } | null;
};

/** ACTIVE + website-visible offerings. Null means the catalogue could not be loaded. */
export async function getPublicProgrammeOfferings(
  slug?: string,
): Promise<PublicOfferingCard[] | null> {
  try {
    const { organizationClient } =
      await import("@/modules/organizations/server");
    const { publicSlug } = await import("@/modules/crm/public");
    const resolved = publicSlug(slug);
    if (!resolved) return [];
    const db = await organizationClient();
    const { data, error } = await db.rpc("crm_public_catalogue", {
      p_slug: resolved,
    });
    if (error || !Array.isArray(data)) return null;
    return data;
  } catch {
    return null;
  }
}
