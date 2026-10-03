import Link from 'next/link';
import type { ReactNode } from 'react';
import { requireOrganization } from '@/modules/organizations/server';
import { signOut } from '@/modules/organizations/actions';
export default async function DashboardLayout({children}:{children:ReactNode}) {
 const {organization}=await requireOrganization();
 return <div className="min-h-screen bg-background"><header className="border-b"><div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-5 py-5"><Link href="/dashboard" className="text-xl font-bold">Outlinerz</Link><div><p className="font-semibold">{organization.name}</p><p className="text-xs text-muted-foreground">{organization.role}</p></div><nav className="flex flex-wrap items-center gap-5 text-sm"><Link href="/dashboard">Home</Link>{['OWNER','ADMIN'].includes(organization.role)&&<Link href="/dashboard/setup">Setup</Link>}<Link href="/organizations">Switch organization</Link><form action={signOut}><button>Sign out</button></form></nav></div></header><main className="mx-auto max-w-6xl px-5 py-8">{children}</main></div>;
}
