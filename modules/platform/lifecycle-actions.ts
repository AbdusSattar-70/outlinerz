"use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { platformClient } from "./rpc-client";
const schema = z.object({
  entity: z.enum(["batch", "offering", "student", "staff", "referrer"]),
  id: z.string().uuid(),
  active: z.boolean(),
  reason: z.string().trim().min(5).max(500),
});
export async function changeRecordState(input: unknown) {
  const parsed = schema.safeParse(input);
  if (!parsed.success)
    return { ok: false, message: "Check the record and change reason." };
  const db = await platformClient();
  const { error } = await db.rpc("record_lifecycle_command", {
    p_input: parsed.data,
  });
  if (error) return { ok: false, message: error.message };
  revalidatePath("/dashboard", "layout");
  revalidatePath("/");
  revalidatePath("/interest");
  return {
    ok: true,
    message: parsed.data.active
      ? "Record reactivated."
      : "Record marked inactive. History retained.",
  };
}
