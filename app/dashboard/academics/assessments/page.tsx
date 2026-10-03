import { PageHeader } from "@/components/erp/page-header";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { getAssessmentWorkspace } from "@/modules/academics/assessments/queries";
import { AssessmentWorkspaceView } from "@/modules/academics/assessments/workspace";

export default async function AssessmentsPage() {
  const context = await requirePermission("academics.view");
  const data = await getAssessmentWorkspace();
  return <div className="space-y-7">
    <PageHeader eyebrow="Academics" title="Assessments & Results" description="Schedule a batch assessment, save the full roster of marks, and obtain independent review before results become official." />
    <AssessmentWorkspaceView data={data} actorId={context.profileId} canRecord={context.permissions.includes("academics.assessments.record")} canReview={context.permissions.includes("academics.assessments.approve")} />
  </div>;
}
