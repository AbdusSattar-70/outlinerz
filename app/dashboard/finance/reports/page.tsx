import {requirePermission} from "@/modules/platform/auth/erp-context";
import {PageHeader} from "@/components/erp/page-header";
import {LocalizedText} from "@/components/shared/localized-text";
import {getMonthlyReport} from "@/modules/finance/reports/queries";
import {MonthlyReports} from "@/modules/finance/reports/workspace";
export default async function Reports({searchParams}:{searchParams:Promise<{month?:string}>}){await requirePermission("accounting.view");const q=await searchParams;const month=q.month&&/^\d{4}-(0[1-9]|1[0-2])$/.test(q.month)?`${q.month}-01`:undefined;const data=await getMonthlyReport(month);return <div className="space-y-6"><PageHeader eyebrow={<LocalizedText en="Finance" bn="অর্থ ব্যবস্থাপনা"/>} title={<LocalizedText en="Monthly accounts & period close" bn="মাসিক হিসাব ও মাস বন্ধ"/>} description={<LocalizedText en="Reports from posted ledger evidence, with controlled month-end close and reopening." bn="পোস্ট করা ledger অনুযায়ী রিপোর্ট এবং নিয়ন্ত্রিত মাস বন্ধ / আবার খোলা।"/>}/><MonthlyReports data={data}/></div>;}
