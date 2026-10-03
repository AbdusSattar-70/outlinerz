"use client";
import { ActionPanel, announceSaved } from "@/components/erp/action-panel";
import { useState, type FormEvent } from "react";
import { createClient } from "@/lib/supabase/client";
export default function AccountPage() {
  const [email, setEmail] = useState(""),
    [message, setMessage] = useState(""),
    [pending, setPending] = useState(false);
  async function submit(e: FormEvent) {
    e.preventDefault();
    setPending(true);
    try {
      const { error } = await createClient().auth.updateUser(
        { email },
        { emailRedirectTo: `${window.location.origin}/auth/confirm` },
      );
      setMessage(
        error
          ? error.message
          : "Confirmation emails sent by Supabase. Confirm the change before using the new address.",
      );
    } finally {
      setPending(false);
    }
  }
  async function reset() {
    setPending(true);
    try {
      const db = createClient();
      const {
        data: { user },
      } = await db.auth.getUser();
      if (!user?.email) {
        setMessage("Sign in again to request recovery.");
        return;
      }
      const { error } = await db.auth.resetPasswordForEmail(user.email, {
        redirectTo: `${window.location.origin}/auth/confirm`,
      });
      setMessage(
        error
          ? error.message
          : "Supabase password recovery link sent to your verified email.",
      );
    } finally {
      setPending(false);
    }
  }
  return (
    <div className="max-w-xl space-y-6">
      <h1 className="text-2xl font-bold">My account</h1>
      <ActionPanel title="Change account email"><form onSubmit={submit} className="space-y-3 rounded-xl border p-5">
        <label className="block">
          New email
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="mt-2 w-full rounded-lg border bg-background p-3"
          />
        </label>
        <button disabled={pending} className="rounded-lg border p-3">
          Send email change confirmation
        </button>
      </form></ActionPanel>
      <button
        disabled={pending}
        onClick={reset}
        className="rounded-lg border p-3"
      >
        Send password recovery link
      </button>
      {message && <p role="status">{message}</p>}
    </div>
  );
}
