"use client";
import { useState, type FormEvent } from "react";
import Link from "next/link";
import { CrmText, useCrmText } from "@/modules/crm/translations";
import { PreferenceControls } from "@/components/shared/preference-controls";
import { createClient } from "@/lib/supabase/client";
export default function ForgotPasswordPage() {
  const tr = useCrmText();
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
      <PreferenceControls compact />
      <h1 className="text-2xl font-bold">
        <CrmText text="Recover your password" />
      </h1>
      <p className="text-sm text-muted-foreground">
        <CrmText text="Enter your account email to request a recovery link." />
      </p>
      <form onSubmit={submit} className="space-y-4">
        <label className="block text-sm">
          <CrmText text="Email" />
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
          {tr(pending ? "Requesting…" : "Send recovery link")}
        </button>
      </form>
      {message && <p role="status">{tr(message)}</p>}
      <Link href="/auth/sign-in" className="block underline">
        <CrmText text="Return to sign in" />
      </Link>
    </main>
  );
}
