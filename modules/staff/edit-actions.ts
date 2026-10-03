"use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { platformClient } from "@/modules/platform/rpc-client";
export async function editStaffRecord(input: unknown) {
  const parsed = z
    .object({
      id: z.string().uuid(),
      full_name: z.string().trim().min(2).max(160),
      mobile: z.string().regex(/^$|^01[3-9][0-9]{8}$/),
      alternate_mobile: z.string().regex(/^$|^01[3-9][0-9]{8}$/).optional(),
      email: z.union([z.email(),z.literal("")]).optional(),
      address: z.string().max(500).optional(), emergency_contact_name:z.string().max(160).optional(),
      emergency_contact_mobile:z.string().regex(/^$|^01[3-9][0-9]{8}$/).optional(),
      joined_on:z.string().optional(),notes:z.string().max(1000).optional(),
      reason: z.string().min(5).max(500),
    })
    .safeParse(input);
  if (!parsed.success)
    return { ok: false, message: "Enter valid staff details." };
  const db = await platformClient();
  const { error } = await db.rpc("edit_staff_record", { p_input: parsed.data });
  if (error) return { ok: false, message: error.message };
  revalidatePath("/dashboard/staff");
  return { ok: true, message: "Staff details corrected." };
}
