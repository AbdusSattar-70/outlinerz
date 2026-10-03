import { z } from "zod";

export const applicantCorrectionSchema = z.object({
  prospectNo: z.string().trim().min(5, "Enter your application reference."),
  mobile: z
    .string()
    .trim()
    .min(8, "Enter the mobile number used in the application."),
  requestedChanges: z
    .string()
    .trim()
    .min(10, "Describe the correction in at least 10 characters.")
    .max(2000, "Keep the correction under 2,000 characters."),
  website: z.string().max(0).optional(),
});

export type ApplicantCorrectionInput = z.infer<
  typeof applicantCorrectionSchema
>;
