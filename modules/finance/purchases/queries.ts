import { z } from "zod";
import { platformClient } from "@/modules/platform/rpc-client";
const choice = z.object({ id: z.string().uuid(), name: z.string() });
export const purchaseSchema = z.object({ page: z.number(), total: z.number(), canPay: z.boolean(), vendors: z.array(choice), categories: z.array(choice), accounts: z.array(choice), rows: z.array(z.object({ id: z.string().uuid(), purchase_no: z.string(), vendor_id: z.string().uuid(), category_id: z.string().uuid(), description: z.string(), items: z.array(z.object({ name: z.string(), quantity: z.number(), price: z.number() })), total: z.number(), expected_on: z.string().nullable(), status: z.enum(["DRAFT", "POSTED", "CANCELLED"]), revision: z.number(), supplier: z.string(), category: z.string(), invoice_reference: z.string().nullable(), received_on: z.string().nullable(), expense_no: z.string().nullable(), payment_mode: z.string().nullable(), payable_id: z.string().nullable(), remaining: z.number() })) });
export type PurchaseData = z.infer<typeof purchaseSchema>;
export async function getPurchases(page: number, status: string, search: string) { const db = await platformClient(); const { data, error } = await db.rpc("purchase_workspace", { p_page: page, p_status: status, p_search: search }); if (error)
    throw Error(error.message); return purchaseSchema.parse(data); }
