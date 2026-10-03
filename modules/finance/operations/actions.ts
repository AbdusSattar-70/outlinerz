"use server";
import { revalidatePath } from "next/cache";
import { z } from "zod";
import { getErpContext } from "@/modules/platform/auth/erp-context";
import { financeClient } from "./queries";
import {
  financeCommandSchema,
  previewSchema,
  type FinanceCommand,
} from "./schema";
export async function runFinanceCommand(input: FinanceCommand) {
  const parsed = financeCommandSchema.safeParse(input);
  if (!parsed.success)
    return { ok: false, message: parsed.error.issues[0].message };
  if (!(await getErpContext()))
    return { ok: false, message: "Sign in to continue." };
  // Every command enforces permission, idempotency and ledger integrity atomically in the database.
  const db = await financeClient();
  const { data, error } = await db.rpc(
    input.action === "PAY" ? "post_admission_payment" : "finance_command",
    { p_input: parsed.data },
  );
  if (error) return { ok: false, message: error.message };
  for (const path of [
    "/dashboard/finance/billing",
    "/dashboard/admissions",
    "/dashboard/students",
    "/dashboard/academics/batches",
    "/dashboard/governance/approvals",
    "/dashboard/governance/audit",
    "/dashboard",
  ])
    revalidatePath(path);
  const result = data as { message?: string; receipt_no?: string };
  return {
    ok: true,
    message: result.message ?? `Payment posted. Receipt ${result.receipt_no}.`,
  };
}
export async function previewBilling(period: string, termId?: string) {
  const parsed = z
    .object({
      period: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
      termId: z.string().uuid().optional(),
    })
    .safeParse({ period, termId });
  if (!parsed.success)
    return { ok: false as const, message: "Choose a billing month or term." };
  const db = await financeClient();
  const { data, error } = await db.rpc("billing_preview", {
    p_period: period,
    ...(termId ? { p_term_id: termId } : {}),
  });
  if (error) return { ok: false as const, message: error.message };
  return { ok: true as const, data: previewSchema.parse(data) };
}
