"use server";

import { revalidatePath } from "next/cache";
import { getErpContext } from "@/modules/platform/auth/erp-context";
import { admissionClient } from "./queries";
import {
  staffAdmissionIntakeSchema,
  type StaffAdmissionIntake,
} from "./intake-schema";

export async function createStaffAdmissionIntake(input: StaffAdmissionIntake) {
  const parsed = staffAdmissionIntakeSchema.safeParse(input);
  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    return {
      ok: false as const,
      message: issue?.message ?? "Check the applicant details.",
      field: issue?.path[0]?.toString(),
    };
  }
  const context = await getErpContext();
  if (!context?.permissions.includes("admissions.create"))
    return { ok: false as const, message: "Admission permission is required." };

  const value = parsed.data;
  const db = await admissionClient();
  const { data, error } = await db.rpc(
    "create_staff_admission_intake" as never,
    {
      p_input: {
        student_mobile: value.studentMobile, student_email: value.studentEmail,
        present_landmark: value.presentLandmark, permanent_same_as_present: value.permanentSameAsPresent,
        father_name: value.fatherName,
        mother_name: value.motherName,
        birth_registration: value.birthRegistration,
        permanent_address: value.permanentAddress,
        emergency_contact: value.emergencyContact,
        emergency_mobile: value.emergencyMobile,
        previous_result: value.previousResult,
        learning_needs: value.learningNeeds,
        request_id: value.requestId,
        offering_id: value.offeringId,
        batch_id: value.batchId,
        student_name: value.studentName,
        student_name_bn: value.studentNameBn ?? "",
        date_of_birth: value.dateOfBirth || "",
        gender: value.gender || "",
        school_name: value.schoolName ?? "",
        school_roll: value.schoolRoll ?? "",
        guardian_name: value.guardianName,
        guardian_relationship: value.guardianRelationship ?? "",
        mobile: value.mobile,
        alternate_mobile: value.alternateMobile ?? "",
        guardian_address: value.guardianAddress,
        referral_note: value.referralNote ?? "",
        reason: value.reason,
        consent_to_contact: value.consentToContact,
      },
    } as never,
  );
  if (error) return { ok: false as const, message: error.message };
  const result = data as {
    admission_id?: string;
    admission_no?: string;
  } | null;
  if (!result?.admission_id)
    return {
      ok: false as const,
      message:
        "The admission service did not return a case reference. Refresh Admissions and check for the new draft before retrying.",
    };

  for (const path of [
    "/dashboard/admissions",
    "/dashboard/crm/prospects",
    "/dashboard/students",
    "/dashboard/action-center",
  ])
    revalidatePath(path);
  return {
    ok: true as const,
    admissionId: result.admission_id,
    admissionNo: result.admission_no ?? "",
  };
}
