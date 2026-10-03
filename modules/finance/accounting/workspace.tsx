"use client";
import Link from "next/link";

import { useEffect, useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { submitAccountingCommand } from "./actions";

import type { FinanceAccountingWorkspaceData } from "./queries";

function money(value: number) {
  return new Intl.NumberFormat("en-BD", { style: "currency", currency: "BDT", maximumFractionDigits: 2 }).format(value);
}

type Field = { name: string; label: string; type?: string; options?: Array<{ id: string; name: string }>; required?: boolean };


export function FinanceAccountingWorkspace({ initialData: data }: { initialData: FinanceAccountingWorkspaceData }) {
  const router = useRouter();
  const request = useRef({signature:"",id:""});
  const formRef = useRef<HTMLFormElement>(null);
  const [operation, setOperation] = useState<{ action: string; title: string; fields: Field[]; preset?: Record<string,string> } | null>(null);
  useEffect(()=>{if(operation){formRef.current?.scrollIntoView({block:"start"});formRef.current?.querySelector<HTMLElement>("input,select,textarea")?.focus();}},[operation]);
  const [feedback, setFeedback] = useState("");
  const [pending, startTransition] = useTransition();
  const cash = data.accounts.filter(x=>["CASH","BANK","MOBILE_BANK"].includes(x.subtype)).map(x=>({id:x.id,name:`${x.code} · ${x.name}`}));
  const choose = (action: string, title: string, fields: Field[], preset?: Record<string,string>) => {
    if(pending)return;request.current={signature:"",id:""};
    setFeedback("");setOperation({action,title,fields,preset});
  };
  const field = (name:string,label:string,type="text",options?:Field["options"]):Field=>({name,label,type,options,required:!["staff_id","vendor_id","project_reference","expected_settlement_date","payment_account_id","receipt_reference","external_reference","advance_offset","adjustment_type","mobile","email","address","service_category","parent_id"].includes(name)});
  const permitted = (permission:string)=>data.permissions.includes(permission);
  const paymentFields = [field("amount","Amount (BDT)","number"),field("payment_account_id","Cash or bank account","select",cash),field("external_reference","Bank or receipt reference")];

  return <div className="space-y-6">
    {feedback && <p role="status" className="rounded-xl border bg-card p-4 text-sm">{feedback}</p>}
    <section className="grid gap-4 md:grid-cols-4">
      <Summary title="Cash / Bank" value={money(data.accounts.filter(x=>["CASH","BANK","MOBILE_BANK"].includes(x.subtype)).reduce((s,x)=>s+x.balance,0))}/>
      <Summary title="Student Receivables" value={money(data.accounts.find(x=>x.subtype==="STUDENT_RECEIVABLE")?.balance??0)}/>
      <Summary title="Teacher Payable" value={money(data.accounts.find(x=>x.subtype==="TEACHER_PAYABLE")?.balance??0)}/>
      <Summary title="Open Advances" value={money(data.advances.filter(x=>!["SETTLED","REFUNDED","REJECTED"].includes(x.status)).reduce((s,x)=>s+x.balance,0))}/>
    </section>
    <section className="rounded-2xl border bg-card p-5">
      <h2 className="text-lg font-semibold">Finance actions</h2>
      <p className="mt-1 text-sm text-muted-foreground">Authorized actions post directly and remain audited. Every posted payment needs a reason and a bank or receipt reference.</p>
      <div className="mt-4 flex flex-wrap gap-2">
        {permitted("accounting.manage") && <Action onClick={()=>choose("CREATE_ACCOUNT","Create financial account",[field("code","Account code"),field("name","Account name"),field("account_type","Account type","select",["ASSET","LIABILITY","EQUITY","REVENUE","CONTRA_REVENUE","EXPENSE"].map(x=>({id:x,name:x}))),field("account_subtype","Account category"),field("parent_id","Parent account (optional)","select",data.accounts.map(x=>({id:x.id,name:`${x.code} · ${x.name}`})))])}>Create account</Action>}
        {permitted("finance.advances.manage") && <Action onClick={()=>choose("CREATE_VENDOR","Create vendor",[field("name","Vendor name"),field("mobile","Mobile"),field("email","Email","email"),field("address","Address"),field("service_category","Service category")])}>Create vendor</Action>}
        {permitted("accounting.reconcile") && <Action onClick={()=>choose("RECONCILE_ACCOUNT","Reconcile cash or bank",[field("account_id","Cash or bank account","select",cash),field("statement_date","Statement date","date"),field("statement_reference","Statement reference"),field("statement_balance","Statement balance","number")])}>Reconcile account</Action>}
        {permitted("finance.advances.manage") && <Action onClick={()=>choose("CREATE_ADVANCE","Create advance",[field("beneficiary_type","Beneficiary type","select",[{id:"STAFF",name:"Staff"},{id:"VENDOR",name:"Vendor"},{id:"PROJECT",name:"Project"}]),field("staff_id","Staff (for staff advances)","select",data.staff),field("vendor_id","Vendor (for vendor advances)","select",data.vendors),field("project_reference","Project reference (for project advances)"),field("purpose","Purpose"),field("requested_amount","Requested amount","number"),field("expected_settlement_date","Expected settlement date","date")])}>Create advance</Action>}
        {permitted("accounting.expense.manage") && <Action onClick={()=>choose("CREATE_EXPENSE_DIRECT","Post expense",[field("expense_date","Expense date","date"),field("category_id","Expense category","select",data.categories),field("description","Description"),field("amount","Amount","number"),field("payment_mode","Payment mode","select",[{id:"PAID_NOW",name:"Paid now"},{id:"ON_ACCOUNT",name:"Pay later"}]),field("payment_account_id","Cash or bank (when paid now)","select",cash),field("vendor_id","Vendor (when payable to vendor)","select",data.vendors),field("staff_id","Staff (when reimbursing staff)","select",data.staff),field("receipt_reference","Receipt reference")])}>Post expense</Action>}
        {permitted("staff.compensation.manage") && <Action onClick={()=>choose("RUN_COMPENSATION","Prepare monthly compensation",[field("period_start","First day of month","date"),field("period_end","Last day of month","date")])}>Prepare compensation</Action>}
        {permitted("staff.compensation.manage") && <Action onClick={()=>choose("APPLY_COMP_ADJUSTMENT","Apply compensation adjustment",[field("teacher_id","Teacher","select",data.staff),field("amount","Amount","number"),field("effective_period","Effective month (first day)","date"),field("adjustment_type","Adjustment type","select",[{id:"ADJUSTMENT",name:"Adjustment"},{id:"GROWTH_BONUS",name:"Growth bonus"}])])}>Apply adjustment</Action>}
      </div>
    </section>
    <section className="rounded-2xl border bg-card p-5"><h2 className="font-semibold">Academy operating result · all posted history</h2><p className="mt-2 text-sm text-muted-foreground">Accrual accounting: billed revenue less discounts/reversals and posted expenses, including referral rewards. Money paid to settle a payable is not another expense.</p><div className="mt-4 grid gap-3 sm:grid-cols-4"><Summary title="Revenue" value={money(data.operatingSummary.revenue)}/><Summary title="Discounts / reversals" value={money(data.operatingSummary.discountsAndReversals)}/><Summary title="Posted expenses" value={money(data.operatingSummary.expenses)}/><Summary title="Profit / loss" value={money(data.operatingSummary.profitLoss)}/></div><Link className="mt-4 inline-block underline" href="/dashboard/referrals">Manage referrers, collection rewards and settlements</Link></section>
    <section className="rounded-2xl border bg-card p-5">
      <h2 className="text-lg font-semibold">Chart of accounts</h2>
      <p className="mt-1 text-sm text-muted-foreground">Current posted balances. Amounts include only approved ledger entries.</p>
      <div className="mt-4 overflow-x-auto"><table className="w-full text-sm"><thead><tr className="border-b text-left"><th className="py-2">Code</th><th>Name</th><th>Type</th><th className="text-right">Balance</th></tr></thead><tbody>{data.accounts.map(a=><tr key={a.id} className="border-b last:border-0"><td className="py-2 font-mono">{a.code}</td><td>{a.name}</td><td>{a.accountType}</td><td className="text-right">{money(a.balance)}</td></tr>)}</tbody></table></div>
    </section>
    <section className="grid gap-6 lg:grid-cols-2">
      <Panel title="Payables" description="Settle vendor and staff obligations against an actual payment account.">
        {data.payables.map(p=><Row key={p.id} title={p.number} detail={`${p.beneficiary} · ${p.type} · ${money(p.remaining)} remaining`} value={money(p.amount)} status={p.status} actions={p.remaining>0 && !p.referrerId && p.type!=="TEACHER_COMPENSATION" && permitted("finance.payments.post")?<Action onClick={()=>choose("SETTLE_PAYABLE",`Settle ${p.number}`,paymentFields,{payable_id:p.id})}>Pay</Action>:null}/>)}{!data.payables.length&&<Empty/>}
      </Panel>
      <Panel title="Advances" description="Approved advances remain a balance until refunded or applied to a matching payable.">
        {data.advances.map(a=><Row key={a.id} title={a.number} detail={`${a.beneficiary} · ${a.purpose} · ${money(a.balance)} open`} value={money(a.requestedAmount)} status={a.status} actions={<div className="flex flex-wrap gap-2">{a.status==="APPROVED" && permitted("finance.advances.manage")&&<Action onClick={()=>choose("PAY_ADVANCE",`Pay ${a.number}`,[field("amount","Amount","number"),field("payment_account_id","Cash or bank","select",cash)],{advance_id:a.id})}>Pay</Action>}{a.balance>0 && permitted("finance.advances.manage")&&<><Action onClick={()=>choose("APPLY_ADVANCE",`Apply ${a.number} to payable`,[field("payable_id","Matching payable","select",data.payables.filter(p=>p.remaining>0 && !p.referrerId && p.type!=="TEACHER_COMPENSATION").map(p=>({id:p.id,name:`${p.number} · ${p.beneficiary} · ${money(p.remaining)}`}))),field("amount","Amount to apply","number")],{advance_id:a.id})}>Apply to payable</Action><Action onClick={()=>choose("REFUND_ADVANCE",`Refund ${a.number}`,[field("amount","Amount","number"),field("payment_account_id","Receiving cash or bank","select",cash)],{advance_id:a.id})}>Refund</Action></>}</div>}/>)}{!data.advances.length&&<Empty/>}
      </Panel>
      <Panel title="Expenses" description="Approval, posting and statement reconciliation.">
        {data.expenses.map(e=><Row key={e.id} title={e.number} detail={`${e.date} · ${e.description}`} value={money(e.amount)} status={e.status} actions={<div className="flex gap-2">{e.status==="POSTED"&&permitted("accounting.reconcile")&&<Action onClick={()=>choose("RECONCILE_EXPENSE",`Reconcile ${e.number}`,[field("statement_reference","Statement reference")],{expense_id:e.id})}>Reconcile</Action>}</div>}/>)}{!data.expenses.length&&<Empty/>}
      </Panel>
      <Panel title="Teacher compensation" description="Monthly policy calculation, direct authorized posting and settlement.">
        {data.compensation.map(c=><div key={c.id}><Row title={c.runNo} detail={`${c.from} → ${c.to}`} value={money(c.total)} status={c.status}/>{c.status==="APPROVED"&&permitted("staff.compensation.manage")&&data.compensationLines.filter(l=>l.runId===c.id).map(l=><div key={l.teacherId} className="ml-3 flex items-center justify-between border-b p-2 text-sm"><span>{l.teacher} · {money(l.amount)}</span><Action onClick={()=>choose("SETTLE_COMPENSATION",`Settle ${l.teacher}`,[field("advance_offset","Advance offset (enter 0 if none)","number"),field("payment_account_id","Cash or bank (if cash is due)","select",cash),field("external_reference","Bank or receipt reference")],{run_id:c.id,teacher_id:l.teacherId})}>Settle</Action></div>)}</div>)}{!data.compensation.length&&<Empty/>}
      </Panel>
    </section>
    {operation&&<div className="rounded-2xl border bg-card p-5"><form ref={formRef} key={operation.action+JSON.stringify(operation.preset??{})} className="space-y-4" onSubmit={e=>{e.preventDefault();const form=new FormData(e.currentTarget);const values=Object.fromEntries([...form.entries()].filter(([key,value])=>key!=="reason"&&value!=="")) as Record<string,string>;const reason=String(form.get("reason")??"").trim();if(reason.length<5){setFeedback("Reason needs at least five characters, excluding spaces.");return;}const payload={action:operation.action,values:{...operation.preset,...values},reason};const signature=JSON.stringify(payload);if(request.current.signature!==signature)request.current={signature,id:crypto.randomUUID()};startTransition(async()=>{const result=await submitAccountingCommand({...payload,request_id:request.current.id});setFeedback(result.message);if(result.ok){request.current={signature:"",id:""};setOperation(null);router.refresh();}})}}>
      <div className="flex items-start justify-between gap-4"><div><h2 className="text-lg font-semibold">{operation.title}</h2><p className="text-sm text-muted-foreground">Confirm details before submitting. Posted entries retain an audit trail. An unchanged retry reuses the same request identity.</p></div><button type="button" disabled={pending} onClick={()=>setOperation(null)} aria-label="Close" className="rounded border px-2 py-1">×</button></div>
      {operation.fields.map(f=><label key={f.name} className="block text-sm font-medium">{f.label}{f.options?<select name={f.name} defaultValue="" required={f.required} className="mt-1 w-full rounded-lg border bg-background p-2"><option value="">Choose…</option>{f.options.map(o=><option key={o.id} value={o.id}>{o.name}</option>)}</select>:<input name={f.name} type={f.type??"text"} step={f.type==="number"?"0.01":undefined} min={f.type==="number" && !(operation.action==="APPLY_COMP_ADJUSTMENT"&&f.name==="amount")?"0":undefined} required={f.required} className="mt-1 w-full rounded-lg border bg-background p-2"/>}</label>)}
      <label className="block text-sm font-medium">Reason for this action<textarea name="reason" minLength={5} required className="mt-1 w-full rounded-lg border bg-background p-2"/></label>
      {feedback&&<p role="alert" className="text-sm">{feedback}</p>}
      <div className="flex justify-end gap-2"><button type="button" disabled={pending} onClick={()=>setOperation(null)} className="rounded-lg border px-4 py-2">Cancel</button><button disabled={pending} className="rounded-lg bg-primary px-4 py-2 text-primary-foreground disabled:opacity-50">{pending?"Saving…":"Submit"}</button></div>
    </form></div>}
  </div>;
}
function Action({onClick,children}:{onClick:()=>void;children:React.ReactNode}){return <button type="button" onClick={onClick} className="rounded-lg border px-3 py-1.5 text-sm font-medium hover:bg-accent">{children}</button>}
function Summary({title,value}:{title:string;value:string}){return <div className="rounded-2xl border bg-card p-5"><p className="text-sm text-muted-foreground">{title}</p><p className="mt-2 text-xl font-semibold">{value}</p></div>}
function Panel({title,description,children}:{title:string;description:string;children:React.ReactNode}){return <section className="rounded-2xl border bg-card p-5"><h2 className="text-lg font-semibold">{title}</h2><p className="mt-1 text-sm text-muted-foreground">{description}</p><div className="mt-4 space-y-2">{children}</div></section>}
function Row({title,detail,value,status,actions}:{title:string;detail:string;value:string;status:string;actions?:React.ReactNode}){return <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border p-3"><div><p className="font-medium">{title}</p><p className="text-sm text-muted-foreground">{detail}</p></div><div className="text-right"><p className="font-semibold">{value}</p><p className="text-xs text-muted-foreground">{status}</p>{actions&&<div className="mt-2">{actions}</div>}</div></div>}
function Empty(){return <p className="rounded-xl border border-dashed p-4 text-sm text-muted-foreground">No records yet.</p>}
