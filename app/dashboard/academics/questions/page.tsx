import { PageHeader } from "@/components/erp/page-header";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { getQuestionWorkspace } from "@/modules/academics/questions/queries";
import { QuestionBank } from "@/modules/academics/questions/workspace";

export default async function QuestionBankPage() {
  const context = await requirePermission("academics.view");
  const data = await getQuestionWorkspace();
  return <div className="space-y-7">
    <PageHeader eyebrow="Academics" title="Question Bank" description="Draft teaching questions, submit them for an independent review, and retain every decision and revision." />
    <QuestionBank data={data} actorId={context.profileId} canAuthor={context.permissions.includes("academics.assessments.record") || context.permissions.includes("academics.sessions.manage")} canReview={context.permissions.includes("academics.assessments.approve")} />
  </div>;
}
