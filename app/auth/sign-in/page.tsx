"use client";

import { useState } from "react";
import Link from "next/link";
import { ArrowLeft, Eye, EyeOff, LockKeyhole } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { ROUTES } from "@/lib/constants";
import Logo from "@/components/shared/logo";
import { PreferenceControls } from "@/components/shared/preference-controls";
import { useLanguage } from "@/components/providers/language-provider";

export default function SignInPage() {
  const { locale } = useLanguage();
  const bn = locale === "bn";
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const copy = {
    campus: bn ? "ডিজিটাল ক্যাম্পাস" : "Digital Campus",
    title: bn ? "নিরাপদভাবে সাইন ইন করুন" : "Sign in securely",
    subtitle: bn
      ? "আপনার সহজ একাডেমি অ্যাকাউন্টের সঙ্গে যুক্ত ইমেইল ও পাসওয়ার্ড ব্যবহার করুন।"
      : "Use the email and password linked to your Sohoj Academy account.",
    email: bn ? "ইমেইল ঠিকানা" : "Email address",
    password: bn ? "পাসওয়ার্ড" : "Password",
    required: bn ? "আবশ্যক" : "Required",
    showPassword: bn ? "পাসওয়ার্ড দেখান" : "Show password",
    hidePassword: bn ? "পাসওয়ার্ড লুকান" : "Hide password",
    submit: bn ? "সাইন ইন" : "Sign In",
    signingIn: bn ? "সাইন ইন হচ্ছে…" : "Signing in…",
    support: bn
      ? "আপনার প্রবেশাধিকার থাকার কথা কিন্তু অ্যাকাউন্ট নেই বা সাইন ইন করতে পারছেন না—একাডেমি প্রশাসকের সঙ্গে যোগাযোগ করুন। দ্বিতীয় অ্যাকাউন্ট তৈরি করবেন না।"
      : "If you should have access but do not have an account or cannot sign in, contact the academy administrator. Do not create a second account.",
    failed: bn
      ? "নিরাপদ সেশন তৈরি করা যায়নি। তথ্য যাচাই করে আবার চেষ্টা করুন।"
      : "A secure session could not be created. Please check your details and try again.",
  };

  const signIn = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setLoading(true);
    setError("");

    const supabase = createClient();
    const { data, error: signInError } = await supabase.auth.signInWithPassword(
      {
        email: email.trim(),
        password,
      },
    );

    if (signInError || !data.session) {
      setError(signInError?.message ?? copy.failed);
      setLoading(false);
      return;
    }

    window.location.assign(ROUTES.DASHBOARD);
  };

  return (
    <main className="min-h-screen bg-background px-5 py-6 text-foreground sm:px-6">
      <div className="mx-auto flex min-h-[calc(100vh-3rem)] max-w-6xl flex-col">
        <header className="flex flex-wrap items-center justify-between gap-3">
          <Link href="/" aria-label="Sohoj Academy home">
            <Logo size={78} priority />
          </Link>

          <div className="flex items-center gap-2">
            <PreferenceControls compact />
            <Link
              href={ROUTES.AUTH}
              className="inline-flex min-h-10 items-center gap-2 rounded-lg px-3 text-sm font-medium text-muted-foreground hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            >
              <ArrowLeft className="size-4" aria-hidden="true" />
              {copy.campus}
            </Link>
          </div>
        </header>

        <div className="flex flex-1 items-center justify-center py-10">
          <div className="w-full max-w-md rounded-[1.75rem] border border-border bg-card p-6 text-card-foreground shadow-[0_24px_70px_-40px_rgba(15,23,42,.45)] sm:p-8">
            <div className="flex size-11 items-center justify-center rounded-2xl bg-blue-50 text-blue-700 dark:bg-blue-950/50 dark:text-blue-300">
              <LockKeyhole className="size-5" aria-hidden="true" />
            </div>

            <h1 className="mt-6 text-2xl font-bold tracking-[-0.03em]">
              {copy.title}
            </h1>
            <p className="mt-2 text-sm leading-6 text-muted-foreground">
              {copy.subtitle}
            </p>

            <form onSubmit={signIn} className="mt-7 space-y-5">
              <div>
                <label
                  htmlFor="email"
                  className="mb-2 block text-sm font-medium"
                >
                  {copy.email}
                </label>
                <input
                  id="email"
                  name="email"
                  className="min-h-11 w-full rounded-xl border border-input bg-background px-3.5 text-sm text-foreground outline-none transition placeholder:text-muted-foreground focus:border-ring focus:ring-3 focus:ring-ring/20"
                  type="email"
                  autoComplete="email"
                  inputMode="email"
                  placeholder="name@example.com"
                  required
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                />
              </div>

              <div>
                <div className="mb-2 flex items-center justify-between gap-4">
                  <label htmlFor="password" className="text-sm font-medium">
                    {copy.password}
                  </label>
                  <span className="text-xs text-muted-foreground">
                    {copy.required}
                  </span>
                </div>
                <div className="relative">
                  <input
                    id="password"
                    name="password"
                    className="min-h-11 w-full rounded-xl border border-input bg-background px-3.5 pr-12 text-sm text-foreground outline-none transition focus:border-ring focus:ring-3 focus:ring-ring/20"
                    type={showPassword ? "text" : "password"}
                    autoComplete="current-password"
                    required
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((value) => !value)}
                    className="absolute right-1.5 top-1/2 flex size-9 -translate-y-1/2 items-center justify-center rounded-lg text-muted-foreground hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    aria-label={
                      showPassword ? copy.hidePassword : copy.showPassword
                    }
                    aria-pressed={showPassword}
                  >
                    {showPassword ? (
                      <EyeOff className="size-4" aria-hidden="true" />
                    ) : (
                      <Eye className="size-4" aria-hidden="true" />
                    )}
                  </button>
                </div>
              </div>

              <div aria-live="polite" aria-atomic="true">
                {error && (
                  <div
                    role="alert"
                    className="rounded-xl border border-destructive/30 bg-destructive/10 px-3.5 py-3 text-sm leading-6 text-destructive"
                  >
                    {error}
                  </div>
                )}
              </div>

              <button
                disabled={loading}
                className="inline-flex min-h-12 w-full items-center justify-center rounded-xl bg-primary px-4 py-3 text-sm font-semibold text-primary-foreground transition hover:opacity-90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {loading ? copy.signingIn : copy.submit}
              </button>
            </form>

            <div className="mt-6 border-t border-border pt-5">
              <Link
                href="/auth/forgot-password"
                className="mb-3 block text-sm underline"
              >
                Forgot password?
              </Link>
              <Link
                href="/auth/sign-up"
                className="mb-3 block text-sm underline"
              >
                Request staff access
              </Link>
              <p className="text-xs leading-5 text-muted-foreground">
                {copy.support}
              </p>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
