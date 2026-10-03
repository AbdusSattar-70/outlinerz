"use client";

import { LogOut, UserRound } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import {
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "@/components/ui/sidebar";
import type { ErpContext } from "@/types/erp";

export function ErpAccount({ context }: { context: ErpContext }) {
  const router = useRouter();
  const [signingOut, setSigningOut] = useState(false);

  async function signOut() {
    if (signingOut) return;
    setSigningOut(true);

    const supabase = createClient();
    await supabase.auth.signOut();
    router.replace("/auth/sign-in");
    router.refresh();
  }

  return (
    <SidebarMenu>
      <SidebarMenuItem>
        <div className="mb-1 flex items-center gap-3 rounded-lg px-2 py-2 group-data-[collapsible=icon]:justify-center">
          <div className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground">
            <UserRound className="size-4" aria-hidden="true" />
          </div>
          <div className="min-w-0 flex-1 group-data-[collapsible=icon]:hidden">
            <p className="truncate text-sm font-medium">{context.displayName}</p>
            <p className="truncate text-xs text-sidebar-foreground/60">
              {context.email}
            </p>
          </div>
        </div>
      </SidebarMenuItem>
      <SidebarMenuItem>
        <SidebarMenuButton
          type="button"
          onClick={signOut}
          disabled={signingOut}
          tooltip="Sign out"
        >
          <LogOut aria-hidden="true" />
          <span>{signingOut ? "Signing out…" : "Sign out"}</span>
        </SidebarMenuButton>
      </SidebarMenuItem>
    </SidebarMenu>
  );
}
