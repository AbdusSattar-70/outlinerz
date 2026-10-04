"use client";

import Link from "next/link";
import { Search } from "lucide-react";
import { useMemo, useState } from "react";
import { StatusBadge } from "@/components/erp/status-badge";
import type { ProspectListRow } from "@/modules/crm/queries";

const statuses = [
  "QUEUE",
  "ALL",
  "NEW",
  "CONTACTED",
  "COUNSELLING",
  "TRIAL_SCHEDULED",
  "TRIAL_ATTENDED",
  "REGISTERED",
  "CONVERTED",
  "FUTURE_FOLLOW_UP",
  "LOST",
] as const;

const intents = ["ALL", "interest", "admission"] as const;

const QUEUE_STATUSES = new Set([
  "NEW",
  "CONTACTED",
  "COUNSELLING",
  "FUTURE_FOLLOW_UP",
]);

export function ProspectTable({ rows }: { rows: ProspectListRow[] }) {
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState<(typeof statuses)[number]>("QUEUE");
  const [intent, setIntent] = useState<(typeof intents)[number]>("ALL");
  const [needsReviewOnly, setNeedsReviewOnly] = useState(false);

  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase();

    return rows.filter((row) => {
      const matchesStatus =
        status === "ALL"
          ? true
          : status === "QUEUE"
            ? QUEUE_STATUSES.has(row.status)
            : row.status === status;
      const matchesIntent = intent === "ALL" || row.submissionIntent === intent;
      const matchesReview = !needsReviewOnly || row.schoolNeedsReview;
      const matchesQuery =
        !needle ||
        [
          row.prospectNo,
          row.studentName,
          row.guardianName,
          row.mobile,
          row.className,
          row.schoolName,
          row.sourceName,
          row.assignedTo,
          row.offeringLabel,
          row.submissionIntent,
        ].some((value) => value.toLowerCase().includes(needle));

      return matchesStatus && matchesIntent && matchesReview && matchesQuery;
    });
  }, [intent, needsReviewOnly, query, rows, status]);

  const queueCount = rows.filter((row) =>
    QUEUE_STATUSES.has(row.status),
  ).length;
  const reviewCount = rows.filter((row) => row.schoolNeedsReview).length;

  return (
    <section className="overflow-hidden rounded-2xl border bg-card">
      <div className="flex flex-col gap-3 border-b p-4">
        <div className="flex flex-wrap items-center gap-2 text-xs">
          <span className="rounded-full bg-blue-50 px-2.5 py-1 font-medium text-blue-800 dark:bg-blue-950/40 dark:text-blue-200">
            Queue: {queueCount}
          </span>
          <span className="rounded-full bg-amber-50 px-2.5 py-1 font-medium text-amber-900 dark:bg-amber-950/40 dark:text-amber-100">
            School review: {reviewCount}
          </span>
        </div>

        <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div className="relative w-full lg:max-w-sm">
            <Search
              className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
              aria-hidden="true"
            />
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search name, mobile, school, offering or prospect ID"
              className="min-h-11 w-full rounded-xl border bg-background pl-9 pr-3 text-sm outline-none focus-visible:ring-2 focus-visible:ring-ring"
              aria-label="Search prospects"
            />
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <label className="flex items-center gap-2 text-sm">
              <span className="text-muted-foreground">Status</span>
              <select
                value={status}
                onChange={(event) =>
                  setStatus(event.target.value as (typeof statuses)[number])
                }
                className="min-h-11 rounded-xl border bg-background px-3"
              >
                {statuses.map((item) => (
                  <option key={item} value={item}>
                    {item === "QUEUE"
                      ? "Verification queue"
                      : item.replaceAll("_", " ")}
                  </option>
                ))}
              </select>
            </label>

            <label className="flex items-center gap-2 text-sm">
              <span className="text-muted-foreground">Intent</span>
              <select
                value={intent}
                onChange={(event) =>
                  setIntent(event.target.value as (typeof intents)[number])
                }
                className="min-h-11 rounded-xl border bg-background px-3"
              >
                <option value="ALL">All</option>
                <option value="interest">Interest</option>
                <option value="admission">Admission</option>
              </select>
            </label>

            <label className="inline-flex min-h-11 cursor-pointer items-center gap-2 rounded-xl border px-3 text-sm">
              <input
                type="checkbox"
                checked={needsReviewOnly}
                onChange={(event) => setNeedsReviewOnly(event.target.checked)}
                className="size-4 accent-amber-700"
              />
              School needs review
            </label>
          </div>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="min-w-full text-left text-sm">
          <thead className="bg-muted/40 text-xs uppercase tracking-wide text-muted-foreground">
            <tr>
              <th className="px-4 py-3 font-medium">Prospect</th>
              <th className="px-4 py-3 font-medium">Student</th>
              <th className="px-4 py-3 font-medium">Class / School</th>
              <th className="px-4 py-3 font-medium">Intent / Offering</th>
              <th className="px-4 py-3 font-medium">Source</th>
              <th className="px-4 py-3 font-medium">Follow-up staff</th>
              <th className="px-4 py-3 font-medium">Next follow-up</th>
              <th className="px-4 py-3 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((row) => (
              <tr key={row.id} className="border-b align-top hover:bg-muted/30">
                <td className="px-4 py-3">
                  <Link
                    href={`/dashboard/crm/prospects/${row.id}`}
                    className="font-semibold text-blue-700 hover:underline dark:text-blue-300"
                  >
                    {row.prospectNo}
                  </Link>
                  <p className="mt-1 text-xs text-muted-foreground">
                    {new Date(row.createdAt).toLocaleDateString()}
                  </p>
                </td>
                <td className="px-4 py-3">
                  <Link
                    href={`/dashboard/crm/prospects/${row.id}`}
                    className="font-medium hover:underline"
                  >
                    {row.studentName}
                  </Link>
                  <p className="mt-1 text-xs text-muted-foreground">
                    {row.guardianName} • {row.mobile}
                  </p>
                </td>
                <td className="px-4 py-3">
                  <p>{row.className}</p>
                  <p className="mt-1 text-xs text-muted-foreground">
                    {row.schoolName}
                  </p>
                  {row.schoolNeedsReview ? (
                    <p className="mt-1 text-xs font-medium text-amber-800 dark:text-amber-200">
                      School needs review
                    </p>
                  ) : null}
                </td>
                <td className="px-4 py-3">
                  <p className="font-medium capitalize">
                    {row.submissionIntent}
                  </p>
                  <p className="mt-1 text-xs text-muted-foreground">
                    {row.offeringLabel}
                  </p>
                </td>
                <td className="px-4 py-3">{row.sourceName}</td>
                <td className="px-4 py-3">{row.assignedTo}</td>
                <td className="px-4 py-3">
                  {row.nextFollowUpAt ? (
                    <>
                      <p>{new Date(row.nextFollowUpAt).toLocaleDateString()}</p>
                      <p className="mt-1 text-xs text-muted-foreground">
                        {new Date(row.nextFollowUpAt).toLocaleTimeString([], {
                          hour: "2-digit",
                          minute: "2-digit",
                        })}
                      </p>
                    </>
                  ) : (
                    "—"
                  )}
                </td>
                <td className="px-4 py-3">
                  <StatusBadge value={row.status} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {!filtered.length && (
          <div className="p-8 text-center text-sm text-muted-foreground">
            No prospects match the current filters.
          </div>
        )}
      </div>

      <div className="border-t px-4 py-3 text-xs text-muted-foreground">
        Showing {filtered.length} of {rows.length} prospect records.
      </div>
    </section>
  );
}
