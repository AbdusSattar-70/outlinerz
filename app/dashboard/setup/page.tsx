import { redirect } from 'next/navigation';
import { requireOrganization } from '@/modules/organizations/server';
import { SetupRecordForm } from '@/modules/organizations/forms';
export default async function SetupPage() {
 const {db,organization}=await requireOrganization();
 if(!['OWNER','ADMIN'].includes(organization.role))redirect('/dashboard');
 const results=await Promise.all([
  db.from('branches').select('id,name').eq('organization_id',organization.id).eq('active',true).order('name'),
  db.from('academic_years').select('id,name').eq('organization_id',organization.id).eq('active',true).order('name'),
  db.from('class_levels').select('id,name').eq('organization_id',organization.id).eq('active',true).order('name'),
  db.from('subjects').select('id,name').eq('organization_id',organization.id).eq('active',true).order('name'),
 ]);
 if(results.some(r=>r.error))throw new Error('Setup records could not be loaded.');
 return <div className="space-y-7"><h1 className="text-3xl font-bold">প্রতিষ্ঠানের setup</h1><p className="text-muted-foreground">একাধিক academic year active থাকতে পারে। Accounting configuration এখানে বাধ্যতামূলক নয়।</p><div className="grid gap-4 sm:grid-cols-2">{['Branches','Academic years','Classes','Subjects'].map((title,i)=><section key={title} className="rounded-2xl border p-5"><h2 className="font-semibold">{title}</h2><ul className="mt-3 space-y-1 text-sm">{results[i].data?.map(r=><li key={r.id}>{r.name}</li>)}</ul>{!results[i].data?.length&&<p className="mt-3 text-sm text-muted-foreground">এখনও যোগ করা হয়নি।</p>}</section>)}</div><div className="grid gap-5 lg:grid-cols-3"><SetupRecordForm kind="year" title="Academic year যোগ করুন"/><SetupRecordForm kind="class" title="Class যোগ করুন"/><SetupRecordForm kind="subject" title="Subject যোগ করুন"/></div></div>;
}
