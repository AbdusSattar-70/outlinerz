import { LocalizedText } from "@/components/shared/localized-text";
import Link from "next/link";
import { BranchAccountForm } from "@/modules/branches/sign-up-form";
import { PreferenceControls } from "@/components/shared/preference-controls";
export default function SignUpPage() {
  return (
    <main className="mx-auto max-w-xl px-5 py-12">
      <Link href="/auth" className="text-sm underline">
        <LocalizedText en="Back to Digital Campus" bn="ডিজিটাল ক্যাম্পাসে ফিরুন"/>
      </Link>
      <section className="mt-6 rounded-3xl border bg-card p-7">
        <h1 className="text-2xl font-bold"><LocalizedText en="Create your academy account" bn="একাডেমির অ্যাকাউন্ট তৈরি করুন"/></h1>
        <p className="my-5 text-sm text-muted-foreground">
          <LocalizedText en="Verify your email to open an institution’s first branch. Staff can create an account and ask their administrator to add it to the correct branch. Students and guardians can apply without an account." bn="প্রতিষ্ঠানের প্রথম শাখা খুলতে ইমেইল যাচাই করুন। স্টাফ অ্যাকাউন্ট তৈরি করে প্রশাসককে সঠিক শাখায় যুক্ত করতে বলতে পারেন। শিক্ষার্থী ও অভিভাবক অ্যাকাউন্ট ছাড়াই আবেদন করতে পারেন."/>
        </p>
        <PreferenceControls className="mb-5 w-fit"/><BranchAccountForm />
      </section>
    </main>
  );
}
