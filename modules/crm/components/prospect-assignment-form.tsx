"use client";
import { ActionPanel, announceSaved } from "@/components/erp/action-panel";
import {useState,useTransition,type FormEvent} from "react";
import {useRouter} from "next/navigation";
import {assignProspect} from "../assignment-actions";
export function ProspectAssignmentForm({prospectId,selected,staff}:{prospectId:string;selected:string|null;staff:{id:string;name:string}[]}){
 const [message,setMessage]=useState(""),[pending,start]=useTransition();const router=useRouter();
 function submit(e:FormEvent<HTMLFormElement>){e.preventDefault();const f=new FormData(e.currentTarget);start(async()=>{try{const r=await assignProspect({prospect_id:prospectId,staff_id:f.get("staff"),reason:"Assigned counselling and follow-up responsibility"});setMessage(r.message);if(r.ok)router.refresh();}catch{setMessage("Could not save assignment. Please retry.");}});}
 return <section className="rounded-xl border p-4"><h2 className="font-semibold">Follow-up responsibility</h2><p className="mt-2 text-sm text-muted-foreground">This staff member handles counselling and follow-up. This is separate from the referrer who may receive compensation.</p><ActionPanel title="Assign follow-up responsibility"><form onSubmit={submit} className="mt-3 flex flex-wrap gap-3"><label className="flex-1 text-sm">Responsible staff<select name="staff" defaultValue={selected??""} className="mt-1 min-h-11 w-full rounded-lg border bg-background px-3"><option value="">Unassigned</option>{staff.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}</select></label><button disabled={pending} className="self-end rounded-lg border px-4 py-3 text-sm">{pending?"Saving…":"Save assignment"}</button></form></ActionPanel>{message&&<p role="status" className="mt-3 text-sm">{message}</p>}</section>;
}
