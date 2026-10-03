import { z } from "zod";
import { PageHeader } from "@/components/erp/page-header";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { getAcademicWorkspace } from "@/modules/academics/operations/queries";
import { AcademicOperations } from "@/modules/academics/operations/workspace";
export default async function AcademicPage({
  searchParams,
}: {
  searchParams: Promise<{ from?: string; to?: string }>;
}) {
  const context = await requirePermission("academics.view");
  const query = await searchParams;
  const today = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Dhaka",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
  const date = z.iso.date();
  const from = date.safeParse(query.from).success
    ? query.from!
    : today.slice(0, 8) + "01";
  const fallback = new Date(`${from}T00:00:00Z`);
  fallback.setUTCDate(fallback.getUTCDate() + 30);
  const to =
    date.safeParse(query.to).success &&
    query.to! >= from &&
    Date.parse(query.to!) - Date.parse(from) <= 366 * 86400000
      ? query.to!
      : fallback.toISOString().slice(0, 10);
  const data = await getAcademicWorkspace(from, to);
  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="Academics"
        title="Academic Operations"
        description="Plan curriculum, reserve weekly slots, schedule real classes and finalize attendance through independent review."
      />
      <form className="flex flex-wrap items-end gap-3 rounded-xl border p-4">
        <label className="text-sm">
          Sessions from
          <input
            className="ml-2 min-h-11 rounded-lg border bg-background px-3"
            type="date"
            name="from"
            defaultValue={from}
            required
          />
        </label>
        <label className="text-sm">
          Through
          <input
            className="ml-2 min-h-11 rounded-lg border bg-background px-3"
            type="date"
            name="to"
            defaultValue={to}
            required
          />
        </label>
        <button
          className="min-h-11 rounded-lg border px-4 text-sm font-semibold"
          type="submit"
        >
          Show Sessions
        </button>
      </form>
      <AcademicOperations data={data} permissions={context.permissions} />
    </div>
  );
}
