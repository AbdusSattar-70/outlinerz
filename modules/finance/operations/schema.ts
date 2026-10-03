import { z } from "zod";
const id = z.string().uuid();
const date = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Choose a date.");
export const financeCommandSchema = z
  .object({
    action: z.enum([
      "APPLY_DISCOUNT",
      "CANCEL_ADMISSION",
      "REFUND",
      "RUN_BILLING",
      "CREATE_TERM",
      "PAY",
    ]),
    request_id: id,
    reason: z
      .string()
      .trim()
      .min(5, "Explain the reason in at least five characters.")
      .max(500),
    admission_id: id.optional(),
    invoice_id: id.optional(),
    payment_id: id.optional(),
    kind: z.enum(["PERCENT", "FIXED"]).optional(),
    value: z.number().positive().multipleOf(0.01).optional(),
    starts_on: date.optional(),
    ends_on: date.optional(),
    due_on: date.optional(),
    settlement: z.enum(["KEEP_CHARGES", "CREDIT_ALL"]).optional(),
    amount: z.number().positive().multipleOf(0.01).optional(),
    payment_method_id: id.optional(),
    external_reference: z.string().trim().max(120).optional(),
    period: date.optional(),
    term_id: id.optional(),
    preview_token: z.string().optional(),
    academic_year_id: id.optional(),
    name: z.string().trim().min(2).max(120).optional(),
  })
  .superRefine((v, ctx) => {
    const required: Record<typeof v.action, string[]> = {
      APPLY_DISCOUNT: [
        "admission_id",
        "kind",
        "value",
        "starts_on",
        "ends_on",
      ],
      CANCEL_ADMISSION: ["admission_id", "settlement"],
      REFUND: ["payment_id", "amount", "payment_method_id"],
      RUN_BILLING: ["period", "preview_token"],
      CREATE_TERM: [
        "academic_year_id",
        "name",
        "starts_on",
        "ends_on",
        "due_on",
      ],
      PAY: ["admission_id", "invoice_id", "amount", "payment_method_id"],
    };
    for (const key of required[v.action])
      if (v[key as keyof typeof v] === undefined)
        ctx.addIssue({
          code: "custom",
          path: [key],
          message: "This field is required.",
        });
    if (v.kind === "PERCENT" && (v.value ?? 0) > 100)
      ctx.addIssue({
        code: "custom",
        path: ["value"],
        message: "Percentage cannot exceed 100.",
      });
    if (v.starts_on && v.ends_on && v.ends_on < v.starts_on)
      ctx.addIssue({
        code: "custom",
        path: ["ends_on"],
        message: "End date must follow the start date.",
      });
  });
export type FinanceCommand = z.infer<typeof financeCommandSchema>;
const option = z.object({ id, name: z.string() });
export const financeWorkspaceSchema = z.object({
  admissions: z.array(
    option.extend({
      number: z.string(),
      status: z.string(),
      studentId: z.string().uuid().nullable(),
      studentNo: z.string().nullable(),
      mobile: z.string().nullable(),
    }),
  ),
  years: z.array(option),
  terms: z.array(
    option.extend({
      startsOn: z.string(),
      endsOn: z.string(),
      dueOn: z.string(),
    }),
  ),
  invoices: z.array(
    z.object({
      id,
      admissionId: id,
      name: z.string(),
      number: z.string(),
      kind: z.string(),
      period: z.string(),
      dueOn: z.string(),
      currency: z.string(),
      gross: z.number(),
      credits: z.number(),
      discountAmount: z.number().default(0),
      scholarshipAmount: z.number().default(0),
      otherAdjustments: z.number().default(0),
      net: z.number(),
      paid: z.number(),
      refunded: z.number(),
      due: z.number(),
      credit: z.number(),
      reserved: z.number(),
      lines: z.array(z.object({ name: z.string(), amount: z.number() })),
    }),
  ),
  payments: z.array(
    z.object({
      id,
      invoiceId: id,
      number: z.string(),
      amount: z.number(),
      postedAt: z.string(),
      method: z.string(),
      remaining: z.number(),
    }),
  ),
  discounts: z.array(
    z.object({
      id,
      admissionId: id,
      kind: z.string(),
      value: z.number(),
      startsOn: z.string(),
      endsOn: z.string(),
    }),
  ),
  refunds: z.array(
    z.object({
      id,
      invoiceId: id,
      paymentId: id,
      amount: z.number(),
      number: z.string().nullable(),
      postedAt: z.string().nullable(),
      method: z.string().nullable(),
      reference: z.string().nullable(),
    }),
  ),
  runs: z.array(
    z.object({
      id,
      period: z.string(),
      count: z.number(),
      gross: z.number(),
      postedAt: z.string(),
    }),
  ),
  paymentMethods: z.array(option),
});
export type FinanceWorkspace = z.infer<typeof financeWorkspaceSchema>;
export const previewSchema = z.object({
  period: z.string(),
  termId: id.nullable(),
  rows: z.array(
    z.object({
      admissionId: id,
      name: z.string(),
      number: z.string(),
      feePlanId: id,
      gross: z.number(),
      discount: z.number(),
      dueOn: z.string(),
    }),
  ),
  netTotal: z.number(),
  token: z.string(),
});
export type BillingPreview = z.infer<typeof previewSchema>;
