import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";
export async function GET(request: NextRequest) {
  const hash = request.nextUrl.searchParams.get("token_hash"),
    type = request.nextUrl.searchParams.get("type"),
    code = request.nextUrl.searchParams.get("code");
  const db = await createClient();
  let error: unknown = "Missing confirmation token";
  if (
    hash &&
    (type === "invite" ||
      type === "recovery" ||
      type === "email_change" ||
      type === "signup")
  ) {
    ({ error } = await db.auth.verifyOtp({ token_hash: hash, type }));
  } else if (code) {
    ({ error } = await db.auth.exchangeCodeForSession(code));
  }
  return NextResponse.redirect(
    new URL(
      error ? "/auth/sign-in?error=confirmation" : type === "recovery" || type === "invite" ? "/auth/update-password" : "/dashboard",
      request.url,
    ),
  );
}
