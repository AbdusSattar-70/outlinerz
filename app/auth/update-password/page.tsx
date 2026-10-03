"use client";
import { useEffect, useState, type FormEvent } from "react";
import Link from "next/link";
import { useLanguage } from "@/components/providers/language-provider";
import { createClient } from "@/lib/supabase/client";
export default function UpdatePasswordPage() {
  const {locale}=useLanguage();const t=(en:string,bn:string)=>locale==="bn"?bn:en;
  const [password, setPassword] = useState(""),
    [confirm, setConfirm] = useState(""),
    [message, setMessage] = useState(""),
    [ready, setReady] = useState(false),
    [pending, setPending] = useState(false);
  useEffect(() => {
    if (new URLSearchParams(window.location.search).get("error")) {
      setMessage("This setup link is expired. Ask the admin to resend it.");
      return;
    }
    const db = createClient();
    void (async () => {
      const hash = new URLSearchParams(window.location.hash.slice(1));
      if (hash.get("access_token") && hash.get("refresh_token")) {
        const { error } = await db.auth.setSession({
          access_token: hash.get("access_token")!,
          refresh_token: hash.get("refresh_token")!,
        });
        window.history.replaceState(null, "", "/auth/update-password");
        if (error) {
          setMessage("This setup link is expired. Ask the admin to resend it.");
          return;
        }
      }
      const {
        data: { user },
      } = await db.auth.getUser();
      setReady(Boolean(user));
      if (!user)
        setMessage("Open a valid secure account setup or recovery link to continue.");
    })();
  }, []);
  async function submit(e: FormEvent) {
    e.preventDefault();
    if (password !== confirm) {
      setMessage("Passwords do not match.");
      return;
    }
    setPending(true);
    try {
      const { error } = await createClient().auth.updateUser({ password });
      if (error) {
        setMessage(error.message);
        return;
      }
      setMessage(
        "Password saved. You can now sign in with your verified email.",
      );
      await createClient().auth.signOut();
      setReady(false);
    } finally {
      setPending(false);
    }
  }
  return (
    <main className="mx-auto max-w-md space-y-5 px-5 py-12">
      <h1 className="text-2xl font-bold">{t("Set your password","আপনার পাসওয়ার্ড তৈরি করুন")}</h1>
      {ready && (
        <form onSubmit={submit} className="space-y-4">
          <label className="block">
            {t("New password","নতুন পাসওয়ার্ড")}
            <input
              type="password"
              autoComplete="new-password"
              minLength={12}
              required
              className="mt-2 w-full rounded-xl border bg-background p-3"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </label>
          <label className="block">
            {t("Confirm password","পাসওয়ার্ড আবার লিখুন")}
            <input
              type="password"
              autoComplete="new-password"
              required
              className="mt-2 w-full rounded-xl border bg-background p-3"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
            />
          </label>
          <button
            disabled={pending}
            className="rounded-xl bg-primary p-3 text-primary-foreground"
          >
            {pending?t("Saving…","সংরক্ষণ হচ্ছে…"):t("Save password","পাসওয়ার্ড সংরক্ষণ করুন")}
          </button>
        </form>
      )}
      {message && <p role="status">{locale==="bn"?({"This setup link is expired. Ask the admin to resend it.":"লিংকের মেয়াদ শেষ। অ্যাডমিনকে নতুন নির্দেশনা পাঠাতে বলুন।","Open a valid secure account setup or recovery link to continue.":"অ্যাকাউন্ট চালু বা পুনরুদ্ধারের বৈধ নিরাপদ লিংক দিয়ে এগিয়ে যান।","Passwords do not match.":"পাসওয়ার্ড দুটি মিলছে না।","Password saved. You can now sign in with your verified email.":"পাসওয়ার্ড সংরক্ষণ হয়েছে। যাচাইকৃত ইমেইল দিয়ে এখন সাইন ইন করুন।"} as Record<string,string>)[message]??message:message}</p>}
      <Link href="/auth/sign-in" className="block underline">
        {t("Go to sign in","সাইন ইন করুন")}
      </Link>
    </main>
  );
}
