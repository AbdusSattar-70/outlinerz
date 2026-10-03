import { requirePermission } from "@/modules/platform/auth/erp-context";
import { getAuditPage } from "@/modules/governance/queries";
import { AuditView } from "@/modules/governance/audit-view";
import { z } from "zod";
export default async function AuditPage({searchParams}:{searchParams:Promise<Record<string,string|undefined>>}){
 await requirePermission("audit.view");const q=await searchParams;const filters:Record<string,string>={};
 for(const key of ['q','entity','action','preset'] as const)if(typeof q[key]==='string')filters[key]=q[key]!.slice(0,key==='q'?160:80);
 const day=z.iso.date();for(const key of ['from','to'] as const)if(day.safeParse(q[key]).success)filters[key]=q[key]!;
 filters.page=String(Math.max(1,Math.min(100000,Number.parseInt(q.page??'1',10)||1)));
 const error=filters.from&&filters.to&&filters.from>filters.to?'range':undefined;if(error){delete filters.from;delete filters.to;}
 const data=await getAuditPage(filters);return <AuditView data={data} filters={filters} error={error}/>;
}
