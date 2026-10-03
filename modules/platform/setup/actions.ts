"use server";
import { revalidatePath } from "next/cache";
import { platformClient } from "../rpc-client";
import { getErpContext } from "../auth/erp-context";
export async function completeSetup() {
  const context = await getErpContext();
  if (!context?.permissions.includes("system.settings.manage"))
    return { ok: false, message: "Academy setup permission required." };
  const db = await platformClient();
  const { error } = await db.rpc("complete_academy_setup");
  if (error) return { ok: false, message: error.message };
  revalidatePath("/dashboard", "layout");
  return { ok: true, message: "Academy setup complete." };
}
