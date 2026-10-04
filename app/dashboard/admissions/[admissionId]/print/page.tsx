import { getPrintCatalogue } from "@/modules/admissions/print-catalogue";
import { getAcademySetup } from "@/modules/platform/setup/queries";
import Link from "next/link";
import { notFound } from "next/navigation";
import { z } from "zod";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { getAdmissionCase } from "@/modules/admissions/queries";
import { PrintAdmissionButton } from "@/modules/admissions/components/print-button";
import { AdmissionPaper } from "@/modules/admissions/components/admission-paper";
export default async function AdmissionDocument({
  params,
  searchParams,
}: {
  params: Promise<{ admissionId: string }>;
  searchParams: Promise<{ receipt?: string }>;
}) {
  await requirePermission("admissions.view");
  const { admissionId } = await params,
    { receipt } = await searchParams;
  if (!z.string().uuid().safeParse(admissionId).success) notFound();
  const a = await getAdmissionCase(admissionId);
  if (receipt && !a.receipts.some((r) => r.number === receipt)) notFound();
  const [setup,catalogue] = await Promise.all([getAcademySetup(),getPrintCatalogue()]);
  return (
    <div className="space-y-5">
      <div className="flex gap-3 print:hidden">
        <Link
          href={`/dashboard/admissions/${a.id}`}
          className="rounded-lg border px-4 py-2 text-sm"
        >
          Return to admission
        </Link>
        <PrintAdmissionButton />
      </div>
      <AdmissionPaper
        data={a}
        catalogue={catalogue} academyName={setup.academyName}
      />
    </div>
  );
}
