'use client';
import { useActionState, useState } from 'react';
import { onboardOrganization, switchOrganization, addSetupRecord, type FormState } from './actions';
const input = 'w-full rounded-xl border bg-background px-3 py-3 text-sm';
const button = 'rounded-xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground disabled:opacity-50';
function Feedback({ state }: { state: FormState }) { return <div aria-live="polite">{state.error && <p role="alert" className="text-sm text-red-400">{state.error}</p>}{state.success && <p className="text-sm text-emerald-400">{state.success}</p>}</div>; }
export function OnboardingForm({ request }: { request: string }) {
  const [state, action, pending] = useActionState(onboardOrganization, {});
  const [requestId] = useState(request);
  const [values, setValues] = useState({ name: '', slug: '', branch: 'Main branch' });
  return <form action={action} className="space-y-5"><input type="hidden" name="request" value={requestId}/>{(['name','slug','branch'] as const).map(key => <label key={key} className="block space-y-2"><span>{({name:'প্রতিষ্ঠানের নাম',slug:'Unique slug',branch:'প্রথম শাখা'})[key]}</span><input className={input} name={key} value={values[key]} disabled={pending} required maxLength={key==='slug'?63:160} onChange={e=>setValues({...values,[key]:e.target.value})}/></label>)}<p className="text-sm text-muted-foreground">Slug example: rahman-tuition. Accounting setup ছাড়াই শুরু করুন।</p><Feedback state={state}/><button className={button} disabled={pending}>{pending?'তৈরি হচ্ছে…':'প্রতিষ্ঠান তৈরি করুন'}</button></form>;
}
export function OrganizationPicker({ organizations }: { organizations: { id: string; name: string; role: string }[] }) {
 const [state, action, pending] = useActionState(switchOrganization, {});
 return <form action={action} className="space-y-4"><label className="block space-y-2"><span>প্রতিষ্ঠান নির্বাচন করুন</span><select name="organization" className={input} required disabled={pending}>{organizations.map(o=><option key={o.id} value={o.id}>{o.name} · {o.role}</option>)}</select></label><Feedback state={state}/><button className={button} disabled={pending}>{pending?'খুলছে…':'Dashboard খুলুন'}</button></form>;
}
export function SetupRecordForm({ kind, title }: { kind: 'year'|'class'|'subject'; title: string }) {
 const [state, action, pending] = useActionState(addSetupRecord, {});
 const [name,setName] = useState('');
 const [dates,setDates] = useState({ start: '', end: '' });
 return <form action={action} className="space-y-3 rounded-2xl border p-5"><h2 className="font-semibold">{title}</h2><input type="hidden" name="kind" value={kind}/><label className="block space-y-1"><span className="text-sm">নাম</span><input className={input} name="name" value={name} onChange={e=>setName(e.target.value)} required maxLength={160} disabled={pending}/></label>{kind==='year' && <div className="grid gap-3 sm:grid-cols-2"><label>শুরু<input type="date" name="starts_on" value={dates.start} onChange={e=>setDates({...dates,start:e.target.value})} className={input} required disabled={pending}/></label><label>শেষ<input type="date" name="ends_on" value={dates.end} onChange={e=>setDates({...dates,end:e.target.value})} className={input} required disabled={pending}/></label></div>}<Feedback state={state}/><button className={button} disabled={pending}>{pending?'সংরক্ষণ হচ্ছে…':'যোগ করুন'}</button></form>;
}
