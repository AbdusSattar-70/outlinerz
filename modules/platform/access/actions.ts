"use server";
import { z } from "zod";
import { sendAccountSetup } from "@/lib/supabase/account-setup";
import { revalidatePath } from "next/cache";
import { getErpContext } from "../auth/erp-context";
import { platformClient } from "../rpc-client";
const roles = z.enum(["ADMIN", "OPERATOR", "TEACHER", "ACCOUNTANT"]);
const requestSchema = z.object({
  full_name: z.string().trim().min(2).max(160),
  email: z.email().max(254),
  mobile: z.string().regex(/^01[3-9][0-9]{8}$/),
  requested_role: roles,
  purpose: z.string().trim().min(5).max(500),
  website: z.string().max(0).optional(),
});
export async function requestStaffAccess(input: unknown) {
  const parsed = requestSchema.safeParse(input);
  if (!parsed.success)
    return {
      ok: false,
      message: parsed.error.issues[0]?.message ?? "Check your details.",
    };
  const db = await platformClient();
  const { error } = await db.rpc("request_staff_access", {
    p_input: parsed.data,
  });
  return error
    ? {
        ok: false,
        message: "Could not receive your request. Please try again.",
      }
    : {
        ok: true,
        message:
          "Your access request has been received. An administrator will verify your identity and responsibilities, then email secure account setup instructions. Access is granted only after verification.",
        messageBn:"আপনার প্রবেশাধিকারের অনুরোধ পাওয়া গেছে। অ্যাডমিন পরিচয় ও দায়িত্ব যাচাই করে ইমেইলে নিরাপদভাবে অ্যাকাউন্ট চালুর নির্দেশনা পাঠাবেন। যাচাইয়ের আগে কোনো প্রবেশাধিকার দেওয়া হয় না।",
      };
}
const reviewSchema = z.object({
  id: z.string().uuid(),
  action: z.enum(["VERIFY", "DECLINE", "INVITE"]),
  assigned_role: roles,
  reason: z.string().trim().min(5).max(500),
});
export async function reviewStaffAccess(input: unknown) {
  const parsed = reviewSchema.safeParse(input);
  if (!parsed.success)
    return { ok: false, message: "Choose a role and verification note." };
  const context = await getErpContext();
  if (
    !context?.roles.includes("ADMIN") ||
    !context.permissions.includes("system.users.manage")
  )
    return { ok: false, message: "Super admin verification required." };
  const value = parsed.data,
    db = await platformClient();
  if (value.action !== "INVITE") {
    const { error } = await db.rpc("review_staff_access", { p_input: value });
    if (error) return { ok: false, message: error.message };
  } else {
    const { data: r, error: readError } = await db
      .from("staff_access_requests")
      .select("email,full_name,status")
      .eq("id", value.id)
      .single();
    if (readError || !r || !["VERIFIED", "INVITED"].includes(r.status))
      return {
        ok: false,
        message: "Verify the request before sending an invitation.",
      };
    const sent=await sendAccountSetup(r.email,r.full_name);
    if(!sent.ok)return sent;
    const { error: completeError } = await db.rpc("review_staff_access", {
      p_input: { ...value, action: "COMPLETE_INVITATION" },
    });
    if (completeError)
      return {
        ok: false,
        message: `Invitation sent, but access assignment failed: ${completeError.message}. Retry this verified request; do not create another account.`,
      };
  }
  revalidatePath("/dashboard/staff");
  revalidatePath("/dashboard/settings");
  revalidatePath("/dashboard/action-center");
  return {
    ok: true,
    message:
      value.action === "INVITE"
        ? "Secure account setup instructions sent. The verified role is now assigned."
        : "Request updated.",
    messageBn: value.action==="INVITE"?"নিরাপদভাবে অ্যাকাউন্ট চালুর নির্দেশনা পাঠানো হয়েছে এবং যাচাইকৃত ভূমিকা দেওয়া হয়েছে।":"অনুরোধ আপডেট হয়েছে।",
  };
}
