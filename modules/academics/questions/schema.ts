import { z } from "zod";

const uuid = z.string().uuid();
const content = z.object({
  topic: z.string().trim().min(2).max(180),
  difficulty: z.enum(["FOUNDATION", "STANDARD", "ADVANCED"]),
  question_type: z.enum(["MCQ", "SHORT_ANSWER"]),
  prompt: z.string().trim().min(10).max(3000),
  choices: z.array(z.string().trim().min(1).max(500)).max(6),
  answer_key: z.string().trim().min(1).max(1500),
  explanation: z.string().trim().max(3000),
}).superRefine((value, ctx) => {
  if (value.question_type === "MCQ" && (value.choices.length < 2 || !"ABCDEF".slice(0, value.choices.length).includes(value.answer_key))) {
    ctx.addIssue({ code: "custom", path: ["answer_key"], message: "Provide at least two choices and a matching answer letter." });
  }
  if (value.question_type === "SHORT_ANSWER" && value.choices.length) {
    ctx.addIssue({ code: "custom", path: ["choices"], message: "Short answer questions cannot have choices." });
  }
});

export const questionCommandSchema = z.discriminatedUnion("action", [
  z.object({ action: z.literal("CREATE_DRAFT"), request_id: uuid, batch_id: uuid, subject_id: uuid, curriculum_version_id: uuid.optional(), topic: z.string(), difficulty: z.enum(["FOUNDATION", "STANDARD", "ADVANCED"]), question_type: z.enum(["MCQ", "SHORT_ANSWER"]), prompt: z.string(), choices: z.array(z.string()), answer_key: z.string(), explanation: z.string() }),
  z.object({ action: z.literal("EDIT_DRAFT"), request_id: uuid, item_id: uuid, topic: z.string(), difficulty: z.enum(["FOUNDATION", "STANDARD", "ADVANCED"]), question_type: z.enum(["MCQ", "SHORT_ANSWER"]), prompt: z.string(), choices: z.array(z.string()), answer_key: z.string(), explanation: z.string() }),
  z.object({ action: z.enum(["SUBMIT", "REVISE_REJECTED"]), request_id: uuid, item_id: uuid }),
  z.object({ action: z.enum(["APPROVE", "REJECT"]), request_id: uuid, item_id: uuid, review_note: z.string().trim().min(5).max(1000) }),
]).superRefine((value, ctx) => {
  if (value.action === "CREATE_DRAFT" || value.action === "EDIT_DRAFT") {
    const checked = content.safeParse(value);
    if (!checked.success) checked.error.issues.forEach((issue) => ctx.addIssue({ code: "custom", path: issue.path, message: issue.message }));
  }
});
export type QuestionCommand = z.infer<typeof questionCommandSchema>;

export const questionWorkspaceSchema = z.object({
  batches: z.array(z.object({ id: uuid, name: z.string() })),
  subjects: z.array(z.object({ id: uuid, name: z.string() })),
  items: z.array(z.object({
    id: uuid, rootId: uuid.nullable(), revision: z.number(), batchId: uuid, batch: z.string(),
    subjectId: uuid, subject: z.string(), curriculumVersionId: uuid.nullable(),
    topic: z.string(), difficulty: z.string(), questionType: z.string(), prompt: z.string(),
    choices: z.array(z.string()), answerKey: z.string(), explanation: z.string().nullable(),
    status: z.enum(["DRAFT", "SUBMITTED", "APPROVED", "REJECTED"]),
    authorId: uuid, author: z.string(), reviewNote: z.string().nullable(), createdAt: z.string(),
  })),
});
export type QuestionWorkspace = z.infer<typeof questionWorkspaceSchema>;
