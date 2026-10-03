"use server";
import { runCommandAction, revalidateDashboard } from "@/modules/platform/command-action";
import { academicClient } from "./queries";
import {
  academicCommandSchema,
  classLogCommandSchema,
  type AcademicCommand,
  type ClassLogCommand,
} from "./schema";

/** Routes affected by academic command mutations. */
export const ACADEMIC_COMMAND_PATHS = [
  "/dashboard/academics/operations",
  "/dashboard/governance/approvals",
  "/dashboard/governance/audit",
  "/dashboard/action-center",
  "/dashboard",
  "/dashboard/teacher",
] as const;

/** Routes affected by class-log mutations. */
export const CLASS_LOG_PATHS = [
  "/dashboard/teacher",
  "/dashboard/academics/operations",
  "/dashboard/action-center",
] as const;

export async function runAcademicCommand(input: AcademicCommand) {
  return runCommandAction<AcademicCommand, { message: string }>({
    schema: academicCommandSchema,
    input,
    client: academicClient,
    rpc: "academic_command",
    permission: "academics.view",
    revalidate: [...ACADEMIC_COMMAND_PATHS],
    revalidateExtra: () =>
      revalidateDashboard("/dashboard/academics/sessions/[sessionId]"),
  });
}

export async function runClassLogCommand(input: ClassLogCommand) {
  return runCommandAction<ClassLogCommand, { message: string }>({
    schema: classLogCommandSchema,
    input,
    client: academicClient,
    rpc: "class_log_command",
    permission: ["academics.attendance.record", "academics.sessions.manage"],
    revalidate: [...CLASS_LOG_PATHS],
    emptyMessage: "Class-log command returned no response.",
    revalidateExtra: () =>
      revalidateDashboard("/dashboard/academics/sessions/[sessionId]"),
  });
}
