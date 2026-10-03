"use client";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
export function WorkflowReturn() {
  const params = useSearchParams();
  const value = params.get("returnTo");
  const safe =
    value &&
    (value === "/dashboard/setup" ||
      /^\/dashboard\/admissions(?:\/[0-9a-f-]{36})?(?:\?[^#]*)?$/.test(value));
  return safe ? (
    <div className="mb-5 flex flex-wrap items-center justify-between gap-3 rounded-xl border bg-card p-4 text-sm">
      <span>
        Your original workflow is saved. Finish this task, then continue where
        you left off.
      </span>
      <Link
        className="rounded-lg bg-primary px-4 py-2 font-semibold text-primary-foreground"
        href={value}
      >
        Save finished? Return to{" "}
        {value === "/dashboard/setup" ? "setup" : "admission"}
      </Link>
    </div>
  ) : null;
}
