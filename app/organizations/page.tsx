import { LocalizedText as L } from "@/components/shared/localized-text";
import { PreferenceControls } from "@/components/shared/preference-controls";
import Link from "next/link";
import { redirect } from "next/navigation";
import { organizationSession } from "@/modules/organizations/server";
import { OrganizationPicker } from "@/modules/organizations/forms";
import { signOut } from "@/modules/organizations/actions";
export default async function OrganizationsPage() {
  const session = await organizationSession();
  if (!session.organizations.length) redirect("/onboarding");
  return (
    <main className="mx-auto max-w-xl px-5 py-12">
      <Link href="/" className="text-xl font-bold">
        Outlinerz
      </Link>
      <div className="mt-4">
        <PreferenceControls compact />
      </div>
      <h1 className="my-8 text-3xl font-bold">
        <L en="Your organizations" bn="আপনার প্রতিষ্ঠান" />
      </h1>
      <OrganizationPicker organizations={session.organizations} />
      <Link href="/onboarding" className="mt-6 block underline">
        <L en="Create another organization" bn="নতুন প্রতিষ্ঠান তৈরি করুন" />
      </Link>
      <form action={signOut} className="mt-6">
        <button className="underline">
          <L en="Sign out" bn="বের হন" />
        </button>
      </form>
    </main>
  );
}
