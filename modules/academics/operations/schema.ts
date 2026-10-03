import { z } from "zod";
const id = z.string().uuid();
const date = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Choose a date.");
const unit = z.object({
  title: z.string().trim().min(2).max(200),
  target_date: date,
});
const entry = z.object({
  enrollment_id: id,
  status: z.enum(["PRESENT", "ABSENT", "LATE", "EXCUSED"]),
  note: z.string().trim().max(500),
});
export const academicCommandSchema = z
  .object({
    action: z.enum([
      "CREATE_ROOM",
      "PUBLISH_CURRICULUM",
      "CREATE_ROUTINE",
      "RETIRE_ROUTINE",
      "CREATE_SESSION",
      "GENERATE_SESSIONS",
      "CANCEL_SESSION",
      "SAVE_ATTENDANCE",
      "SUBMIT_ATTENDANCE",
      "DECIDE_ATTENDANCE",
    ]),
    request_id: id,
    reason: z
      .string()
      .trim()
      .min(5, "Enter a reason with at least five characters.")
      .max(500),
    branch_id: id.optional(),
    batch_id: id.optional(),
    subject_id: id.optional(),
    teacher_id: id.optional(),
    room_id: id.optional(),
    curriculum_id: id.optional(),
    routine_id: id.optional(),
    session_id: id.optional(),
    base_id: id.optional(),
    attendance_id: id.optional(),
    approval_id: id.optional(),
    name: z.string().trim().min(2).max(120).optional(),
    capacity: z.number().int().positive().max(10000).optional(),
    title: z.string().trim().min(2).max(200).optional(),
    units: z.array(unit).min(1).max(200).optional(),
    weekday: z.number().int().min(0).max(6).optional(),
    start_time: z
      .string()
      .regex(/^\d{2}:\d{2}$/)
      .optional(),
    end_time: z
      .string()
      .regex(/^\d{2}:\d{2}$/)
      .optional(),
    starts_on: date.optional(),
    ends_on: date.optional(),
    planned_scope: z.string().trim().min(2).max(2000).optional(),
    entries: z.array(entry).min(1).max(1000).optional(),
    decision: z.enum(["APPROVED", "REJECTED"]).optional(),
  })
  .superRefine((v, ctx) => {
    const required: Record<typeof v.action, string[]> = {
      CREATE_ROOM: ["branch_id", "name", "capacity"],
      PUBLISH_CURRICULUM: ["batch_id", "subject_id", "title", "units"],
      CREATE_ROUTINE: [
        "batch_id",
        "subject_id",
        "teacher_id",
        "room_id",
        "weekday",
        "start_time",
        "end_time",
        "starts_on",
        "ends_on",
      ],
      RETIRE_ROUTINE: ["routine_id"],
      CREATE_SESSION: [
        "batch_id",
        "subject_id",
        "teacher_id",
        "room_id",
        "starts_on",
        "start_time",
        "end_time",
        "planned_scope",
      ],
      GENERATE_SESSIONS: [
        "routine_id",
        "starts_on",
        "ends_on",
        "planned_scope",
      ],
      CANCEL_SESSION: ["session_id"],
      SAVE_ATTENDANCE: ["session_id", "entries"],
      SUBMIT_ATTENDANCE: ["session_id", "attendance_id"],
      DECIDE_ATTENDANCE: ["approval_id", "decision"],
    };
    for (const k of required[v.action])
      if (v[k as keyof typeof v] === undefined)
        ctx.addIssue({
          code: "custom",
          path: [k],
          message: "This field is required.",
        });
    if (v.starts_on && v.ends_on && v.ends_on < v.starts_on)
      ctx.addIssue({
        code: "custom",
        path: ["ends_on"],
        message: "End date must follow start date.",
      });
    if (v.start_time && v.end_time && v.end_time <= v.start_time)
      ctx.addIssue({
        code: "custom",
        path: ["end_time"],
        message: "End time must follow start time on the same day.",
      });
  });
export type AcademicCommand = z.infer<typeof academicCommandSchema>;
const option = z.object({ id, name: z.string() });
export const academicWorkspaceSchema = z.object({
  branches: z.array(option),
  batches: z.array(option.extend({ branchId: id, capacity: z.number() })),
  subjects: z.array(option),
  teachers: z.array(option.extend({ subjects: z.array(id) })),
  rooms: z.array(option.extend({ branchId: id, capacity: z.number() })),
  curricula: z.array(
    z.object({
      id,
      batchId: id,
      subjectId: id,
      batch: z.string(),
      subject: z.string(),
      version: z.number(),
      title: z.string(),
      units: z.array(unit),
    }),
  ),
  routines: z.array(
    z.object({
      id,
      batchId: id,
      subjectId: id,
      batch: z.string(),
      subject: z.string(),
      teacher: z.string(),
      room: z.string(),
      weekday: z.number(),
      startTime: z.string(),
      endTime: z.string(),
      startsOn: z.string(),
      endsOn: z.string(),
      retired: z.boolean(),
    }),
  ),
  sessions: z.array(
    z.object({
      id,
      batch: z.string(),
      subject: z.string(),
      teacher: z.string(),
      room: z.string(),
      date: z.string(),
      startTime: z.string(),
      endTime: z.string(),
      timezone: z.string(),
      status: z.string(),
      scope: z.string(),
      latestStatus: z.string().nullable(),
      approvedRevision: z.number().nullable(),
    }),
  ),
});
export type AcademicWorkspace = z.infer<typeof academicWorkspaceSchema>;
const rosterEntry = z.object({
  enrollment_id: id,
  student_id: id,
  number: z.string(),
  name: z.string(),
  status: z.enum(["PRESENT", "ABSENT", "LATE", "EXCUSED"]).optional(),
  note: z.string().optional(),
});
export const sessionWorkspaceSchema = z.object({
  session: z.object({
    id,
    batch: z.string(),
    subject: z.string(),
    teacher: z.string(),
    teacherProfileId: id.nullable(),
    room: z.string(),
    date: z.string(),
    canRecordNow: z.boolean(),
    startsAt: z.string(),
    endsAt: z.string(),
    timezone: z.string(),
    status: z.string(),
    scope: z.string(),
    cancellationReason: z.string().nullable(),
    curriculumTitle: z.string().nullable(),
    curriculumVersion: z.number().nullable(),
    units: z.array(unit),
  }),
  roster: z.array(rosterEntry),
  submissions: z.array(
    z.object({
      id,
      revision: z.number(),
      status: z.string(),
      entries: z.array(rosterEntry),
      reason: z.string(),
      recordedBy: id,
      recorder: z.string(),
      createdAt: z.string(),
      approvalId: id.nullable(),
      decisionNote: z.string().nullable(),
    }),
  ),
});
export type SessionWorkspace = z.infer<typeof sessionWorkspaceSchema>;

export const classLogCommandSchema = z
  .object({
    action: z.enum(["SAVE_DRAFT", "SUBMIT"]),
    request_id: id,
    session_id: id,
    reason: z.string().trim().min(5).max(500),
    unit_progress: z
      .array(
        z.object({
          unit_index: z.number().int().min(0),
          status: z.enum(["COVERED", "PARTIAL", "NOT_COVERED"]),
          note: z.string().max(500),
        }),
      )
      .max(200),
    class_summary: z.string().trim().min(2).max(4000),
    unfinished_reason: z.string().max(2000),
    homework: z.string().max(2000),
    next_session_plan: z.string().max(2000),
  })
  .superRefine((v, ctx) => {
    if (
      v.unit_progress.some((x) => x.status !== "COVERED") &&
      !v.unfinished_reason.trim()
    )
      ctx.addIssue({
        code: "custom",
        path: ["unfinished_reason"],
        message: "Explain planned curriculum left incomplete.",
      });
  });
export const classLogWorkspaceSchema = z.object({
  units: z.array(
    z.object({ title: z.string(), target_date: z.string() }).passthrough(),
  ),
  logs: z.array(
    z.object({
      id: id,
      session_id: id,
      revision: z.number(),
      previous_log_id: id.nullable(),
      status: z.enum(["DRAFT", "SUBMITTED"]),
      unit_progress: z.array(
        z.object({
          unit_index: z.number(),
          status: z.enum(["COVERED", "PARTIAL", "NOT_COVERED"]),
          note: z.string(),
        }),
      ),
      class_summary: z.string(),
      unfinished_reason: z.string(),
      homework: z.string(),
      next_session_plan: z.string(),
      reason: z.string(),
      authored_by: id,
      created_at: z.string(),
      submitted_at: z.string().nullable(),
    }),
  ),
});
export type ClassLogCommand = z.infer<typeof classLogCommandSchema>;
export type ClassLogWorkspace = z.infer<typeof classLogWorkspaceSchema>;
