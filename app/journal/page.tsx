import { getSiteSettings } from "@/modules/crm/site/server";
import { resolvePublicSlug } from "@/modules/crm/public";
import type { Metadata } from "next";
import { BookOpenText, ClipboardCheck, Lightbulb } from "lucide-react";
import { LocalizedText } from "@/components/shared/localized-text";
import { PublicPageShell } from "@/modules/home/public-page-shell";

const articles = [
  {
    icon: Lightbulb,
    category: ["STUDY HABITS", "পড়াশোনার অভ্যাস"],
    title: [
      "A study session that has a clear finish line",
      "যে পড়ার সেশনের শেষ লক্ষ্য পরিষ্কার",
    ],
    summary: [
      "Replace an open-ended ‘study more’ goal with one small outcome a student can check.",
      "‘আরও পড়ব’—এমন অস্পষ্ট লক্ষ্য না রেখে শিক্ষার্থী যাচাই করতে পারে এমন ছোট লক্ষ্য ঠিক করুন।",
    ],
    content: [
      "Choose one topic and define what ‘done’ means: explain the idea without notes, solve a short set of questions, or correct yesterday’s mistakes. Keep the session focused on that outcome.",
      "একটি বিষয় বেছে নিয়ে ‘শেষ’ বলতে কী বোঝায় ঠিক করুন: নোট ছাড়া ধারণাটি বোঝানো, কয়েকটি প্রশ্ন সমাধান, অথবা গতকালের ভুল সংশোধন। পুরো সেশনটি সেই লক্ষ্যেই রাখুন।",
      "At the end, ask the student to mark what felt easy and what still needs help. That note becomes the starting point for the next session.",
      "শেষে শিক্ষার্থীকে বলতে বলুন কোন অংশ সহজ লেগেছে এবং কোথায় আরও সাহায্য দরকার। পরের সেশনের শুরু হবে সেই নোট থেকে।",
    ],
  },
  {
    icon: ClipboardCheck,
    category: ["TEST REVIEW", "পরীক্ষা পর্যালোচনা"],
    title: [
      "Use mistakes as a map for the next lesson",
      "ভুলকে পরের পাঠের দিকনির্দেশনা করুন",
    ],
    summary: [
      "A test result is more useful when students can see why an answer went wrong and what to practise next.",
      "কেন উত্তর ভুল হয়েছে এবং এরপর কী অনুশীলন করতে হবে বুঝলে পরীক্ষার ফল বেশি কাজে লাগে।",
    ],
    content: [
      "After a quiz, sort mistakes into a few simple groups: the idea was unclear, a step was skipped, the question was misread, or the answer was not checked. Avoid correcting only the final number.",
      "কুইজের পর ভুলগুলো কয়েকটি সহজ ভাগে রাখুন: ধারণা অস্পষ্ট ছিল, ধাপ বাদ গেছে, প্রশ্ন ভুল পড়া হয়েছে, অথবা উত্তর যাচাই করা হয়নি। শুধু শেষের সংখ্যাটি ঠিক করে থেমে যাবেন না।",
      "Pick one recurring pattern and practise it with a fresh example. Then revisit it in a later session to see whether the correction stuck.",
      "বারবার হওয়া একটি ভুল বেছে নতুন উদাহরণে অনুশীলন করুন। পরে আবার সেটি দেখে সংশোধনটি স্থায়ী হয়েছে কি না যাচাই করুন।",
    ],
  },
  {
    icon: BookOpenText,
    category: ["FOR GUARDIANS", "অভিভাবকদের জন্য"],
    title: [
      "Support a learner without taking over",
      "শিক্ষার্থীর হয়ে না করে পাশে থাকুন",
    ],
    summary: [
      "A calm check-in can help a student plan, reflect and ask for support while keeping ownership of the work.",
      "শান্তভাবে খোঁজ নিলে শিক্ষার্থী পরিকল্পনা করতে, ভাবতে এবং সাহায্য চাইতে পারে—কাজের দায়িত্ব নিজের কাছেই থাকে।",
    ],
    content: [
      "Ask what the student is working on, what feels difficult and what the next small step could be. Give them time to answer before suggesting a solution.",
      "শিক্ষার্থীকে জিজ্ঞেস করুন সে কী পড়ছে, কোন অংশ কঠিন লাগছে এবং পরের ছোট পদক্ষেপ কী হতে পারে। সমাধান বলার আগে তাকে উত্তর দেওয়ার সময় দিন।",
      "Notice steady effort and specific progress, not only marks. If a difficulty continues, share the observation with the teacher so support can be planned together.",
      "শুধু নম্বর নয়, ধারাবাহিক চেষ্টা ও নির্দিষ্ট অগ্রগতিও খেয়াল করুন। কোনো সমস্যা চলতে থাকলে শিক্ষককে জানান, যাতে একসঙ্গে সহায়তার পরিকল্পনা করা যায়।",
    ],
  },
] as const;

export default async function JournalPage({
  searchParams,
}: {
  searchParams: Promise<{ organization?: string }>;
}) {
  const { organization } = await searchParams;
  const slug = await resolvePublicSlug(organization);
  return (
    <PublicPageShell
      organizationSlug={slug}
      eyebrow={["Sohoj Learning Journal", "সহজ একাডেমি শিক্ষা-জার্নাল"]}
      title={[
        "Small ideas for better learning.",
        "আরও ভালো শেখার জন্য ছোট কিছু ভাবনা।",
      ]}
      description={[
        "Practical notes for students and guardians on study habits, test review and everyday learning.",
        "পড়ার অভ্যাস, পরীক্ষা পর্যালোচনা এবং প্রতিদিনের শেখা নিয়ে শিক্ষার্থী ও অভিভাবকদের জন্য ব্যবহারিক লেখা।",
      ]}
    >
      <section className="mx-auto max-w-7xl px-5 py-12 sm:px-6 lg:px-8 lg:py-16">
        <div className="grid gap-5 lg:grid-cols-3">
          {articles.map(({ icon: Icon, category, title, summary, content }) => (
            <article
              key={title[0]}
              className="flex flex-col rounded-3xl border border-border bg-card p-6 shadow-[0_20px_60px_-48px_rgba(37,99,235,.5)]"
            >
              <span className="flex size-11 items-center justify-center rounded-xl bg-blue-500/10 text-blue-300">
                <Icon className="size-5" aria-hidden="true" />
              </span>
              <p className="mt-6 text-[11px] font-bold tracking-[0.18em] text-blue-300">
                <LocalizedText en={category[0]} bn={category[1]} />
              </p>
              <h2 className="mt-2 text-xl font-semibold leading-snug">
                <LocalizedText en={title[0]} bn={title[1]} />
              </h2>
              <p className="mt-3 text-sm leading-7 text-muted-foreground">
                <LocalizedText en={summary[0]} bn={summary[1]} />
              </p>
              <details className="group mt-5 border-t border-border pt-4">
                <summary className="cursor-pointer list-none text-sm font-semibold text-blue-300 marker:hidden focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring [&::-webkit-details-marker]:hidden">
                  <span className="group-open:hidden">
                    <LocalizedText en="Read article" bn="লেখাটি পড়ুন" />
                  </span>
                  <span className="hidden group-open:inline">
                    <LocalizedText en="Close article" bn="লেখা বন্ধ করুন" />
                  </span>
                  <span
                    aria-hidden="true"
                    className="ml-2 inline-block transition group-open:rotate-180"
                  >
                    ⌄
                  </span>
                </summary>
                <div className="mt-4 space-y-3 text-sm leading-7 text-muted-foreground">
                  <p>
                    <LocalizedText en={content[0]} bn={content[1]} />
                  </p>
                  <p>
                    <LocalizedText en={content[2]} bn={content[3]} />
                  </p>
                </div>
              </details>
            </article>
          ))}
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
  return { title: { absolute: "Journal | " + site.nameEn } };
}
