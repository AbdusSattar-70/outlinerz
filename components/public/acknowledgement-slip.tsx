export type AcknowledgementData = {
  prospectNo?: string | null;
  studentName?: string;
  intentLabel?: string;
  details?: Record<string, string>;
};
export function AcknowledgementSlip({
  organizationName,
  message,
  bn = false,
}: {
  organizationName: string;
  message: AcknowledgementData;
  bn?: boolean;
}) {
  const rows = [
    { en: "Student", bn: "শিক্ষার্থী", value: message.studentName },
    { en: "Guardian", bn: "অভিভাবক", value: message.details?.guardian },
    {
      en: "Contact mobile",
      bn: "যোগাযোগের ফোন",
      value: message.details?.mobile,
    },
    {
      en: "Student email",
      bn: "শিক্ষার্থীর ইমেইল",
      value: message.details?.email,
    },
    { en: "Application type", bn: "আবেদনের ধরন", value: message.intentLabel },
    {
      en: "Programme preference",
      bn: "পছন্দের প্রোগ্রাম",
      value: message.details?.programme,
    },
    {
      en: "Subject preferences",
      bn: "পছন্দের বিষয়",
      value: message.details?.subjects,
    },
    {
      en: "Present address",
      bn: "বর্তমান ঠিকানা",
      value: message.details?.address,
    },
  ];
  return (
    <>
      <style>{`.ack-slip{background:#fff;color:#111;max-width:185mm;padding:10mm;margin:auto;border:1px solid #777;font:10pt/1.5 Arial,sans-serif}.ack-title{display:flex;justify-content:space-between;border-bottom:2px solid #111;padding-bottom:5mm}.ack-title h2{font-size:18pt;font-weight:700;margin:0}.ack-meta{display:grid;grid-template-columns:1fr 1fr;gap:4mm;margin:5mm 0}.ack-slip table{width:100%;border-collapse:collapse}.ack-slip th,.ack-slip td{border:1px solid #999;padding:3mm;text-align:left;overflow-wrap:anywhere}.ack-slip th{width:30%}.ack-next{border:1px solid #111;padding:4mm;margin:6mm 0}@media print{body:has(.ack-slip) *:not(:has(.ack-slip)):not(.ack-slip):not(.ack-slip *){display:none!important}body:has(.ack-slip) *:has(.ack-slip){display:block!important;margin:0!important;padding:0!important;max-width:none!important;min-height:0!important}.ack-slip{border:0;padding:0;width:100%;max-width:none}@page{size:A4;margin:16mm}}`}</style>
      <article id="interest-acknowledgement-slip" className="ack-slip">
        <header className="ack-title">
          <div>
            <h2>
              {bn
                ? "আবেদনের প্রাপ্তি স্বীকারপত্র"
                : "Application acknowledgement"}
            </h2>
            <p>{organizationName} · Outlinerz</p>
          </div>
          <span>{bn ? "গৃহীত · যাচাই হয়নি" : "Received · Unverified"}</span>
        </header>
        <dl className="ack-meta">
          <div>
            <dt>{bn ? "আবেদনের নম্বর" : "Application reference"}</dt>
            <dd>
              {message.prospectNo ?? (bn ? "দেওয়া হয়নি" : "Not issued")}
            </dd>
          </div>
          <div>
            <dt>
              {bn
                ? "জমা দেওয়ার সময় (বাংলাদেশ)"
                : "Submitted (Bangladesh time)"}
            </dt>
            <dd>{message.details?.submitted}</dd>
          </div>
        </dl>
        <table>
          <tbody>
            {rows.map((r) => (
              <tr key={r.en}>
                <th>{bn ? r.bn : r.en}</th>
                <td>{r.value || (bn ? "উল্লেখ নেই" : "Not provided")}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <section className="ack-next">
          <h3>{bn ? "পরবর্তী ধাপ" : "Next steps"}</h3>
          <p>
            {bn
              ? "এই নম্বরটি সংরক্ষণ করুন। প্রতিষ্ঠান তথ্য ও পছন্দের প্রোগ্রাম যাচাই করে যোগাযোগ করবে। এটি ভর্তি নিশ্চিতকরণ বা টাকা আদায়ের রসিদ নয়।"
              : "Keep this reference. The organization will verify the details and preferred programme, then contact the guardian. This acknowledgement is not admission confirmation or a payment receipt."}
          </p>
        </section>
        <footer>{message.prospectNo}</footer>
      </article>
    </>
  );
}
