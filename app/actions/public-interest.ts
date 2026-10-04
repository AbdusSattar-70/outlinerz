"use server";

import { createClient } from "@/lib/supabase/server";
import {
  publicInterestSchema,
  type PublicInterestInput,
} from "@/lib/academy/public-interest-schema";

export type PublicInterestResult =
  | { ok: true; prospectNo: string | null }
  | { ok: false; error: string; field?: string | null };

export async function submitPublicInterest(
  input: PublicInterestInput,
): Promise<PublicInterestResult> {
  const parsed = publicInterestSchema.safeParse(input);

  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    return {
      ok: false,
      error: issue?.message ?? "Please check the information and try again.",
      field: issue?.path?.[0]?.toString() ?? null,
    };
  }

  const data = parsed.data;

  // Honeypot: pretend success for automated submissions without polluting CRM.
  if (data.website) {
    return { ok: true, prospectNo: null };
  }

  const supabase = await createClient();
  // Keep the client receiver: Supabase rpc() reads this.rest internally.
  const { data: result, error } = await supabase.rpc("submit_public_interest", {
    p_payload: {
      student_mobile:data.studentMobile,student_email:data.studentEmail,present_landmark:data.presentLandmark,permanent_same_as_present:data.permanentSameAsPresent,
      date_of_birth: data.dateOfBirth || "",
      gender: data.gender || "",
      school_roll: data.schoolRoll || "",
      father_name: data.fatherName || "",
      mother_name: data.motherName || "",
      birth_registration: data.birthRegistration || "",
      permanent_address: data.permanentAddress || "",
      emergency_contact: data.emergencyContact || "",
      emergency_mobile: data.emergencyMobile || "",
      previous_result: data.previousResult || "",
      learning_needs: data.learningNeeds || "",
      student_name: data.studentName,
      student_name_bn: data.studentNameBn || "",
      guardian_name: data.guardianName,
      guardian_relationship: data.guardianRelationship || "",
      mobile: data.mobile,
      alternate_mobile: data.alternateMobile || "",
      class_id: data.classId,
      school_id: data.schoolId || "",
      school_name_snapshot: data.schoolNameSnapshot || "",
      area: data.area || "",
      preferred_schedule: data.preferredSchedule || "",
      preferred_days: data.preferredDays.join(","),
      trial_interest: data.trialInterest,
      program_ids: data.programIds,
      subject_ids: data.subjectIds,
      source_code: data.sourceCode || "",
      referral_note: data.referralNote || "",
      notes: data.notes || "",
      consent_to_contact: data.consentToContact,
      offering_id: data.offeringId || "",
      intent: data.intent || "interest",
      guardian_address: data.guardianAddress || "",
      academic_background: data.academicBackground || "",
      requirements_acknowledged: data.requirementsAcknowledged === true,
      policy_acknowledged: data.policyAcknowledged === true,
    },
  });

  if (error) {
    const knownMessages = [
      "A similar interest request was submitted recently. Please wait before submitting again.",
      "Student name is required.",
      "Guardian name is required.",
      "A valid mobile number is required.",
      "Consent to contact is required.",
      "Selected class is not available.",
      "Selected school is not available.",
      "Selected source is not available.",
      "One selected program is not available.",
      "One selected subject is not available.",
      "Selected programme offering is not available.",
      "Applications are closed for this programme offering.",
      "Applications are not open yet for this programme offering.",
      "An open programme offering is required for admission applications.",
      "Selected class does not match the chosen programme offering.",
      "One selected subject is not part of the chosen programme offering.",
      "Guardian address is required for an admission application.",
      "Review and acknowledge the programme requirements and admission policy.",
    ];

    const known = knownMessages.find((message) =>
      error.message.includes(message),
    );
    return {
      ok: false,
      error:
        known ??
        "We could not save your interest request right now. Please try again in a moment.",
    };
  }

  return {
    ok: true,
    prospectNo:
      result &&
      typeof result === "object" &&
      !Array.isArray(result) &&
      typeof result.prospect_no === "string"
        ? result.prospect_no
        : null,
  };
}
