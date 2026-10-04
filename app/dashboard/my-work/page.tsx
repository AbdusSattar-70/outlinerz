import {getTaskData} from "@/modules/workforce/tasks";
import {TaskRegister} from "@/modules/workforce/task-register";
import Link from "next/link";
import {LocalizedText} from "@/components/shared/localized-text";
import {PageHeader} from "@/components/erp/page-header";
import {requirePermission} from "@/modules/platform/auth/erp-context";
import {getWorkData} from "@/modules/workforce/queries";
import {WorkWorkspace} from "@/modules/workforce/workspace";
import {workforceQuery} from "@/modules/workforce/route-query";
export default async function MyWorkPage({searchParams}:{searchParams:Promise<{month?:string;page?:string;tasksPage?:string;tasksView?:string}>}){const context=await requirePermission("workforce.self.view");const raw=await searchParams;const q=workforceQuery(raw);const tasksPage=Math.max(1,Math.min(10000,Number.parseInt(raw.tasksPage??"1",10)||1));const history=raw.tasksView==="history";const [data,tasks]=await Promise.all([getWorkData(q.month,undefined,q.page),getTaskData(undefined,history,tasksPage)]);return <div className="space-y-6"><PageHeader eyebrow={<LocalizedText en="My workspace" bn="আমার কর্মক্ষেত্র"/>} title={<LocalizedText en="My work & attendance" bn="আমার কাজ ও উপস্থিতি"/>} description={<LocalizedText en="Your recorded attendance and assigned work." bn="আপনার উপস্থিতি ও নির্ধারিত কাজ।"/>}/>{context.roles.includes("TEACHER")&&<Link className="inline-block rounded-lg border p-3" href="/dashboard/teacher"><LocalizedText en="My classes → record student attendance" bn="আমার ক্লাস → শিক্ষার্থীদের উপস্থিতি নিন"/></Link>}<WorkWorkspace data={data} page={q.page}/><TaskRegister data={tasks} people={data.people} history={history} page={tasksPage} month={data.month}/></div>;}
