"use client";
import { useState, useTransition, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { saveAcademyIdentity } from "./identity-actions";
export function AcademyIdentityForm({
  name,
  branchName,
}: {
  name: string;
  branchName: string;
}) {
  const [pending, start] = useTransition(),
    [message, setMessage] = useState("");
  const router = useRouter();
  function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    start(async () => {
      const r = await saveAcademyIdentity({
        name: f.get("name"),
        branch_name: f.get("branch_name"),
      });
      setMessage(r.message);
      if (r.ok) router.refresh();
    });
  }
  return (
    <form
      onSubmit={submit}
      className="space-y-4 rounded-2xl border bg-card p-5"
    >
      <h2 className="font-semibold">Confirm academy identity first</h2>
      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block text-sm">
          Academy name
          <input
            name="name"
            required
            defaultValue={name}
            maxLength={160}
            className="mt-1 w-full rounded-lg border bg-background p-3"
          />
        </label>
        <label className="block text-sm">
          Main campus name
          <input
            name="branch_name"
            required
            defaultValue={branchName}
            maxLength={160}
            className="mt-1 w-full rounded-lg border bg-background p-3"
          />
        </label>
      </div>
      <button
        disabled={pending}
        className="rounded-lg border px-4 py-3 text-sm"
      >
        Save and confirm academy identity
      </button>
      {message && (
        <p role="status" className="text-sm">
          {message}
        </p>
      )}
    </form>
  );
}
