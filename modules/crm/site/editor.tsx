"use client";
import { useState } from "react";
import Link from "next/link";
import { useLanguage } from "@/components/providers/language-provider";
import { siteCopy } from "./catalogue";
import { type SiteRecord } from "./model";
import { saveSite } from "./actions";
export function SiteEditor({
  initial,
  slug,
  enabled,
}: {
  initial: SiteRecord;
  slug: string;
  enabled: boolean;
}) {
  const { locale } = useLanguage();
  const bn = locale === "bn";
  const [record, setRecord] = useState(initial),
    [message, setMessage] = useState(""),
    [busy, setBusy] = useState(false);
  const [requestId, setRequestId] = useState(() => crypto.randomUUID());
  const fields = [
    ["nameEn", "Organization name — English", "প্রতিষ্ঠানের নাম — ইংরেজি"],
    ["nameBn", "Organization name — Bangla", "প্রতিষ্ঠানের নাম — বাংলা"],
    ["logo", "Full logo URL", "সম্পূর্ণ লোগোর ঠিকানা"],
    ["mark", "Logo mark URL", "লোগো চিহ্নের ঠিকানা"],
    ["heroImage", "Classroom image URL", "শ্রেণিকক্ষের ছবির ঠিকানা"],
    ["learningImage", "Learning image URL", "শেখার ছবির ঠিকানা"],
    ["phone", "Phone", "ফোন"],
    ["email", "Email", "ইমেইল"],
    ["addressEn", "Address — English", "ঠিকানা — ইংরেজি"],
    ["addressBn", "Address — Bangla", "ঠিকানা — বাংলা"],
  ] as const;
  const change = () => {
    setRequestId(crypto.randomUUID());
    setMessage("");
  };
  return (
    <div className="space-y-7">
      <header>
        <h1 className="text-3xl font-bold">
          {bn ? "প্রতিষ্ঠানের যোগাযোগ ব্যবস্থাপনা" : "CRM management dashboard"}
        </h1>
        <p className="mt-3 text-muted-foreground">
          {bn
            ? "প্রতিষ্ঠানের পরিচিতি, ছবি এবং দুই ভাষার ওয়েবসাইট লেখা পরিচালনা করুন।"
            : "Manage organization identity, images and bilingual website content."}
        </p>
      </header>
      <div className="flex gap-4">
        <Link
          href={`/?organization=${encodeURIComponent(slug)}`}
          target="_blank"
          className="underline"
        >
          {bn ? "ওয়েবসাইট দেখুন" : "Preview website"}
        </Link>
        <Link href="/dashboard/crm/manage" className="underline">
          {bn ? "তথ্যতালিকা পরিচালনা" : "Manage registration directories"}
        </Link>
      </div>
      <form
        className="space-y-6"
        onSubmit={async (e) => {
          e.preventDefault();
          setBusy(true);
          try {
            const result = await saveSite({
              requestId,
              revision: record.revision,
              settings: record.settings,
            });
            if (result.error)
              setMessage(
                bn
                  ? result.error.includes("Reload") ||
                    result.error.includes("updated")
                    ? "অন্য কেউ তথ্য পরিবর্তন করেছেন। পাতা আবার খুলে সংরক্ষণ করুন।"
                    : "সংরক্ষণ করা যায়নি। তথ্য যাচাই করে আবার চেষ্টা করুন।"
                  : result.error,
              );
            else {
              setRecord({ ...record, revision: result.revision! });
              setRequestId(crypto.randomUUID());
              setMessage(bn ? "পরিবর্তন সংরক্ষিত হয়েছে।" : "Changes saved.");
            }
          } catch {
            setMessage(
              bn
                ? "সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।"
                : "Could not save. Try again.",
            );
          } finally {
            setBusy(false);
          }
        }}
      >
        <fieldset
          disabled={busy || !enabled}
          className="grid gap-4 rounded-xl border p-6 md:grid-cols-2"
        >
          <legend className="px-2 font-semibold">
            {bn ? "প্রতিষ্ঠানের পরিচিতি" : "Organization identity"}
          </legend>
          {fields.map(([key, en, bangla]) => (
            <label key={key} className="space-y-2 text-sm">
              <span className="block">{bn ? bangla : en}</span>
              <input
                className="w-full rounded-md border bg-background p-3"
                required={[
                  "nameEn",
                  "nameBn",
                  "logo",
                  "mark",
                  "heroImage",
                  "learningImage",
                ].includes(key)}
                value={record.settings[key]}
                onChange={(e) => {
                  change();
                  setRecord({
                    ...record,
                    settings: { ...record.settings, [key]: e.target.value },
                  });
                }}
              />
            </label>
          ))}
        </fieldset>
        {Array.from(new Set(siteCopy.map((e) => e.group))).map((group) => (
          <details key={group} className="rounded-xl border p-5">
            <summary className="cursor-pointer font-semibold">
              {bn
                ? {
                    Home: "মূল পাতা",
                    about: "পরিচিতি",
                    faq: "প্রশ্নোত্তর",
                    journal: "শিক্ষা-জার্নাল",
                    Registration: "নিবন্ধন",
                  }[group] || group
                : {
                    Home: "Homepage",
                    about: "About",
                    faq: "FAQ",
                    journal: "Journal",
                    Registration: "Registration",
                  }[group] || group}
            </summary>
            <fieldset disabled={busy || !enabled} className="mt-5 space-y-5">
              {siteCopy
                .filter((e) => e.group === group)
                .map((entry) => (
                  <div
                    key={entry.key}
                    className="grid gap-3 border-b pb-5 md:grid-cols-2"
                  >
                    {(["en", "bn"] as const).map((lang) => (
                      <label key={lang} className="text-sm">
                        <span className="mb-2 block">
                          {lang === "en"
                            ? bn
                              ? "ইংরেজি"
                              : "English"
                            : "বাংলা"}
                        </span>
                        <textarea
                          rows={3}
                          maxLength={10000}
                          className="w-full rounded-md border bg-background p-3"
                          value={
                            record.settings.copy[entry.key]?.[lang] ??
                            entry[lang]
                          }
                          onChange={(e) => {
                            change();
                            setRecord({
                              ...record,
                              settings: {
                                ...record.settings,
                                copy: {
                                  ...record.settings.copy,
                                  [entry.key]: {
                                    ...(record.settings.copy[entry.key] || {
                                      en: entry.en,
                                      bn: entry.bn,
                                    }),
                                    [lang]: e.target.value,
                                  },
                                },
                              },
                            });
                          }}
                        />
                      </label>
                    ))}
                  </div>
                ))}
            </fieldset>
          </details>
        ))}
        <div className="sticky bottom-0 flex items-center gap-4 border-t bg-background py-4">
          <button
            disabled={busy || !enabled}
            className="rounded-lg bg-primary px-5 py-3 text-primary-foreground disabled:opacity-50"
          >
            {busy
              ? bn
                ? "সংরক্ষণ হচ্ছে…"
                : "Saving…"
              : bn
                ? "পরিবর্তন সংরক্ষণ"
                : "Save changes"}
          </button>
          <p role="status">{message}</p>
        </div>
      </form>
    </div>
  );
}
