"use client";
import { announceSaved } from "@/components/erp/action-panel";

import { useRef, useState, useTransition, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { receivePhysicalConsent } from "../consent-actions";

export function PhysicalConsentForm({ admissionId }: { admissionId: string }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);
  const requestId = useRef(crypto.randomUUID());
  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    setMessage(null);
    startTransition(async () => {
      const result = await receivePhysicalConsent({
        admissionId,
        requestId: requestId.current,
        guardianSignedOn: form.get("guardianSignedOn"),
        studentSigned: form.get("studentSigned") === "on",
        physicalCopyReference: form.get("physicalCopyReference"),
        reason: form.get("reason"),
      });
      setMessage({ ok: result.ok, text: result.message });
      if (result.ok) {
        requestId.current = crypto.randomUUID();
        formElement.reset();
        announceSaved();
        router.refresh();
      }
    });
  };
  return <form onSubmit={submit} className="space-y-4 rounded-xl border p-4 print:hidden">
    <div>
      <h3 className="font-semibold">3. Record the signed paper form</h3>
      <p className="mt-1 text-sm text-muted-foreground">Keep the signed original in the student file. Record the signing date and where the paper is filed; no scan or upload is needed.</p>
    </div>
    <div className="grid gap-3 sm:grid-cols-2">
      <label className="space-y-1 text-sm">Guardian signed on<input type="date" name="guardianSignedOn" required className="block min-h-11 w-full rounded-lg border bg-background px-3" /></label>
      <label className="space-y-1 text-sm">Paper file location <span className="font-normal text-muted-foreground">(optional)</span><input name="physicalCopyReference" maxLength={160} placeholder="e.g. Admissions cabinet · file 2026-041" className="block min-h-11 w-full rounded-lg border bg-background px-3" /></label>
    </div>
    <label className="flex items-center gap-2 text-sm"><input type="checkbox" name="studentSigned" />Student also signed, if able</label>
    <label className="block space-y-1 text-sm">Staff note<input name="reason" required minLength={5} defaultValue="Verified and filed the guardian-signed paper form" className="block min-h-11 w-full rounded-lg border bg-background px-3" /></label>
    <button disabled={pending} className="min-h-11 rounded-lg bg-primary px-4 text-sm font-semibold text-primary-foreground disabled:opacity-50">{pending ? "Recording…" : "Confirm paper form received"}</button>
    {message && <p role={message.ok ? "status" : "alert"} className={`text-sm ${message.ok ? "text-emerald-700" : "text-destructive"}`}>{message.text}</p>}
  </form>;
}
