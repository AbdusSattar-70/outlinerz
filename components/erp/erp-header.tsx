"use client";

import { usePathname } from "next/navigation";
import Link from "next/link";
import { CircleHelp } from "lucide-react";
import { Separator } from "@/components/ui/separator";
import { SidebarTrigger } from "@/components/ui/sidebar";
import { getErpRoute } from "@/modules/platform/navigation/erp-route-registry";

export function ErpHeader() {
  const pathname = usePathname();
  const current = getErpRoute(pathname);

  return (
    <header className="sticky top-0 z-30 flex min-h-16 items-center gap-3 border-b bg-background/95 px-4 backdrop-blur supports-[backdrop-filter]:bg-background/85 sm:px-6">
      <SidebarTrigger className="-ml-1" />
      <Separator orientation="vertical" className="h-6" />
      <div className="min-w-0 flex-1">
        <p className="truncate text-[11px] font-semibold uppercase tracking-[0.18em] text-muted-foreground">
          {current?.eyebrow ?? "Sohoj Academy ERP"}
        </p>
        <h1 className="truncate text-sm font-semibold sm:text-base">
          {current?.title ?? "Workspace"}
        </h1>
      </div>
      <Link href="/dashboard/help" aria-label="Open ERP help" title="Help & Workflows" className="inline-flex size-9 shrink-0 items-center justify-center rounded-lg text-muted-foreground hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">
        <CircleHelp className="size-5" aria-hidden="true" />
      </Link>
    </header>
  );
}
