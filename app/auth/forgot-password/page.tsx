"use client";
import { useState, type FormEvent } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
export default function ForgotPasswordPage() {
  const [message, setMessage] = useState(""),
    [pending, setPending] = useState(false);
  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const email = String(
      new FormData(e.currentTarget).get("email") ?? "",
    ).trim();
    setPending(true);
    try {
      const { error } = await createClient().auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/auth/update-password`,
      });
      setMessage(
        error
          ? "The recovery service is unavailable. Please try again later."
          : "If this email has an account, check its inbox for a password recovery link.",
      );
    } catch {
      setMessage(
        "The recovery service is unavailable. Please try again later.",
      );
    } finally {
      setPending(false);
    }
  }
  return (
    <main className="mx-auto max-w-md space-y-5 px-5 py-12">
      <h1 className="text-2xl font-bold">Recover your password</h1>
      <p className="text-sm text-muted-foreground">
        Use your verified staff email. A recovery link does not grant ERP access
        or change your permissions.
      </p>
      <form onSubmit={submit} className="space-y-4">
        <label className="block text-sm">
          Email
          <input
            name="email"
            type="email"
            autoComplete="email"
            required
            maxLength={254}
            className="mt-2 w-full rounded-xl border bg-background p-3"
          />
        </label>
        <button
          disabled={pending}
          className="rounded-xl bg-primary px-4 py-3 text-primary-foreground"
        >
          {pending ? "Requesting…" : "Send recovery link"}
        </button>
      </form>
      {message && <p role="status">{message}</p>}
      <Link href="/auth/sign-in" className="block underline">
        Return to sign in
      </Link>
    </main>
  );
}
