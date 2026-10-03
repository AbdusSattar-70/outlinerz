import {requirePermission} from "@/modules/platform/auth/erp-context";
import {PageHeader} from "@/components/erp/page-header";
import {LocalizedText} from "@/components/shared/localized-text";
import {getCloseData} from "@/modules/finance/daily-close/queries";
import {DailyCloseRegister} from "@/modules/finance/daily-close/register";
export default async function DailyClose({searchParams}:{searchParams:Promise<{page?:string}>}){await requirePermission("accounting.reconcile");const q=await searchParams;const page=Math.max(1,Math.min(10000,Number.parseInt(q.page??"1",10)||1));const data=await getCloseData(page);return <div className="space-y-6"><PageHeader eyebrow={<LocalizedText en="Finance" bn="অর্থ ব্যবস্থাপনা"/>} title={<LocalizedText en="Daily cash & statement close" bn="দৈনিক নগদ ও স্টেটমেন্টের শেষ হিসাব"/>} description={<LocalizedText en="Count actual funds, compare the ledger and preserve differences and handover evidence." bn="প্রকৃত অর্থ গণনা করুন, ledger-এর সঙ্গে মিলান এবং পার্থক্য ও হস্তান্তরের প্রমাণ রাখুন।"/>}/><DailyCloseRegister data={data} page={page}/></div>;}
