import { LocalizedText } from "@/components/shared/localized-text";
import Link from "next/link";
import { StaffAccessRequestForm } from "@/modules/platform/access/request-form";
export default function SignUpPage() {
  return (
    <main className="mx-auto max-w-xl px-5 py-12">
      <Link href="/auth" className="text-sm underline">
        <LocalizedText en="Back to Digital Campus" bn="ডিজিটাল ক্যাম্পাসে ফিরুন"/>
      </Link>
      <section className="mt-6 rounded-3xl border bg-card p-7">
        <h1 className="text-2xl font-bold"><LocalizedText en="Request academy staff access" bn="একাডেমির স্টাফ প্রবেশাধিকারের অনুরোধ"/></h1>
        <p className="my-5 text-sm text-muted-foreground">
          <LocalizedText en="Choose your intended role. An administrator verifies your identity and responsibilities before emailing secure account setup instructions. Referral partners receive access through the academy; students and guardians can apply without an account." bn="দায়িত্ব নির্বাচন করুন। অ্যাডমিন পরিচয় ও দায়িত্ব যাচাই করে অ্যাকাউন্ট চালুর নিরাপদ নির্দেশনা ইমেইলে পাঠাবেন। রেফারেল সহযোগীরা একাডেমির মাধ্যমে প্রবেশাধিকার পাবেন; শিক্ষার্থী ও অভিভাবক অ্যাকাউন্ট ছাড়াই আবেদন করতে পারেন।"/>
        </p>
        <StaffAccessRequestForm />
      </section>
    </main>
  );
}
