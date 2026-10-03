import Link from 'next/link';
import { randomUUID } from 'node:crypto';
import { organizationSession } from '@/modules/organizations/server';
import { OnboardingForm } from '@/modules/organizations/forms';
export default async function OnboardingPage() {
 await organizationSession();
 return <main className="mx-auto max-w-xl px-5 py-12"><Link href="/" className="text-xl font-bold">Outlinerz</Link><h1 className="mt-10 text-3xl font-bold">আপনার প্রতিষ্ঠান শুরু করুন</h1><p className="my-5 text-muted-foreground">প্রতিষ্ঠান ও প্রথম শাখা একসঙ্গে তৈরি হবে। আপনি এই প্রতিষ্ঠানের owner হবেন।</p><OnboardingForm request={randomUUID()}/><Link className="mt-6 block underline" href="/organizations">আপনার Organizations তালিকা দেখুন</Link></main>;
}
