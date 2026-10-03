import Link from "next/link";
import { GraduationCap } from "lucide-react";
import { EmptyState } from "@/components/erp/empty-state";
import { PageHeader } from "@/components/erp/page-header";
import { StatusBadge } from "@/components/erp/status-badge";
import { getStudentList } from "@/modules/students/queries";
import { requirePermission } from "@/modules/platform/auth/erp-context";

export default async function StudentsPage() {
  await requirePermission("students.view");
  const rows = await getStudentList();

  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow="Student Core"
        title="Students"
        description="Permanent Student identities remain stable across academic years, batches, fee terms and lifecycle changes."
      />

      {rows.length ? (
        <section className="overflow-hidden rounded-2xl border bg-card">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[760px] text-sm">
              <thead>
                <tr className="border-b bg-muted/40 text-left">
                  <th className="px-4 py-3 font-semibold">Student ID</th>
                  <th className="px-4 py-3 font-semibold">Name</th>
                  <th className="px-4 py-3 font-semibold">School</th>
                  <th className="px-4 py-3 font-semibold">Status</th>
                  <th className="px-4 py-3 font-semibold">Created</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.id} className="border-b hover:bg-muted/30">
                    <td className="px-4 py-3 font-semibold">
                      <Link
                        className="underline underline-offset-4"
                        href={`/dashboard/students/${row.id}`}
                      >
                        {row.studentNo}
                      </Link>
                    </td>
                    <td className="px-4 py-3">{row.fullName}</td>
                    <td className="px-4 py-3">{row.schoolName}</td>
                    <td className="px-4 py-3">
                      <StatusBadge value={row.status} />
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {new Date(row.createdAt).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      ) : (
        <EmptyState
          icon={GraduationCap}
          title="No admitted students yet"
          description="Students will appear here after the v2 admission workflow creates a permanent Student identity. Prospect records remain separate until conversion."
        />
      )}
    </div>
  );
}
