import { getPrintCatalogue } from "@/modules/admissions/print-catalogue";
import { getAcademySetup } from "@/modules/platform/setup/queries";
import Link from "next/link";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { PrintAdmissionButton } from "@/modules/admissions/components/print-button";
import { AdmissionPaper } from "@/modules/admissions/components/admission-paper";
export default async function BlankApplication() {
  await requirePermission("admissions.create");
  const [setup,catalogue] = await Promise.all([getAcademySetup(),getPrintCatalogue()]);
  return (
    <div className="space-y-5">
      <header className="flex flex-wrap items-center justify-between gap-4 print:hidden">
        <div>
          <h1 className="text-2xl font-bold">Two-page admission form</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            A4 · Page 1 for family details · Page 2 for consent and academic
            verification. Enter the signed paper later; the system
            assigns the Student ID.
          </p>
        </div>
        <div className="flex gap-3">
          <Link
            className="rounded border px-4 py-2"
            href="/dashboard/admissions"
          >
            Back to admissions
          </Link>
          <PrintAdmissionButton />
        </div>
      </header>
      <AdmissionPaper catalogue={catalogue} academyName={setup.academyName} />
    </div>
  );
}
