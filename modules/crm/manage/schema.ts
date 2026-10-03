import { z } from "zod";

export const masterEntities = [
  "academic_year",
  "class",
  "group",
  "subject",
  "program",
  "school",
  "lead_source",
  "guardian_relationship",
] as const;

export type MasterEntity = (typeof masterEntities)[number];

const reason = z
  .string()
  .trim()
  .min(5, "Explain the change in at least five characters.")
  .max(500);

const codeField = z
  .string()
  .trim()
  .min(1, "Code is required.")
  .max(40)
  .regex(/^[A-Za-z0-9_-]+$/, "Use letters, numbers, _ or -.");

const nameField = z.string().trim().min(1, "Name is required.").max(160);

export const manageMasterRecordSchema = z
  .object({
    requestId: z.uuid(),
    entity: z.enum(masterEntities),
    id: z.union([z.string().uuid(), z.literal("")]).optional(),
    code: z.string().optional(),
    name: z.string().optional(),
    description: z.string().trim().max(1200).optional(),
    sortOrder: z.number().int().min(0).max(9999).optional(),
    startsOn: z.string().optional(),
    endsOn: z.string().optional(),
    areaId: z.union([z.string().uuid(), z.literal("")]).optional(),
    isActive: z.boolean(),
    isVerified: z.boolean().optional(),
    reason,
  })
  .superRefine((value, ctx) => {
    if (value.entity === "academic_year") {
      if (!value.name || value.name.trim().length < 2) {
        ctx.addIssue({
          code: "custom",
          path: ["name"],
          message: "Year name is required.",
        });
      }
      if (!value.startsOn) {
        ctx.addIssue({
          code: "custom",
          path: ["startsOn"],
          message: "Start date is required.",
        });
      }
      if (!value.endsOn) {
        ctx.addIssue({
          code: "custom",
          path: ["endsOn"],
          message: "End date is required.",
        });
      }
      if (value.startsOn && value.endsOn && value.endsOn < value.startsOn) {
        ctx.addIssue({
          code: "custom",
          path: ["endsOn"],
          message: "End date must be on or after the start date.",
        });
      }
      return;
    }

    if (value.entity === "school") {
      if (!value.name || value.name.trim().length < 2) {
        ctx.addIssue({
          code: "custom",
          path: ["name"],
          message: "School name is required.",
        });
      }
      return;
    }

    const codeResult = codeField.safeParse(value.code ?? "");
    if (!codeResult.success) {
      ctx.addIssue({
        code: "custom",
        path: ["code"],
        message: codeResult.error.issues[0]?.message ?? "Invalid code.",
      });
    }
    const nameResult = nameField.safeParse(value.name ?? "");
    if (!nameResult.success) {
      ctx.addIssue({
        code: "custom",
        path: ["name"],
        message: nameResult.error.issues[0]?.message ?? "Invalid name.",
      });
    }
  });

export type ManageMasterRecordInput = z.infer<typeof manageMasterRecordSchema>;
