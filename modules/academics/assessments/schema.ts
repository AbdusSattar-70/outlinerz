import { z } from "zod";
const id = z.string().uuid();
const entry = z.object({ enrollment_id: id, score: z.number().min(0).max(1000), feedback: z.string().trim().max(500) });
export const assessmentCommandSchema = z.discriminatedUnion("action", [
  z.object({ action: z.literal("CREATE"), request_id:id, batch_id:id, subject_id:id, title:z.string().trim().min(3).max(180), assessment_date:z.iso.date(), max_marks:z.number().positive().max(1000) }),
  z.object({ action: z.literal("PUBLISH"), request_id:id, assessment_id:id }),
  z.object({ action: z.literal("SAVE_RESULTS"), request_id:id, assessment_id:id, entries:z.array(entry).min(1).max(500) }),
  z.object({ action: z.literal("SUBMIT_RESULTS"), request_id:id, assessment_id:id }),
  z.object({ action: z.enum(["APPROVE_RESULTS","REJECT_RESULTS"]), request_id:id, assessment_id:id, review_note:z.string().trim().min(5).max(1000) }),
]);
export type AssessmentCommand = z.infer<typeof assessmentCommandSchema>;
export const assessmentWorkspaceSchema = z.object({
  scopes:z.array(z.object({batchId:id,subjectId:id,batch:z.string(),subject:z.string()})),
  assessments:z.array(z.object({
    id,batchId:id,subjectId:id,batch:z.string(),subject:z.string(),title:z.string(),date:z.string(),
    maxMarks:z.number(),status:z.enum(["DRAFT","PUBLISHED","CANCELLED"]),authorId:id,
    roster:z.array(z.object({enrollmentId:id,studentNo:z.string(),name:z.string()})),
    submissions:z.array(z.object({
      id,revision:z.number(),status:z.enum(["DRAFT","SUBMITTED","APPROVED","REJECTED"]),
      entries:z.array(entry),authorId:id,reviewNote:z.string().nullable(),createdAt:z.string(),
    })),
  })),
});
export type AssessmentWorkspace = z.infer<typeof assessmentWorkspaceSchema>;
