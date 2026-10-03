"use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { platformClient } from "../rpc-client";
export async function saveAcademyIdentity(input: unknown) {
  const parsed = z
    .object({
      name: z.string().trim().min(2).max(160),
      branch_name: z.string().trim().min(2).max(160),
    })
    .safeParse(input);
  if (!parsed.success)
    return { ok: false, message: "Enter academy and campus names." };
  const db = await platformClient();
  const { error } = await db.rpc("save_academy_identity", {
    p_input: parsed.data,
  });
  if (error) return { ok: false, message: error.message };
  revalidatePath("/dashboard", "layout");
  return {
    ok: true,
    message:
      "Academy identity confirmed. Continue with the academic directory.",
  };
}
