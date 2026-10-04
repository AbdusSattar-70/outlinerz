import { z } from "zod";
const id = z.string().uuid();
export const studentCommandSchema = z
  .object({
    action: z.enum([
      "CREATE_EXISTING",
      "TRANSFER",
      "MERGE",
    ]),
    request_id: id,
    student_id: id.optional(),
    batch_id: id.optional(),
    admission_id: id.optional(),
    target_id: id.optional(),
    confirmed_same_person: z.boolean().optional(),
    reason: z
      .string()
      .trim()
      .min(5, "Explain the reason in at least five characters.")
      .max(500),
  })
  .superRefine((v, ctx) => {
    const required = {
      CREATE_EXISTING: ["student_id", "batch_id"],
      TRANSFER: ["student_id", "admission_id", "batch_id"],
      MERGE: ["student_id", "target_id"],
    }[v.action];
    for (const key of required)
      if (!v[key as keyof typeof v])
        ctx.addIssue({
          code: "custom",
          path: [key],
          message: "Select a valid option.",
        });
    if (v.action === "MERGE" && !v.confirmed_same_person)
      ctx.addIssue({
        code: "custom",
        path: ["confirmed_same_person"],
        message: "Verify these records belong to the same student.",
      });
  });
export type StudentCommand = z.infer<typeof studentCommandSchema>;
const identity = z.object({ id, name: z.string(), number: z.string() });
export const profileSchema = z.object({
  student: identity.extend({
    nameBn: z.string().nullable(),
    status: z.string(),
    birthDate: z.string().nullable(),
    school: z.string().nullable(),
    createdAt: z.string(),
    canonicalId: id,
    canonicalNumber: z.string(),
  }),
  identities: z.array(identity),
  guardians: z.array(
    z.object({
      id,
      studentId: id,
      name: z.string(),
      mobile: z.string(),
      alternateMobile: z.string().nullable(),
      relationship: z.string().nullable(),
      primary: z.boolean(),
    }),
  ),
  enrollments: z.array(
    z.object({
      id,
      studentId: id,
      year: z.string(),
      class: z.string(),
      batch: z.string().nullable(),
      status: z.string(),
      startsOn: z.string(),
      endsOn: z.string().nullable(),
    }),
  ),
  admissions: z.array(
    z.object({
      id,
      number: z.string(),
      studentId: id,
      batchId: id,
      offeringId: id,
      batch: z.string(),
      status: z.string(),
      createdAt: z.string(),
      feeVersion: z.number().nullable(),
    }),
  ),
  batches: z.array(
    z.object({
      id,
      name: z.string(),
      offeringId: id,
      offering: z.string(),
      year: z.string(),
      class: z.string(),
      capacity: z.number(),
      occupied: z.number(),
    }),
  ),
  financeVisible: z.boolean(),
  invoices: z.array(
    z.object({
      id,
      studentId: id,
      number: z.string(),
      period: z.string(),
      gross: z.number(),
      credits: z.number(),
      paid: z.number(),
      refunded: z.number(),
      due: z.number(),
      credit: z.number(),
    }),
  ),
  transfers: z.array(
    z.object({
      id,
      fromBatch: z.string(),
      toBatch: z.string(),
      date: z.string(),
      authorizedBy: id,
    }),
  ),
  candidates: z.array(
    identity.extend({
      status: z.string(),
      birthDate: z.string().nullable(),
      school: z.string().nullable(),
      mobile: z.string().nullable(),
    }),
  ),

});
export type StudentProfile = z.infer<typeof profileSchema>;
