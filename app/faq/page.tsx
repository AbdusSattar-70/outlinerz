import { getSiteSettings } from "@/modules/crm/site/server";
import { publicSlug } from "@/modules/crm/public";
import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { LocalizedText } from "@/components/shared/localized-text";
import { PublicPageShell } from "@/modules/home/public-page-shell";

const faqs = [
  [
    "Which students does Sohoj Academy support?",
    "Sohoj Academy focuses on academic support for Classes 8–10. The current programme offerings show the classes and subjects available for registration.",
    "সহজ একাডেমি কোন শিক্ষার্থীদের সহায়তা করে?",
    "সহজ একাডেমি ৮–১০ম শ্রেণির একাডেমিক সহায়তায় গুরুত্ব দেয়। বর্তমানে কোন শ্রেণি ও বিষয়ের জন্য নিবন্ধন চলছে তা প্রোগ্রাম কার্ডে দেখা যাবে।",
  ],
  [
    "Does registering interest confirm admission?",
    "No. Interest registration helps the academy understand what support is needed. Staff follow up and verify details; admission is confirmed only after the admission process is completed.",
    "আগ্রহ নিবন্ধন করলেই কি ভর্তি নিশ্চিত হয়?",
    "না। আগ্রহ নিবন্ধন একাডেমিকে প্রয়োজন বুঝতে সাহায্য করে। স্টাফ তথ্য যাচাই করে যোগাযোগ করবেন; ভর্তি প্রক্রিয়া সম্পন্ন হওয়ার পরই ভর্তি নিশ্চিত হয়।",
  ],
  [
    "How do I apply for an open programme?",
    "Choose an offering marked as accepting applications and use its admission application button. The form can be submitted without creating a student account.",
    "উন্মুক্ত প্রোগ্রামে কীভাবে আবেদন করব?",
    "আবেদন গ্রহণ করছে এমন প্রোগ্রাম বেছে নিয়ে তার ভর্তি আবেদন বাটনে চাপ দিন। শিক্ষার্থী অ্যাকাউন্ট তৈরি না করেই ফর্ম জমা দেওয়া যায়।",
  ],
  [
    "Where can I find programme fees and subjects?",
    "Each programme card shows its published fee summary, subjects and application status. Open the programme details for schedule, requirements and other information when available.",
    "প্রোগ্রামের ফি ও বিষয় কোথায় পাব?",
    "প্রতিটি প্রোগ্রাম কার্ডে প্রকাশিত ফি, বিষয় এবং আবেদন অবস্থা দেখানো হয়। সময়সূচি, শর্ত ও অন্যান্য তথ্য থাকলে বিস্তারিত অংশ খুলে দেখুন।",
  ],
  [
    "How are batch and class placement confirmed?",
    "The academy checks the student's application and available placement options. Submitting an interest or application form does not reserve a seat by itself.",
    "ব্যাচ ও শ্রেণি নির্ধারণ কীভাবে নিশ্চিত হয়?",
    "একাডেমি শিক্ষার্থীর আবেদন এবং উপলভ্য স্থান যাচাই করে। আগ্রহ বা আবেদন ফর্ম জমা দিলেই আসন সংরক্ষিত হয় না।",
  ],
  [
    "Can a guardian submit the form for a student?",
    "Yes. A parent or guardian can provide the student's details and their own contact information so the academy can follow up.",
    "অভিভাবক কি শিক্ষার্থীর হয়ে ফর্ম জমা দিতে পারেন?",
    "হ্যাঁ। অভিভাবক শিক্ষার্থীর তথ্য ও নিজের যোগাযোগের তথ্য দিয়ে একাডেমির ফলো-আপের জন্য ফর্ম জমা দিতে পারেন।",
  ],
] as const;

export default async function FaqPage({
  searchParams,
}: {
  searchParams: Promise<{ organization?: string }>;
}) {
  const { organization } = await searchParams;
  return (
    <PublicPageShell
      organizationSlug={publicSlug(organization)}
      eyebrow={["Help for families", "পরিবারের জন্য সহায়তা"]}
      title={["Questions, answered clearly.", "আপনার প্রশ্নের সহজ উত্তর।"]}
      description={[
        "A few practical details about programmes, registration and what happens after a form is submitted.",
        "প্রোগ্রাম, নিবন্ধন এবং ফর্ম জমা দেওয়ার পর কী হয়—কিছু প্রয়োজনীয় তথ্য এখানে দেওয়া হলো।",
      ]}
    >
      <section className="mx-auto max-w-4xl px-5 py-12 sm:px-6 lg:px-8 lg:py-16">
        <div className="divide-y divide-border overflow-hidden rounded-3xl border border-border bg-card">
          {faqs.map(([questionEn, answerEn, questionBn, answerBn], index) => (
            <details
              key={questionEn}
              className="group p-5 open:bg-muted/30 sm:p-6"
              open={index === 0}
            >
              <summary className="flex cursor-pointer list-none items-start justify-between gap-5 text-base font-semibold marker:hidden focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring [&::-webkit-details-marker]:hidden">
                <span>
                  <LocalizedText en={questionEn} bn={questionBn} />
                </span>
                <span
                  aria-hidden="true"
                  className="text-xl leading-5 text-blue-300 transition group-open:rotate-45"
                >
                  +
                </span>
              </summary>
              <p className="max-w-3xl pt-4 text-sm leading-7 text-muted-foreground">
                <LocalizedText en={answerEn} bn={answerBn} />
              </p>
            </details>
          ))}
        </div>
        <div className="mt-8 flex flex-col justify-between gap-4 rounded-2xl border border-blue-300/15 bg-blue-500/[0.06] p-6 sm:flex-row sm:items-center">
          <p className="text-sm leading-6 text-muted-foreground">
            <LocalizedText
              en="Ready to see which programmes are open?"
              bn="কোন প্রোগ্রামে আবেদন চলছে দেখতে চান?"
            />
          </p>
          <Link
            href={`/?organization=${encodeURIComponent(publicSlug(organization))}#programs`}
            className="inline-flex min-h-11 shrink-0 items-center justify-center gap-2 rounded-xl bg-blue-500 px-4 text-sm font-semibold text-white hover:bg-blue-400"
          >
            <LocalizedText en="Browse programmes" bn="প্রোগ্রাম দেখুন" />
            <ArrowRight className="size-4" aria-hidden="true" />
          </Link>
        </div>
      </section>
    </PublicPageShell>
  );
}

export async function generateMetadata({
  searchParams,
}: {
  searchParams: Promise<{ organization?: string }>;
}): Promise<Metadata> {
  const { organization } = await searchParams;
  const site = await getSiteSettings(publicSlug(organization));
  return { title: { absolute: "FAQ | " + site.nameEn } };
}
