import {NextResponse,type NextRequest} from "next/server";
import {updateSession} from "@/lib/supabase/middleware";
export async function proxy(request:NextRequest){
 request.headers.set("x-erp-pathname",request.nextUrl.pathname);
 request.headers.delete("x-academy-public-slug");
 const requested=request.nextUrl.searchParams.get("branch");const slug=requested&&/^[a-z0-9][a-z0-9-]{2,62}$/.test(requested)?requested:request.cookies.get("academy-public-branch")?.value??process.env.NEXT_PUBLIC_BRANCH_SLUG??"";
 request.headers.set("x-academy-public-slug",slug);
 const response=request.nextUrl.pathname.startsWith("/dashboard")||request.nextUrl.pathname.startsWith("/branches")?await updateSession(request):NextResponse.next({request});
 if(requested===slug)response.cookies.set("academy-public-branch",slug,{httpOnly:true,sameSite:"lax",secure:process.env.NODE_ENV==="production",path:"/",maxAge:60*60*24*30});return response;
}
export const config={matcher:["/((?!_next/static|_next/image|favicon.ico|branding|favicons|fonts).*)"]};
