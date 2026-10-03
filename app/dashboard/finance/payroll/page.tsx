import {requireErpContext} from "@/modules/platform/auth/erp-context";
import {PageHeader} from "@/components/erp/page-header";
import {LocalizedText} from "@/components/shared/localized-text";
import {getPayrollData} from "@/modules/finance/payroll/queries";
import {PayrollRegister} from "@/modules/finance/payroll/register";
export default async function Payroll({searchParams}:{searchParams:Promise<{page?:string}>}){await requireErpContext();const q=await searchParams;const page=Math.max(1,Math.min(10000,Number.parseInt(q.page??"1",10)||1));const data=await getPayrollData(undefined,page);return <div className="space-y-6"><PageHeader eyebrow={<LocalizedText en="Finance" bn="অর্থ ব্যবস্থাপনা"/>} title={<LocalizedText en="Payroll & payslips" bn="বেতন ও বেতন স্লিপ"/>} description={<LocalizedText en="Preview agreed fixed/hourly earnings, post once, and record actual payment or advance recovery. Staff see only their own payslips." bn="Fixed/hourly আয় পর্যালোচনা করে একবার পোস্ট করুন, প্রকৃত পরিশোধ বা অগ্রিম সমন্বয় করুন। স্টাফ শুধু নিজের স্লিপ দেখেন।"/>}/><PayrollRegister data={data} page={page}/></div>;}
