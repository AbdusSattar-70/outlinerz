import { cache } from "react";
import { redirect } from "next/navigation";
import { z } from "zod";
import { createClient, getVerifiedUser } from "@/lib/supabase/server";
import type { ErpContext } from "@/types/erp";

const contextSchema = z.object({
  profile_id: z.string().uuid(),
  display_name: z.string().min(1),
  status: z.enum(["ACTIVE", "SUSPENDED", "ARCHIVED"]),
  staff_id: z.string().uuid().nullable(),
  staff_no: z.string().nullable(),
  staff_name: z.string().nullable(),
  roles: z.array(z.string()),
  permissions: z.array(z.string()),
});

export const getErpContext = cache(async (): Promise<ErpContext | null> => {
  const supabase = await createClient();
  const {
    data: { user },
    error: authError,
  } = await getVerifiedUser(supabase);

  if (authError || !user) return null;

  const { data, error } = await supabase.rpc("my_erp_context");

  if (error || !data) return null;

  const parsed = contextSchema.safeParse(data);
  if (!parsed.success) return null;

  return {
    profileId: parsed.data.profile_id,
    displayName: parsed.data.display_name,
    email: user.email ?? "",
    status: parsed.data.status,
    staffId: parsed.data.staff_id,
    staffNo: parsed.data.staff_no,
    staffName: parsed.data.staff_name,
    roles: parsed.data.roles,
    permissions: parsed.data.permissions,
  };
});


export async function requireErpContext() {
  const context = await getErpContext();

  if (!context) {
    redirect("/auth/sign-in");
  }

  return context;
}

export async function requirePermission(permission: string) {
  const context = await requireErpContext();

  if (!context.permissions.includes(permission)) {
    redirect("/dashboard?access=denied");
  }

  return context;
}
