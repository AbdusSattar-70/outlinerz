"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Activity,
  BadgeCheck,
  BookOpenCheck,
  ClipboardCheck,
  LayoutDashboard,
  ListChecks,
  ScrollText,
  Settings2,
  ShieldCheck,
  UserRoundSearch,
  UsersRound,
  GraduationCap,
  Calculator,
  CircleHelp,
} from "lucide-react";
import Logo from "@/components/shared/logo";
import { ErpAccount } from "@/components/erp/erp-account";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
} from "@/components/ui/sidebar";
import type { ErpContext, ErpNavGroup, ErpNavIcon } from "@/types/erp";
import { routeMatches, erpRouteRegistry } from "@/modules/platform/navigation/erp-route-registry";

const icons: Record<ErpNavIcon, typeof LayoutDashboard> = {
  dashboard: LayoutDashboard,
  "action-center": ListChecks,
  prospects: UserRoundSearch,
  students: BookOpenCheck,
  staff: UsersRound,
  offerings: BookOpenCheck,
  "fee-plans": Settings2,
  approvals: ClipboardCheck,
  audit: ScrollText,
  rules: ShieldCheck,
  settings: Settings2,
  teacher: GraduationCap,
  accounting: Calculator,
  help: CircleHelp,
};

function isActive(pathname: string, id: string) {
  const route = erpRouteRegistry.find((item) => item.id === id);
  return route ? routeMatches(pathname, route) : false;
}

export function ErpSidebar({
  context,
  navigation,
}: {
  context: ErpContext;
  navigation: ErpNavGroup[];
}) {
  const pathname = usePathname();

  return (
    <Sidebar collapsible="icon" variant="sidebar">
      <SidebarHeader className="border-b border-sidebar-border">
        <Link
          href="/dashboard"
          className="flex min-h-14 items-center gap-3 rounded-lg px-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sidebar-ring"
          aria-label="Sohoj Academy ERP dashboard"
        >
          <Logo variant="mark" size={36} priority />
          <div className="min-w-0 group-data-[collapsible=icon]:hidden">
            <p className="truncate text-sm font-bold">Sohoj Academy</p>
            <p className="truncate text-[11px] text-sidebar-foreground/60">
              Operations ERP
            </p>
          </div>
        </Link>
      </SidebarHeader>

      <SidebarContent className="py-2">
        {navigation.map((group) => (
          <SidebarGroup key={group.title}>
            <SidebarGroupLabel>{group.title}</SidebarGroupLabel>
            <SidebarMenu>
              {group.items.map((item) => {
                const Icon = icons[item.icon] ?? Activity;
                const active = isActive(pathname, item.id);

                return (
                  <SidebarMenuItem key={item.href}>
                    <SidebarMenuButton
                      asChild
                      isActive={active}
                      tooltip={item.title}
                    >
                      <Link
                        href={item.href}
                        aria-current={active ? "page" : undefined}
                      >
                        <Icon aria-hidden="true" />
                        <span>{item.title}</span>
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                );
              })}
            </SidebarMenu>
          </SidebarGroup>
        ))}
      </SidebarContent>

      <SidebarFooter className="border-t border-sidebar-border">
        <div className="mb-1 hidden items-center gap-2 rounded-lg bg-sidebar-accent/50 px-3 py-2 text-xs group-data-[collapsible=icon]:hidden md:flex">
          <BadgeCheck className="size-4 shrink-0" aria-hidden="true" />
          <div className="min-w-0">
            <p className="truncate font-medium">{context.roles.join(", ")}</p>
            {context.staffNo && (
              <p className="truncate text-sidebar-foreground/60">
                {context.staffNo}
              </p>
            )}
          </div>
        </div>
        <ErpAccount context={context} />
      </SidebarFooter>

      <SidebarRail />
    </Sidebar>
  );
}
