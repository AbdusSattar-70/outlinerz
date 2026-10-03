'use server';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { ORGANIZATION_COOKIE, organizationClient, organizationSession, requireOrganization, selectOrganizationCookie } from './server';

export type FormState = { error?: string; success?: string };
const organizationInput = z.object({ request: z.uuid(), name: z.string().trim().min(1).max(160), slug: z.string().regex(/^[a-z0-9][a-z0-9-]{2,62}$/), branch: z.string().trim().min(1).max(160) });
export async function onboardOrganization(_state: FormState, form: FormData): Promise<FormState> {
  const parsed = organizationInput.safeParse(Object.fromEntries(form));
  if (!parsed.success) return { error: 'নাম ও শাখা দিন। Slug-এ ৩–৬৩টি ছোট ইংরেজি অক্ষর, সংখ্যা বা hyphen ব্যবহার করুন।' };
  const { db } = await organizationSession();
  const { request, name, slug, branch } = parsed.data;
  const { data, error } = await db.rpc('onboard_organization', { p_request: request, p_name: name, p_slug: slug, p_branch_name: branch });
  if (error || !data) return { error: error?.code === '23505' ? 'এই slug ইতিমধ্যে ব্যবহৃত হয়েছে। অন্য slug দিন।' : 'প্রতিষ্ঠান তৈরি নিশ্চিত করা যায়নি। Organizations তালিকা দেখুন; একই তথ্য অপরিবর্তিত রেখে আবার চেষ্টা করতে পারেন।' };
  await selectOrganizationCookie(data.organization_id);
  redirect('/dashboard/setup');
}
export async function switchOrganization(_state: FormState, form: FormData): Promise<FormState> {
  const session = await organizationSession();
  const id = String(form.get('organization') ?? '');
  if (!session.organizations.some(o => o.id === id)) return { error: 'এই প্রতিষ্ঠানে আপনার active membership নেই।' };
  await selectOrganizationCookie(id);
  redirect('/dashboard');
}
export async function signOut() {
  const db = await organizationClient();
  const { error } = await db.auth.signOut();
  if (error) throw new Error('Sign out failed. Please retry.');
  (await cookies()).delete(ORGANIZATION_COOKIE);
  redirect('/auth/sign-in');
}
export async function addSetupRecord(_state: FormState, form: FormData): Promise<FormState> {
  const { db, organization } = await requireOrganization();
  if (!['OWNER', 'ADMIN'].includes(organization.role)) return { error: 'Setup পরিবর্তনের অনুমতি নেই।' };
  const name = z.string().trim().min(1).max(160).safeParse(form.get('name'));
  if (!name.success) return { error: 'একটি নাম দিন।' };
  const kind = form.get('kind');
  let error;
  if (kind === 'year') {
    const start = String(form.get('starts_on') ?? ''), end = String(form.get('ends_on') ?? '');
    if (!/^\d{4}-\d{2}-\d{2}$/.test(start) || !/^\d{4}-\d{2}-\d{2}$/.test(end) || end < start) return { error: 'সঠিক শুরু ও শেষের তারিখ দিন।' };
    ({ error } = await db.from('academic_years').insert({ organization_id: organization.id, name: name.data, starts_on: start, ends_on: end }));
  } else if (kind === 'class' || kind === 'subject') {
    ({ error } = await db.from(kind === 'class' ? 'class_levels' : 'subjects').insert({ organization_id: organization.id, name: name.data }));
  } else return { error: 'Unknown setup record.' };
  if (error) return { error: error.code === '23505' ? 'এই নাম ইতিমধ্যে আছে।' : 'তথ্য সংরক্ষণ হয়নি। আবার চেষ্টা করুন।' };
  revalidatePath('/dashboard/setup');
  return { success: 'সংরক্ষিত হয়েছে।' };
}
