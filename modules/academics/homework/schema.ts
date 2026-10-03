import { z } from "zod";

const id = z.string().uuid();
export const homeworkWorkspaceSchema = z.object({
  assignment: z.object({ id, revision: z.number(), description: z.string(), submittedAt: z.string() }).nullable(),
  students: z.array(z.object({
    enrollmentId: id, studentNo: z.string(), name: z.string(), latestRevision: z.number().nullable(),
    status: z.enum(["NOT_SUBMITTED", "NEEDS_WORK", "COMPLETE"]).nullable(),
    submittedOn: z.string().nullable(), feedback: z.string().nullable(),
  })),
  history: z.array(z.object({
    id, enrollmentId: id, revision: z.number(), status: z.string(), submittedOn: z.string().nullable(),
    feedback: z.string(), recordedAt: z.string(),
  })),
});
export type HomeworkWorkspace = z.infer<typeof homeworkWorkspaceSchema>;

export const homeworkCommandSchema = z.object({
  request_id: id, session_id: id, class_log_id: id, enrollment_id: id,
  base_revision: z.number().int().min(0),
  status: z.enum(["NOT_SUBMITTED", "NEEDS_WORK", "COMPLETE"]),
  submitted_on: z.iso.date().optional(),
  feedback: z.string().trim().max(1000),
}).superRefine((value, ctx) => {
  if (value.status === "NEEDS_WORK" && value.feedback.length<5) ctx.addIssue({ code: "custom", path: ["feedback"], message: "Explain what needs attention." });
  if (value.status === "NOT_SUBMITTED" && value.submitted_on) ctx.addIssue({ code: "custom", path: ["submitted_on"], message: "Remove the submission date when work was not submitted." });
});
export type HomeworkCommand = z.infer<typeof homeworkCommandSchema>;
