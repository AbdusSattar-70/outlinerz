"use server";
import { z } from "zod";
import { organizationClient } from "@/modules/organizations/server";
import {
  publicInterestSchema,
  type PublicInterestInput,
} from "@/lib/academy/public-interest-schema";
export type PublicInterestResult =
  | { ok: true; prospectNo: string | null }
  | { ok: false; error: string; field?: string | null };
export async function submitPublicInterest(
  input: PublicInterestInput,
  slug: string,
  requestId: string,
): Promise<PublicInterestResult> {
  if (input.website) return { ok: true, prospectNo: null };
  const parsed = publicInterestSchema.safeParse(input);
  if (!parsed.success)
    return {
      ok: false,
      error: "Please check the registration details.",
      field: parsed.error.issues[0]?.path[0]?.toString(),
    };
  if (
    !z.uuid().safeParse(requestId).success ||
    !z
      .string()
      .regex(/^[a-z0-9][a-z0-9-]{2,62}$/)
      .safeParse(slug).success
  )
    return { ok: false, error: "Registration is unavailable." };
  const db = await organizationClient();
  const { data, error } = await db.rpc("crm_public_interest", {
    p_slug: slug,
    p_request: requestId,
    p_payload: parsed.data,
  });
  if (error)
    return {
      ok: false,
      error:
        "Could not submit. Check the selected programme or try again later.",
    };
  return { ok: true, prospectNo: data.prospect_no };
}
