import {getTaskData} from "@/modules/workforce/tasks";
import {TaskRegister} from "@/modules/workforce/task-register";
import {PageHeader} from "@/components/erp/page-header";
import {LocalizedText} from "@/components/shared/localized-text";
import {requirePermission} from "@/modules/platform/auth/erp-context";
import {getWorkData} from "@/modules/workforce/queries";
import {WorkWorkspace} from "@/modules/workforce/workspace";
import {workforceQuery} from "@/modules/workforce/route-query";
export default async function StaffOperations({searchParams}:{searchParams:Promise<{month?:string;person?:string;page?:string;tasksPage?:string;tasksView?:string}>}){await requirePermission("workforce.manage");const raw=await searchParams;const q=workforceQuery(raw);const tasksPage=Math.max(1,Math.min(10000,Number.parseInt(raw.tasksPage??"1",10)||1));const history=raw.tasksView==="history";const [data,tasks]=await Promise.all([getWorkData(q.month,q.person,q.page),getTaskData(q.person,history,tasksPage)]);return <div className="space-y-6"><PageHeader eyebrow={<LocalizedText en="People" bn="ব্যক্তিবর্গ"/>} title={<LocalizedText en="Staff attendance" bn="স্টাফ উপস্থিতি"/>} description={<LocalizedText en="Record actual daily evidence. Corrections are audited; no staff record is deleted." bn="প্রকৃত দৈনিক তথ্য রেকর্ড করুন। সংশোধন অডিটে থাকে; স্টাফ রেকর্ড মুছে ফেলা হয় না।"/>}/><WorkWorkspace data={data} page={q.page} admin/><TaskRegister data={tasks} people={data.people} admin history={history} page={tasksPage} month={data.month}/></div>;}
