"use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { platformClient } from "@/modules/platform/rpc-client";
export async function createAdmissionDirectoryChoice(input: unknown) {
  const parsed = z
    .object({
      entity: z.enum(["school", "relationship"]),
      name: z.string().trim().min(2).max(160),
    })
    .safeParse(input);
  if (!parsed.success)
    return { ok: false as const, message: "Enter a valid name." };
  const db = await platformClient();
  const { data, error } = await db.rpc("create_admission_directory_choice", {
    p_input: parsed.data,
  });
  if (error) return { ok: false as const, message: error.message };
  const row = z.object({ id: z.string().uuid(), name: z.string() }).parse(data);
  revalidatePath("/dashboard/crm/manage");
  return { ok: true as const, row };
}
