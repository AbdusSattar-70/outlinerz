"use client";

import { DirectoryChoice } from "./directory-choice";
import { useRouter } from "next/navigation";
import { useRef, useState, useTransition, type FormEvent } from "react";
import { Button } from "@/components/ui/button";
import type { AdmissionWorkspace } from "../schema";
import { createStaffAdmissionIntake } from "../intake-actions";

const input =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm";
const phonePattern = "01[3-9][0-9]{8}";

function TextField({
  label,
  name,
  required = false,
  type = "text",
  pattern,
  maxLength,
  hint,
  className = "",
}: {
  label: string;
  name: string;
  required?: boolean;
  type?: string;
  pattern?: string;
  maxLength?: number;
  hint?: string;
  className?: string;
}) {
  return (
    <label className={`block space-y-1.5 text-sm ${className}`}>
      <span className="font-medium">
        {label}
        {required ? " *" : ""}
      </span>
      <input
        className={input}
        name={name}
        type={type}
        required={required}
        pattern={pattern}
        maxLength={maxLength}
      />
      {hint && (
        <span className="block text-xs text-muted-foreground">{hint}</span>
      )}
    </label>
  );
}

export function StaffAdmissionIntakeForm({
  data,
}: {
  data: AdmissionWorkspace;
}) {
  const router = useRouter();
  const formRef = useRef<HTMLFormElement>(null);
  const bypassReview = useRef(false);
  const [sameAddress,setSameAddress]=useState(false);
  const [review, setReview] = useState<Record<string, string> | null>(null);
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState("");
  const [offeringId, setOfferingId] = useState("");
  const requestId = useRef("");
  const offering = data.offerings.find((row) => row.id === offeringId);
  const batches = data.batches.filter(
    (batch) =>
      batch.isActive &&
      batch.offeringId === offeringId &&
      batch.occupied <
        Math.min(batch.capacity, data.capacityLimit ?? batch.capacity),
  );

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = event.currentTarget;
    if (!requestId.current) requestId.current = crypto.randomUUID();
    const values = new FormData(form);
    if (!review && !bypassReview.current) {
      setReview(
        Object.fromEntries(
          Array.from(values.entries()).map(([k, v]) => [k, String(v)]),
        ),
      );
      return;
    }
    bypassReview.current = false;
    const value = (key: string) => String(values.get(key) ?? "");
    startTransition(async () => {
      setError("");
      const result = await createStaffAdmissionIntake({
        studentMobile:value("studentMobile"),studentEmail:value("studentEmail"),presentLandmark:value("presentLandmark"),permanentSameAsPresent:sameAddress,
        fatherName: value("fatherName"),
        motherName: value("motherName"),
        birthRegistration: value("birthRegistration"),
        permanentAddress: value("permanentAddress"),
        emergencyContact: value("emergencyContact"),
        emergencyMobile: value("emergencyMobile"),
        previousResult: value("previousResult"),
        learningNeeds: value("learningNeeds"),
        requestId: requestId.current,
        offeringId: value("offeringId"),
        batchId: value("batchId"),
        studentName: value("studentName"),
        studentNameBn: value("studentNameBn"),
        dateOfBirth: value("dateOfBirth"),
        gender: value("gender") as
          "" | "Female" | "Male" | "Other" | "Prefer not to say",
        schoolName: value("schoolName"),
        schoolRoll: value("schoolRoll"),
        guardianName: value("guardianName"),
        guardianRelationship: value("guardianRelationship"),
        mobile: value("mobile"),
        alternateMobile: value("alternateMobile"),
        guardianAddress: value("guardianAddress"),
        referralNote: value("referralNote"),
        reason: value("reason"),
        consentToContact: values.get("consentToContact") === "on",
      });
      if (!result.ok) {
        setError(result.message);
        return;
      }
      requestId.current = "";
      form.reset();
      setOfferingId("");
      router.push(`/dashboard/admissions/${result.admissionId}`);
    });
  }

  return (
    <>
      <form
        ref={formRef}
        onSubmit={submit}
        className={`space-y-6 rounded-2xl border bg-card p-5 sm:p-6 ${review ? "hidden" : ""}`}
      >
        <header>
          <p className="text-sm font-semibold">
            Enter applicant details with the student or guardian
          </p>
          <p className="mt-1 text-sm text-muted-foreground">
            This creates an admission application and draft case directly. It
            does not create a CRM Enquiry. Staff can complete this on the
            family’s behalf; it does not accept admission, post fees, or
            activate enrollment.
          </p>
        </header>

        <section className="space-y-3">
          <h3 className="text-sm font-semibold">Programme and placement</h3>
          <div className="grid gap-4 md:grid-cols-2">
            <label className="block space-y-1.5 text-sm">
              <span className="font-medium">Programme offering *</span>
              <select
                name="offeringId"
                required
                value={offeringId}
                onChange={(e) => setOfferingId(e.target.value)}
                className={input}
              >
                <option value="">Choose an active programme</option>
                {data.offerings.map((row) => (
                  <option
                    key={row.id}
                    value={row.id}
                    disabled={row.feeReady === false}
                  >
                    {row.code} · {row.name} · {row.yearName} ·{" "}
                    {row.branchName ?? "No branch"} · {row.className}
                    {row.feeReady === false ? " · Publish Fee Plan first" : ""}
                  </option>
                ))}
              </select>
              <span className="block text-xs text-muted-foreground">
                Active offerings appear here. Publish an effective Fee Plan to
                enable selection; the class is assigned from the chosen
                offering.
              </span>
            </label>
            <label className="block space-y-1.5 text-sm">
              <span className="font-medium">Batch *</span>
              <select
                name="batchId"
                required
                disabled={!offeringId}
                className={input}
              >
                <option value="">
                  {!offeringId
                    ? "Choose an offering first"
                    : batches.length
                      ? "Choose a batch"
                      : "No available batch for this offering"}
                </option>
                {batches.map((row) => (
                  <option key={row.id} value={row.id}>
                    {row.name} · {row.occupied}/{row.capacity} seats
                  </option>
                ))}
              </select>
            </label>
          </div>
          {offering && (
            <p className="rounded-xl bg-muted/40 p-3 text-xs text-muted-foreground">
              Placement: {offering.className} · {offering.yearName} ·{" "}
              {offering.branchName ?? "No branch"}. Fee terms are inherited from
              the current published Fee Plan and shown on the draft for review.
            </p>
          )}
        </section>

        <section className="space-y-3">
          <h3 className="text-sm font-semibold">Student details</h3>
          <div className="grid gap-4 md:grid-cols-2">
            <TextField
              label="Student full name"
              name="studentName"
              required
              maxLength={160}
            />
            <TextField
              label="Student name in Bangla"
              name="studentNameBn"
              maxLength={160}
            />
            <TextField label="Student mobile (optional)" name="studentMobile" pattern={phonePattern} />
            <TextField label="Student email (optional)" name="studentEmail" type="email" />
            <TextField label="Date of birth" name="dateOfBirth" type="date" />
            <label className="block space-y-1.5 text-sm">
              <span className="font-medium">Gender</span>
              <select name="gender" className={input}>
                <option value="">Not provided</option>
                <option>Female</option>
                <option>Male</option>
                <option>Other</option>
                <option>Prefer not to say</option>
              </select>
            </label>
            <DirectoryChoice
              entity="school"
              name="schoolName"
              label="Current school"
              options={data.directory.schools}
            />
            <TextField label="School roll" name="schoolRoll" maxLength={40} />
            <TextField
              label="Birth registration (optional)"
              name="birthRegistration"
              maxLength={40}
            />
            <TextField
              label="Previous exam / result"
              name="previousResult"
              maxLength={200}
            />
          </div>
        </section>

        <section className="space-y-3">
          <h3 className="text-sm font-semibold">Guardian and contact</h3>
          <div className="grid gap-4 md:grid-cols-2">
            <TextField
              label="Father’s name (optional)"
              name="fatherName"
              maxLength={160}
            />
            <TextField
              label="Mother’s name (optional)"
              name="motherName"
              maxLength={160}
            />
            <TextField
              label="Guardian full name"
              name="guardianName"
              required
              maxLength={160}
            />
            <DirectoryChoice
              entity="relationship"
              name="guardianRelationship"
              label="Relationship to student"
              options={data.directory.relationships}
            />
            <TextField
              label="Primary mobile"
              name="mobile"
              required
              pattern={phonePattern}
              hint="11-digit Bangladesh mobile, e.g. 01712345678."
            />
            <TextField
              label="Alternate mobile"
              name="alternateMobile"
              pattern={`^$|${phonePattern}`}
            />
            <TextField
              label="Present address — village/road, post, upazila and district"
              name="guardianAddress"
              required
              maxLength={300}
              className="md:col-span-2"
            />
            <TextField label="Nearby landmark / special location" name="presentLandmark" maxLength={160} className="md:col-span-2" />
            <label className="flex gap-2 text-sm md:col-span-2"><input type="checkbox" checked={sameAddress} onChange={e=>setSameAddress(e.target.checked)}/> Permanent address is the same as present address</label>
            {!sameAddress && <TextField
              label="Permanent address (if different)"
              name="permanentAddress"
              maxLength={300}
              className="md:col-span-2"
            />}
            <TextField
              label="Emergency contact name / relationship"
              name="emergencyContact"
              maxLength={160}
            />
            <TextField
              label="Emergency contact mobile"
              name="emergencyMobile"
              pattern={`^$|${phonePattern}`}
            />
            <TextField
              label="Health, accessibility or learning support needs (optional)"
              name="learningNeeds"
              maxLength={500}
              className="md:col-span-2"
            />
            <TextField
              label="Additional intake note"
              name="referralNote"
              maxLength={500}
              hint="Optional context from the family. The official admission source is recorded separately on the case before acceptance."
              className="md:col-span-2"
            />
          </div>
        </section>

        <section className="space-y-3">
          <h3 className="text-sm font-semibold">Verification and record</h3>
          <label className="block text-sm font-medium">
            Intake reason
            <select required name="reason" className={input}>
              <option value="Entered application with student and guardian present">
                Student / guardian present
              </option>
              <option value="Entered verified signed paper application into ERP">
                Entering signed paper application
              </option>
              <option value="Saved applicant details for later verification">
                Save for later verification
              </option>
            </select>
          </label>
          <label className="flex items-start gap-3 rounded-xl border p-3 text-sm leading-6">
            <input
              className="mt-1 size-4"
              type="checkbox"
              name="consentToContact"
              required
            />
            <span>
              The guardian gave permission for Sohoj Academy to contact them
              about this student. Signed admission consent is collected
              separately before acceptance.
            </span>
          </label>
        </section>

        {error && (
          <p
            role="alert"
            className="rounded-lg bg-destructive/10 p-3 text-sm text-destructive"
          >
            {error}
          </p>
        )}
        <div className="flex flex-wrap items-center gap-3">
          <Button
            type="submit"
            disabled={pending || data.offerings.length === 0} loading={pending}
          >
            {pending ? "Creating admission draft…" : "Review application"}
          </Button>
          <Button
            type="button"
            variant="outline"
            disabled={pending} loading={pending}
            onClick={() => {
              bypassReview.current = true;
              formRef.current?.requestSubmit();
            }}
          >
            Save draft for later
          </Button>
          <span className="text-xs text-muted-foreground">
            No CRM Enquiry is created, no fee is charged, and no enrollment is
            activated at this step.
          </span>
        </div>
      </form>
      {review && (
        <section className="space-y-4 rounded-2xl border bg-card p-5">
          <h3 className="text-xl font-semibold">Review applicant details</h3>
          <p className="text-sm text-muted-foreground">
            Confirm this information before saving the admission draft. Final
            fees and consent follow on the case page.
          </p>
          <dl className="grid gap-3 sm:grid-cols-2">
            {Object.entries(review)
              .filter(
                ([k, v]) => v && !["consentToContact", "reason"].includes(k),
              )
              .map(([k, v]) => (
                <div key={k}>
                  <dt className="text-xs text-muted-foreground">
                    {k.replace(/([A-Z])/g, " $1")}
                  </dt>
                  <dd className="text-sm">
                    {k === "offeringId"
                      ? data.offerings.find((o) => o.id === v)?.name
                      : k === "batchId"
                        ? data.batches.find((b) => b.id === v)?.name
                        : v}
                  </dd>
                </div>
              ))}
          </dl>
          <Button
            type="button"
            variant="outline"
            onClick={() => setReview(null)}
          >
            Back to edit
          </Button>
          <Button
            type="button"
            className="ml-3"
            disabled={pending} loading={pending}
            onClick={() => {
              bypassReview.current = true;
              formRef.current?.requestSubmit();
            }}
          >
            {pending ? "Saving…" : "Save reviewed draft and open case"}
          </Button>
          {error && <p role="alert">{error}</p>}
        </section>
      )}
    </>
  );
}
