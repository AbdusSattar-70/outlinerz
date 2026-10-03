import { LocalizedText } from "@/components/shared/localized-text";
import { z } from "zod";
import { requireErpContext } from "@/modules/platform/auth/erp-context";
import { PageHeader } from "@/components/erp/page-header";
import { getReferrerWorkspace } from "@/modules/referrals/queries";
import { ReferrerRegister } from "@/modules/referrals/register";
export default async function Referrals({searchParams}:{searchParams:Promise<{person?:string}>}){
 await requireErpContext();const {person}=await searchParams;const id=person&&z.string().uuid().safeParse(person).success?person:undefined;
 const data=await getReferrerWorkspace(id);
 return <div className="space-y-6"><PageHeader eyebrow={<LocalizedText en="Referral partnerships" bn="রেফারেল সহযোগিতা"/>} title={<LocalizedText en={data.manager?"Referrers":"My referred students"} bn={data.manager?"রেফারার":"আমার রেফার করা শিক্ষার্থী"}/>} description={<LocalizedText en="View referred students, fee reductions, tuition collections and acquisition rewards. Actual net tuition collection determines rewards; refunds and corrections adjust entitlement." bn="রেফার করা শিক্ষার্থী, ফি ছাড়, টিউশন আদায় ও অর্জিত বোনাস দেখুন। প্রকৃত নিট টিউশন আদায় থেকে বোনাস হিসাব হয়; ফেরত ও সংশোধনে প্রাপ্য সমন্বয় হয়।"/>}/><ReferrerRegister data={data}/></div>;
}
