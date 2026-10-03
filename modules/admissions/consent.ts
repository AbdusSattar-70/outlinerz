import { createClient } from "@/lib/supabase/server";

export type PhysicalConsentReceipt = {
  id: string; admission_id: string; version: number; guardian_signed_on: string;
  student_signed: boolean; physical_copy_reference: string | null; received_at: string;
  received_by: string;
};

export async function getPhysicalConsentReceipts(): Promise<PhysicalConsentReceipt[]> {
  const db = await createClient();
  const table = db as unknown as { from: (name: string) => { select: (columns: string) => { order: (column: string, options: { ascending: boolean }) => Promise<{ data: PhysicalConsentReceipt[] | null; error: { message: string } | null }> } } };
  const { data, error } = await table.from("admission_physical_consent_receipts")
    .select("id,admission_id,version,guardian_signed_on,student_signed,physical_copy_reference,received_at,received_by")
    .order("received_at", { ascending: false });
  if (error) throw new Error(error.message);
  return data ?? [];
}
