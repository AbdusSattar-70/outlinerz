import Link from "next/link";
import {
  ArrowLeft,
  ArrowRight,
  BookOpenCheck,
  ClipboardCheck,
  ShieldCheck,
  UsersRound,
} from "lucide-react";
import Logo from "@/components/shared/logo";
import { PreferenceControls } from "@/components/shared/preference-controls";
import { LocalizedText } from "@/components/shared/localized-text";
import { ROUTES } from "@/lib/constants";

const workspaceFeatures = [
  {
    title: ["Academic records", "একাডেমিক রেকর্ড"],
    description: [
      "Attendance, assessments and student progress in one connected workspace.",
      "উপস্থিতি, মূল্যায়ন ও শিক্ষার্থীর অগ্রগতি—একটি সংযুক্ত কর্মপরিসরে।",
    ],
    icon: BookOpenCheck,
  },
  {
    title: ["Role-based access", "ভূমিকাভিত্তিক প্রবেশাধিকার"],
    description: [
      "Each user sees the tools and records appropriate to their role.",
      "প্রত্যেক ব্যবহারকারী তার ভূমিকা অনুযায়ী প্রয়োজনীয় টুল ও রেকর্ড দেখবেন।",
    ],
    icon: UsersRound,
  },
  {
    title: ["Traceable operations", "ট্রেসযোগ্য কার্যক্রম"],
    description: [
      "Important academy actions are designed to remain reviewable and accountable.",
      "গুরুত্বপূর্ণ একাডেমি কার্যক্রম যেন পরবর্তীতে যাচাই ও জবাবদিহির জন্য দেখা যায়—সেভাবেই ডিজাইন করা।",
    ],
    icon: ClipboardCheck,
  },
] as const;

export default function AuthHomePage() {
  return (
    <main className="min-h-screen bg-background text-foreground">
      <div className="mx-auto grid min-h-screen max-w-384 lg:grid-cols-[1.05fr_.95fr]">
        <section className="relative hidden overflow-hidden bg-slate-950 p-10 text-white dark:bg-black lg:flex lg:flex-col xl:p-14">
          <div
            className="pointer-events-none absolute inset-0"
            aria-hidden="true"
            style={{
              background:
                "radial-gradient(circle at 15% 15%, rgba(37,99,235,.28), transparent 28%), radial-gradient(circle at 85% 85%, rgba(14,165,233,.16), transparent 28%)",
            }}
          />

          <div className="relative">
            <Logo size={112} priority />
          </div>

          <div className="relative my-auto max-w-2xl py-16">
            <p className="text-xs font-bold uppercase tracking-[0.22em] text-blue-300">
              <LocalizedText
                en="Sohoj Academy Digital Campus"
                bn="সহজ একাডেমি ডিজিটাল ক্যাম্পাস"
              />
            </p>
            <h1 className="mt-5 text-4xl font-bold tracking-[-0.04em] xl:text-5xl">
              <LocalizedText
                en="Academy operations and learning records, connected with clarity."
                bn="একাডেমির কার্যক্রম ও শিক্ষার রেকর্ড—স্পষ্টভাবে এক জায়গায় সংযুক্ত।"
              />
            </h1>
            <p className="mt-5 max-w-xl text-base leading-8 text-slate-300">
              <LocalizedText
                en="A secure workspace for authorised academy users to manage and follow the academic journey without losing important operational history."
                bn="অনুমোদিত ব্যবহারকারীদের জন্য একটি নিরাপদ কর্মপরিসর—যেখানে গুরুত্বপূর্ণ কার্যক্রমের ইতিহাস অক্ষুণ্ণ রেখে একাডেমিক যাত্রা পরিচালনা ও অনুসরণ করা যায়।"
              />
            </p>

            <div className="mt-10 grid gap-3">
              {workspaceFeatures.map((item) => (
                <div
                  key={item.title[0]}
                  className="flex gap-4 rounded-2xl border border-white/10 bg-white/5 p-4"
                >
                  <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-blue-400/10 text-blue-200">
                    <item.icon className="size-5" aria-hidden="true" />
                  </div>
                  <div>
                    <h2 className="text-sm font-semibold text-white">
                      <LocalizedText en={item.title[0]} bn={item.title[1]} />
                    </h2>
                    <p className="mt-1 text-sm leading-6 text-slate-400">
                      <LocalizedText
                        en={item.description[0]}
                        bn={item.description[1]}
                      />
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <p className="relative text-xs text-slate-500">
            শিক্ষা হোক সহজ ও আনন্দময়
          </p>
        </section>

        <section className="flex min-h-screen flex-col bg-background">
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border px-5 py-4 sm:px-8 lg:border-0 lg:px-10 xl:px-14">
            <div className="lg:hidden">
              <Logo size={76} priority />
            </div>
            <div className="ml-auto flex items-center gap-2">
              <PreferenceControls compact />
              <Link
                href="/"
                className="inline-flex min-h-10 items-center gap-2 rounded-lg px-3 text-sm font-medium text-muted-foreground hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              >
                <ArrowLeft className="size-4" aria-hidden="true" />
                <LocalizedText en="Back to website" bn="ওয়েবসাইটে ফিরুন" />
              </Link>
            </div>
          </div>

          <div className="flex flex-1 items-center justify-center px-5 py-12 sm:px-8 lg:px-10 xl:px-14">
            <div className="w-full max-w-md">
              <div className="inline-flex size-12 items-center justify-center rounded-2xl bg-blue-50 text-blue-700 dark:bg-blue-950/50 dark:text-blue-300">
                <ShieldCheck className="size-6" aria-hidden="true" />
              </div>

              <h1 className="mt-6 text-3xl font-bold tracking-[-0.03em]">
                <LocalizedText
                  en="Welcome to Digital Campus"
                  bn="ডিজিটাল ক্যাম্পাসে স্বাগতম"
                />
              </h1>
              <p className="mt-3 text-sm leading-7 text-muted-foreground">
                <LocalizedText
                  en="Sign in with your authorised Sohoj Academy account. Your available tools are determined by your assigned role."
                  bn="আপনার অনুমোদিত সহজ একাডেমি অ্যাকাউন্ট দিয়ে সাইন ইন করুন। আপনার ভূমিকা অনুযায়ী প্রয়োজনীয় টুলগুলো দেখানো হবে।"
                />
              </p>

              <div className="mt-8 rounded-2xl border border-border bg-muted/50 p-4">
                <p className="text-sm font-semibold">
                  <LocalizedText
                    en="Who can sign in?"
                    bn="কারা সাইন ইন করতে পারবেন?"
                  />
                </p>
                <p className="mt-2 text-sm leading-6 text-muted-foreground">
                  <LocalizedText
                    en="Authorised academy staff and verified referral partners. Each account sees only its permitted tools and records. Students and guardians can apply on the website without an account."
                    bn="অনুমোদিত একাডেমি স্টাফ ও যাচাইকৃত রেফারেল সহযোগীরা সাইন ইন করতে পারবেন। প্রত্যেকে কেবল অনুমোদিত কাজ ও তথ্য দেখতে পাবেন। শিক্ষার্থী ও অভিভাবক অ্যাকাউন্ট ছাড়াই ওয়েবসাইটে আবেদন করতে পারেন।"
                  />
                </p>
              </div>

              <Link
                href={ROUTES.SIGN_IN}
                className="mt-6 inline-flex min-h-12 w-full items-center justify-center gap-2 rounded-xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground shadow-sm transition hover:opacity-90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              >
                <LocalizedText
                  en="Continue to Sign In"
                  bn="সাইন ইন করতে এগিয়ে যান"
                />
                <ArrowRight className="size-4" aria-hidden="true" />
              </Link>

              <Link
                href="/auth/sign-up"
                className="mt-4 block text-center text-sm underline"
              >
                <LocalizedText en="Request staff access" bn="স্টাফ প্রবেশাধিকার চাই" />
              </Link>
              <p className="mt-3 text-center text-sm text-muted-foreground"><LocalizedText en="Referral partner? Ask the academy to verify your identity and send account setup instructions." bn="রেফারেল সহযোগী? পরিচয় যাচাই করে অ্যাকাউন্ট চালুর নির্দেশনা পাঠাতে একাডেমিকে অনুরোধ করুন।" /></p>
              <p className="mt-5 text-center text-xs leading-5 text-muted-foreground">
                <LocalizedText
                  en="Access is for authorised users. Public interest registration is separate from account sign-in."
                  bn="এটি অনুমোদিত ব্যবহারকারীদের জন্য। সাধারণ শিক্ষার্থী আগ্রহ নিবন্ধন অ্যাকাউন্ট সাইন-ইন থেকে আলাদা।"
                />
              </p>
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
