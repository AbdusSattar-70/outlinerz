"use client";
import { useState } from "react";
import { useLanguage } from "@/components/providers/language-provider";
import { saveOffering } from "./actions";
export type OfferingPublication = {
  name: string;
  intake_open: boolean;
  public_visible: boolean;
  public_copy: Record<string, string>;
};
const fields = [
  ["showcase_title", "Title", "শিরোনাম"],
  ["showcase_description", "Description", "বিবরণ"],
  ["showcase_eyebrow", "Category label", "বিভাগের নাম"],
  ["public_schedule", "Schedule", "সময়সূচি"],
  ["public_requirements", "Requirements", "প্রয়োজনীয় তথ্য"],
  ["admission_policy", "Admission policy", "ভর্তির নিয়ম"],
] as const;
export function OfferingEditor({
  offerings,
  enabled,
}: {
  offerings: (OfferingPublication & { id: string })[];
  enabled: boolean;
}) {
  const { locale } = useLanguage();
  return (
    <section className="space-y-5">
      <h2 className="text-xl font-semibold">
        {locale === "bn" ? "প্রোগ্রাম প্রকাশনা" : "Programme publications"}
      </h2>
      {offerings.map((o) => (
        <OfferingForm key={o.id} offering={o} enabled={enabled} />
      ))}
      {!offerings.length && (
        <p className="text-muted-foreground">
          {locale === "bn"
            ? "এখনও কোনো সক্রিয় অফারিং নেই।"
            : "No active offerings yet."}
        </p>
      )}
    </section>
  );
}
function OfferingForm({
  offering,
  enabled,
}: {
  offering: OfferingPublication & { id: string };
  enabled: boolean;
}) {
  const { locale } = useLanguage(),
    bn = locale === "bn";
  const { id, ...initial } = offering;
  const [value, setValue] = useState(initial),
    [expected, setExpected] = useState(initial),
    [busy, setBusy] = useState(false),
    [message, setMessage] = useState(""),
    [requestId, setRequestId] = useState(() => crypto.randomUUID());
  function change(v: OfferingPublication) {
    setValue(v);
    setRequestId(crypto.randomUUID());
    setMessage("");
  }
  return (
    <details className="rounded-xl border p-5">
      <summary className="cursor-pointer font-semibold">{value.name}</summary>
      <form
        className="mt-5 space-y-4"
        onSubmit={async (e) => {
          e.preventDefault();
          setBusy(true);
          try {
            const result = await saveOffering({
              id,
              requestId,
              expected,
              value,
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
              setExpected(value);
              setRequestId(crypto.randomUUID());
              setMessage(bn ? "সংরক্ষিত হয়েছে।" : "Saved.");
            }
          } catch {
            setMessage(bn ? "সংরক্ষণ করা যায়নি।" : "Could not save.");
          } finally {
            setBusy(false);
          }
        }}
      >
        <fieldset disabled={busy || !enabled} className="space-y-4">
          <label className="block">
            {bn ? "অফারিংয়ের নাম" : "Offering name"}
            <input
              required
              maxLength={180}
              className="mt-2 w-full rounded-md border bg-background p-3"
              value={value.name}
              onChange={(e) => change({ ...value, name: e.target.value })}
            />
          </label>
          {(["public_visible", "intake_open"] as const).map((key) => (
            <label key={key} className="flex gap-3">
              <input
                type="checkbox"
                checked={value[key]}
                onChange={(e) => change({ ...value, [key]: e.target.checked })}
              />
              {key === "public_visible"
                ? bn
                  ? "ওয়েবসাইটে প্রকাশিত"
                  : "Published on website"
                : bn
                  ? "আবেদন গ্রহণ চলছে"
                  : "Applications open"}
            </label>
          ))}
          {fields.map(([key, en, bangla]) => (
            <div key={key} className="grid gap-3 md:grid-cols-2">
              {(["", "_bn"] as const).map((suffix) => (
                <label key={suffix}>
                  {bn ? bangla : en} —{" "}
                  {suffix ? "বাংলা" : bn ? "ইংরেজি" : "English"}
                  <textarea
                    rows={3}
                    maxLength={5000}
                    className="mt-2 w-full rounded-md border bg-background p-3"
                    value={value.public_copy[key + suffix] || ""}
                    onChange={(e) =>
                      change({
                        ...value,
                        public_copy: {
                          ...value.public_copy,
                          [key + suffix]: e.target.value,
                        },
                      })
                    }
                  />
                </label>
              ))}
            </div>
          ))}
          <button className="rounded-lg bg-primary px-5 py-3 text-primary-foreground disabled:opacity-50">
            {busy
              ? bn
                ? "সংরক্ষণ হচ্ছে…"
                : "Saving…"
              : bn
                ? "প্রোগ্রাম সংরক্ষণ"
                : "Save programme"}
          </button>
        </fieldset>
        <p role="status">{message}</p>
      </form>
    </details>
  );
}
