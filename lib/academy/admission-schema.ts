import { z } from "zod";

export const admissionSchema = z
  .object({
    name: z.string().trim().min(2, "Student name must contain at least 2 characters."),
    nameBn: z.string().trim().optional(),
    gender: z.string().trim().optional(),
    dateOfBirth: z.string().optional(),
    schoolId: z.string().uuid().optional(),
    schoolNameSnapshot: z.string().trim().optional(),
    schoolRoll: z.string().trim().optional(),
    guardianName: z.string().trim().min(2, "Guardian name must contain at least 2 characters."),
    relationship: z.string().trim().min(2, "Select the guardian's relationship to the student."),
    mobile: z.string().trim().min(10, "Enter a valid primary mobile number."),
    alternateMobile: z.string().trim().optional(),
    address: z.string().trim().optional(),
    academicYearId: z.string().uuid("Select an academic year."),
    classId: z.string().uuid("Select a class."),
    batchId: z.string().uuid().optional(),
    programId: z.string().uuid().optional(),
    admissionDate: z.string().min(1, "Admission date is required."),
    monthlyFee: z.coerce.number().min(0, "Monthly fee cannot be negative."),
    discount: z.coerce.number().min(0, "Discount cannot be negative."),
  })
  .superRefine((data, ctx) => {
    if (data.discount > data.monthlyFee) {
      ctx.addIssue({
        code: "custom",
        path: ["discount"],
        message: "Discount cannot be greater than the monthly tuition.",
      });
    }
  });

export type AdmissionInput = z.infer<typeof admissionSchema>;
