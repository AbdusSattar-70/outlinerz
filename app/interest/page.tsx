import type { Metadata } from "next";
import Link from "next/link";
import { House, Info, ShieldCheck } from "lucide-react";
import Navbar from "@/components/home-navbar/navbar";
import { PublicInterestForm } from "@/components/public/interest-form";
import Logo from "@/components/shared/logo";
import { LocalizedText } from "@/components/shared/localized-text";
import { platformClient } from "@/modules/platform/rpc-client";
import { z } from "zod";
import { getPublicProgrammeOfferings } from "@/modules/offerings/queries";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Register Interest | Sohoj Academy",
  description:
    "Register academic interest with Sohoj Academy for programme, subject and schedule follow-up.",
};

type SearchParams = Promise<{ offering?: string; intent?: string }>;

export default async function InterestPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;
  const intent = params.intent === "admission" ? "admission" : "interest";
  const requestedOfferingId = params.offering?.trim() || "";

  const supabase = await platformClient();
  const [directoryQ,publicOfferings]=await Promise.all([supabase.rpc("public_academic_directory"),getPublicProgrammeOfferings()]);
  const option=z.object({id:z.string().uuid(),name:z.string()});const code=z.object({code:z.string(),name:z.string()});
  const directory=z.object({classes:z.array(option),programs:z.array(option),subjects:z.array(option),schools:z.array(option),sources:z.array(code),relationships:z.array(code)}).safeParse(directoryQ.data);
  const error=directoryQ.error??(!directory.success?{message:"Academic directory unavailable"}:null);
  const classesQ={data:directory.success?directory.data.classes:[],error};
  const programsQ={data:directory.success?directory.data.programs:[],error};
  const subjectsQ={data:directory.success?directory.data.subjects:[],error};
  const schoolsQ={data:directory.success?directory.data.schools:[],error};
  const sourcesQ={data:directory.success?directory.data.sources:[],error};
  const relationshipsQ={data:directory.success?directory.data.relationships:[],error};

  const openOfferings = (publicOfferings ?? []).filter((row) => row.is_accepting_applications);
  const preselected =
    openOfferings.find((row) => row.id === requestedOfferingId) ??
    null;
  const closedRequested =
    Boolean(requestedOfferingId) &&
    !preselected &&
    (publicOfferings ?? []).some((row) => row.id === requestedOfferingId);

  const optionsUnavailable =
    Boolean(classesQ.error) ||
    Boolean(programsQ.error) ||
    Boolean(subjectsQ.error) ||
    Boolean(schoolsQ.error) ||
    Boolean(sourcesQ.error) ||
    Boolean(relationshipsQ.error) ||
    publicOfferings === null;

  return (
    <div className="min-h-screen bg-background text-foreground">
      <Navbar />
      <main id="main-content">
        <section className="border-b border-border bg-background">
          <div className="mx-auto max-w-5xl px-5 py-12 sm:px-6 lg:px-8 lg:py-16">
            <Link
              href="/"
              className="inline-flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-foreground"
            >
              <House className="size-4" aria-hidden="true" />
              <LocalizedText en="Go to homepage" bn="মূল পাতায় ফিরুন" />
            </Link>

            <div className="mt-8 max-w-3xl">
              <p className="text-xs font-bold uppercase tracking-[0.22em] text-blue-700 dark:text-blue-400">
                {intent === "admission" ? (
                  <LocalizedText en="Admission application" bn="ভর্তির আবেদন" />
                ) : (
                  <LocalizedText en="Student Interest Registration" bn="শিক্ষার্থী আগ্রহ নিবন্ধন" />
                )}
              </p>
              <h1 className="mt-3 text-3xl font-bold tracking-[-0.03em] sm:text-4xl lg:text-5xl">
                {intent === "admission" ? (
                  <LocalizedText
                    en="Apply for an open programme offering."
                    bn="উন্মুক্ত প্রোগ্রাম অফারিংয়ে ভর্তির আবেদন করুন।"
                  />
                ) : (
                  <LocalizedText
                    en="Tell us what support the student is looking for."
                    bn="শিক্ষার্থী কী ধরনের সহায়তা খুঁজছে তা আমাদের জানান।"
                  />
                )}
              </h1>
              <p className="mt-5 text-base leading-8 text-muted-foreground">
                {intent === "admission" ? (
                  <LocalizedText
                    en="Choose an offering that is currently accepting applications. Staff will verify the details before any admission is confirmed."
                    bn="বর্তমানে আবেদন গ্রহণ করছে এমন একটি অফারিং বেছে নিন। ভর্তি নিশ্চিত হওয়ার আগে স্টাফ তথ্য যাচাই করবে।"
                  />
                ) : (
                  <LocalizedText
                    en="This short registration helps Sohoj Academy understand the student's class, programme or subject interests and preferred schedule before admission."
                    bn="এই সংক্ষিপ্ত নিবন্ধন ভর্তির আগে শিক্ষার্থীর ক্লাস, প্রোগ্রাম বা বিষয় আগ্রহ এবং পছন্দের সময় বুঝতে সাহায্য করে।"
                  />
                )}
              </p>
            </div>

            <div className="mt-7 grid gap-3 sm:grid-cols-2">
              <div className="flex gap-3 rounded-2xl border border-border bg-muted/50 p-4">
                <Info className="mt-0.5 size-5 shrink-0 text-blue-700 dark:text-blue-400" aria-hidden="true" />
                <div>
                  <p className="text-sm font-semibold">
                    <LocalizedText en="This is not admission" bn="এটি ভর্তি নয়" />
                  </p>
                  <p className="mt-1 text-xs leading-5 text-muted-foreground">
                    <LocalizedText
                      en="No fee or permanent Student ID is created by this form until staff complete verification and admission."
                      bn="স্টাফ যাচাই ও ভর্তি সম্পন্ন না করা পর্যন্ত এই ফর্ম থেকে ফি বা স্থায়ী Student ID তৈরি হয় না।"
                    />
                  </p>
                </div>
              </div>
              <div className="flex gap-3 rounded-2xl border border-border bg-muted/50 p-4">
                <ShieldCheck className="mt-0.5 size-5 shrink-0 text-blue-700 dark:text-blue-400" aria-hidden="true" />
                <div>
                  <p className="text-sm font-semibold">
                    <LocalizedText en="Structured follow-up" bn="গোছানো ফলো-আপ" />
                  </p>
                  <p className="mt-1 text-xs leading-5 text-muted-foreground">
                    <LocalizedText
                      en="The information becomes a traceable prospect record for academy follow-up."
                      bn="তথ্যগুলো একাডেমির ফলো-আপের জন্য ট্রেসযোগ্য Prospect রেকর্ড হিসেবে সংরক্ষিত হয়।"
                    />
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section className="mx-auto max-w-5xl px-5 py-10 sm:px-6 lg:px-8 lg:py-14">
          {closedRequested ? (
            <div
              role="alert"
              className="mb-5 rounded-2xl border border-amber-300 bg-amber-50 p-5 text-sm leading-6 text-amber-900 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-100"
            >
              <LocalizedText
                en="Applications are closed for the programme you selected. Choose another open offering below, or register general interest."
                bn="আপনি যে প্রোগ্রামটি বেছেছিলেন তার আবেদন বর্তমানে বন্ধ। নিচে অন্য উন্মুক্ত অফারিং বেছে নিন, অথবা সাধারণ আগ্রহ নিবন্ধন করুন।"
              />
            </div>
          ) : null}

          {optionsUnavailable ? (
            <div
              role="alert"
              className="rounded-2xl border border-amber-300 bg-amber-50 p-5 text-sm leading-6 text-amber-900 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-100"
            >
              <LocalizedText
                en="The registration choices are temporarily unavailable. Please refresh after the academy database update is completed."
                bn="নিবন্ধনের অপশনগুলো সাময়িকভাবে পাওয়া যাচ্ছে না। একাডেমির ডাটাবেজ আপডেট সম্পন্ন হলে পেজটি রিফ্রেশ করুন।"
              />
            </div>
          ) : (
            <div className="rounded-[2rem] border border-border bg-card p-5 text-card-foreground shadow-[0_24px_70px_-50px_rgba(15,23,42,.35)] sm:p-7 lg:p-9">
              <PublicInterestForm
                classes={classesQ.data ?? []}
                programs={programsQ.data ?? []}
                subjects={subjectsQ.data ?? []}
                schools={(schoolsQ.data ?? []).map((school) => ({
                  id: school.id,
                  label: school.name,
                }))}
                sourceOptions={sourcesQ.data ?? []}
                relationships={relationshipsQ.data ?? []}
                openOfferings={openOfferings.map((row) => ({
                  id: row.id,
                  code: row.code,
                  schedule: row.public_schedule,
                  scheduleBn: row.public_schedule_bn,
                  requirements: row.public_requirements,
                  requirementsBn: row.public_requirements_bn,
                  policy: row.admission_policy,
                  policyBn: row.admission_policy_bn,
                  feePlan: row.fee_plan,
                  openSeats: row.current_open_seats,
                  activeBatches: row.active_batch_count,
                  name: row.showcase_title || row.name,
                  classId: row.class_id,
                  programId: row.program_id,
                  subjectIds: (row.subjects ?? []).map((subject) => subject.id),
                }))}
                defaultOfferingId={preselected?.id ?? ""}
                intent={intent}
              />
            </div>
          )}
        </section>
      </main>

      <footer className="border-t border-border bg-background">
        <div className="mx-auto flex max-w-5xl flex-col gap-4 px-5 py-8 sm:px-6 md:flex-row md:items-center md:justify-between lg:px-8">
          <Logo size={76} />
          <p className="text-xs text-muted-foreground">
            <LocalizedText en="Learning should be easy and enjoyable" bn="শিক্ষা হোক সহজ ও আনন্দময়" />
          </p>
        </div>
      </footer>
    </div>
  );
}
