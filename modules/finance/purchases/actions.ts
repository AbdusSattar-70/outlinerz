"use server";
import { z } from "zod";
import { platformClient } from "@/modules/platform/rpc-client";
import { runCommandAction } from "@/modules/platform/command-action";
const schema = z.object({ action: z.enum(["SAVE", "CANCEL", "RECEIVE", "PAY", "CREATE_VENDOR"]), request_id: z.string().uuid(), reason: z.string().trim().min(5).max(1000), id: z.string().uuid().optional(), revision: z.number().int().positive().optional(), vendor_id: z.string().uuid().optional(), category_id: z.string().uuid().optional(), description: z.string().max(1000).optional(), items: z.array(z.object({ name: z.string().trim().min(2).max(200), quantity: z.number().positive().max(100000), price: z.number().positive().max(999999999999.99) })).min(1).max(30).optional(), expected_on: z.string().optional(), received_on: z.string().optional(), invoice_reference: z.string().max(200).optional(), confirmed_received: z.boolean().optional(), payment_mode: z.enum(["PAID_NOW", "ON_ACCOUNT"]).optional(), payment_account_id: z.string().uuid().optional(), amount: z.number().positive().optional(), external_reference: z.string().max(200).optional(), name: z.string().max(200).optional(), mobile: z.string().max(30).optional(), email: z.string().max(200).optional(), address: z.string().max(1000).optional() });
export async function purchaseAction(input: unknown) { try {
    return await runCommandAction({ schema, input, client: platformClient, rpc: "purchase_command", permission: "accounting.expense.manage", revalidate: ["/dashboard/finance/purchases", "/dashboard/finance/accounting", "/dashboard/finance/reports", "/dashboard/finance/daily-close"], mapResult: (data) => ({ message: (data as {
                message: string;
            }).message, id: (data as {
                id: string;
            }).id }) });
}
catch {
    return { ok: false as const, message: "Could not confirm the result. Check the register before changing inputs; unchanged retries reuse the same request identity." };
} }
