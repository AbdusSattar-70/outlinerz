"use server";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { platformClient } from "@/modules/platform/rpc-client";
export async function saveOfferingDiscountPolicy(input: unknown) {
  const parsed = z
    .object({
      offeringId: z.string().uuid(),
      percentages: z
        .array(
          z
            .number()
            .int()
            .refine((v) => [5, 10, 15, 20, 25, 30].includes(v)),
        )
        .max(6),
    })
    .safeParse(input);
  if (!parsed.success)
    return { ok: false, message: "Choose valid discount percentages." };
  const db = await platformClient();
  const { error } = await db.rpc("save_offering_discount_policy", {
    p_input: {
      offering_id: parsed.data.offeringId,
      percentages: parsed.data.percentages,
    },
  });
  if (error) return { ok: false, message: error.message };
  revalidatePath("/dashboard/finance/fee-plans");
  revalidatePath("/dashboard/admissions");
  return { ok: true, message: "Discount policy saved." };
}
