import { z } from "zod";

const id = z.string().uuid("Select a valid option.");
export const createOfferingSchema = z.object({
  branchId: id,
  academicYearId: id,
  classId: id,
  programId: id,
  groupId: z.union([id, z.literal("")]),
  code: z
    .string()
    .trim()
    .min(2)
    .max(40)
    .regex(/^[A-Za-z0-9_-]+$/, "Use letters, numbers, _ or -."),
  name: z.union([z.string().trim().min(2).max(160), z.literal("")]),
  reason: z
    .string()
    .trim()
    .min(5, "Explain why this offering is being created.")
    .max(500),
});
export type CreateOfferingInput = z.infer<typeof createOfferingSchema>;
export const offeringFormSchema = createOfferingSchema.extend({
  offeringId: id.optional(),
  requestId: id.optional(),
});
export type OfferingFormInput = z.infer<typeof offeringFormSchema>;
export const updateOfferingSchema = createOfferingSchema.extend({
  offeringId: id,
  requestId: id,
});
export type UpdateOfferingInput = z.infer<typeof updateOfferingSchema>;

export const publishFeePlanSchema = z
  .object({
    offeringId: id,
    billingCycle: z.enum(["MONTHLY", "ONE_TIME", "TERM"]),
    dueDay: z.number().int().min(1).max(28).nullable(),
    effectiveFrom: z.iso.date(),
    reason: z.string().trim().min(5, "Explain the fee change.").max(500),
    components: z
      .array(
        z.object({
          code: z
            .string()
            .trim()
            .min(2)
            .max(40)
            .regex(/^[A-Za-z][A-Za-z0-9_]*$/),
          name: z.string().trim().min(2).max(100),
          amount: z.number().finite().min(0).max(9999999999.99),
          chargeType: z.enum([
            "TUITION",
            "ADMISSION",
            "EXAM",
            "MATERIAL",
            "OTHER",
          ]),
          recurrence: z.enum(["PER_CYCLE", "ONE_TIME"]),
        }),
      )
      .min(1)
      .max(30),
  })
  .superRefine((value, ctx) => {
    if ((value.billingCycle === "MONTHLY") !== (value.dueDay !== null)) {
      ctx.addIssue({
        code: "custom",
        path: ["dueDay"],
        message:
          "Monthly plans need a due day; other plans must leave it blank.",
      });
    }
    if (
      !value.components.some(
        (item) =>
          item.chargeType === "TUITION" && item.recurrence === "PER_CYCLE",
      )
    ) {
      ctx.addIssue({
        code: "custom",
        path: ["components"],
        message: "Add a recurring Tuition component.",
      });
    }
    if (
      new Set(value.components.map((item) => item.code.toUpperCase())).size !==
      value.components.length
    ) {
      ctx.addIssue({
        code: "custom",
        path: ["components"],
        message: "Component codes must be unique.",
      });
    }
  });
export type PublishFeePlanInput = z.infer<typeof publishFeePlanSchema>;

export const SHOWCASE_ICON_VALUES = [
  "clipboard-check",
  "graduation-cap",
  "users-round",
  "book-open-check",
  "line-chart",
  "shield-check",
] as const;

const updateOfferingPublicControlsBaseSchema = z.object({
  offeringId: id,
  showcaseTitle: z.string().trim().max(120),
  showcaseTitleBn: z.string().trim().max(120),
  showcaseDescription: z.string().trim().max(400),
  showcaseDescriptionBn: z.string().trim().max(400),
  showcaseEyebrow: z.string().trim().max(80),
  showcaseEyebrowBn: z.string().trim().max(80),
  publicSchedule: z.string().trim().max(300),
  publicScheduleBn: z.string().trim().max(300),
  publicRequirements: z.string().trim().max(800),
  publicRequirementsBn: z.string().trim().max(800),
  admissionPolicy: z.string().trim().max(800),
  admissionPolicyBn: z.string().trim().max(800),
  showcaseIcon: z.union([z.enum(SHOWCASE_ICON_VALUES), z.literal("")]),
  showcaseSortOrder: z.number().int().min(0).max(9999),
  isWebsiteVisible: z.boolean(),
  isAcceptingApplications: z.boolean(),
  applicationsOpenOn: z.string().optional(),
  applicationsCloseOn: z.string().optional(),
  subjectIds: z.array(z.string().uuid()).max(30),
  reason: z
    .string()
    .trim()
    .min(5, "Explain why public controls are changing.")
    .max(500),
});
export const updateOfferingPublicControlsSchema =
  updateOfferingPublicControlsBaseSchema.superRefine((value, ctx) => {
    if (value.isWebsiteVisible) {
      if (!value.showcaseTitle) {
        ctx.addIssue({
          code: "custom",
          path: ["showcaseTitle"],
          message: "English title is required when website visibility is on.",
        });
      }
      if (!value.showcaseDescription) {
        ctx.addIssue({
          code: "custom",
          path: ["showcaseDescription"],
          message:
            "English description is required when website visibility is on.",
        });
      }
    }
    const open = value.applicationsOpenOn?.trim() || "";
    const close = value.applicationsCloseOn?.trim() || "";
    if (open && close && close < open) {
      ctx.addIssue({
        code: "custom",
        path: ["applicationsCloseOn"],
        message: "Close date must be on or after the open date.",
      });
    }
  });
export type UpdateOfferingPublicControlsInput = z.infer<
  typeof updateOfferingPublicControlsSchema
>;

/** @deprecated Use updateOfferingPublicControlsSchema — kept so old showcase-form.tsx can be deleted safely. */
export const updateOfferingShowcaseSchema = updateOfferingPublicControlsSchema;
/** @deprecated Use UpdateOfferingPublicControlsInput */
export type UpdateOfferingShowcaseInput = UpdateOfferingPublicControlsInput;
