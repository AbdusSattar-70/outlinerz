import Link from "next/link";
import Image from "next/image";
import {
  ArrowRight,
  BookOpenCheck,
  Check,
  LineChart,
  BarChart3,
  MessageSquareText,
  ShieldCheck,
  Sparkles,
  UsersRound,
} from "lucide-react";
import Navbar from "@/components/home-navbar/navbar";
import Logo from "@/components/shared/logo";
import { LocalizedText } from "@/components/shared/localized-text";
import { HomeProgramSection } from "@/modules/home/program-section";

const trustPoints = [
  {
    title: ["Small learning groups", "ছোট শেখার দল"],
    description: [
      "Small batches make personal attention practical, not promotional.",
      "ছোট ব্যাচে ব্যক্তিগত মনোযোগ বাস্তবে দেওয়া সম্ভব হয়।",
    ],
    icon: UsersRound,
  },
  {
    title: ["Continuous assessment", "ধারাবাহিক মূল্যায়ন"],
    description: [
      "Regular practice and review help make progress measurable.",
      "নিয়মিত অনুশীলন ও পর্যালোচনা অগ্রগতি পরিমাপে সাহায্য করে।",
    ],
    icon: BookOpenCheck,
  },
  {
    title: ["Guardian visibility", "অভিভাবকের স্পষ্ট ধারণা"],
    description: [
      "Attendance, results and progress records support clearer guardian follow-up.",
      "উপস্থিতি, ফলাফল ও অগ্রগতির রেকর্ড অভিভাবকের নিয়মিত অনুসরণকে সহজ করে।",
    ],
    icon: MessageSquareText,
  },
  {
    title: ["Structured academic records", "গোছানো একাডেমিক রেকর্ড"],
    description: [
      "Learning history is organised so important progress does not disappear between classes.",
      "শেখার ইতিহাস সংগঠিত থাকে, যাতে ক্লাসের মাঝে গুরুত্বপূর্ণ অগ্রগতি হারিয়ে না যায়।",
    ],
    icon: ShieldCheck,
  },
] as const;

const method = [
  ["01", "Understand", "বুঝি", "Concept first", "আগে ধারণা পরিষ্কার করি"],
  [
    "02",
    "Practise",
    "অনুশীলন করি",
    "Practise deliberately",
    "উদ্দেশ্যপূর্ণ অনুশীলন করি",
  ],
  [
    "03",
    "Assess",
    "পরীক্ষা দিই",
    "Measure learning",
    "শেখা কতটুকু হয়েছে যাচাই করি",
  ],
  ["04", "Analyse", "বিশ্লেষণ করি", "Find the gap", "ঘাটতি চিহ্নিত করি"],
] as const;

export async function HomePageContent({ slug }: { slug?: string }) {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <Navbar organizationSlug={slug} />

      <main id="main-content">
        <section className="relative overflow-hidden border-b border-border bg-background">
          <div
            className="pointer-events-none absolute inset-0"
            aria-hidden="true"
            style={{
              background:
                "radial-gradient(circle at 75% 20%, rgba(37,99,235,0.10), transparent 28%), radial-gradient(circle at 20% 70%, rgba(14,165,233,0.08), transparent 25%)",
            }}
          />

          <div className="relative mx-auto grid max-w-7xl gap-12 px-5 py-14 sm:px-6 sm:py-20 lg:grid-cols-[1.08fr_.92fr] lg:items-center lg:px-8 lg:py-24">
            <div className="max-w-3xl">
              <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-blue-200 bg-blue-50 px-3 py-1.5 text-xs font-semibold text-blue-800 dark:border-blue-900 dark:bg-blue-950/50 dark:text-blue-200">
                <Sparkles className="size-3.5" aria-hidden="true" />
                <LocalizedText
                  en="Small batch • Personal attention • Visible progress"
                  bn="ছোট ব্যাচ • ব্যক্তিগত মনোযোগ • দৃশ্যমান অগ্রগতি"
                />
              </div>

              <h1 className="max-w-4xl text-4xl font-bold tracking-[-0.04em] sm:text-5xl lg:text-6xl">
                <LocalizedText en="Learning should be" bn="শিক্ষা হোক" />
                <span className="block text-blue-700 dark:text-blue-400">
                  <LocalizedText en="easy and enjoyable" bn="সহজ ও আনন্দময়" />
                </span>
              </h1>

              <p className="mt-6 max-w-2xl text-base leading-8 text-muted-foreground sm:text-lg">
                <LocalizedText
                  en="Outlinerz is built around focused teaching, regular practice and measurable progress—so students know what to improve and guardians can follow the learning journey with confidence."
                  bn="Outlinerzতে মনোযোগী পাঠদান, নিয়মিত অনুশীলন এবং পরিমাপযোগ্য অগ্রগতির ওপর গুরুত্ব দেওয়া হয়—যাতে শিক্ষার্থী বুঝতে পারে কোথায় উন্নতি প্রয়োজন এবং অভিভাবক আত্মবিশ্বাসের সঙ্গে শেখার যাত্রা অনুসরণ করতে পারেন।"
                />
              </p>

              <div className="mt-8 flex flex-col gap-3 sm:flex-row">
                <Link
                  href={`/interest?organization=${encodeURIComponent(slug ?? "")}`}
                  className="inline-flex min-h-12 items-center justify-center gap-2 rounded-xl bg-blue-700 px-5 py-3 text-sm font-semibold text-white shadow-[0_10px_30px_-12px_rgba(29,78,216,0.65)] transition hover:bg-blue-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-600 focus-visible:ring-offset-2"
                >
                  <LocalizedText
                    en="Register Interest"
                    bn="আগ্রহ নিবন্ধন করুন"
                  />
                  <ArrowRight className="size-4" aria-hidden="true" />
                </Link>
                <Link
                  href="#programs"
                  className="inline-flex min-h-12 items-center justify-center rounded-xl border border-border bg-background px-5 py-3 text-sm font-semibold transition hover:bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                >
                  <LocalizedText en="Explore Programs" bn="প্রোগ্রাম দেখুন" />
                </Link>
              </div>

              <div className="mt-8 grid max-w-2xl gap-3 text-sm text-muted-foreground sm:grid-cols-3">
                {[
                  ["Class 8–12 focus", "ক্লাস ৮–১২ ফোকাস"],
                  ["12 students per batch", "প্রতি ব্যাচে ১২ জন"],
                  ["Regular progress review", "নিয়মিত অগ্রগতি পর্যালোচনা"],
                ].map(([en, bn]) => (
                  <div key={en} className="flex items-center gap-2">
                    <span className="flex size-5 shrink-0 items-center justify-center rounded-full bg-emerald-50 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300">
                      <Check className="size-3" aria-hidden="true" />
                    </span>
                    <LocalizedText en={en} bn={bn} />
                  </div>
                ))}
              </div>
            </div>

            <div className="relative mx-auto w-full max-w-2xl lg:mx-0">
              <div
                className="absolute -inset-4 rounded-[2.5rem] bg-linear-to-br from-blue-500/20 via-transparent to-emerald-400/20 blur-2xl"
                aria-hidden="true"
              />
              <div className="relative overflow-hidden rounded-[2rem] border border-white/10 bg-slate-950 shadow-[0_35px_90px_-35px_rgba(2,6,23,.8)]">
                <Image
                  src="/images/sohoj-classroom.webp"
                  alt="Illustrative classroom photo of a teacher guiding students through a lesson"
                  width={1672}
                  height={941}
                  priority
                  sizes="(max-width: 1024px) 100vw, 48vw"
                  className="aspect-[1.22] w-full object-cover object-center sm:aspect-[1.38]"
                />
                <div
                  className="absolute inset-0 bg-linear-to-t from-slate-950/90 via-slate-950/10 to-transparent"
                  aria-hidden="true"
                />
                <div className="absolute inset-x-0 bottom-0 p-5 text-white sm:p-7">
                  <p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-200">
                    <LocalizedText
                      en="LEARNING, MADE CLEAR"
                      bn="সহজভাবে শেখা"
                    />
                  </p>
                  <p className="mt-2 max-w-md text-xl font-semibold leading-snug sm:text-2xl">
                    <LocalizedText
                      en="A classroom where every question gets room."
                      bn="যে শ্রেণিকক্ষে প্রতিটি প্রশ্নের জন্য জায়গা আছে।"
                    />
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>
        <HomeProgramSection slug={slug} />
        <section
          id="method"
          className="relative scroll-mt-24 overflow-hidden border-b border-border bg-slate-950 text-white"
        >
          <div
            className="pointer-events-none absolute inset-0"
            aria-hidden="true"
            style={{
              background:
                "radial-gradient(circle at 80% 15%, rgba(37,99,235,0.18), transparent 32%), radial-gradient(circle at 15% 80%, rgba(14,165,233,0.12), transparent 28%)",
            }}
          />

          <div className="relative mx-auto max-w-7xl px-5 py-16 sm:px-6 lg:px-8 lg:py-24">
            {/* header */}
            <div className="mx-auto max-w-3xl text-center">
              <p className="text-xs font-bold uppercase tracking-[0.22em] text-blue-300">
                <LocalizedText
                  en="The Learning Method"
                  bn="Outlinerzর শেখার পদ্ধতি"
                />
              </p>
              <h2 className="mt-3 text-3xl font-bold tracking-[-0.03em] sm:text-4xl">
                <LocalizedText
                  en="A clear path from first understanding to steady improvement."
                  bn="প্রথম ধারণা থেকে ধারাবাহিক উন্নতি—একটি পরিষ্কার শেখার পথ।"
                />
              </h2>
              <p className="mx-auto mt-4 max-w-2xl text-sm leading-7 text-slate-300">
                <LocalizedText
                  en="When a test reveals a gap, students return to the concept and practise again. Learning moves forward when understanding is stronger."
                  bn="পরীক্ষায় ঘাটতি ধরা পড়লে শিক্ষার্থী ধারণায় ফিরে গিয়ে আবার অনুশীলন করে। বোঝাপড়া শক্ত হলে শেখা সামনে এগোয়।"
                />
              </p>
            </div>

            {/* matched two-column body */}
            <div className="mt-12 grid gap-8 lg:mt-16 lg:grid-cols-2 lg:items-stretch lg:gap-12">
              {/* LEFT — image fills column height */}
              <div className="relative min-h-[320px] sm:min-h-[380px] lg:min-h-0">
                <div
                  className="absolute -inset-3 rounded-[2rem] bg-linear-to-br from-blue-500/25 via-transparent to-emerald-400/20 blur-2xl"
                  aria-hidden="true"
                />
                <div className="relative h-full overflow-hidden rounded-[1.75rem] border border-white/10 bg-slate-950 shadow-[0_30px_80px_-30px_rgba(2,6,23,0.75)]">
                  <Image
                    src="/images/sohoj-learning.webp"
                    alt="Teacher guiding students through a focused lesson"
                    width={1672}
                    height={941}
                    sizes="(max-width: 1024px) 100vw, 42vw"
                    className="h-full w-full object-cover object-center"
                  />
                  <div
                    className="absolute inset-0 bg-linear-to-t from-slate-950/90 via-slate-950/20 to-transparent"
                    aria-hidden="true"
                  />
                  <div className="absolute inset-x-0 bottom-0 p-5 sm:p-6">
                    <p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-200">
                      <LocalizedText
                        en="Understand → Practise → Improve"
                        bn="বুঝি → অনুশীলন → উন্নতি"
                      />
                    </p>
                    <p className="mt-2 max-w-sm text-lg font-semibold leading-snug sm:text-xl">
                      <LocalizedText
                        en="Every gap becomes the next practice target."
                        bn="প্রতিটি ঘাটতিই পরবর্তী অনুশীলনের লক্ষ্য।"
                      />
                    </p>
                  </div>
                </div>
              </div>

              {/* RIGHT — method card + snapshot, stretched to match image */}
              <div className="flex flex-col">
                <div className="relative flex flex-1 flex-col overflow-hidden rounded-[1.75rem] border border-slate-800 bg-slate-950/90 p-5 sm:p-6">
                  <div
                    className="absolute right-0 top-0 size-48 rounded-full bg-blue-600/20 blur-3xl"
                    aria-hidden="true"
                  />
                  <div className="relative flex flex-1 flex-col">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-blue-300">
                          <LocalizedText
                            en="Learning Method"
                            bn="সহজ লার্নিং মেথড"
                          />
                        </p>
                        <h3 className="mt-2 text-lg font-semibold text-white sm:text-xl">
                          <LocalizedText
                            en="Learn → practise → measure → improve"
                            bn="বুঝি → অনুশীলন করি → পরীক্ষা দিই → উন্নতি করি"
                          />
                        </h3>
                      </div>
                      <div className="shrink-0 rounded-xl bg-white/10 p-2 text-blue-200">
                        <LineChart className="size-5" aria-hidden="true" />
                      </div>
                    </div>

                    <div className="mt-5 grid flex-1 gap-2.5 sm:grid-cols-2 sm:gap-3">
                      {method.map(
                        ([number, enTitle, bnTitle, enDesc, bnDesc]) => (
                          <div
                            key={number}
                            className="rounded-xl border border-white/10 bg-white/[0.06] p-3.5"
                          >
                            <div className="flex items-center gap-2.5">
                              <span className="text-xs font-bold text-blue-300">
                                {number}
                              </span>
                              <span className="text-sm font-semibold text-white">
                                <LocalizedText en={enTitle} bn={bnTitle} />
                              </span>
                            </div>
                            <p className="mt-1.5 text-xs leading-5 text-slate-400">
                              <LocalizedText en={enDesc} bn={bnDesc} />
                            </p>
                          </div>
                        ),
                      )}
                    </div>

                    <div className="mt-3 rounded-xl border border-emerald-400/20 bg-emerald-400/[0.08] p-3.5">
                      <div className="flex items-center justify-between gap-3 text-sm">
                        <span className="font-medium text-emerald-100">
                          <LocalizedText
                            en="80% mastery achieved?"
                            bn="৮০% দক্ষতা অর্জিত?"
                          />
                        </span>
                        <span className="shrink-0 rounded-full bg-emerald-400/15 px-2.5 py-1 text-xs font-semibold text-emerald-200">
                          <LocalizedText
                            en="YES → Move forward"
                            bn="হ্যাঁ → এগিয়ে যাই"
                          />
                        </span>
                      </div>
                      <p className="mt-1.5 text-xs leading-5 text-emerald-100/65">
                        <LocalizedText
                          en="If not, return to practice, fix the gap and measure again."
                          bn="না হলে অনুশীলনে ফিরে গিয়ে ঘাটতি ঠিক করি—তারপর আবার যাচাই করি।"
                        />
                      </p>
                    </div>
                  </div>
                </div>

                {/* progress snapshot — overlaps bottom of method card */}
                <div className="relative z-10 -mt-4 ml-auto w-[90%] rounded-xl border border-border bg-card p-3.5 text-card-foreground shadow-xl sm:w-[85%]">
                  <div className="flex items-center justify-between gap-3">
                    <div>
                      <p className="text-[11px] font-medium text-muted-foreground">
                        <LocalizedText
                          en="Example progress snapshot"
                          bn="উদাহরণ অগ্রগতি চিত্র"
                        />
                      </p>
                      <p className="mt-0.5 text-sm font-semibold">
                        <LocalizedText
                          en="Weekly learning review"
                          bn="সাপ্তাহিক শেখার পর্যালোচনা"
                        />
                      </p>
                    </div>
                    <BarChart3
                      className="size-4.5 text-blue-700 dark:text-blue-400"
                      aria-hidden="true"
                    />
                  </div>
                  <div className="mt-3 grid grid-cols-3 gap-2 text-center">
                    {[
                      ["Homework", "হোমওয়ার্ক", "90%"],
                      ["Participation", "অংশগ্রহণ", "85%"],
                      ["Weekly Test", "সাপ্তাহিক টেস্ট", "84%"],
                    ].map(([en, bn, value]) => (
                      <div key={en} className="rounded-lg bg-muted px-2 py-2.5">
                        <p className="text-sm font-bold">{value}</p>
                        <p className="mt-0.5 text-[10px] text-muted-foreground">
                          <LocalizedText en={en} bn={bn} />
                        </p>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="why-sohoj" className="scroll-mt-24 bg-background">
          <div className="mx-auto max-w-7xl px-5 py-18 sm:px-6 lg:px-8 lg:py-20">
            <div className="max-w-2xl">
              <p className="text-xs font-bold uppercase tracking-[0.22em] text-blue-700 dark:text-blue-400">
                <LocalizedText en="Why Outlinerz" bn="কেন Outlinerz" />
              </p>
              <h2 className="mt-3 text-3xl font-bold tracking-[-0.03em] sm:text-4xl">
                <LocalizedText
                  en="Attention you can see in the learning."
                  bn="শেখার অগ্রগতিতে স্পষ্ট মনোযোগ।"
                />
              </h2>
            </div>
            <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              {trustPoints.map((point) => (
                <div
                  key={point.title[0]}
                  className="rounded-2xl border border-border bg-card p-5"
                >
                  <div className="flex size-10 items-center justify-center rounded-xl bg-blue-50 text-blue-700 dark:bg-blue-950/50 dark:text-blue-300">
                    <point.icon className="size-5" aria-hidden="true" />
                  </div>
                  <h3 className="mt-4 font-semibold">
                    <LocalizedText en={point.title[0]} bn={point.title[1]} />
                  </h3>
                  <p className="mt-2 text-sm leading-6 text-muted-foreground">
                    <LocalizedText
                      en={point.description[0]}
                      bn={point.description[1]}
                    />
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="border-t border-border bg-muted/35">
          <div className="mx-auto flex max-w-7xl flex-col gap-8 px-5 py-14 sm:px-6 lg:flex-row lg:items-center lg:justify-between lg:px-8">
            <div>
              <p className="text-sm font-semibold text-blue-700 dark:text-blue-400">
                SOHOJ ACADEMY
              </p>
              <h2 className="mt-2 text-2xl font-bold tracking-tight sm:text-3xl">
                <LocalizedText
                  en="Find the right next step for your student."
                  bn="আপনার শিক্ষার্থীর জন্য সঠিক পরবর্তী পদক্ষেপটি খুঁজুন।"
                />
              </h2>
            </div>
            <div className="flex flex-col gap-3 sm:flex-row">
              <Link
                href="#programs"
                className="inline-flex min-h-11 items-center justify-center rounded-xl border border-border bg-background px-4 py-2.5 text-sm font-semibold hover:bg-muted"
              >
                <LocalizedText en="View Programs" bn="প্রোগ্রাম দেখুন" />
              </Link>
              <Link
                href={`/interest?organization=${encodeURIComponent(slug ?? "")}`}
                className="inline-flex min-h-11 items-center justify-center rounded-xl bg-blue-700 px-4 py-2.5 text-sm font-semibold text-white hover:bg-blue-800"
              >
                <LocalizedText en="Register Interest" bn="আগ্রহ নিবন্ধন করুন" />
              </Link>
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-border bg-background">
        <div className="mx-auto flex max-w-7xl flex-col gap-5 px-5 py-8 sm:px-6 md:flex-row md:items-center md:justify-between lg:px-8">
          <Logo size={76} />
          <p className="text-xs leading-5 text-muted-foreground">
            <LocalizedText
              en="© Outlinerz. Academic support and Digital Campus."
              bn="© Outlinerz। একাডেমিক সহায়তা ও ডিজিটাল ক্যাম্পাস।"
            />
          </p>
          <div className="flex flex-wrap gap-x-4 gap-y-2 text-sm text-muted-foreground">
            <Link href="/about" className="hover:text-foreground">
              <LocalizedText en="About" bn="পরিচিতি" />
            </Link>
            <Link href="/faq" className="hover:text-foreground">
              <LocalizedText en="FAQ" bn="প্রশ্নোত্তর" />
            </Link>
            <Link href="/journal" className="hover:text-foreground">
              <LocalizedText en="Journal" bn="শিক্ষা-জার্নাল" />
            </Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
