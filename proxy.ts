import type { NextRequest } from "next/server";
import { updateSession } from "@/lib/supabase/middleware";

export async function proxy(request: NextRequest) {
  request.headers.set("x-erp-pathname", request.nextUrl.pathname);
  return updateSession(request);
}

export const config = {
  matcher: ["/dashboard/:path*"],
};
