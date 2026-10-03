import { amountInWords } from "@/lib/academy/money-in-words";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requirePermission } from "@/modules/platform/auth/erp-context";
import { getAcademySetup } from "@/modules/platform/setup/queries";
import { getFinanceWorkspace } from "@/modules/finance/operations/queries";
import { PrintAdmissionButton } from "@/modules/admissions/components/print-button";
const money = (currency: string, n: number) => `${currency} ${n.toFixed(2)}`;
const date = (value: string) =>
  new Date(value).toLocaleString("en-GB", { timeZone: "Asia/Dhaka" });
export default async function Statement({
  params,
}: {
  params: Promise<{ invoiceId: string }>;
}) {
  await requirePermission("finance.view");
  const { invoiceId } = await params;
  const [data, setup] = await Promise.all([
    getFinanceWorkspace(),
    getAcademySetup(),
  ]);
  const i = data.invoices.find((r) => r.id === invoiceId);
  if (!i) notFound();
  const a = data.admissions.find((r) => r.id === i.admissionId);
  const payments = data.payments.filter((p) => p.invoiceId === i.id),
    refunds = data.refunds.filter((r) => r.invoiceId === i.id && r.number);
  return (
    <div className="space-y-4">
      <nav className="flex flex-wrap gap-3 print:hidden">
        <Link
          className="rounded-lg border px-4 py-2 text-sm"
          href={`/dashboard/finance/billing?admission=${i.admissionId}`}
        >
          ← Back to student account
        </Link>
        <Link
          className="rounded-lg border px-4 py-2 text-sm"
          href={`/dashboard/admissions/${i.admissionId}`}
        >
          Admission case
        </Link>
        <PrintAdmissionButton />
      </nav>
      <style>{`
 .finance-document{max-width:185mm;margin:auto;padding:12mm;background:white;color:#111;font:9pt/1.35 Arial,var(--font-bn),sans-serif;border:1px solid #aaa}
 .finance-document{padding-top:36mm}.invoice-header{display:flex;justify-content:space-between;gap:8mm;align-items:start;border-bottom:2px solid #111;padding-bottom:5mm}.invoice-brand{display:flex;gap:4mm;align-items:center}.invoice-monogram{border:2px solid #111;padding:3mm;font-size:19pt;font-weight:800}.invoice-header h1{font-size:20pt;font-weight:800;margin:0;text-transform:uppercase}.invoice-header p{margin:1mm 0;font-size:8pt}.invoice-badge{border:1px solid #111;padding:2mm 3mm;font-weight:700;font-size:9pt}
 .invoice-meta{display:grid;grid-template-columns:1fr 1fr;gap:3mm 6mm;padding:3mm 0;border-bottom:1px solid #aaa}.invoice-meta dt{font-size:8pt;color:#333}.invoice-meta dd{margin:0;font-weight:600;overflow-wrap:anywhere}.invoice-section{margin-top:4mm}.invoice-section h2{font-size:10pt;text-transform:uppercase;letter-spacing:.5pt;border-bottom:1px solid #111;padding-bottom:2mm;margin-bottom:3mm}
 .invoice-table{width:100%;border-collapse:collapse;font-size:9pt}.invoice-table th,.invoice-table td{border:1px solid #aaa;padding:1.7mm;text-align:left}.invoice-table th{font-size:8pt;text-transform:uppercase}.invoice-table .number{text-align:right;white-space:nowrap}.invoice-summary{margin:3mm 0 3mm auto;max-width:90mm;border:1px solid #111;padding:3mm}.invoice-summary>div{display:flex;justify-content:space-between;gap:5mm;padding:.7mm 0}.invoice-summary dt{font-size:8.5pt}.invoice-summary dd{margin:0;font-weight:600}.invoice-total{border-top:1px solid #111;margin-top:2mm;padding-top:3mm!important;font-size:12pt}.invoice-total dt{font-size:10pt;font-weight:700}
 .invoice-note{font-size:8pt;margin-top:4mm}.invoice-footer{border-top:1px solid #777;margin-top:5mm;padding-top:3mm;font-size:7.5pt}.invoice-seal{border:1px dashed #888;padding:3mm;margin-top:4mm;width:55mm;text-align:center;font-size:8pt}.invoice-section,.invoice-summary{break-inside:avoid}
 @media print{body:has(.finance-document) *:not(:has(.finance-document)):not(.finance-document):not(.finance-document *){display:none!important}body:has(.finance-document) *:has(.finance-document){display:block!important;margin:0!important;padding:0!important;max-width:none!important;min-height:0!important}body *{visibility:hidden}.finance-document,.finance-document *{visibility:visible}.finance-document{position:static;width:100%;max-width:none;padding:24mm 0 0;border:0} .invoice-table thead{display:table-header-group}@page{size:A4;margin:14mm}}
 `}</style>
      <article className="finance-document">
        <header className="invoice-header">
          <div><h1>Student invoice</h1><p>Charges, reductions and payment statement</p></div>
          <span className="invoice-badge">INVOICE STATEMENT</span>
        </header>
        <dl className="invoice-meta">
          {[
            ["Invoice number", i.number],
            ["Billing period / due date", `${i.period} / ${i.dueOn}`],
            ["Student", i.name],
            ["Student ID", a?.studentNo ?? "—"],
            ["Admission reference", a?.number ?? "—"],
            ["Contact mobile", a?.mobile ?? "—"],
          ].map(([label, value]) => (
            <div key={label}>
              <dt>{label}</dt>
              <dd>{value}</dd>
            </div>
          ))}
        </dl>
        <section className="invoice-section">
          <h2>01 · Charges</h2>
          <table className="invoice-table">
            <thead>
              <tr>
                <th>Description</th>
                <th className="number">Amount ({i.currency})</th>
              </tr>
            </thead>
            <tbody>
              {i.lines.map((l, n) => (
                <tr key={n}>
                  <td>{l.name}</td>
                  <td className="number">{l.amount.toFixed(2)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
        <dl className="invoice-summary">
          {[
            ["Original charges", i.gross],
            ["Discount", i.discountAmount],
            ["Scholarship", i.scholarshipAmount],
            ["Other adjustments", i.otherAdjustments],
            ["Net charges", i.net],
            ["Money received", i.paid],
            ["Refunds paid", i.refunded],
            ["Overpayment balance", i.credit],
            ["Outstanding balance", i.due],
          ].filter(([label,value])=>!["Scholarship","Other adjustments","Refunds paid","Overpayment balance"].includes(String(label))||Number(value)!==0).map(([label, value]) => (
            <div
              key={label}
              className={label === "Outstanding balance" ? "invoice-total" : ""}
            >
              <dt>{label}</dt>
              <dd>{money(i.currency, Number(value))}</dd>
            </div>
          ))}
        </dl>
        <p className="invoice-note"><strong>Outstanding amount in words / কথায়:</strong> {amountInWords(i.due)}</p>
        <section className="invoice-section">
          <h2>02 · Payment record</h2>
          {payments.length ? (
            <table className="invoice-table">
              <thead>
                <tr>
                  <th>Receipt / date</th>
                  <th>Method</th>
                  <th className="number">Received</th>
                </tr>
              </thead>
              <tbody>
                {payments.map((p) => (
                  <tr key={p.id}>
                    <td>
                      {p.number}
                      <br />
                      {date(p.postedAt)}<br/><small>{amountInWords(p.amount)}</small>
                    </td>
                    <td>{p.method}</td>
                    <td className="number">{money(i.currency, p.amount)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <p className="invoice-note">
              No payment has been recorded. The amount due above remains
              outstanding.
            </p>
          )}
        </section>
        {refunds.length > 0 && (
          <section className="invoice-section">
            <h2>03 · Refunds paid</h2>
            <table className="invoice-table">
              <thead>
                <tr>
                  <th>Refund reference</th>
                  <th>Method / transaction</th>
                  <th className="number">Amount</th>
                </tr>
              </thead>
              <tbody>
                {refunds.map((r) => (
                  <tr key={r.id}>
                    <td>{r.number}</td>
                    <td>
                      {r.method} · {r.reference ?? "—"}
                    </td>
                    <td className="number">{money(i.currency, r.amount)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </section>
        )}
        {i.reserved > 0 && (
          <p className="invoice-note">
            Refunds authorized but not yet paid: {money(i.currency, i.reserved)}
            .
          </p>
        )}
        <p className="invoice-note">
          Keep the invoice reference for future payments. Posted charges remain
          in history; discounts, scholarships and other adjustments are shown separately. This
          statement is not evidence of a new payment.
        </p>
        <div className="invoice-seal">
          Office verification / academy seal
          <br />
          If required
        </div>
        <footer className="invoice-footer">
          System-generated statement · {date(new Date().toISOString())}
          <br />
          {i.number} · Original receipts remain evidence of money received. No
          signature or seal has been digitally asserted.
        </footer>
      </article>
    </div>
  );
}
