"use client";
import { useState,useTransition } from "react";
import { useRouter } from "next/navigation";
import { saveReferralOperatingRules } from "../referral-policy-actions";
import type { SettingsPolicyRow } from "../queries";
export function ReferralPolicyEditor({rules}:{rules:SettingsPolicyRow[]}){
 const [pending,start]=useTransition(),[message,setMessage]=useState("");const router=useRouter();
 const referral=rules.find(r=>r.domain==="referrals")?.payload as Record<string,number>|undefined,collection=rules.find(r=>r.domain==="finance"&&r.ruleKey==="collection_discount_policy")?.payload as Record<string,number>|undefined;
 return <details className="rounded-2xl border bg-card p-5" data-action-panel><summary className="cursor-pointer font-semibold">Referrer rewards and collection-time discounts — edit settings</summary><form className="mt-4 grid gap-4 sm:grid-cols-2" onSubmit={e=>{e.preventDefault();const form=e.currentTarget;const f=new FormData(form);start(async()=>{const r=await saveReferralOperatingRules({bonusPercent:Number(f.get("bonus")),discountMax:Number(f.get("discount")),scholarshipMax:Number(f.get("scholarship")),reason:String(f.get("reason"))});setMessage(r.message);if(r.ok){form.closest("details")?.removeAttribute("open");router.refresh();}});}}>
 <p className="text-sm text-muted-foreground sm:col-span-2">The acquisition rate applies equally to staff and external referrers. Existing reward contracts retain their agreed rate. Collection-time reductions affect only unpaid tuition.</p>
 {[["bonus","Acquisition reward (%)",referral?.bonus_percent??50],["discount","Maximum additional discount (%)",collection?.max_discount_percent??30],["scholarship","Maximum scholarship (%)",collection?.max_scholarship_percent??100]].map(([name,label,value])=><label key={String(name)} className="text-sm">{label}<input name={String(name)} type="number" min="0" max="100" step="0.01" defaultValue={value} required className="mt-1 w-full rounded-lg border bg-background p-3"/></label>)}<label className="text-sm">Reason<input name="reason" required minLength={5} className="mt-1 w-full rounded-lg border bg-background p-3"/></label>{message&&<p role="status" className="sm:col-span-2">{message}</p>}<button disabled={pending} className="rounded-lg bg-primary p-3 text-primary-foreground">{pending?"Saving…":"Save settings"}</button></form></details>;
}
