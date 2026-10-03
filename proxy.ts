import { NextResponse, type NextRequest } from 'next/server';
import { updateSession } from '@/lib/supabase/middleware';
export async function proxy(request: NextRequest) {
 // Legacy pages are not wired to the applied Outlinerz database yet.
 if(request.nextUrl.pathname.startsWith('/dashboard') && !['/dashboard','/dashboard/setup'].includes(request.nextUrl.pathname)) {
  return NextResponse.redirect(new URL('/dashboard',request.url));
 }
 return updateSession(request);
}
export const config={matcher:['/dashboard/:path*','/onboarding','/organizations','/auth/:path*']};
