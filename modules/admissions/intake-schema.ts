import { z } from "zod";

const uuid = z.string().uuid("Choose a valid option.");

export const staffAdmissionIntakeSchema = z.object({
  studentMobile: z.string().regex(/^$|^01[3-9][0-9]{8}$/).optional(),
  studentEmail: z.union([z.email(),z.literal("")]).optional(),
  presentLandmark: z.string().trim().max(160).optional(),
  permanentSameAsPresent: z.boolean().optional(),
  fatherName: z.string().trim().max(160).optional(),
  motherName: z.string().trim().max(160).optional(),
  birthRegistration: z.string().trim().max(40).optional(),
  permanentAddress: z.string().trim().max(300).optional(),
  emergencyContact: z.string().trim().max(160).optional(),
  emergencyMobile: z
    .string()
    .regex(/^$|^01[3-9][0-9]{8}$/)
    .optional(),
  previousResult: z.string().trim().max(200).optional(),
  learningNeeds: z.string().trim().max(500).optional(),
  requestId: uuid,
  offeringId: uuid,
  batchId: uuid,
  studentName: z.string().trim().min(2).max(160),
  studentNameBn: z.string().trim().max(160).optional(),
  dateOfBirth: z.string().optional(),
  gender: z
    .enum(["", "Female", "Male", "Other", "Prefer not to say"])
    .optional(),
  schoolName: z.string().trim().max(200).optional(),
  schoolRoll: z.string().trim().max(40).optional(),
  guardianName: z.string().trim().min(2).max(160),
  guardianRelationship: z.string().trim().max(80).optional(),
  mobile: z
    .string()
    .regex(/^01[3-9][0-9]{8}$/, "Enter an 11-digit Bangladesh mobile."),
  alternateMobile: z
    .string()
    .regex(
      /^$|^01[3-9][0-9]{8}$/,
      "Enter an 11-digit Bangladesh mobile or leave blank.",
    )
    .optional(),
  guardianAddress: z
    .string()
    .trim()
    .min(5, "Enter the guardian’s address.")
    .max(300),
  referralNote: z.string().trim().max(500).optional(),
  reason: z
    .string()
    .trim()
    .min(5, "Enter a reason with at least five characters.")
    .max(500),
  consentToContact: z
    .boolean()
    .refine((value) => value, "Record the guardian’s consent to be contacted."),
});

export type StaffAdmissionIntake = z.infer<typeof staffAdmissionIntakeSchema>;
