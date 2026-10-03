"use server";
import {
  runCommandAction,
  revalidateDashboard,
} from "@/modules/platform/command-action";
import { studentClient } from "./queries";
import { studentCommandSchema, type StudentCommand } from "./schema";

export async function runStudentCommand(input: StudentCommand) {
  return runCommandAction<StudentCommand, { message: string; admissionId?: string }>(
    {
      schema: studentCommandSchema,
      input,
      client: studentClient,
      rpc: "student_command",
      permission: "students.view",
      revalidate: [
        "/dashboard/students",
        "/dashboard/admissions",
        "/dashboard/academics/batches",
        "/dashboard/finance/billing",
        "/dashboard/governance/approvals",
        "/dashboard/governance/audit",
        "/dashboard/action-center",
        "/dashboard",
      ],
      revalidateExtra: () =>
        revalidateDashboard("/dashboard/students/[studentId]"),
      emptyMessage: "Student command returned no response.",
      mapResult: (data) => {
        const result = data as { id?: string; message?: string };
        if (!result?.id || !result.message)
          return { ok: false, message: "Student command returned no response." };
        return {
          message: result.message,
          admissionId:
            input.action === "CREATE_EXISTING" ? result.id : undefined,
        };
      },
    },
  );
}
