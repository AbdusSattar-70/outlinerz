import { getSiteSettings } from "@/modules/crm/site/server";
import { resolvePublicSlug } from "@/modules/crm/public";
import type { Metadata } from "next";
import { SiteImage } from "@/modules/crm/site/provider";
import Link from "next/link";
import {
  ArrowRight,
  BookOpenCheck,
  HeartHandshake,
  Target,
} from "lucide-react";
import { LocalizedText } from "@/components/shared/localized-text";
import { PublicPageShell } from "@/modules/home/public-page-shell";

const commitments = [
  {
    icon: BookOpenCheck,
    title: ["Teach for understanding", "বোঝার জন্য শেখানো"] as [string, string],
    body: [
      "Start with clear concepts, then give students time to practise and ask questions.",
      "ধারণা পরিষ্কার করে শুরু করি, তারপর অনুশীলন ও প্রশ্নের জন্য সময় রাখি।",
    ] as [string, string],
  },
  {
    icon: Target,
    title: ["Notice what needs work", "কোথায় উন্নতি দরকার খেয়াল রাখা"] as [
      string,
      string,
    ],
    body: [
      "Use regular exercises and assessments to find learning gaps and plan the next lesson.",
      "নিয়মিত অনুশীলন ও মূল্যায়নের মাধ্যমে শেখার ঘাটতি বুঝে পরের পাঠ সাজাই।",
    ] as [string, string],
  },
  {
    icon: HeartHandshake,
    title: ["Keep guardians informed", "অভিভাবককে অবহিত রাখা"] as [
      string,
      string,
    ],
    body: [
      "Make attendance, learning progress and next steps easier for families to follow.",
      "উপস্থিতি, শেখার অগ্রগতি ও পরবর্তী পদক্ষেপ পরিবার যেন সহজে অনুসরণ করতে পারে।",
    ] as [string, string],
  },
];

export default async function AboutPage({
  searchParams,
}: {
  searchParams: Promise<{ organization?: string }>;
}) {
  const { organization } = await searchParams;
  const slug = await resolvePublicSlug(organization);
  return (
    <PublicPageShell
      organizationSlug={slug}
      eyebrow={["About Sohoj Academy", "সহজ একাডেমি সম্পর্কে"]}
      title={[
        "A focused place to learn with confidence.",
        "আত্মবিশ্বাস নিয়ে শেখার একটি মনোযোগী পরিবেশ।",
      ]}
      description={[
        "Sohoj Academy supports students in Classes 8–12 with clear teaching, purposeful practice and a steady view of progress.",
        "সহজ একাডেমি ৮–১২ম শ্রেণির শিক্ষার্থীদের স্পষ্ট পাঠদান, উদ্দেশ্যপূর্ণ অনুশীলন এবং অগ্রগতির নিয়মিত ধারণা দিয়ে সহায়তা করে।",
      ]}
    >
      <section className="mx-auto grid max-w-7xl gap-10 px-5 py-12 sm:px-6 lg:grid-cols-[1fr_1fr] lg:items-center lg:px-8 lg:py-16">
        <div className="relative overflow-hidden rounded-[2rem] border border-white/10 shadow-2xl shadow-blue-950/30">
          <SiteImage
            kind="heroImage"
            alt="Illustrative classroom photo of a teacher guiding students through a lesson"
            width={1672}
            height={941}
            sizes="(max-width: 1024px) 100vw, 50vw"
            className="aspect-[1.3] w-full object-cover"
          />
          <div
            className="absolute inset-0 bg-gradient-to-t from-slate-950/60 to-transparent"
            aria-hidden="true"
          />
          <p className="absolute bottom-5 left-5 right-5 text-sm font-medium text-white sm:text-base">
            <LocalizedText
              en="Making difficult things easier to learn."
              bn="কঠিন বিষয় সহজ করে শেখা।"
            />
          </p>
        </div>

        <div>
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-300">
            <LocalizedText en="Our purpose" bn="আমাদের লক্ষ্য" />
          </p>
          <h2 className="mt-3 text-3xl font-bold tracking-tight">
            <LocalizedText en="Mission" bn="মিশন" />
          </h2>
          <p className="mt-3 text-base leading-8 text-muted-foreground">
            <LocalizedText
              en="Make learning clear, engaging and manageable by helping students understand concepts, practise with purpose and see what to work on next."
              bn="শিক্ষার্থী যেন ধারণা বুঝতে পারে, উদ্দেশ্য নিয়ে অনুশীলন করে এবং পরবর্তী করণীয় জানতে পারে—এভাবে শেখাকে স্পষ্ট, আনন্দদায়ক ও সহজসাধ্য করা।"
            />
          </p>
          <h2 className="mt-8 text-3xl font-bold tracking-tight">
            <LocalizedText en="Vision" bn="ভিশন" />
          </h2>
          <p className="mt-3 text-base leading-8 text-muted-foreground">
            <LocalizedText
              en="Build a trusted local learning community where every student receives attention, useful feedback and a clear path to improve."
              bn="এমন একটি বিশ্বস্ত স্থানীয় শেখার পরিবেশ গড়ে তোলা, যেখানে প্রতিটি শিক্ষার্থী মনোযোগ, কার্যকর মতামত এবং উন্নতির পরিষ্কার পথ পায়।"
            />
          </p>
        </div>
      </section>

      <section className="border-y border-border bg-muted/25">
        <div className="mx-auto max-w-7xl px-5 py-14 sm:px-6 lg:px-8 lg:py-16">
          <div className="max-w-2xl">
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-300">
              <LocalizedText
                en="What families can expect"
                bn="পরিবার যা আশা করতে পারে"
              />
            </p>
            <h2 className="mt-3 text-3xl font-bold">
              <LocalizedText
                en="A thoughtful routine, from lesson to feedback."
                bn="পাঠ থেকে মতামত—একটি যত্নশীল ধারাবাহিকতা।"
              />
            </h2>
          </div>
          <div className="mt-8 grid gap-4 md:grid-cols-3">
            {commitments.map(({ icon: Icon, title, body }) => (
              <article
                key={title[0]}
                className="rounded-2xl border border-border bg-card p-6"
              >
                <span className="flex size-11 items-center justify-center rounded-xl bg-blue-500/10 text-blue-300">
                  <Icon className="size-5" aria-hidden="true" />
                </span>
                <h3 className="mt-5 text-lg font-semibold">
                  <LocalizedText en={title[0]} bn={title[1]} />
                </h3>
                <p className="mt-2 text-sm leading-7 text-muted-foreground">
                  <LocalizedText en={body[0]} bn={body[1]} />
                </p>
              </article>
            ))}
          </div>
          <Link
            href={`/?organization=${encodeURIComponent(slug)}#programs`}
            className="mt-8 inline-flex min-h-11 items-center gap-2 rounded-xl bg-blue-500 px-5 text-sm font-semibold text-white transition hover:bg-blue-400"
          >
            <LocalizedText
              en="Explore current programmes"
              bn="বর্তমান প্রোগ্রাম দেখুন"
            />
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
  const site = await getSiteSettings(await resolvePublicSlug(organization));
  return { title: { absolute: "About | " + site.nameEn } };
}
