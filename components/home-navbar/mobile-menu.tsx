import {
  SidebarProvider,
} from "@/components/ui/sidebar"
import { NavUser } from "./nav-user"

export const iframeHeight = "800px"

export const description = "A sidebar with a header and a search form."

export default function MobileMenu() {
  return (
    <div className="[--header-height:calc(--spacing(14))]">
      <SidebarProvider className="flex flex-col">
        <NavUser />
      </SidebarProvider>
    </div>
  )
}
