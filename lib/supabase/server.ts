import { createServerClient } from "@supabase/ssr";
import { cache } from "react";
import { boundedFetch } from "./fetch";
import { headers, cookies } from "next/headers";
import type { Database } from "@/types/database";

export const createClient = cache(async () => {
  const cookieStore = await cookies();
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  if (!url || !key) {
    throw new Error("Missing Supabase environment variables");
  }

  const client = createServerClient<Database>(url, key, {
    db: { schema: "public" },
    global: { fetch: boundedFetch, headers: { "x-academy-branch": cookieStore.get("academy-branch")?.value ?? "", "x-academy-public-branch": (await headers()).get("x-academy-public-slug") ?? cookieStore.get("academy-public-branch")?.value ?? process.env.NEXT_PUBLIC_BRANCH_SLUG ?? "" } },
    cookies: {
      getAll: () => cookieStore.getAll(),
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          );
        } catch {
          // Server Components cannot always write cookies.
        }
      },
    },
  });
  // Validate the cookie-backed user on this instance before it is used for data calls.
  // No stored session.user is ever used as an authorization decision.
  if (cookieStore.getAll().some(c => c.name.startsWith("sb-") && c.name.includes("auth-token"))) {
    await getVerifiedUser(client);
  }
  return client;
});

const verifiedUsers = new WeakMap<object, ReturnType<ReturnType<typeof createServerClient<Database>>["auth"]["getUser"]>>();
export function getVerifiedUser(client: ReturnType<typeof createServerClient<Database>>) {
  let verification = verifiedUsers.get(client);
  if (!verification) { verification = client.auth.getUser(); verifiedUsers.set(client, verification); }
  return verification;
}

