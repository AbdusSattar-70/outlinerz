import { z } from "zod";
const uuid = z.string().uuid();
export const commandSchema = z
  .object({
    action: z.enum([
      "CREATE_BATCH",
      "EDIT_BATCH",
      "CREATE",
      "EDIT_DRAFT",
      "READY",
      "REFRESH_FEES",
      "ACCEPT",
      "BILL",
      "ACTIVATE",
      "PAY",
      "FINALIZE",
      "RETURN_TO_DRAFT",
      "SAVE_DISCOUNT",
    ]),
    requestId: uuid,
    reason: z
      .string()
      .trim()
      .min(5, "Enter a reason with at least five characters.")
      .max(500),
    offeringId: z.string().optional(),
    prospectId: z.string().optional(),
    confirmPlacementCorrection: z.boolean().optional(),
    batchId: z.string().optional(),
    admissionId: z.string().optional(),
    studentName: z.string().trim().min(2).max(160).optional(),
    guardianName: z.string().trim().min(2).max(160).optional(),
    mobile: z
      .string()
      .regex(/^01[3-9][0-9]{8}$/, "Enter an 11-digit Bangladesh mobile.")
      .optional(),
    code: z.string().trim().max(40).optional(),
    name: z.string().trim().max(160).optional(),
    capacity: z.number().int().positive().max(500).optional(),
    amount: z.number().positive().max(9999999999.99).optional(),
    paymentMethodId: z.string().optional(),
    externalReference: z.string().trim().max(120).optional(),
    discountPercent: z.number().int().min(0).max(30).optional(),
    discountReason: z.string().max(80).optional(),
  })
  .superRefine((v, ctx) => {
    const required =
      v.action === "CREATE_BATCH"
        ? ["offeringId"]
        : v.action === "EDIT_BATCH"
          ? ["batchId"]
          : v.action === "CREATE"
            ? ["prospectId", "offeringId", "batchId"]
            : v.action === "PAY"
              ? ["admissionId", "paymentMethodId"]
              : ["admissionId"];
    for (const field of required)
      if (!uuid.safeParse(v[field as keyof typeof v]).success)
        ctx.addIssue({
          code: "custom",
          path: [field],
          message: "Select a valid option.",
        });
    if (v.action === "CREATE_BATCH" || v.action === "EDIT_BATCH") {
      for (const field of ["code", "name"] as const)
        if ((v[field]?.length ?? 0) < 2)
          ctx.addIssue({
            code: "custom",
            path: [field],
            message: "Enter at least two characters.",
          });
      if (v.capacity === undefined || Number.isNaN(v.capacity))
        ctx.addIssue({
          code: "custom",
          path: ["capacity"],
          message: "Enter the batch capacity.",
        });
    }
    if (v.action === "EDIT_DRAFT")
      for (const key of ["studentName", "guardianName", "mobile"] as const)
        if (!v[key])
          ctx.addIssue({
            code: "custom",
            path: [key],
            message: "This field is required.",
          });
    if (v.action === "PAY" && !v.amount)
      ctx.addIssue({
        code: "custom",
        path: ["amount"],
        message: "Enter the actual amount received.",
      });
  });
export type AdmissionCommand = z.infer<typeof commandSchema>;
const option = z.object({ id: uuid, name: z.string() });
export const workspaceSchema = z.object({
  directory: z
    .object({ schools: z.array(option), relationships: z.array(option) })
    .default({ schools: [], relationships: [] }),
  offerings: z.array(
    option.extend({
      code: z.string(),
      classId: uuid,
      className: z.string(),
      yearName: z.string(),
      branchName: z.string().nullable(),
      feeReady: z.boolean().optional(),
    }),
  ),
  capacityLimit: z.number().nullable(),
  batches: z.array(
    option.extend({
      code: z.string(),
      offeringId: uuid,
      offeringName: z.string(),
      classId: uuid,
      className: z.string(),
      yearName: z.string(),
      branchName: z.string().nullable(),
      capacity: z.number(),
      occupied: z.number(),
      isActive: z.boolean(),
    }),
  ),
  prospects: z.array(
    option.extend({
      number: z.string(),
      classId: uuid.nullable(),
      interestedOfferingId: uuid.nullable(),
      guardian: z.string(),
      mobile: z.string(),
    }),
  ),
  paymentMethods: z.array(option),
  cases: z.array(
    z.object({
      id: uuid,
      number: z.string(),
      status: z.enum([
        "DRAFT",
        "READY",
        "ACCEPTED",
        "BILLING_POSTED",
        "PENDING_PAYMENT",
        "ACTIVE_ENROLLMENT",
        "CLOSED_ENROLLMENT",
        "CANCELLED",
      ]),
      createdAt: z.string(),
      batchId: uuid,
      existingStudent: z.boolean(),
      studentNo: z.string().nullable(),
      studentId: uuid.nullable(),
      name: z.string(),
      nameBn: z.string().nullable(),
      gender: z.string().nullable(),
      dateOfBirth: z.string().nullable(),
      schoolName: z.string().nullable(),
      schoolRoll: z.string().nullable(),
      guardianAddress: z.string().nullable(),
      alternateMobile: z.string().nullable(),
      guardianRelationship: z.string().nullable(),
      guardian: z.string(),
      mobile: z.string(),
      feeVersion: z.number().nullable(),
      feePlanId: uuid.nullable(),
      policyVersion: z.number().nullable(),
      paymentRequirement: z.string().nullable(),
      components: z.array(
        z.object({
          name: z.string(),
          amount: z.number(),
          recurrence: z.string(),
        }),
      ),
      invoice: z
        .object({
          number: z.string(),
          total: z.number(),
          dueOn: z.string(),
          paid: z.number(),
          credits: z.number(),
          net: z.number(),
          refunded: z.number(),
          due: z.number(),
          credit: z.number(),
        })
        .nullable(),
      receipts: z.array(
        z.object({
          number: z.string(),
          amount: z.number(),
          postedAt: z.string(),
          method: z.string(),
          refunded: z.number(),
        }),
      ),
    }),
  ),
});
export const admissionCaseDetailSchema = z.object({
  additionalCharges: z
    .array(
      z.object({
        id: uuid,
        name: z.string(),
        amount: z.number(),
        is_active: z.boolean(),
      }),
    )
    .default([]),
  discountPercent: z.number().optional(),
  discountReason: z.string().nullable().optional(),
  academyRoll: z.string().nullable().optional(),
  additionalDetails: z.record(z.string(), z.string().nullable()).optional(),
  id: uuid,
  number: z.string(),
  status: z.enum([
    "DRAFT",
    "READY",
    "ACCEPTED",
    "BILLING_POSTED",
    "PENDING_PAYMENT",
    "ACTIVE_ENROLLMENT",
    "CLOSED_ENROLLMENT",
    "CANCELLED",
  ]),
  createdAt: z.string(),
  existingStudent: z.boolean(),
  origin: z.enum([
    "DIRECT_STAFF",
    "PROSPECT_CONVERSION",
    "PUBLIC_APPLICATION",
    "EXISTING_STUDENT",
  ]),
  originProspectId: uuid.nullable(),
  batchId: uuid,
  batchName: z.string(),
  batchCode: z.string(),
  batchCapacity: z.number(),
  batchOccupied: z.number(),
  offeringId: uuid,
  offeringName: z.string(),
  className: z.string(),
  yearName: z.string(),
  branchName: z.string().nullable(),
  studentNo: z.string().nullable(),
  studentId: uuid.nullable(),
  name: z.string(),
  nameBn: z.string().nullable(),
  gender: z.string().nullable(),
  dateOfBirth: z.string().nullable(),
  schoolName: z.string().nullable(),
  schoolRoll: z.string().nullable(),
  guardianAddress: z.string().nullable(),
  alternateMobile: z.string().nullable(),
  guardianRelationship: z.string().nullable(),
  guardian: z.string(),
  mobile: z.string(),
  feeVersion: z.number().nullable(),
  feePlanId: uuid.nullable(),
  policyVersion: z.number().nullable(),
  paymentRequirement: z.string().nullable(),
  tuitionTotal: z.number().default(0),
  components: z.array(
    z.object({
      name: z.string(),
      amount: z.number(),
      recurrence: z.string(),
    }),
  ),
  invoice: z
    .object({
      id: uuid,
      number: z.string(),
      total: z.number(),
      dueOn: z.string(),
      paid: z.number(),
      credits: z.number(),
      net: z.number(),
      refunded: z.number(),
      due: z.number(),
      credit: z.number(),
    })
    .nullable(),
  receipts: z.array(
    z.object({
      number: z.string(),
      amount: z.number(),
      postedAt: z.string(),
      method: z.string(),
      refunded: z.number(),
    }),
  ),
});

export type AdmissionWorkspace = z.infer<typeof workspaceSchema>;
export type AdmissionCommandFormData = Pick<
  AdmissionWorkspace,
  "capacityLimit" | "offerings" | "batches" | "prospects" | "paymentMethods"
>;
export type AdmissionCase = AdmissionWorkspace["cases"][number];
