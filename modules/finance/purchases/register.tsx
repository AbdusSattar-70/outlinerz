"use client";
import { startTransition, useState } from "react";
import Link from "next/link";
import { purchaseAction } from "./actions";
import type { PurchaseData } from "./queries";
type Row = PurchaseData["rows"][number];
const money = (n: number) => new Intl.NumberFormat("en-BD", { style: "currency", currency: "BDT" }).format(n);
const today = () => new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Dhaka", year: "numeric", month: "2-digit", day: "2-digit" }).format(new Date());
export function PurchaseRegister({ data, status, search }: {
    data: PurchaseData;
    status: string;
    search: string;
}) {
    const [form, setForm] = useState<{
        action: "SAVE" | "RECEIVE" | "CANCEL" | "PAY" | "CREATE_VENDOR";
        row?: Row;
    } | null>(null);
    const [pending, setPending] = useState(false);
    const [notice, setNotice] = useState<{
        ok: boolean;
        message: string;
    } | null>(null);
    const [items, setItems] = useState([{ name: "", quantity: 1, price: 0 }]);
    const [mode, setMode] = useState("ON_ACCOUNT");
    const [request, setRequest] = useState("");
    const [previous, setPrevious] = useState("");
    const [supplier, setSupplier] = useState("");
    const [extraSuppliers, setExtraSuppliers] = useState<{
        id: string;
        name: string;
    }[]>([]);
    const [addingSupplier, setAddingSupplier] = useState(false);
    function open(action: NonNullable<typeof form>["action"], row?: Row) { setForm({ action, row }); setSupplier(row?.vendor_id ?? ""); setAddingSupplier(false); setItems(row?.items ?? [{ name: "", quantity: 1, price: 0 }]); setMode("ON_ACCOUNT"); setRequest(crypto.randomUUID()); setPrevious(""); setNotice(null); }
    async function submit(e: React.FormEvent<HTMLFormElement>) { e.preventDefault(); if (!form || pending)
        return; const values = Object.fromEntries(new FormData(e.currentTarget)); const { row, action } = form; const input = { ...values, action, ...(row ? { id: row.id, revision: row.revision } : {}), ...(action === "SAVE" ? { items } : {}), ...(action === "RECEIVE" ? { confirmed_received: values.confirmed_received === "on" } : {}), ...(action === "PAY" ? { amount: Number(values.amount) } : {}) }; const fingerprint = JSON.stringify(input); const req = previous && previous !== fingerprint ? crypto.randomUUID() : request; setRequest(req); setPrevious(fingerprint); setPending(true); startTransition(async () => { try {
        const result = await purchaseAction({ ...input, request_id: req });
        setNotice(result);
        if (result.ok) {
            setForm(null);
        }
    }
    catch {
        setNotice({ ok: false, message: "Could not confirm completion. Check the register before changing inputs, then retry unchanged if needed." });
    }
    finally {
        setPending(false);
    } }); }
    const options = (list: {
        id: string;
        name: string;
    }[]) => list.map(x => <option key={x.id} value={x.id}>{x.name}</option>);
    const field = (label: string, name: string, type = "text", value?: string, required = true) => <label className="grid gap-1">{label}<input className="rounded border bg-background p-2" name={name} type={type} defaultValue={value} required={required} step={type === "number" ? "0.01" : undefined} min={type === "number" ? "0.01" : undefined}/></label>;
    return <div className="space-y-5">
 <div className="flex flex-wrap gap-3"><button className="rounded border px-4 py-2" disabled={pending} onClick={() => open("SAVE")}>Create purchase draft</button><button className="rounded border px-4 py-2" disabled={pending} onClick={() => open("CREATE_VENDOR")}>Add supplier</button><Link className="px-3 py-2 underline" href="/dashboard/finance/accounting">Other expenses & advances</Link></div>
 <p className="text-sm text-muted-foreground">Use this register for operating expenses and consumables. Durable equipment belongs in the upcoming asset workflow. Confirm the full delivery before posting; partial delivery and advance payment use separate workflows.</p>
 {notice && <p role={notice.ok ? "status" : "alert"} className={notice.ok ? "text-emerald-500" : "text-red-500"}>{notice.message}</p>}
 {form && <form key={`${form.action}:${form.row?.id ?? "new"}`} onSubmit={submit} className="space-y-4 rounded border p-5"><h2 className="text-xl font-semibold">{form.action === "SAVE" ? (form.row ? "Edit purchase draft" : "New purchase draft") : form.action === "RECEIVE" ? "Verify receipt & post expense" : form.action === "PAY" ? "Record supplier payment" : form.action === "CANCEL" ? "Cancel unused draft" : "New supplier"}{form.row ? ` · ${form.row.purchase_no}` : ""}</h2><fieldset disabled={pending} className="space-y-4">
 {form.action === "SAVE" && <><div className="grid gap-4 md:grid-cols-2"><label className="grid gap-1">Supplier<select name="vendor_id" value={supplier} onChange={e => setSupplier(e.target.value)} required className="rounded border bg-background p-2"><option value="">Select supplier</option>{options([...data.vendors, ...extraSuppliers.filter(x => !data.vendors.some(v => v.id === x.id))])}</select><button type="button" onClick={() => setAddingSupplier(!addingSupplier)}>{addingSupplier ? "Close supplier entry" : "Supplier missing? Add here"}</button></label><label className="grid gap-1">Expense category<select name="category_id" defaultValue={form.row?.category_id ?? ""} required className="rounded border bg-background p-2"><option value="">Select expense category</option>{options(data.categories)}</select></label>{field("Purpose / description", "description", "text", form.row?.description)}{field("Expected delivery (optional)", "expected_on", "date", form.row?.expected_on ?? undefined, false)}</div>{addingSupplier && <InlineSupplier busy={pending} onBusy={setPending} onSaved={(id, name) => { setExtraSuppliers([...extraSuppliers, { id, name }]); setSupplier(id); setAddingSupplier(false); }}/>}<div className="space-y-2"><p>Items · quantity × unit price (BDT)</p>{items.map((item, i) => <div className="grid gap-2 md:grid-cols-4" key={i}><input aria-label={`Item ${i + 1}`} required minLength={2} className="rounded border bg-background p-2" value={item.name} onChange={e => setItems(items.map((x, j) => j === i ? { ...x, name: e.target.value } : x))}/><input aria-label={`Quantity ${i + 1}`} type="number" min="0.001" max="100000" step="0.001" required className="rounded border bg-background p-2" value={item.quantity} onChange={e => setItems(items.map((x, j) => j === i ? { ...x, quantity: Number(e.target.value) } : x))}/><input aria-label={`Unit price ${i + 1}`} type="number" min="0.01" step="0.01" required className="rounded border bg-background p-2" value={item.price} onChange={e => setItems(items.map((x, j) => j === i ? { ...x, price: Number(e.target.value) } : x))}/><button type="button" disabled={items.length === 1} onClick={() => setItems(items.filter((_, j) => j !== i))}>Remove item</button></div>)}<button type="button" disabled={items.length >= 30} onClick={() => setItems([...items, { name: "", quantity: 1, price: 0 }])}>+ Add item</button><p className="font-semibold">Total: {money(items.reduce((n, x) => n + Math.round(x.quantity * x.price * 100) / 100, 0))}</p></div></>}
 {form.action === "CREATE_VENDOR" && <div className="grid gap-4 md:grid-cols-2">{field("Supplier name", "name")}{field("Mobile (optional)", "mobile", "tel", undefined, false)}{field("Email (optional)", "email", "email", undefined, false)}{field("Address (optional)", "address", "text", undefined, false)}</div>}
 {form.action === "RECEIVE" && <><p>{form.row?.supplier} · {money(form.row?.total ?? 0)}. This posts the reviewed draft total. Correct the draft first if the invoice differs.</p><div className="grid gap-4 md:grid-cols-2">{field("Received / expense date", "received_on", "date", today())}{field("Supplier invoice / receipt reference", "invoice_reference")}<label className="grid gap-1">Payment treatment<select name="payment_mode" value={mode} onChange={e => setMode(e.target.value)} className="rounded border bg-background p-2"><option value="ON_ACCOUNT">Pay later · supplier payable</option>{data.canPay && <option value="PAID_NOW">Full amount paid now</option>}</select></label>{mode === "PAID_NOW" && <label className="grid gap-1">Paid from<select name="payment_account_id" required className="rounded border bg-background p-2"><option value="">Select account</option>{options(data.accounts)}</select></label>}</div><label className="flex gap-2"><input type="checkbox" name="confirmed_received" required/>I checked all goods / services, invoice total and receipt evidence.</label></>}
 {form.action === "PAY" && <><p>Outstanding supplier balance: {money(form.row?.remaining ?? 0)}. Record money actually paid; partial payment is allowed.</p><div className="grid gap-4 md:grid-cols-2">{field("Amount paid (BDT)", "amount", "number", String(form.row?.remaining ?? 0))}{field("Payment reference", "external_reference")}<label className="grid gap-1">Paid from<select name="payment_account_id" required className="rounded border bg-background p-2"><option value="">Select account</option>{options(data.accounts)}</select></label></div></>}
 {form.action === "CANCEL" && <p>Cancel this unused draft. No accounting record is removed or reversed.</p>}
 <label className="grid gap-1">Reason / verification note<textarea name="reason" required minLength={5} maxLength={1000} className="rounded border bg-background p-2"/></label><div className="flex gap-3"><button className="rounded bg-primary px-4 py-2 text-primary-foreground" type="submit">{pending ? "Saving…" : form.action === "RECEIVE" ? "Confirm receipt & post" : form.action === "PAY" ? "Record payment" : "Save"}</button><button type="button" onClick={() => setForm(null)}>Close</button></div></fieldset></form>}
 <form className="flex flex-wrap gap-3"><input name="q" aria-label="Search purchases" defaultValue={search} maxLength={100} placeholder="Purchase, supplier or purpose" className="rounded border bg-background p-2"/><select name="status" defaultValue={status} className="rounded border bg-background p-2">{["ALL", "DRAFT", "POSTED", "CANCELLED"].map(x => <option key={x}>{x}</option>)}</select><button className="rounded border px-4">Search</button></form>
 <div className="overflow-x-auto rounded border"><table className="w-full text-sm"><thead><tr>{["Purchase / purpose", "Supplier / category", "Amount", "Status", "Expense / balance", "Actions"].map(x => <th className="p-3 text-left" key={x}>{x}</th>)}</tr></thead><tbody>{data.rows.map(row => <tr className="border-t" key={row.id}><td className="p-3"><strong>{row.purchase_no}</strong><p>{row.description}</p><p className="text-muted-foreground">{row.expected_on ? `Expected ${row.expected_on}` : ""}</p></td><td className="p-3">{row.supplier}<p className="text-muted-foreground">{row.category}</p></td><td className="p-3">{money(row.total)}</td><td className="p-3"><span className={row.status === "POSTED" ? "text-emerald-500" : row.status === "CANCELLED" ? "text-muted-foreground" : "text-amber-500"}>{row.status}</span></td><td className="p-3">{row.expense_no ?? "Not posted"}{row.status === "POSTED" && <><p>{row.invoice_reference} · {row.received_on}</p><p>{row.payable_id ? `Due ${money(row.remaining)}` : "Paid on receipt"}</p></>}</td><td className="p-3"><div className="flex flex-wrap gap-3">{row.status === "DRAFT" && <><button disabled={pending} onClick={() => open("SAVE", row)}>Edit</button><button disabled={pending} onClick={() => open("RECEIVE", row)}>Receive & post</button><button disabled={pending} onClick={() => open("CANCEL", row)}>Cancel draft</button></>}{row.status === "POSTED" && row.payable_id && row.remaining > 0 && data.canPay && <button disabled={pending} onClick={() => open("PAY", row)}>Pay supplier</button>}</div></td></tr>)}</tbody></table>{data.rows.length === 0 && <p className="p-5">No purchases match these filters.</p>}</div>
 <div className="flex justify-between"><p>{data.total} purchases · page {data.page}</p><div className="flex gap-4">{data.page > 1 && <Link href={`?${new URLSearchParams({ page: String(data.page - 1), status, q: search })}`}>Previous</Link>}{data.page * 25 < data.total && <Link href={`?${new URLSearchParams({ page: String(data.page + 1), status, q: search })}`}>Next</Link>}</div></div></div>;
}
function InlineSupplier({ busy, onBusy, onSaved }: {
    busy: boolean;
    onBusy: (busy: boolean) => void;
    onSaved: (id: string, name: string) => void;
}) {
    const [values, setValues] = useState({ name: "", mobile: "", email: "", address: "" });
    const [message, setMessage] = useState("");
    const [request, setRequest] = useState("");
    const [previous, setPrevious] = useState("");
    async function save() { if (busy)
        return; const fingerprint = JSON.stringify(values); const id = !request || fingerprint !== previous ? crypto.randomUUID() : request; setRequest(id); setPrevious(fingerprint); onBusy(true); startTransition(async () => { try {
        const result = await purchaseAction({ ...values, action: "CREATE_VENDOR", request_id: id, reason: "Added supplier while preparing purchase draft" });
        setMessage(result.message);
        if (result.ok)
            onSaved(result.id, values.name);
    }
    catch {
        setMessage("Could not confirm supplier creation. Check the supplier list before retrying.");
    }
    finally {
        onBusy(false);
    } }); }
    return <div className="space-y-3 rounded border p-4"><p className="font-semibold">Add supplier without leaving this draft</p><div className="grid gap-3 md:grid-cols-2">{(Object.keys(values) as (keyof typeof values)[]).map(key => <label className="grid gap-1" key={key}>{key === "name" ? "Supplier name" : `${key} (optional)`}<input className="rounded border bg-background p-2" type={key === "email" ? "email" : "text"} value={values[key]} onChange={e => setValues({ ...values, [key]: e.target.value })}/></label>)}</div><button type="button" disabled={busy || values.name.trim().length < 2} onClick={save}>{busy ? "Saving supplier…" : "Save & select supplier"}</button>{message && <p role="status">{message}</p>}</div>;
}
