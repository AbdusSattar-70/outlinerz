import { LocalizedText as L } from "@/components/shared/localized-text";
import { PreferenceControls } from "@/components/shared/preference-controls";
import Link from "next/link";
import { randomUUID } from "node:crypto";
import { organizationSession } from "@/modules/organizations/server";
import { OnboardingForm } from "@/modules/organizations/forms";
export default async function OnboardingPage() {
  await organizationSession();
  return (
    <main className="mx-auto max-w-xl px-5 py-12">
      <Link href="/" className="text-xl font-bold">
        Outlinerz
      </Link>
      <div className="mt-4">
        <PreferenceControls compact />
      </div>
      <h1 className="mt-10 text-3xl font-bold">
        <L en="Start your organization" bn="আপনার প্রতিষ্ঠান শুরু করুন" />
      </h1>
      <p className="my-5 text-muted-foreground">
        <L
          en="Your organization and first branch are created together. You become its owner."
          bn="প্রতিষ্ঠান ও প্রথম শাখা একসঙ্গে তৈরি হবে। আপনি এই প্রতিষ্ঠানের মালিক হবেন।"
        />
      </p>
      <OnboardingForm request={randomUUID()} />
      <Link className="mt-6 block underline" href="/organizations">
        <L en="View your organizations" bn="আপনার প্রতিষ্ঠানের তালিকা দেখুন" />
      </Link>
    </main>
  );
}
