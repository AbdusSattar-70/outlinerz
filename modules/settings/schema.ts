import { z } from "zod";

const percent = z
  .number()
  .min(0, "Percentage cannot be below 0.")
  .max(100, "Percentage cannot exceed 100.");

export const batchCapacityPolicySchema = z.object({
  policy: z.literal("batch_capacity"),
  maxStudents: z
    .number()
    .int("Batch capacity must be a whole number.")
    .min(1, "Batch capacity must be at least 1.")
    .max(500, "Batch capacity is unusually high; use 500 or less."),
  reason: z.string().trim().min(5, "Explain why this policy is changing.").max(500),
});

export const teacherCompensationPolicySchema = z
  .object({
    policy: z.literal("teacher_compensation"),
    teachingPoolPercent: percent,
    teachingPoolReviewMaxPercent: percent,
    acquisitionBonusPercent: percent,
    retention3MonthPercent: percent,
    retention6MonthPercent: percent,
    reason: z.string().trim().min(5, "Explain why this policy is changing.").max(500),
  })
  .superRefine((value, ctx) => {
    if (value.teachingPoolPercent > value.teachingPoolReviewMaxPercent) {
      ctx.addIssue({
        code: "custom",
        path: ["teachingPoolReviewMaxPercent"],
        message: "Review maximum cannot be below the normal teaching-pool percentage.",
      });
    }
  });

export const admissionActivationPolicySchema = z
  .object({
    policy: z.literal("admission_activation"),
    requiresAdmissionAcceptance: z.boolean(),
    requiresInitialBillingPosted: z.boolean(),
    paymentRequirement: z.enum(["NONE", "MINIMUM_PERCENT", "FULL"]),
    minimumPaymentPercent: percent,
    allowCreditEnrollment: z.boolean(),
    countStudentActiveOnlyWhenEnrollmentActive: z.boolean(),
    reason: z.string().trim().min(5, "Explain why this policy is changing.").max(500),
  })
  .superRefine((value, ctx) => {
    if (value.paymentRequirement === "NONE" && value.minimumPaymentPercent !== 0) {
      ctx.addIssue({
        code: "custom",
        path: ["minimumPaymentPercent"],
        message: "Minimum payment must be 0 when no payment is required.",
      });
    }

    if (
      value.paymentRequirement === "MINIMUM_PERCENT" &&
      (value.minimumPaymentPercent <= 0 || value.minimumPaymentPercent >= 100)
    ) {
      ctx.addIssue({
        code: "custom",
        path: ["minimumPaymentPercent"],
        message: "Minimum-payment policy must be greater than 0% and below 100%.",
      });
    }

    if (value.paymentRequirement === "FULL" && value.minimumPaymentPercent !== 100) {
      ctx.addIssue({
        code: "custom",
        path: ["minimumPaymentPercent"],
        message: "Full-payment policy requires 100%.",
      });
    }
  });

export const editablePolicySchema = z.discriminatedUnion("policy", [
  batchCapacityPolicySchema,
  teacherCompensationPolicySchema,
  admissionActivationPolicySchema,
]);

export type EditablePolicyInput = z.infer<typeof editablePolicySchema>;
export type BatchCapacityPolicyInput = z.infer<typeof batchCapacityPolicySchema>;
export type TeacherCompensationPolicyInput = z.infer<typeof teacherCompensationPolicySchema>;
export type AdmissionActivationPolicyInput = z.infer<typeof admissionActivationPolicySchema>;

export const rolePermissionUpdateSchema = z.object({
  roleCode: z.string().trim().min(1).max(80),
  permissionCodes: z.array(z.string().trim().min(1)).max(200),
  reason: z.string().trim().min(5, "Explain why access is changing.").max(500),
});

export type RolePermissionUpdateInput = z.infer<typeof rolePermissionUpdateSchema>;


export const userAccessUpdateSchema = z.object({
  profileId: z.string().uuid(),
  roleCodes: z.array(z.string().trim().min(1)).max(20),
  reason: z.string().trim().min(5, "Explain why this user's access is changing.").max(500),
});

export type UserAccessUpdateInput = z.infer<typeof userAccessUpdateSchema>;
