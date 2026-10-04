import Link from "next/link";
import {
  BookOpenCheck,
  ClipboardCheck,
  GraduationCap,
  LineChart,
  ShieldCheck,
  UsersRound,
  type LucideIcon,
} from "lucide-react";
import { LocalizedText } from "@/components/shared/localized-text";
import { getPublicProgrammeOfferings } from "@/modules/offerings/queries";

function feeSummaryFromPlan(
  plan: {
    billing_cycle: string;
    currency_code: string;
    components: { name: string; amount: number; charge_type: string; recurrence: string }[];
  } | null | undefined,
): [string, string] | null {
  if (!plan?.components?.length) return null;
  const tuition = plan.components.find(
    (c) => c.charge_type === "TUITION" && c.recurrence === "PER_CYCLE",
  );
  const admission = plan.components.find((c) => c.charge_type === "ADMISSION");
  const currency = plan.currency_code || "BDT";
  const cycle = (plan.billing_cycle || "MONTHLY").replaceAll("_", " ").toLowerCase();
  const partsEn: string[] = [];
  const partsBn: string[] = [];
  if (tuition) {
    partsEn.push(`${currency} ${Number(tuition.amount).toLocaleString("en-BD")} / ${cycle}`);
    partsBn.push(`${currency} ${Number(tuition.amount).toLocaleString("en-BD")} / ${cycle}`);
  }
  if (admission) {
    partsEn.push(`Admission ${currency} ${Number(admission.amount).toLocaleString("en-BD")}`);
    partsBn.push(`ভর্তি ${currency} ${Number(admission.amount).toLocaleString("en-BD")}`);
  }
  if (!partsEn.length) {
    const first = plan.components[0];
    partsEn.push(`${currency} ${Number(first.amount).toLocaleString("en-BD")}`);
    partsBn.push(`${currency} ${Number(first.amount).toLocaleString("en-BD")}`);
  }
  return [partsEn.join(" · "), partsBn.join(" · ")];
}

function windowNoteFromOffering(row: {
  is_accepting_applications: boolean;
  application_state: "OPEN" | "UPCOMING" | "CLOSED";
  applications_open_on: string | null;
  applications_close_on: string | null;
}): [string, string] | null {
  if (row.application_state === "UPCOMING" && row.applications_open_on) {
    return [`Opens ${row.applications_open_on}`, `${row.applications_open_on} থেকে আবেদন`];
  }
  if (!row.is_accepting_applications) {
    return ["Applications closed", "আবেদন বন্ধ"];
  }
  const open = row.applications_open_on;
  const close = row.applications_close_on;
  if (!open && !close) return ["Applications open", "আবেদন চলছে"];
  const fmt = (d: string) => {
    try {
      return new Date(d).toLocaleDateString("en-GB", {
        day: "numeric",
        month: "short",
        year: "numeric",
      });
    } catch {
      return d;
    }
  };
  if (open && close) {
    return [`Apply ${fmt(open)} – ${fmt(close)}`, `আবেদন ${fmt(open)} – ${fmt(close)}`];
  }
  if (close) {
    return [`Apply by ${fmt(close)}`, `${fmt(close)} পর্যন্ত আবেদন`];
  }
  return [`Opens ${fmt(open!)}`, `${fmt(open!)} থেকে খোলা`];
}

const SHOWCASE_ICONS: Record<string, LucideIcon> = {
  "clipboard-check": ClipboardCheck,
  "graduation-cap": GraduationCap,
  "users-round": UsersRound,
  "book-open-check": BookOpenCheck,
  "line-chart": LineChart,
  "shield-check": ShieldCheck,
};

type ProgramCard = {
  key: string;
  eyebrow: [string, string];
  title: [string, string];
  description: [string, string];
  icon: LucideIcon;
  offeringId: string | null;
  acceptingApplications: boolean;
  feeSummary: [string, string] | null;
  windowNote: [string, string] | null;
  academicContext: string;
  subjects: string[];
  schedule: [string, string] | null;
  requirements: [string, string] | null;
  policy: [string, string] | null;
  availability: [string, string];
};

export async function HomeProgramSection() {
  const rows = await getPublicProgrammeOfferings();
  const programs: ProgramCard[] =
    rows?.map((row) => ({
          key: row.id,
          eyebrow: [
            row.showcase_eyebrow || row.code,
            row.showcase_eyebrow_bn || row.showcase_eyebrow || row.code,
          ] as [string, string],
          title: [
            row.showcase_title || row.name,
            row.showcase_title_bn || row.showcase_title || row.name,
          ] as [string, string],
          description: [
            row.showcase_description || "",
            row.showcase_description_bn || row.showcase_description || "",
          ] as [string, string],
          icon: SHOWCASE_ICONS[row.showcase_icon ?? ""] ?? GraduationCap,
          offeringId: row.id,
          acceptingApplications: Boolean(row.is_accepting_applications),
          feeSummary: feeSummaryFromPlan(row.fee_plan),
          windowNote: windowNoteFromOffering(row),
          academicContext: [row.academic_year_name, row.branch_name, row.class_name, row.group_name]
            .filter(Boolean).join(" · "),
          subjects: row.subjects.map((subject) => subject.name),
          schedule: row.public_schedule ? [row.public_schedule, row.public_schedule_bn || row.public_schedule] : null,
          requirements: row.public_requirements ? [row.public_requirements, row.public_requirements_bn || row.public_requirements] : null,
          policy: row.admission_policy ? [row.admission_policy, row.admission_policy_bn || row.admission_policy] : null,
          availability: row.active_batch_count === 0
            ? ["Batch placement being prepared", "ব্যাচে স্থান নির্ধারণ প্রস্তুত হচ্ছে"]
            : row.current_open_seats === 0
              ? ["Current batches are full; staff will review placement options", "বর্তমান ব্যাচগুলো পূর্ণ; স্টাফ স্থান নির্ধারণ পর্যালোচনা করবে"]
              : [`${row.current_open_seats} of ${row.current_total_seats} current batch seats open · placement confirmed after review`, `বর্তমান ব্যাচে ${row.current_total_seats}টির মধ্যে ${row.current_open_seats}টি আসন খালি · যাচাইয়ের পরে স্থান নিশ্চিত`],
        })) ?? [];

  return (
    <section id="programs" className="scroll-mt-24 border-b border-border bg-muted/35">
      <div className="mx-auto max-w-7xl px-5 py-18 sm:px-6 lg:px-8 lg:py-24">
        <div className="max-w-3xl">
          <p className="text-xs font-bold uppercase tracking-[0.22em] text-blue-700 dark:text-blue-400">
            <LocalizedText en="Programs" bn="প্রোগ্রামসমূহ" />
          </p>
          <h2 className="mt-3 text-3xl font-bold tracking-[-0.03em] sm:text-4xl">
            <LocalizedText
              en="Focused academic support—not crowded coaching."
              bn="ভিড় নয়—মনোযোগী একাডেমিক সহায়তা।"
            />
          </h2>
          <p className="mt-4 max-w-2xl leading-7 text-muted-foreground">
            <LocalizedText
              en="Each program is designed around a clear academic purpose, manageable batch size and regular measurement of student progress."
              bn="প্রতিটি প্রোগ্রাম স্পষ্ট একাডেমিক লক্ষ্য, নিয়ন্ত্রিত ব্যাচ সাইজ এবং শিক্ষার্থীর নিয়মিত অগ্রগতি পরিমাপকে কেন্দ্র করে সাজানো।"
            />
          </p>
        </div>

        <div className="mt-10 grid gap-5 lg:grid-cols-3">
          {programs.length === 0 && (
            <p className="rounded-3xl border border-border bg-card p-6 text-sm text-muted-foreground lg:col-span-3" role={rows === null ? "alert" : "status"}>
              {rows === null ? (
                <LocalizedText en="Programme information is temporarily unavailable. Please try again shortly." bn="প্রোগ্রামের তথ্য সাময়িকভাবে পাওয়া যাচ্ছে না। কিছুক্ষণ পরে আবার চেষ্টা করুন।" />
              ) : (
                <LocalizedText en="No programmes are published at the moment. Please check back soon." bn="এখন কোনো প্রোগ্রাম প্রকাশিত নেই। পরে আবার দেখুন।" />
              )}
            </p>
          )}
          {programs.map((program) => {
            const interestHref = program.offeringId
              ? `/interest?offering=${program.offeringId}`
              : "/interest";
            const applyHref = program.offeringId
              ? `/interest?offering=${program.offeringId}&intent=admission`
              : "/interest?intent=admission";

            return (
              <article
                key={program.key}
                className="group flex flex-col overflow-hidden rounded-[1.75rem] border border-white/10 bg-linear-to-b from-slate-900 to-slate-950 p-6 text-white shadow-[0_22px_65px_-38px_rgba(0,0,0,.85)] transition duration-300 hover:-translate-y-1 hover:border-blue-400/40 hover:shadow-[0_28px_75px_-38px_rgba(37,99,235,.32)]"
              >
                <div className="flex items-start justify-between gap-4">
                  <div className="flex size-12 items-center justify-center rounded-2xl border border-blue-300/15 bg-blue-400/10 text-blue-200">
                    <program.icon className="size-5" aria-hidden="true" />
                  </div>
                  {program.windowNote ? (
                    <span className={`rounded-full px-3 py-1 text-[11px] font-semibold ${program.acceptingApplications ? "border border-emerald-300/20 bg-emerald-300/10 text-emerald-200" : "border border-white/10 bg-white/5 text-slate-300"}`}>
                      <LocalizedText en={program.windowNote[0]} bn={program.windowNote[1]} />
                    </span>
                  ) : null}
                </div>
                <p className="mt-6 text-[11px] font-bold uppercase tracking-[0.18em] text-blue-300">
                  <LocalizedText en={program.eyebrow[0]} bn={program.eyebrow[1]} />
                </p>
                <h3 className="mt-2 text-2xl font-semibold tracking-tight text-white">
                  <LocalizedText en={program.title[0]} bn={program.title[1]} />
                </h3>
                <p className="mt-2 text-sm leading-6 text-slate-400">{program.academicContext}</p>

                {program.subjects.length > 0 && (
                  <div className="mt-4 flex flex-wrap gap-2" aria-label="Subjects">
                    {program.subjects.map((subject) => (
                      <span key={subject} className="rounded-full border border-white/10 bg-white/4 px-2.5 py-1 text-[11px] text-slate-300">{subject}</span>
                    ))}
                  </div>
                )}

                <details className="group/details mt-4 border-t border-white/10 pt-4">
                  <summary className="cursor-pointer list-none rounded-lg text-sm text-slate-300 outline-none marker:hidden focus-visible:ring-2 focus-visible:ring-blue-400 [&::-webkit-details-marker]:hidden">
                    {program.description[0] ? (
                      <span className="mb-2 block line-clamp-2 leading-6 text-slate-300 group-open/details:line-clamp-none">
                        <LocalizedText en={program.description[0]} bn={program.description[1]} />
                      </span>
                    ) : null}
                    <span className="inline-flex items-center gap-2 font-semibold text-blue-200 transition group-open/details:text-blue-100">
                      <span className="group-open/details:hidden"><LocalizedText en="Read programme details" bn="প্রোগ্রামের বিস্তারিত" /></span>
                      <span className="hidden group-open/details:inline"><LocalizedText en="Show less" bn="সংক্ষিপ্ত করুন" /></span>
                      <span aria-hidden="true" className="transition group-open/details:rotate-180">⌄</span>
                    </span>
                  </summary>
                  <div className="mt-4 space-y-3 text-sm leading-6 text-slate-300">
                  {program.schedule ? <p><span className="font-semibold text-white"><LocalizedText en="Schedule" bn="সময়সূচি" /></span><br /><LocalizedText en={program.schedule[0]} bn={program.schedule[1]} /></p> : null}
                  {program.requirements ? <p><span className="font-semibold text-white"><LocalizedText en="Requirements" bn="শর্ত" /></span><br /><LocalizedText en={program.requirements[0]} bn={program.requirements[1]} /></p> : null}
                  {program.policy ? <p><span className="font-semibold text-white"><LocalizedText en="Admission" bn="ভর্তি" /></span><br /><LocalizedText en={program.policy[0]} bn={program.policy[1]} /></p> : null}
                  <p className="text-slate-400"><LocalizedText en={program.availability[0]} bn={program.availability[1]} /></p>
                  </div>
                </details>

                <div className="mt-auto pt-5">
                  {program.feeSummary ? (
                    <p className="mb-4 rounded-xl border border-white/10 bg-white/4 px-3 py-2.5 text-sm font-semibold text-white">
                      <LocalizedText en={program.feeSummary[0]} bn={program.feeSummary[1]} />
                    </p>
                  ) : null}
                  <div className="flex flex-col gap-2 sm:flex-row">
                  <Link
                    href={interestHref}
                    className="inline-flex min-h-11 flex-1 items-center justify-center rounded-xl border border-white/15 bg-white/4 px-3 text-sm font-semibold text-white transition hover:bg-white/10"
                  >
                    <LocalizedText en="Register Interest" bn="আগ্রহ নিবন্ধন" />
                  </Link>
                  {program.acceptingApplications ? (
                    <Link
                      href={applyHref}
                      className="inline-flex min-h-11 flex-1 items-center justify-center rounded-xl bg-blue-500 px-3 text-sm font-semibold text-white shadow-lg shadow-blue-950/40 transition hover:bg-blue-400"
                    >
                      <LocalizedText en="Apply for Admission" bn="ভর্তির আবেদন" />
                    </Link>
                  ) : (
                    <span className="inline-flex min-h-11 flex-1 items-center justify-center rounded-xl border border-white/10 px-3 text-xs font-medium text-slate-400">
                      <LocalizedText en="Applications closed" bn="আবেদন বন্ধ" />
                    </span>
                  )}
                  </div>
                </div>
              </article>
            );
          })}
        </div>
      </div>
    </section>
  );
}
