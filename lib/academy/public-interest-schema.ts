import { z } from "zod";

const optionalPhone = z.string().trim().max(30).optional();

export const publicInterestSchema = z
  .object({
    studentMobile: z
      .string()
      .regex(/^$|^01[3-9][0-9]{8}$/)
      .optional(),
    studentEmail: z.union([z.email(), z.literal("")]).optional(),
    presentLandmark: z.string().max(160).optional(),
    permanentSameAsPresent: z.boolean().optional(),
    dateOfBirth: z.string().trim().max(300).optional(),
    gender: z.string().trim().max(300).optional(),
    schoolRoll: z.string().trim().max(300).optional(),
    fatherName: z.string().trim().max(300).optional(),
    motherName: z.string().trim().max(300).optional(),
    birthRegistration: z.string().trim().max(300).optional(),
    permanentAddress: z.string().trim().max(300).optional(),
    emergencyContact: z.string().trim().max(300).optional(),
    emergencyMobile: z.string().trim().max(300).optional(),
    previousResult: z.string().trim().max(300).optional(),
    learningNeeds: z.string().trim().max(500).optional(),
    studentName: z.string().trim().min(2, "Enter the student's name.").max(120),
    studentNameBn: z.string().trim().max(120).optional(),
    guardianName: z
      .string()
      .trim()
      .min(2, "Enter the guardian's name.")
      .max(120),
    guardianRelationship: z.string().trim().max(40).optional(),
    mobile: z.string().trim().min(10, "Enter a valid mobile number.").max(30),
    alternateMobile: optionalPhone,
    classId: z.string().uuid("Select the student's current class."),
    schoolId: z.string().uuid().optional(),
    schoolNameSnapshot: z.string().trim().max(180).optional(),
    area: z.string().trim().max(180).optional(),
    preferredSchedule: z
      .enum(["MORNING", "AFTERNOON", "EVENING", "FLEXIBLE"])
      .optional(),
    preferredDays: z
      .array(z.enum(["SAT", "SUN", "MON", "TUE", "WED", "THU", "FRI"]))
      .max(7)
      .default([]),
    trialInterest: z.boolean().default(false),
    programIds: z.array(z.string().uuid()).max(10).default([]),
    subjectIds: z.array(z.string().uuid()).max(20).default([]),
    sourceCode: z
      .string()
      .trim()
      .max(40)
      .regex(/^[A-Z0-9_-]+$/)
      .optional(),
    referralNote: z.string().trim().max(240).optional(),
    notes: z.string().trim().max(500).optional(),
    consentToContact: z.boolean().default(false),
    website: z.string().max(0).optional(),
    offeringId: z.string().uuid().optional(),
    intent: z.enum(["interest", "admission"]).default("interest"),
    guardianAddress: z.string().trim().max(300).optional(),
    academicBackground: z.string().trim().max(500).optional(),
    requirementsAcknowledged: z.boolean().optional(),
    policyAcknowledged: z.boolean().optional(),
  })
  .superRefine((value, ctx) => {
    if (value.intent === "admission" && !value.offeringId) {
      ctx.addIssue({
        code: "custom",
        path: ["offeringId"],
        message:
          "Select an open programme offering for admission applications.",
      });
    }
    if (value.intent === "admission") {
      if (!value.guardianAddress || value.guardianAddress.length < 5) {
        ctx.addIssue({
          code: "custom",
          path: ["guardianAddress"],
          message: "Enter the guardian's address.",
        });
      }
    }
  });

export type PublicInterestInput = z.infer<typeof publicInterestSchema>;
