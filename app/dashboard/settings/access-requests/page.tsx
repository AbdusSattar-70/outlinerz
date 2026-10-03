import { redirect } from "next/navigation";
import { requirePermission } from "@/modules/platform/auth/erp-context";
export default async function AccessRequestsPage(){await requirePermission("system.users.manage");redirect("/dashboard/staff#staff-access");}
