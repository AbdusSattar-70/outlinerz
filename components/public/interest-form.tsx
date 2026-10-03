"use client";
import { AcknowledgementSlip } from "./acknowledgement-slip";

import {
  useMemo,
  useRef,
  useState,
  useTransition,
  type ReactNode,
} from "react";
import Link from "next/link";
import { CheckCircle2, Download, Send } from "lucide-react";
import { toast } from "react-toastify";
import { submitPublicInterest } from "@/app/actions/public-interest";
import {
  SmartSelect,
  type SmartSelectOption,
} from "@/components/shared/smart-select";
import Logo from "@/components/shared/logo";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useLanguage } from "@/components/providers/language-provider";
import { cn } from "@/lib/utils";

type Option = { id: string; name: string };

type OpenOfferingOption = {
  id: string;
  code: string;
  name: string;
  classId: string;
  programId: string;
  subjectIds: string[];
  schedule: string | null;
  scheduleBn: string | null;
  requirements: string | null;
  requirementsBn: string | null;
  policy: string | null;
  policyBn: string | null;
  feePlan: {
    billing_cycle: string;
    currency_code: string;
    components: { name: string; amount: number; recurrence: string }[];
  } | null;
  openSeats: number;
  activeBatches: number;
};

const dayOptions = [
  ["SAT", "Sat", "শনি"],
  ["SUN", "Sun", "রবি"],
  ["MON", "Mon", "সোম"],
  ["TUE", "Tue", "মঙ্গল"],
  ["WED", "Wed", "বুধ"],
  ["THU", "Thu", "বৃহঃ"],
  ["FRI", "Fri", "শুক্র"],
] as const;

const selectClass =
  "h-11 w-full rounded-xl border border-input bg-background px-3 text-sm text-foreground outline-none transition focus:border-ring focus:ring-3 focus:ring-ring/20";

function Field({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return <div className={cn("flex flex-col gap-2", className)}>{children}</div>;
}



export function PublicInterestForm({
  classes,
  programs,
  subjects,
  schools,
  sourceOptions,
  relationships,
  openOfferings = [],
  defaultOfferingId = "",
  intent = "interest",
}: {
  classes: Option[];
  programs: Option[];
  subjects: Option[];
  schools: SmartSelectOption[];
  sourceOptions: { code: string; name: string }[];
  relationships: { code: string; name: string }[];
  openOfferings?: OpenOfferingOption[];
  defaultOfferingId?: string;
  intent?: "interest" | "admission";
}) {
  const { locale } = useLanguage();
  const bn = locale === "bn";
  const [selectedOfferingId, setSelectedOfferingId] =
    useState(defaultOfferingId);
  const selectedOffering = useMemo(
    () => openOfferings.find((row) => row.id === selectedOfferingId) ?? null,
    [openOfferings, selectedOfferingId],
  );
  const visibleSubjects = subjects; // Preferences are reverified by staff; do not filter out other subjects.

  const [sameAddress,setSameAddress]=useState(false);
  const formRef = useRef<HTMLFormElement>(null);
  const [isPending, startTransition] = useTransition();
  const [formVersion, setFormVersion] = useState(0);
  const [message, setMessage] = useState<{
    ok: true;
    text: string;
    prospectNo?: string | null;
    studentName?: string;
    intentLabel?: string;
    details?:Record<string,string>;
  } | null>(null);

  function submit(formData: FormData) {
    setMessage(null);
    const input = {
      studentMobile:String(formData.get("studentMobile")??""),studentEmail:String(formData.get("studentEmail")??""),presentLandmark:String(formData.get("presentLandmark")??""),permanentSameAsPresent:sameAddress,
      dateOfBirth: String(formData.get("dateOfBirth") ?? ""),
      gender: String(formData.get("gender") ?? ""),
      schoolRoll: String(formData.get("schoolRoll") ?? ""),
      fatherName: String(formData.get("fatherName") ?? ""),
      motherName: String(formData.get("motherName") ?? ""),
      birthRegistration: String(formData.get("birthRegistration") ?? ""),
      permanentAddress: String(formData.get("permanentAddress") ?? ""),
      emergencyContact: String(formData.get("emergencyContact") ?? ""),
      emergencyMobile: String(formData.get("emergencyMobile") ?? ""),
      previousResult: String(formData.get("previousResult") ?? ""),
      learningNeeds: String(formData.get("learningNeeds") ?? ""),
      studentName: String(formData.get("studentName") ?? ""),
      studentNameBn: String(formData.get("studentNameBn") ?? ""),
      guardianName: String(formData.get("guardianName") ?? ""),
      guardianRelationship: String(formData.get("guardianRelationship") ?? ""),
      mobile: String(formData.get("mobile") ?? ""),
      alternateMobile: String(formData.get("alternateMobile") ?? ""),
      classId: String(formData.get("classId") ?? ""),
      schoolId: String(formData.get("schoolId") ?? "") || undefined,
      schoolNameSnapshot: String(formData.get("schoolNameSnapshot") ?? ""),
      area: String(formData.get("area") ?? ""),
      preferredSchedule: (String(formData.get("preferredSchedule") ?? "") ||
        undefined) as
        "MORNING" | "AFTERNOON" | "EVENING" | "FLEXIBLE" | undefined,
      preferredDays: formData.getAll("preferredDays").map(String) as (
        "SAT" | "SUN" | "MON" | "TUE" | "WED" | "THU" | "FRI"
      )[],
      trialInterest: formData.get("trialInterest") === "on",
      programIds: formData.getAll("programIds").map(String),
      subjectIds: formData.getAll("subjectIds").map(String),
      sourceCode: String(formData.get("sourceCode") ?? "") || undefined,
      referralNote: String(formData.get("referralNote") ?? ""),
      notes: String(formData.get("notes") ?? ""),
      consentToContact: formData.get("consentToContact") === "on",
      website: String(formData.get("website") ?? ""),
      offeringId: String(formData.get("offeringId") ?? "") || undefined,
      intent: (String(formData.get("intent") ?? intent) || "interest") as
        "interest" | "admission",
      guardianAddress: String(formData.get("guardianAddress") ?? ""),
      academicBackground: String(formData.get("academicBackground") ?? ""),
      requirementsAcknowledged:
        formData.get("requirementsAcknowledged") === "on",
      policyAcknowledged: formData.get("policyAcknowledged") === "on",
    };

    startTransition(async () => {
      const result = await submitPublicInterest(input);
      if (result.ok) {
        setMessage({
          ok: true,
          prospectNo: result.prospectNo,
          studentName: input.studentName,
          details:{guardian:input.guardianName,mobile:input.mobile,email:input.studentEmail,address:input.guardianAddress,programme:selectedOffering?.name??programs.filter(p=>input.programIds.includes(p.id)).map(p=>p.name).join(", "),subjects:subjects.filter(s=>input.subjectIds.includes(s.id)).map(s=>s.name).join(", "),submitted:new Date().toLocaleString("en-GB",{timeZone:"Asia/Dhaka"})},
          intentLabel:
            input.intent === "admission"
              ? bn
                ? "ভর্তির আবেদন"
                : "Admission application"
              : bn
                ? "আগ্রহ নিবন্ধন"
                : "Interest registration",
          text: bn
            ? "ধন্যবাদ। আপনার অনুরোধ রেকর্ড হয়েছে। এটি এখনো ভর্তি নয়—স্টাফ যাচাইয়ের পর যোগাযোগ করবে।"
            : "Thank you. Your request is recorded. This is not yet admission — staff will verify and contact you.",
        });
        formRef.current?.reset();
        setFormVersion((value) => value + 1);
        window.scrollTo({ top: 0, behavior: "smooth" });
      } else {
        toast.error(
          result.error ||
            (bn
              ? "কিছু ভুল হয়েছে। আবার চেষ্টা করুন।"
              : "Something went wrong. Please try again."),
          { position: "bottom-right", autoClose: 5000 },
        );
      }
    });
  }

  function downloadPdf(){window.print();}

  // ── Success only: no form ──────────────────────────────────────────
  if (message?.ok) {
    return (
      <div className="space-y-5">
        <div
          role="status"
          className="flex items-start gap-3 rounded-2xl border border-emerald-300/80 bg-emerald-50 p-4 text-emerald-950 dark:border-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-50"
        >
          <CheckCircle2
            className="mt-0.5 size-5 shrink-0 text-emerald-600 dark:text-emerald-400"
            aria-hidden="true"
          />
          <div>
            <p className="font-semibold">
              {bn ? "আগ্রহ রেকর্ড হয়েছে" : "Interest recorded"}
            </p>
            <p className="mt-1 text-sm leading-6 opacity-90">{message.text}</p>
          </div>
        </div>

        <AcknowledgementSlip message={message} bn={bn} />

        <div className="flex flex-wrap gap-3">
          <button
            type="button"
            onClick={downloadPdf}
            className="inline-flex min-h-10 items-center justify-center gap-2 rounded-xl bg-blue-700 px-4 text-sm font-semibold text-white hover:bg-blue-800"
          >
            <Download className="size-4" aria-hidden="true" />
            {bn ? "প্রিন্ট / PDF সংরক্ষণ" : "Print / Save PDF"}
          </button>
          <Link
            href="/"
            className="inline-flex min-h-10 items-center justify-center rounded-xl border border-border bg-background px-4 text-sm font-semibold hover:bg-muted"
          >
            {bn ? "হোমে ফিরুন" : "Back to home"}
          </Link>
        </div>
      </div>
    );
  }

  // ── Form (only when not successful) ────────────────────────────────
  return (
    <div className="space-y-6" key={formVersion}>
      <form ref={formRef} onSubmit={event=>{event.preventDefault();submit(new FormData(event.currentTarget));}} className="space-y-8">
        <div className="sr-only" aria-hidden="true">
          <label htmlFor="website">Website</label>
          <input id="website" name="website" tabIndex={-1} autoComplete="off" />
        </div>
        <input type="hidden" name="intent" value={intent} />

        <section className="space-y-4">
          <h2 className="text-lg font-semibold">
            {bn ? "প্রোগ্রাম অফারিং" : "Programme offering"}
          </h2>
          <Field>
            <Label htmlFor="interest-offering">
              {bn ? "অফারিং" : "Offering"}
              {intent === "admission" ? " *" : ""}
            </Label>
            <select
              id="interest-offering"
              name="offeringId"
              className={selectClass}
              required={intent === "admission"}
              value={selectedOfferingId}
              onChange={(event) => setSelectedOfferingId(event.target.value)}
            >
              <option value="">
                {intent === "admission"
                  ? bn
                    ? "একটি উন্মুক্ত অফারিং বেছে নিন"
                    : "Select an open offering"
                  : bn
                    ? "সাধারণ আগ্রহ (কোনো নির্দিষ্ট অফারিং নয়)"
                    : "General interest (no specific offering)"}
              </option>
              {openOfferings.map((offering) => (
                <option key={offering.id} value={offering.id}>
                  {offering.code} — {offering.name}
                </option>
              ))}
            </select>
          </Field>
          {intent === "admission" && openOfferings.length === 0 ? (
            <p className="text-sm text-amber-800 dark:text-amber-200">
              {bn
                ? "এখন কোনো অফারিং আবেদন গ্রহণ করছে না।"
                : "No offerings are accepting applications right now."}
            </p>
          ) : null}
          {intent === "admission" && selectedOffering ? (
            <div className="space-y-3 rounded-xl border bg-muted/40 p-4 text-sm leading-6">
              <p>
                {selectedOffering.activeBatches === 0
                  ? bn
                    ? "ব্যাচে স্থান নির্ধারণ প্রস্তুত হচ্ছে।"
                    : "Batch placement is being prepared."
                  : selectedOffering.openSeats === 0
                    ? bn
                      ? "বর্তমান ব্যাচগুলো পূর্ণ; স্টাফ স্থান নির্ধারণ পর্যালোচনা করবে।"
                      : "Current batches are full; staff will review placement options."
                    : bn
                      ? `বর্তমানে ${selectedOffering.openSeats}টি ব্যাচ আসন খালি। যাচাইয়ের পরে স্থান নিশ্চিত হবে।`
                      : `${selectedOffering.openSeats} current batch seats are open. Placement is confirmed after staff review.`}
              </p>
              {selectedOffering.schedule ? (
                <p>
                  <strong>{bn ? "সময়সূচি" : "Schedule"}:</strong>{" "}
                  {bn
                    ? selectedOffering.scheduleBn || selectedOffering.schedule
                    : selectedOffering.schedule}
                </p>
              ) : null}
              {selectedOffering.feePlan?.components.length ? (
                <div>
                  <p className="font-semibold">
                    {bn ? "প্রকাশিত ফি" : "Published fees"} (
                    {selectedOffering.feePlan.currency_code},{" "}
                    {selectedOffering.feePlan.billing_cycle
                      .toLowerCase()
                      .replaceAll("_", " ")}
                    )
                  </p>
                  <ul className="list-inside list-disc">
                    {selectedOffering.feePlan.components.map((component) => (
                      <li key={component.name}>
                        {component.name}:{" "}
                        {Number(component.amount).toLocaleString("en-BD")} (
                        {component.recurrence
                          .toLowerCase()
                          .replaceAll("_", " ")}
                        )
                      </li>
                    ))}
                  </ul>
                </div>
              ) : null}
            </div>
          ) : null}
        </section>

        <section className="space-y-4">
          <h2 className="text-lg font-semibold">
            {bn ? "শিক্ষার্থীর তথ্য" : "Student information"}
          </h2>
          <div className="grid gap-5 md:grid-cols-2">
            <Field>
              <Label htmlFor="interest-student-name">
                {bn ? "শিক্ষার্থীর নাম (ইংরেজি)" : "Student Name (English)"} *
              </Label>
              <Input
                id="interest-student-name"
                name="studentName"
                className="h-11"
                required
              />
            </Field>
            <Field>
              <Label htmlFor="interest-student-name-bn">
                {bn ? "শিক্ষার্থীর নাম (বাংলা)" : "Student Name (Bangla)"}
              </Label>
              <Input
                id="interest-student-name-bn"
                name="studentNameBn"
                className="h-11"
              />
            </Field>
            <Field><Label htmlFor="student-mobile">{bn?"শিক্ষার্থীর মোবাইল (ঐচ্ছিক)":"Student mobile (optional)"}</Label><Input id="student-mobile" name="studentMobile" type="tel" pattern="01[3-9][0-9]{8}" className="h-11"/></Field>
            <Field><Label htmlFor="student-email">{bn?"শিক্ষার্থীর ইমেইল (ঐচ্ছিক)":"Student email (optional)"}</Label><Input id="student-email" name="studentEmail" type="email" className="h-11"/></Field>
            <Field>
              <Label htmlFor="interest-class">
                {bn ? "বর্তমান ক্লাস" : "Current Class"} *
              </Label>
              <select
                id="interest-class"
                name="classId"
                className={selectClass}
                required
                key={selectedOffering?.classId ?? "class"}
                defaultValue={selectedOffering?.classId ?? ""}
              >
                <option value="">
                  {bn ? "বর্তমান ক্লাস নির্বাচন করুন" : "Select current class"}
                </option>
                {classes.map((row) => (
                  <option key={row.id} value={row.id}>
                    {row.name}
                  </option>
                ))}
              </select>
            </Field>
            <div>
              <SmartSelect
                key={`school-${formVersion}`}
                name="schoolId"
                snapshotName="schoolNameSnapshot"
                label={bn ? "বর্তমান স্কুল" : "Current School"}
                options={schools}
                placeholder={
                  bn
                    ? "স্কুলের নাম লিখতে শুরু করুন"
                    : "Start typing the school name"
                }
                hint={
                  bn
                    ? "তালিকায় থাকলে স্কুলটি নির্বাচন করুন। না থাকলে অফিসিয়াল নাম লিখুন; স্টাফ পরে যাচাই করবে।"
                    : "Pick a listed school when possible. If not listed, type the official name; staff can verify later."
                }
              />
            </div>
            <Field className="md:col-span-2">
              <Label htmlFor="interest-area">
                {bn ? "এলাকা / লোকেশন" : "Area / Locality"}
              </Label>
              <Input id="interest-area" name="area" className="h-11" />
            </Field>
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="text-lg font-semibold">
            {bn ? "অভিভাবক ও যোগাযোগ" : "Guardian & contact"}
          </h2>
          <div className="grid gap-5 md:grid-cols-2">
            <Field>
              <Label htmlFor="interest-guardian">
                {bn ? "অভিভাবকের নাম" : "Guardian Name"} *
              </Label>
              <Input
                id="interest-guardian"
                name="guardianName"
                className="h-11"
                required
              />
            </Field>
            <Field>
              <Label htmlFor="interest-relationship">
                {bn ? "সম্পর্ক" : "Relationship"}
              </Label>
              <select
                id="interest-relationship"
                name="guardianRelationship"
                className={selectClass}
              >
                <option value="">
                  {bn ? "সম্পর্ক নির্বাচন করুন" : "Select relationship"}
                </option>
                {relationships.map((row) => (
                  <option key={row.code} value={row.code}>
                    {row.name}
                  </option>
                ))}
              </select>
            </Field>
            <Field>
              <Label htmlFor="interest-mobile">
                {bn ? "প্রধান মোবাইল" : "Primary Mobile"} *
              </Label>
              <Input
                id="interest-mobile"
                name="mobile"
                className="h-11"
                inputMode="tel"
                required
              />
            </Field>
            <Field>
              <Label htmlFor="interest-alt-mobile">
                {bn ? "বিকল্প মোবাইল" : "Alternate Mobile"}
              </Label>
              <Input
                id="interest-alt-mobile"
                name="alternateMobile"
                className="h-11"
                inputMode="tel"
              />
            </Field>
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="text-lg font-semibold">
            {bn ? "কোন বিষয়ে আগ্রহী?" : "What are you interested in?"}
          </h2>

          <fieldset>
            <legend className="text-sm font-semibold">
              {bn ? "বিষয়সমূহ" : "Subjects"}
            </legend>
            <div className="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {visibleSubjects.map((subject) => (
                <label
                  key={subject.id}
                  className="flex min-h-11 cursor-pointer items-center gap-3 rounded-xl border px-3 py-2.5 text-sm"
                >
                  <input
                    type="checkbox"
                    name="subjectIds"
                    value={subject.id}
                    defaultChecked={selectedOffering?.subjectIds.includes(
                      subject.id,
                    )}
                    className="size-4 accent-blue-700"
                  />
                  <span>{subject.name}</span>
                </label>
              ))}
            </div>
          </fieldset>
        </section>

        <section className="space-y-4">
          <h2 className="text-lg font-semibold">
            {bn ? "সময় ও ফলো-আপ পছন্দ" : "Schedule & follow-up"}
          </h2>
          <div className="grid gap-5 md:grid-cols-2">
            <Field>
              <Label htmlFor="interest-schedule">
                {bn ? "পছন্দের ক্লাস সময়" : "Preferred Class Time"}
              </Label>
              <select
                id="interest-schedule"
                name="preferredSchedule"
                className={selectClass}
              >
                <option value="">
                  {bn
                    ? "পছন্দ থাকলে নির্বাচন করুন"
                    : "Select if you have a preference"}
                </option>
                <option value="MORNING">{bn ? "সকাল" : "Morning"}</option>
                <option value="AFTERNOON">{bn ? "বিকেল" : "Afternoon"}</option>
                <option value="EVENING">{bn ? "সন্ধ্যা" : "Evening"}</option>
                <option value="FLEXIBLE">
                  {bn ? "যেকোনো সময়" : "Flexible"}
                </option>
              </select>
            </Field>
            <Field>
              <Label htmlFor="interest-source">
                {bn ? "কীভাবে জেনেছেন?" : "How did you hear about us?"}
              </Label>
              <select
                id="interest-source"
                name="sourceCode"
                className={selectClass}
              >
                <option value="">
                  {bn ? "জানা থাকলে নির্বাচন করুন" : "Select if known"}
                </option>
                {sourceOptions.map((row) => (
                  <option key={row.code} value={row.code}>
                    {row.name}
                  </option>
                ))}
              </select>
            </Field>
          </div>
          <fieldset>
            <legend className="text-sm font-semibold">
              {bn ? "পছন্দের দিন" : "Preferred days"}
            </legend>
            <div className="mt-3 flex flex-wrap gap-2">
              {dayOptions.map(([code, en, bnLabel]) => (
                <label
                  key={code}
                  className="inline-flex min-h-11 cursor-pointer items-center gap-2 rounded-xl border px-3 text-sm"
                >
                  <input
                    type="checkbox"
                    name="preferredDays"
                    value={code}
                    className="size-4 accent-blue-700"
                  />
                  <span>{bn ? bnLabel : en}</span>
                </label>
              ))}
            </div>
          </fieldset>
          <label className="flex min-h-11 cursor-pointer items-center gap-3 rounded-xl border px-3 py-2.5 text-sm">
            <input
              type="checkbox"
              name="trialInterest"
              className="size-4 accent-blue-700"
            />
            <span>
              {bn
                ? "ট্রায়াল / ওরিয়েন্টেশন ক্লাসে আগ্রহী"
                : "Interested in a trial / orientation class"}
            </span>
          </label>
          <Field>
            <Label htmlFor="interest-referral">
              {bn ? "রেফারেল তথ্য" : "Referral details"}
            </Label>
            <Input
              id="interest-referral"
              name="referralNote"
              className="h-11"
            />
          </Field>
          <Field>
            <Label htmlFor="interest-notes">
              {bn ? "আর কিছু জানাতে চান?" : "Anything else?"}
            </Label>
            <textarea
              id="interest-notes"
              name="notes"
              rows={3}
              className={`${selectClass} min-h-22 py-2`}
            />
          </Field>
        </section>

        {intent === "admission" && (
          <section>
            <h2 className="mb-4 text-lg font-semibold">
              {bn
                ? "অতিরিক্ত শিক্ষার্থী তথ্য (ঐচ্ছিক)"
                : "Additional student details (optional)"}
            </h2>
            <div className="grid gap-4 sm:grid-cols-2">
              <label className="block text-sm">
                Date of birth / জন্ম তারিখ
                <input
                  name="dateOfBirth"
                  type="date"
                  maxLength={300}
                  className="mt-2 min-h-11 w-full rounded-xl border bg-background px-3"
                />
              </label>
              <label className="block text-sm">Gender / লিঙ্গ<select name="gender" className={`${selectClass} mt-2`}><option value="">Not provided / উল্লেখ নেই</option><option>Female</option><option>Male</option><option>Other</option></select></label>
              <label className="block text-sm">Birth registration (optional) / জন্ম নিবন্ধন<input name="birthRegistration" maxLength={80} className="mt-2 min-h-11 w-full rounded-xl border bg-background px-3"/></label>
              <label className="block text-sm">Previous exam / result (optional) / আগের ফলাফল<input name="previousResult" maxLength={160} className="mt-2 min-h-11 w-full rounded-xl border bg-background px-3"/></label>
              <label className="block text-sm">
                Father’s name / পিতার নাম
                <input
                  name="fatherName"
                  type="text"
                  maxLength={300}
                  className="mt-2 min-h-11 w-full rounded-xl border bg-background px-3"
                />
              </label>
              <label className="block text-sm">
                Mother’s name / মাতার নাম
                <input
                  name="motherName"
                  type="text"
                  maxLength={300}
                  className="mt-2 min-h-11 w-full rounded-xl border bg-background px-3"
                />
              </label>
              <label className="block text-sm">
                School roll / স্কুল রোল
                <input
                  name="schoolRoll"
                  type="text"
                  maxLength={300}
                  className="mt-2 min-h-11 w-full rounded-xl border bg-background px-3"
                />
              </label>
              <label className="block text-sm">
                Emergency contact / জরুরি যোগাযোগ
                <input
                  name="emergencyContact"
                  type="text"
                  maxLength={300}
                  className="mt-2 min-h-11 w-full rounded-xl border bg-background px-3"
                />
              </label>
              <label className="block text-sm">
                Emergency mobile / জরুরি মোবাইল
                <input
                  name="emergencyMobile"
                  type="tel"
                  maxLength={300}
                  className="mt-2 min-h-11 w-full rounded-xl border bg-background px-3"
                />
              </label>
              <label className="block text-sm">
                Health or learning support needs (optional) / বিশেষ সহায়তা
                <input
                  name="learningNeeds"
                  type="text"
                  maxLength={300}
                  className="mt-2 min-h-11 w-full rounded-xl border bg-background px-3"
                />
              </label>
            </div>
          </section>
        )}
        {intent === "admission" ? (
          <section className="space-y-4 rounded-xl border p-4">
            <h2 className="text-lg font-semibold">
              {bn ? "ভর্তির আবেদন" : "Admission application"}
            </h2>
            <Field>
              <Label htmlFor="guardian-address">
                {bn ? "বর্তমান ঠিকানা: গ্রাম/রাস্তা, ডাকঘর, উপজেলা ও জেলা" : "Present address: village/road, post, upazila and district"} *
              </Label>
              <textarea
                id="guardian-address"
                name="guardianAddress"
                required
                minLength={5}
                maxLength={300}
                rows={2}
                className={`${selectClass} min-h-20 py-2`}
              />
            </Field>
            <Field><Label htmlFor="present-landmark">{bn?"কাছের পরিচিত স্থান / বিশেষ লোকেশন":"Nearby landmark / special location"}</Label><Input id="present-landmark" name="presentLandmark" maxLength={160} className="h-11"/></Field>
            <label className="flex gap-2 text-sm"><input type="checkbox" checked={sameAddress} onChange={e=>setSameAddress(e.target.checked)}/>{bn?"স্থায়ী ঠিকানা বর্তমান ঠিকানার মতো":"Permanent address is the same as present address"}</label>
            <Field className={sameAddress?"hidden":""}><Label htmlFor="permanent-address">{bn?"স্থায়ী ঠিকানা (আলাদা হলে)":"Permanent address (if different)"}</Label><textarea id="permanent-address" name="permanentAddress" disabled={sameAddress} maxLength={300} rows={3} className={`${selectClass} min-h-24 py-2`}/></Field>
            <Field>
              <Label htmlFor="academic-background">
                {bn ? "পূর্ববর্তী শিক্ষাগত তথ্য" : "Academic background"}
              </Label>
              <textarea
                id="academic-background"
                name="academicBackground"
                maxLength={500}
                rows={2}
                className={`${selectClass} min-h-20 py-2`}
              />
            </Field>
            <div className="rounded-lg bg-muted/50 p-3 text-sm leading-6">
              <p className="font-semibold">
                {bn ? "প্রোগ্রামের শর্ত" : "Programme requirements"}
              </p>
              <p className="whitespace-pre-wrap">
                {(bn
                  ? selectedOffering?.requirementsBn ||
                    selectedOffering?.requirements
                  : selectedOffering?.requirements) ||
                  (bn
                    ? "অফারিংয়ের জন্য কোনো অতিরিক্ত শর্ত প্রকাশিত নেই।"
                    : "No additional requirements published for this offering.")}
              </p>
            </div>
            <label className="flex items-start gap-3 text-sm">
              <input
                type="checkbox"
                name="requirementsAcknowledged"
                required
                className="mt-1 size-4 accent-blue-700"
              />
              <span>
                {bn
                  ? "আমি প্রোগ্রামের শর্ত পড়েছি ও বুঝেছি।"
                  : "I have read and understood the programme requirements."}
              </span>
            </label>
            <div className="rounded-lg bg-muted/50 p-3 text-sm leading-6">
              <p className="font-semibold">
                {bn ? "ভর্তি নীতি" : "Admission policy"}
              </p>
              <p className="whitespace-pre-wrap">
                {(bn
                  ? selectedOffering?.policyBn || selectedOffering?.policy
                  : selectedOffering?.policy) ||
                  (bn
                    ? "স্টাফ যাচাইয়ের পরে ভর্তি নিশ্চিত হবে।"
                    : "Admission is confirmed only after staff verification.")}
              </p>
            </div>
            <label className="flex items-start gap-3 text-sm">
              <input
                type="checkbox"
                name="policyAcknowledged"
                required
                className="mt-1 size-4 accent-blue-700"
              />
              <span>
                {bn
                  ? "আমি ভর্তি নীতি পড়েছি ও বুঝেছি।"
                  : "I have read and understood the admission policy."}
              </span>
            </label>
          </section>
        ) : null}

        <label className="flex items-start gap-3 rounded-xl border p-4 text-sm leading-6">
          <input
            type="checkbox"
            name="consentToContact"
            required
            className="mt-1 size-4 accent-blue-700"
          />
          <span>
            {bn
              ? "এই আগ্রহ নিবন্ধন সম্পর্কে সহজ একাডেমিকে আমার সঙ্গে যোগাযোগের অনুমতি দিচ্ছি।"
              : "I allow Sohoj Academy to contact me about this interest request and related programmes."}
          </span>
        </label>

        <button
          type="submit"
          disabled={
            isPending || (intent === "admission" && openOfferings.length === 0)
          }
          className="inline-flex min-h-12 items-center justify-center gap-2 rounded-xl bg-blue-700 px-5 text-sm font-semibold text-white hover:bg-blue-800 disabled:opacity-60"
        >
          <Send className="size-4" aria-hidden="true" />
          {isPending
            ? bn
              ? "জমা হচ্ছে…"
              : "Submitting…"
            : bn
              ? intent === "admission"
                ? "ভর্তির আবেদন জমা দিন"
                : "আগ্রহ জমা দিন"
              : intent === "admission"
                ? "Submit Admission Application"
                : "Submit Interest"}
        </button>
      </form>
    </div>
  );
}
