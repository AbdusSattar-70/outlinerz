"use client";
import { announceSaved } from "@/components/erp/action-panel";
import { useState, useTransition, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import type { z } from "zod";
import type { admissionCaseDetailSchema } from "../schema";
import { editAdmissionIdentity } from "../review-actions";
type Case = z.infer<typeof admissionCaseDetailSchema>;
export function AdmissionIdentityEditor({ admission: a }: { admission: Case }) {
  const [pending, start] = useTransition(),
    [message, setMessage] = useState("");
  const router = useRouter();
  const values = {
    student_mobile:a.additionalDetails?.student_mobile??"",student_email:a.additionalDetails?.student_email??"",present_landmark:a.additionalDetails?.present_landmark??"",permanent_address:a.additionalDetails?.permanent_address??"",permanent_same_as_present:a.additionalDetails?.permanent_same_as_present??"false",
    student_name: a.name,
    student_name_bn: a.nameBn ?? "",
    guardian_name: a.guardian,
    mobile: a.mobile,
    alternate_mobile: a.alternateMobile ?? "",
    guardian_address: a.guardianAddress ?? "",
    guardian_relationship: a.guardianRelationship ?? "",
    date_of_birth: a.dateOfBirth ?? "",
    gender: a.gender ?? "",
    school_name: a.schoolName ?? "",
    school_roll: a.schoolRoll ?? "",
  };
  function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const identity = Object.fromEntries(
      Object.keys(values).map((key) => [key, String(f.get(key) ?? "")]),
    );
    start(async () => {
      try {
        const result = await editAdmissionIdentity({
          admission_id: a.id,
          identity,
          reason: "Corrected application details with student or guardian",
        });
        setMessage(result.message);
        if (result.ok) { announceSaved(result.message); router.refresh(); }
      } catch {
        setMessage("Could not save corrections. Try again.");
      }
    });
  }
  const labels: Record<keyof typeof values, string> = {
    student_mobile:"Student mobile (optional)",student_email:"Student email (optional)",present_landmark:"Nearby landmark",permanent_address:"Permanent address",permanent_same_as_present:"Same as present address (true / false)",
    student_name: "Student full name",
    student_name_bn: "Student name in Bangla",
    guardian_name: "Guardian name",
    mobile: "Primary mobile",
    alternate_mobile: "Alternate mobile",
    guardian_address: "Full address",
    guardian_relationship: "Guardian relationship",
    date_of_birth: "Date of birth",
    gender: "Gender",
    school_name: "School",
    school_roll: "School roll",
  };
  return (
    <details data-action-panel
      className="rounded-xl border p-4"
      open={a.origin === "PROSPECT_CONVERSION" && a.status === "DRAFT"}
    >
      <summary className="cursor-pointer font-semibold">
        {a.status === "DRAFT"
          ? "Review / correct application details"
          : "Edit student and guardian details"}
      </summary>
      <form onSubmit={submit} className="mt-4 space-y-4">
        <div className="grid gap-4 sm:grid-cols-2">
          {Object.entries(values).map(([key, value]) => (
            <label key={key} className="block text-sm">
              {labels[key as keyof typeof values]}
              {["gender","permanent_same_as_present"].includes(key) ? (
                <select
                  name={key}
                  defaultValue={value}
                  className="mt-1 w-full rounded-lg border bg-background p-3"
                >
                  <option value="">Not provided</option>
                  {(key === "gender" ? ["Female", "Male", "Other", "Prefer not to say"] : ["true","false"]).map((v) => (
                    <option key={v}>{v}</option>
                  ))}
                </select>
              ) : (
                <input
                  name={key}
                  defaultValue={value}
                  required={[
                    "student_name",
                    "guardian_name",
                    "mobile",
                    "guardian_address",
                  ].includes(key)}
                  type={key === "date_of_birth" ? "date" : "text"}
                  className="mt-1 w-full rounded-lg border bg-background p-3"
                />
              )}
            </label>
          ))}
        </div>
        <button
          disabled={pending}
          className="rounded-lg border px-4 py-3 text-sm"
        >
          {pending ? "Saving…" : "Save corrections"}
        </button>
        {message && (
          <p role="status" className="text-sm">
            {message}
          </p>
        )}
      </form>
    </details>
  );
}
