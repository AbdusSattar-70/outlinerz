"use client";
import Link from "next/link";
export default function CaseError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return <section className="space-y-4 rounded-2xl border p-6"><h2 className="text-xl font-semibold">The admission case could not be refreshed</h2><p className="text-sm text-muted-foreground">The connection may have timed out. A previous save may already have completed. Reload the case to check its recorded state before submitting the same financial action again.</p>{error.digest && <p className="text-xs">Support reference: {error.digest}</p>}<button onClick={reset} className="rounded-lg border px-4 py-2">Reload case</button><Link className="ml-3 underline" href="/dashboard/admissions">Admission register</Link></section>;
}
