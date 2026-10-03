import type { SupabaseClient } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";

export type FinanceAccountingWorkspaceData = {
  operatingSummary:{revenue:number;discountsAndReversals:number;expenses:number;profitLoss:number};
  permissions: string[];
  currentProfileId: string;
  staff: Array<{ id: string; name: string }>;
  vendors: Array<{ id: string; name: string }>;
  categories: Array<{ id: string; name: string }>;
  externalReferrals: Array<{ admissionId:string; referrer:string; student:string; awardStatus:string|null }>;
  compensationLines: Array<{ runId: string; teacherId: string; teacher: string; amount: number }>;
  accounts: Array<{ id: string; code: string; name: string; accountType: string; subtype: string; balance: number }>;
  payables: Array<{ id: string; number: string; type: string; referrerId:string|null; beneficiary: string; amount: number; status: string; dueOn: string | null; remaining: number }>;
  advances: Array<{ id: string; number: string; beneficiary: string; purpose: string; requestedAmount: number; balance: number; status: string; expectedDate: string | null }>;
  expenses: Array<{ id: string; number: string; date: string; description: string; amount: number; status: string }>;
  compensation: Array<{ id: string; runNo: string; from: string; to: string; total: number; status: string }>;
};

function relatedRecord<T>(value: T | T[] | null | undefined): T | undefined {
  return Array.isArray(value) ? value[0] : value ?? undefined;
}

export async function getFinanceAccountingWorkspace(): Promise<FinanceAccountingWorkspaceData> {
  const supabase = (await createClient()) as unknown as SupabaseClient;
  const context = await (await import("@/modules/platform/auth/erp-context")).requireErpContext();
  const [
    summaryResult, referralResult, referralAwardsResult,
    staffResult, vendorsResult, categoriesResult, linesResult, settlementsResult,
    accountsResult,
    payablesResult,
    advancesResult,
    expensesResult,
    compensationResult,
    movementsResult,
  ] = await Promise.all([
    supabase.rpc("finance_operating_summary"),
    supabase.from("admission_referrals").select("admission_id,source,referrer:referrer_id(id,full_name,staff_id),admission:admission_id(identity_snapshot,status)").eq("source","REFERRED"),
    supabase.from("referral_bonus_awards").select("admission_id,status"),
    supabase.from("staff").select("id,full_name").eq("status", "ACTIVE").order("full_name"),
    supabase.from("vendors").select("id,name").order("name"),
    supabase.from("finance_expense_categories").select("id,name").eq("is_active",true).order("name"),
    supabase.from("teacher_compensation_lines").select("run_id,teacher_id,amount,staff:teacher_id(full_name)"),
    supabase.from("finance_payable_settlements").select("payable_id,amount"),
    supabase.from("finance_accounts").select("id,code,name,account_type,account_subtype").eq("is_active", true).order("code"),
    supabase.from("finance_payables").select("id,payable_no,payable_type,referrer_id,original_amount,status,due_on,staff:staff_id(full_name),vendor:vendor_id(name),referrer:referrer_id(full_name)").neq("status", "VOIDED").order("due_on"),
    supabase.from("finance_advances").select("id,advance_no,beneficiary_type,purpose,requested_amount,status,expected_settlement_date,staff:staff_id(full_name),vendor:vendor_id(name)").order("created_at", { ascending: false }),
    supabase.from("finance_expenses").select("id,expense_no,expense_date,description,amount,status").order("expense_date", { ascending: false }),
    supabase.from("teacher_compensation_runs").select("id,run_no,period_start,period_end,total_amount,status").order("period_end", { ascending: false }),
    supabase.from("finance_advance_movements").select("advance_id,movement_type,amount"),
  ]);

  for (const result of [summaryResult,referralResult,referralAwardsResult,staffResult,vendorsResult,categoriesResult,linesResult,settlementsResult,accountsResult, payablesResult, advancesResult, expensesResult, compensationResult, movementsResult]) {
    if (result.error) throw new Error(result.error.message);
  }

  const summary=summaryResult.data as {revenue:number;discountsAndReversals:number;expenses:number;profitLoss:number;balances:Record<string,number>};
  const accounts=(accountsResult.data??[]).map(account=>({id:account.id,code:account.code,name:account.name,accountType:account.account_type,subtype:account.account_subtype,balance:Number(summary.balances[account.id]??0)}));

  const advanceBalances = new Map<string, number>();
  for (const movement of movementsResult.data ?? []) {
    const signed = movement.movement_type === "PAYMENT"
      ? Number(movement.amount) : -Number(movement.amount);
    advanceBalances.set(movement.advance_id,
      (advanceBalances.get(movement.advance_id) ?? 0) + signed);
  }

  const paidByPayable = new Map<string,number>();
  for (const row of settlementsResult.data ?? []) paidByPayable.set(row.payable_id,(paidByPayable.get(row.payable_id) ?? 0)+Number(row.amount));
  const compensationLines = new Map<string,{ runId:string; teacherId:string; teacher:string; amount:number }>();
  for (const row of linesResult.data ?? []) {
    const key = `${row.run_id}:${row.teacher_id}`;
    const current = compensationLines.get(key);
    compensationLines.set(key,{ runId:row.run_id, teacherId:row.teacher_id, teacher:relatedRecord(row.staff)?.full_name ?? "Teacher", amount:(current?.amount ?? 0)+Number(row.amount) });
  }
  return {
    operatingSummary:summary,
    permissions:context.permissions,
    currentProfileId:context.profileId,
    staff:(staffResult.data ?? []).map(x=>({id:x.id,name:x.full_name})),
    vendors:(vendorsResult.data ?? []).map(x=>({id:x.id,name:x.name})),
    categories:(categoriesResult.data ?? []).map(x=>({id:x.id,name:x.name})),
    externalReferrals:(referralResult.data??[]).filter(r=>relatedRecord(r.referrer)&&!relatedRecord(r.referrer)?.staff_id&&relatedRecord(r.admission)?.status==="ACTIVE_ENROLLMENT")
      .map(r=>({admissionId:r.admission_id,referrer:relatedRecord(r.referrer)?.full_name??"Unknown",student:String((relatedRecord(r.admission)?.identity_snapshot as Record<string,unknown>|null)?.student_name??"Student"),
        awardStatus:(referralAwardsResult.data??[]).find(a=>a.admission_id===r.admission_id)?.status??null})),
    compensationLines:[...compensationLines.values()],
    accounts,
    payables: (payablesResult.data ?? []).map((row) => ({
      id: row.id,
      number: row.payable_no,
      type: row.payable_type,referrerId:row.referrer_id,
      beneficiary: relatedRecord(row.staff)?.full_name ?? relatedRecord(row.vendor)?.name ?? relatedRecord(row.referrer)?.full_name ?? "Other",
      amount: Number(row.original_amount),
      status: row.status,
      dueOn: row.due_on,
      remaining: Number(row.original_amount)-(paidByPayable.get(row.id) ?? 0),
    })),
    advances: (advancesResult.data ?? []).map((row) => ({
      id: row.id,
      number: row.advance_no,
      beneficiary: relatedRecord(row.staff)?.full_name ?? relatedRecord(row.vendor)?.name ?? row.beneficiary_type,
      purpose: row.purpose,
      requestedAmount: Number(row.requested_amount),
      balance: advanceBalances.get(row.id) ?? 0,
      status: row.status,
      expectedDate: row.expected_settlement_date,
    })),
    expenses: (expensesResult.data ?? []).map((row) => ({
      id: row.id,
      number: row.expense_no,
      date: row.expense_date,
      description: row.description,
      amount: Number(row.amount),
      status: row.status,
    })),
    compensation: (compensationResult.data ?? []).map((row) => ({
      id: row.id,
      runNo: row.run_no,
      from: row.period_start,
      to: row.period_end,
      total: Number(row.total_amount),
      status: row.status,
    })),
  };
}
