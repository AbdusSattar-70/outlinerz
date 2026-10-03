"use client";
import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { useLanguage } from "@/components/providers/language-provider";
import { LocalizedText } from "@/components/shared/localized-text";
import { reviewStaffAccess } from "./actions";
type RequestRow = {
  id: string;
  full_name: string;
  email: string;
  mobile: string;
  requested_role: string;
  purpose: string;
  status: string;
  assigned_role: string | null;
};
export function AccessRequestRegister({ rows }: { rows: RequestRow[] }) {
  return (
    <div className="space-y-4">
      {rows.length ? (
        rows.map((r) => <RequestCard key={r.id} row={r} />)
      ) : (
        <p className="rounded-xl border p-6"><LocalizedText en="No staff requests yet." bn="এখনো কোনো স্টাফ অনুরোধ নেই।"/></p>
      )}
    </div>
  );
}
function RequestCard({ row: r }: { row: RequestRow }) {
  const {locale}=useLanguage();const t=(en:string,bn:string)=>locale==="bn"?bn:en;
  const [role, setRole] = useState(r.assigned_role ?? r.requested_role),
    [note, setNote] = useState(
      "Verified identity, contact details and required responsibilities",
    ),
    [message, setMessage] = useState("");
  const [pending, start] = useTransition();
  const router = useRouter();
  function act(action: "VERIFY" | "DECLINE" | "INVITE") {
    start(async () => {
      try {
        const result = await reviewStaffAccess({
          id: r.id,
          action,
          assigned_role: role,
          reason: note,
        });
        setMessage(locale==="bn" && "messageBn" in result ? String(result.messageBn):result.message);
        if (result.ok) router.refresh();
      } catch {
        setMessage(
          t("Could not finish this action. Refresh the request before retrying.","কাজটি শেষ হয়নি। আবার চেষ্টা করার আগে অনুরোধটি রিফ্রেশ করুন।"),
        );
      }
    });
  }
  return (
    <article className="rounded-2xl border bg-card p-5">
      <div className="flex flex-wrap justify-between gap-3">
        <div>
          <h2 className="font-semibold">{r.full_name}</h2>
          <p className="text-sm">
            {r.email} · {r.mobile}
          </p>
        </div>
        <span className="text-xs font-bold">{r.status}</span>
      </div>
      <p className="my-3 text-sm">
        {t("Requested role","অনুরোধকৃত ভূমিকা")} {r.requested_role}: {r.purpose}
      </p>
      {r.status === "ACTIVE" && <p className="text-sm text-muted-foreground">{t("Account setup completed; this person has accessed the workspace. Manage their identity and responsibilities in the staff register.","অ্যাকাউন্ট চালু হয়েছে এবং এই ব্যক্তি কর্মক্ষেত্রে প্রবেশ করেছেন। স্টাফ তালিকা থেকে পরিচয় ও দায়িত্ব পরিচালনা করুন।")}</p>}
      {["PENDING", "VERIFIED", "INVITED"].includes(r.status) && (
        <details className="space-y-3"><summary className="cursor-pointer font-semibold">{t("Review access request","প্রবেশাধিকারের অনুরোধ পর্যালোচনা করুন")}</summary><div className="mt-3 space-y-3">
          <label className="block text-sm">
            {t("Verified role","যাচাইকৃত ভূমিকা")}
            <select
              disabled={r.status === "INVITED"}
              value={role}
              onChange={(e) => setRole(e.target.value)}
              className="ml-3 rounded-lg border bg-background p-2"
            >
              {["ADMIN", "OPERATOR", "TEACHER", "ACCOUNTANT"].map((v) => (
                <option key={v}>{v}</option>
              ))}
            </select>
          </label>
          <label className="block text-sm">
            {t("Verification note","যাচাইয়ের নোট")}
            <input
              value={note}
              onChange={(e) => setNote(e.target.value)}
              className="mt-1 w-full rounded-lg border bg-background p-3"
            />
          </label>
          {r.assigned_role && role!==r.assigned_role && <p className="text-sm">{t("Verify the changed role before sending account setup instructions.","পরিবর্তিত ভূমিকা যাচাই করে তারপর অ্যাকাউন্ট চালুর নির্দেশনা পাঠান।")}</p>}
          <div className="flex flex-wrap gap-3">
            {r.status !== "INVITED" && (
              <>
                <button
                  disabled={pending}
                  className="rounded-lg border p-3 text-sm"
                  onClick={() => act("VERIFY")}
                >
                  {pending?t("Working…","কাজ চলছে…"):t("Verify role","ভূমিকা যাচাই করুন")}
                </button>
                <button
                  disabled={pending}
                  className="rounded-lg border p-3 text-sm"
                  onClick={() => act("DECLINE")}
                >
                  {t("Decline","প্রত্যাখ্যান করুন")}
                </button>
              </>
            )}
            {["VERIFIED", "INVITED"].includes(r.status) && (
              <button
                disabled={pending || role!==r.assigned_role}
                className="rounded-lg bg-primary p-3 text-sm text-primary-foreground"
                onClick={() => act("INVITE")}
              >
                {pending?t("Sending…","পাঠানো হচ্ছে…"):r.status === "INVITED"?t("Resend account setup","আবার অ্যাকাউন্ট চালুর নির্দেশনা পাঠান"):t("Send account setup","অ্যাকাউন্ট চালুর নির্দেশনা পাঠান")}
              </button>
            )}
          </div>
        </div></details>
      )}
      {message && (
        <p role="status" className="mt-3 text-sm">
          {message}
        </p>
      )}
    </article>
  );
}
