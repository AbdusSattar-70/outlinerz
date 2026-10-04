"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
export function OverviewReturnLink() {
  const path = usePathname();
  return (
    <Link
      className="mb-3 inline-block text-xs text-muted-foreground underline print:hidden"
      href={path === "/dashboard" ? "/" : "/dashboard"}
    >
      {path === "/dashboard" ? "← Public website" : "← Back to overview"}
    </Link>
  );
}
