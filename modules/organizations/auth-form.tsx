"use client";
import Link from "next/link";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useLanguage } from "@/components/providers/language-provider";
import { PreferenceControls } from "@/components/shared/preference-controls";
export function AuthForm({
  signup = false,
  confirmationError = false,
}: {
  signup?: boolean;
  confirmationError?: boolean;
}) {
  const { locale } = useLanguage();
  const bn = locale === "bn";
  const [busy, setBusy] = useState(false),
    [error, setError] = useState(confirmationError ? "confirmation" : ""),
    [message, setMessage] = useState(false);
  const errors = {
    confirmation: bn
      ? "নিশ্চিতকরণের লিংকটি অবৈধ বা মেয়াদোত্তীর্ণ। প্রবেশ করুন অথবা নতুন ইমেইল চান।"
      : "Confirmation link is invalid or expired. Sign in or request a new email.",
    signup: bn
      ? "অ্যাকাউন্ট তৈরি করা যায়নি। ইমেইল ও পাসওয়ার্ড যাচাই করুন।"
      : "Could not create the account. Check your email and password.",
    signin: bn
      ? "প্রবেশ করা যায়নি। ইমেইল, পাসওয়ার্ড ও ইমেইল নিশ্চিতকরণ যাচাই করুন।"
      : "Could not sign in. Check your email, password and email confirmation.",
  };
  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setBusy(true);
    setError("");
    setMessage(false);
    const f = new FormData(e.currentTarget);
    try {
      const db = createClient();
      const email = String(f.get("email")).trim(),
        password = String(f.get("password"));
      if (signup) {
        const { data, error } = await db.auth.signUp({
          email,
          password,
          options: {
            emailRedirectTo: `${window.location.origin}/auth/confirm`,
          },
        });
        if (error) throw error;
        if (data.session) {
          window.location.assign("/onboarding");
          return;
        }
        setMessage(true);
      } else {
        const { error } = await db.auth.signInWithPassword({ email, password });
        if (error) throw error;
        window.location.assign("/dashboard");
        return;
      }
    } catch {
      setError(signup ? "signup" : "signin");
    } finally {
      setBusy(false);
    }
  }
  return (
    <main className="mx-auto max-w-md px-5 py-12">
      <header className="flex items-center justify-between gap-3">
        <Link href="/" className="text-xl font-bold">
          Outlinerz
        </Link>
        <PreferenceControls compact />
      </header>
      <section className="mt-10 rounded-2xl border bg-card p-6">
        <h1 className="text-3xl font-bold">
          {signup
            ? bn
              ? "মালিকের অ্যাকাউন্ট তৈরি করুন"
              : "Create an owner account"
            : bn
              ? "প্রবেশ করুন"
              : "Sign in"}
        </h1>
        <p className="my-5 text-muted-foreground">
          {signup
            ? bn
              ? "অ্যাকাউন্ট তৈরি করে নিজের প্রতিষ্ঠান শুরু করুন।"
              : "Create your account to start your organization."
            : bn
              ? "আপনার প্রতিষ্ঠানের অ্যাকাউন্ট দিয়ে প্রবেশ করুন।"
              : "Sign in with your organization account."}
        </p>
        <form onSubmit={submit} className="space-y-5">
          <label className="block space-y-2">
            <span>{bn ? "ইমেইল" : "Email"}</span>
            <input
              name="email"
              type="email"
              autoComplete="email"
              required
              disabled={busy}
              className="w-full rounded-xl border bg-background p-3"
            />
          </label>
          <label className="block space-y-2">
            <span>{bn ? "পাসওয়ার্ড" : "Password"}</span>
            <input
              name="password"
              type="password"
              minLength={signup ? 8 : undefined}
              autoComplete={signup ? "new-password" : "current-password"}
              required
              disabled={busy}
              className="w-full rounded-xl border bg-background p-3"
            />
          </label>
          <div aria-live="polite">
            {error && (
              <p role="alert" className="text-sm text-red-400">
                {errors[error as keyof typeof errors]}
              </p>
            )}
            {message && (
              <p className="text-sm text-emerald-400">
                {bn
                  ? "ইমেইলের নিশ্চিতকরণ লিংক খুলে তারপর প্রবেশ করুন।"
                  : "Open the confirmation link in your email, then sign in."}
              </p>
            )}
          </div>
          <button
            disabled={busy}
            className="w-full rounded-xl bg-primary p-3 font-semibold text-primary-foreground disabled:opacity-50"
          >
            {busy
              ? bn
                ? "অপেক্ষা করুন…"
                : "Please wait…"
              : signup
                ? bn
                  ? "অ্যাকাউন্ট তৈরি করুন"
                  : "Create account"
                : bn
                  ? "প্রবেশ করুন"
                  : "Sign in"}
          </button>
        </form>
        <Link
          className="mt-6 block underline"
          href={signup ? "/auth/sign-in" : "/auth/sign-up"}
        >
          {signup
            ? bn
              ? "অ্যাকাউন্ট আছে? প্রবেশ করুন"
              : "Already have an account? Sign in"
            : bn
              ? "মালিকের অ্যাকাউন্ট তৈরি করুন"
              : "Create an owner account"}
        </Link>
        {!signup && (
          <Link href="/auth/forgot-password" className="mt-3 block underline">
            {bn ? "পাসওয়ার্ড ভুলে গেছেন?" : "Forgot password?"}
          </Link>
        )}
      </section>
    </main>
  );
}
