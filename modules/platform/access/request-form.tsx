"use client";
import { useState, useTransition, type FormEvent } from "react";
import { useLanguage } from "@/components/providers/language-provider";
import { requestStaffAccess } from "./actions";
export function StaffAccessRequestForm() {
  const {locale}=useLanguage();const t=(en:string,bn:string)=>locale==="bn"?bn:en;
  const [pending, start] = useTransition(),
    [message, setMessage] = useState(""),
    [sent, setSent] = useState(false);
  function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    start(async () => {
      try {
        const r = await requestStaffAccess(Object.fromEntries(f));
        setMessage(locale==="bn" && "messageBn" in r ? String(r.messageBn):r.message);
        setSent(r.ok);
      } catch {
        setMessage(t("Request could not be sent. Please try again.","অনুরোধ পাঠানো যায়নি। আবার চেষ্টা করুন।"));
      }
    });
  }
  const control = "mt-1 min-h-11 w-full rounded-xl border bg-background px-3";
  return (
    <form onSubmit={submit} className="space-y-5">
      {!sent && (
        <>
          <label className="block text-sm">
            {t("Full name","পূর্ণ নাম")}
            <input
              required
              maxLength={160}
              name="full_name"
              className={control}
            />
          </label>
          <label className="block text-sm">
            {t("Email","ইমেইল")}
            <input
              required
              type="email"
              maxLength={254}
              name="email"
              className={control}
            />
          </label>
          <label className="block text-sm">
            {t("Mobile","মোবাইল")}
            <input
              required
              pattern="01[3-9][0-9]{8}"
              name="mobile"
              className={control}
            />
          </label>
          <label className="block text-sm">
            {t("Which role are you requesting?","কোন দায়িত্বের জন্য প্রবেশাধিকার চান?")}
            <select name="requested_role" required className={control}>
              <option value="">{t("Choose role","ভূমিকা নির্বাচন করুন")}</option>
              <option value="ADMIN">Admin</option>
              <option value="OPERATOR">Operator</option>
              <option value="TEACHER">Teacher</option>
              <option value="ACCOUNTANT">Accountant</option>
            </select>
          </label>
          <label className="block text-sm">
            {t("Why do you need access?","কেন প্রবেশাধিকার প্রয়োজন?")}
            <textarea
              name="purpose"
              required
              minLength={5}
              maxLength={500}
              className={`${control} py-3`}
            />
          </label>
          <input
            tabIndex={-1}
            autoComplete="off"
            name="website"
            className="hidden"
          />
          <button
            disabled={pending}
            className="min-h-11 w-full rounded-xl bg-primary font-semibold text-primary-foreground"
          >
            {pending ? t("Sending…","পাঠানো হচ্ছে…") : t("Request staff access","প্রবেশাধিকারের অনুরোধ পাঠান")}
          </button>
        </>
      )}
      {message && (
        <p role="status" className="rounded-xl border p-4 text-sm">
          {message}
        </p>
      )}
    </form>
  );
}
