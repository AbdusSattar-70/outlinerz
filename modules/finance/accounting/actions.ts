"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import type { SupabaseClient } from "@supabase/supabase-js";
import { requireErpContext } from "@/modules/platform/auth/erp-context";
import { createClient } from "@/lib/supabase/server";

const commands = {
  CREATE_ACCOUNT: "accounting.manage",
  CREATE_VENDOR: "finance.advances.manage",
  CREATE_ADVANCE: "finance.advances.manage",
  PAY_ADVANCE: "finance.advances.manage",
  APPLY_ADVANCE: "finance.advances.manage",
  REFUND_ADVANCE: "finance.advances.manage",
  CREATE_EXPENSE_DIRECT: "accounting.expense.manage",
  SETTLE_PAYABLE: "finance.payments.post",
  RECONCILE_EXPENSE: "accounting.reconcile",
  RECONCILE_ACCOUNT: "accounting.reconcile",
  RUN_COMPENSATION: "staff.compensation.manage",
  SETTLE_COMPENSATION: "staff.compensation.manage",
  APPLY_COMP_ADJUSTMENT: "staff.compensation.manage",
} as const;

type Command = keyof typeof commands;
const inputSchema = z.object({
  request_id: z.string().uuid(),
  action: z.enum(Object.keys(commands) as [Command, ...Command[]]),
  reason: z.string().trim().min(5).max(1000),
  values: z.record(z.string(), z.union([z.string(), z.number()])).default({}),
});

export async function submitAccountingCommand(input: unknown): Promise<{ ok: boolean; message: string }> {
  const parsed = inputSchema.safeParse(input);
  if (!parsed.success) return { ok: false, message: parsed.error.issues.some(i => i.path[0] === "reason") ? "Reason needs at least five characters after removing spaces. Your entries have been kept." : "Choose a valid action and check the entered details." };
  try {
  const context = await requireErpContext();
  const permission = commands[parsed.data.action];
  if (!context.permissions.includes(permission)) return { ok: false, message: "You do not have permission for this action." };
  const supabase = (await createClient()) as unknown as SupabaseClient;
  const { data, error } = await supabase.rpc("finance_accounting_command", {
    p_input: {
      ...parsed.data.values,
      action: parsed.data.action,
      reason: parsed.data.reason,
      request_id: parsed.data.request_id,
    },
  });
  if (error) return { ok: false, message: error.message };
  revalidatePath("/dashboard/finance/accounting");
  return { ok: true, message: (data as { message?: string } | null)?.message ?? "Finance action completed." };
  } catch { return {ok:false,message:"Could not confirm the result. Check the record before changing inputs; retrying unchanged inputs uses the same request identity."}; }
}
