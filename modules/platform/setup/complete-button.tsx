"use client";
import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { completeSetup } from "./actions";
export function CompleteSetupButton({ ready }: { ready: boolean }) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const [message, setMessage] = useState("");
  return (
    <div className="space-y-3">
      <button
        disabled={!ready || pending}
        className="min-h-11 rounded-xl bg-primary px-5 font-semibold text-primary-foreground disabled:opacity-40"
        onClick={() =>
          start(async () => {
            const result = await completeSetup();
            setMessage(result.message);
            if (result.ok) {
              router.push("/dashboard");
              router.refresh();
            }
          })
        }
      >
        {pending ? "Opening operations…" : "Confirm setup and open ERP"}
      </button>
      {message && <p role="status">{message}</p>}
    </div>
  );
}
