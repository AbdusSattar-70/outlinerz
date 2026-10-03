import { MutationFeedback } from "./mutation-feedback";
import { Suspense } from "react";
import { WorkflowReturn } from "./workflow-return";
import type { ReactNode } from "react";
import { ErpSidebar } from "@/components/erp/erp-sidebar";
import { ErpHeader } from "@/components/erp/erp-header";
import { SidebarInset, SidebarProvider } from "@/components/ui/sidebar";
import { getNavigation } from "@/modules/platform/navigation/erp-navigation";
import type { ErpContext } from "@/types/erp";

export function ErpShell({
  context,
  children,
  setupPending = false,
}: {
  context: ErpContext;
  children: ReactNode;
  setupPending?: boolean;
}) {
  const navigation = getNavigation(context)
    .map((group) => ({
      ...group,
      items: setupPending
        ? group.items.filter((item) =>
            [
              "/dashboard/settings",
              "/dashboard/crm/manage",
              "/dashboard/academics/offerings",
              "/dashboard/finance/fee-plans",
              "/dashboard/academics/batches",
              "/dashboard/governance/rules",
              "/dashboard/help",
            ].includes(item.href),
          )
        : group.items,
    }))
    .filter((group) => group.items.length);

  return (
    <SidebarProvider>
      <ErpSidebar context={context} navigation={navigation} />
      <SidebarInset className="min-w-0 bg-muted/20">
        <ErpHeader />
        <main
          id="erp-main"
          className="mx-auto w-full max-w-[1600px] flex-1 px-4 py-5 sm:px-6 lg:px-8 lg:py-7"
        >
          <Suspense>
            <WorkflowReturn />
          </Suspense>
          <MutationFeedback />
          {children}
        </main>
      </SidebarInset>
    </SidebarProvider>
  );
}
