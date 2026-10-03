import 'server-only';
import { cache } from 'react';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { createServerClient } from '@supabase/ssr';
import { boundedFetch } from '@/lib/supabase/fetch';
import type { OrganizationDatabase } from './database';

export const ORGANIZATION_COOKIE = 'outlinerz-organization';
export const organizationClient = cache(async () => {
  const store = await cookies();
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) throw new Error('Configure the Supabase URL and publishable key for Outlinerz.');
  return createServerClient<OrganizationDatabase>(url, key, {
    global: { fetch: boundedFetch },
    cookies: {
      getAll: () => store.getAll(),
      setAll: (values) => {
        try { values.forEach(({ name, value, options }) => store.set(name, value, options)); }
        catch { /* Proxy refreshes cookies during Server Component requests. */ }
      },
    },
  });
});
export const organizationSession = cache(async () => {
  const db = await organizationClient();
  const { data: { user }, error } = await db.auth.getUser();
  if (error || !user) redirect('/auth/sign-in');
  const { data: memberships, error: membershipError } = await db.from('memberships')
    .select('organization_id,role').eq('user_id', user.id).eq('active', true);
  if (membershipError) throw new Error('Organization access could not be loaded. Check the database setup and retry.');
  const ids = (memberships ?? []).map(m => m.organization_id);
  if (!ids.length) return { db, user, organizations: [] };
  const { data: organizations, error: orgError } = await db.from('organizations')
    .select('id,name,slug,currency,timezone').in('id', ids).order('name');
  if (orgError) throw new Error('Organizations could not be loaded.');
  return { db, user, organizations: (organizations ?? []).map(o => ({ ...o, role: memberships!.find(m => m.organization_id === o.id)!.role })) };
});
export const requireOrganization = cache(async () => {
  const session = await organizationSession();
  if (!session.organizations.length) redirect('/onboarding');
  const selected = (await cookies()).get(ORGANIZATION_COOKIE)?.value;
  const organization = session.organizations.find(o => o.id === selected)
    ?? (!selected && session.organizations.length === 1 ? session.organizations[0] : undefined);
  if (!organization) redirect('/organizations');
  return { ...session, organization };
});
export async function selectOrganizationCookie(id: string) {
  (await cookies()).set(ORGANIZATION_COOKIE, id, { httpOnly: true, sameSite: 'lax', secure: process.env.NODE_ENV === 'production', path: '/', maxAge: 60 * 60 * 24 * 30 });
}
