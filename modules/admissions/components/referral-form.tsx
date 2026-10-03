"use client";
import { announceSaved } from "@/components/erp/action-panel";
import { useState,useTransition } from "react";
import { useRouter } from "next/navigation";
import { runReferralCommand } from "../referral-actions";

type People=Awaited<ReturnType<typeof import("../referrals").getAdmissionReferrals>>;
export function ReferralForm({admissionId,people,choice}:{admissionId:string;people:People;choice:People["choices"][number]|undefined}){
 const router=useRouter();
 const [source,setSource]=useState(choice?.source??"");
 const [person,setPerson]=useState(choice?.referrer_id??"");
 const [message,setMessage]=useState<{ok:boolean;text:string}|null>(null);
 const [pending,startTransition]=useTransition();
 return <section className="rounded-xl border p-4 print:hidden"><h3 className="font-semibold">2. Record the admission source</h3>
  <p className="mt-1 text-sm text-muted-foreground">Ask the guardian who referred the student. Choose Organic when nobody referred them. Any referral reward is handled later by Finance.</p>
  <form className="mt-4 grid gap-3 sm:grid-cols-2" onSubmit={e=>{e.preventDefault();const form=new FormData(e.currentTarget);
    startTransition(async()=>{const result=await runReferralCommand({action:"CAPTURE",admissionId,source,
      staffId:person.startsWith("staff:")?person.slice(6):undefined,
      referrerId:person&&!person.startsWith("staff:")&&person!=="new"?person:undefined,
      fullName:form.get("fullName")||undefined,mobile:form.get("mobile")||undefined,
      relationshipNote:form.get("relationshipNote")||undefined,contactNote:form.get("contactNote")||undefined,
      reason:form.get("reason")});setMessage({ok:result.ok,text:result.message});if(result.ok)router.refresh();});}}>
    <label className="text-sm">Source<select value={source} onChange={e=>setSource(e.target.value)} required className="mt-1 w-full rounded-lg border bg-background p-2"><option value="">Choose…</option><option value="ORGANIC">Organic · no referrer</option><option value="REFERRED">Referred by a person</option></select></label>
    {source==="REFERRED"&&<><label className="text-sm">Referrer<select value={person} onChange={e=>setPerson(e.target.value)} required className="mt-1 w-full rounded-lg border bg-background p-2"><option value="">Choose…</option>{people.people.map(p=><option key={p.id} value={p.id}>{p.full_name}{p.mobile?` · ${p.mobile}`:""}</option>)}{people.staff.filter(s=>!people.people.some(p=>p.staff_id===s.id)).map(s=><option key={s.id} value={`staff:${s.id}`}>{s.full_name} · Staff</option>)}<option value="new">Register a new referrer</option></select></label>
    {person==="new"&&<><label className="text-sm">Full name<input name="fullName" required minLength={2} className="mt-1 w-full rounded-lg border bg-background p-2"/></label><label className="text-sm">Mobile<input name="mobile" required pattern="01[3-9][0-9]{8}" inputMode="tel" className="mt-1 w-full rounded-lg border bg-background p-2"/></label><label className="text-sm">Relationship to student<input name="relationshipNote" className="mt-1 w-full rounded-lg border bg-background p-2"/></label><label className="text-sm">Contact details or note<input name="contactNote" className="mt-1 w-full rounded-lg border bg-background p-2"/></label></>}</>}
    <label className="text-sm sm:col-span-2">Staff verification note<input name="reason" required minLength={5} defaultValue="Verified admission source with guardian" className="mt-1 w-full rounded-lg border bg-background p-2"/></label>
    <div className="sm:col-span-2"><button disabled={pending} className="rounded-lg bg-primary px-4 py-2 text-sm text-primary-foreground disabled:opacity-50">{pending?"Saving…":"Save referral choice"}</button>{message&&<p role={message.ok?"status":"alert"} className={`mt-2 text-sm ${message.ok?"text-emerald-700":"text-destructive"}`}>{message.text}{message.ok?" You can continue to the next step.":""}</p>}</div>
  </form>
 </section>
}
