"use client";
import Logo from "@/components/shared/logo";
import { useSite } from "@/modules/crm/site/provider";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  UserRoundSearch,
  Settings2,
  Building2,
  LogOut,
} from "lucide-react";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarInset,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarRail,
  SidebarTrigger,
} from "@/components/ui/sidebar";
import { PreferenceControls } from "@/components/shared/preference-controls";
import { useLanguage } from "@/components/providers/language-provider";
import { signOut } from "./actions";
import type { ReactNode } from "react";
export function WorkspaceShell({
  organization,
  crmEnabled,
  children,
}: {
  organization: { name: string; role: string; slug: string };
  crmEnabled: boolean;
  children: ReactNode;
}) {
  const { locale } = useLanguage();
  const bn = locale === "bn";
  const site = useSite();
  const organizationName = site
    ? bn
      ? site.nameBn
      : site.nameEn
    : organization.name;
  const path = usePathname();
  const admin = ["OWNER", "ADMIN"].includes(organization.role);
  const links = [
    {
      href: "/dashboard",
      en: "Overview",
      bn: "সারসংক্ষেপ",
      icon: LayoutDashboard,
    },
    ...(["OWNER", "ADMIN", "ACADEMIC", "OPERATOR"].includes(organization.role)
      ? [
          {
            href: "/dashboard/crm/prospects",
            en: "Prospects",
            bn: "সম্ভাব্য শিক্ষার্থী",
            icon: UserRoundSearch,
          },
        ]
      : []),
    ...(admin
      ? [
          {
            href: "/dashboard/setup",
            en: "Organization setup",
            bn: "প্রতিষ্ঠানের প্রস্তুতি",
            icon: Building2,
          },
          ...[
            {
              href: "/dashboard/crm/website",
              en: "CRM management dashboard",
              bn: "প্রতিষ্ঠানের যোগাযোগ ব্যবস্থাপনা",
              icon: Settings2,
            },
            {
              href: "/dashboard/crm/manage",
              en: "Manage CRM",
              bn: "যোগাযোগ ব্যবস্থাপনা",
              icon: Settings2,
            },
          ],
        ]
      : []),
  ];
  const current =
    links.find((l) => l.href === path) ??
    links.find((l) => path.startsWith(l.href) && l.href != "/dashboard");
  return (
    <SidebarProvider>
      <Sidebar collapsible="icon" variant="sidebar">
        <SidebarHeader className="border-b border-sidebar-border">
          <Link
            href="/dashboard"
            className="flex min-h-14 items-center gap-3 rounded-lg px-2"
          >
            <Logo variant="mark" size={36} priority />
            <div className="min-w-0 group-data-[collapsible=icon]:hidden">
              <p className="truncate text-sm font-bold">{organizationName}</p>
              <p className="truncate text-[11px] text-sidebar-foreground/60">
                {bn ? "প্রতিষ্ঠানের কার্যক্রম" : "Operations ERP"}
              </p>
            </div>
          </Link>
        </SidebarHeader>
        <SidebarContent className="py-2">
          <SidebarGroup>
            <SidebarGroupLabel>
              {bn ? "কর্মপরিসর" : "Workspace"}
            </SidebarGroupLabel>
            <SidebarMenu>
              {links.map((l) => (
                <SidebarMenuItem key={l.href}>
                  <SidebarMenuButton
                    asChild
                    isActive={
                      path === l.href ||
                      (l.href != "/dashboard" && path.startsWith(l.href))
                    }
                    tooltip={bn ? l.bn : l.en}
                  >
                    <Link href={l.href}>
                      <l.icon />
                      <span>{bn ? l.bn : l.en}</span>
                    </Link>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroup>
        </SidebarContent>
        <SidebarFooter className="border-t">
          <SidebarMenu>
            <SidebarMenuItem>
              <SidebarMenuButton asChild>
                <Link href="/organizations">
                  <Building2 />
                  <span>{bn ? "প্রতিষ্ঠান বদলান" : "Switch organization"}</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
            <SidebarMenuItem>
              <form action={signOut}>
                <SidebarMenuButton type="submit">
                  <LogOut />
                  <span>{bn ? "বের হন" : "Sign out"}</span>
                </SidebarMenuButton>
              </form>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarFooter>
        <SidebarRail />
      </Sidebar>
      <SidebarInset className="min-w-0 bg-muted/20">
        <header className="sticky top-0 z-30 flex min-h-16 items-center gap-3 border-b bg-background/95 px-4 backdrop-blur sm:px-6">
          <SidebarTrigger />
          <div className="min-w-0 flex-1">
            <p className="text-[11px] font-semibold uppercase tracking-[.18em] text-muted-foreground">
              {organizationName}
            </p>
            <h1 className="truncate text-sm font-semibold sm:text-base">
              {current ? (bn ? current.bn : current.en) : organization.name}
              {!crmEnabled && path.startsWith("/dashboard/crm") && (
                <span className="ml-2 text-xs text-muted-foreground">
                  {bn ? "(শুধু পড়া যাবে)" : "(Read only)"}
                </span>
              )}
            </h1>
          </div>
          <PreferenceControls compact />
        </header>
        <main
          id="erp-main"
          className="mx-auto w-full max-w-[1600px] flex-1 px-4 py-5 sm:px-6 lg:px-8 lg:py-7"
        >
          {children}
        </main>
      </SidebarInset>
    </SidebarProvider>
  );
}
