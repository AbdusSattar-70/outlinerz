"use client";
import Link from "next/link";
import {
  ArrowLeft,
  Phone,
  UserRound,
  GraduationCap,
  School,
  CalendarClock,
  MapPin,
} from "lucide-react";
import { useLanguage } from "@/components/providers/language-provider";
import { PageHeader } from "@/components/erp/page-header";
import { ProspectFollowupForm } from "./prospect-followup-form";
import { ProspectAssignmentForm } from "./prospect-assignment-form";
import type { Prospect, Followup } from "@/modules/organizations/database";
import { useCrmText } from "../translations";
export function ProspectDetailView({
  prospect: p,
  writable,
  staff,
}: {
  prospect: Prospect & { followups: Followup[] };
  writable: boolean;
  staff: { id: string; name: string }[];
}) {
  const { locale } = useLanguage();
  const tr = useCrmText();
  const bn = locale === "bn";
  const s = p.application_snapshot;
  const date = (v: string) =>
    new Date(v).toLocaleString(bn ? "bn-BD" : "en-GB");
  const info = [
    { icon: UserRound, label: tr("Guardian"), value: p.guardian_name ?? "—" },
    { icon: Phone, label: tr("Contact"), value: p.phone },
    {
      icon: GraduationCap,
      label: tr("Current class"),
      value: String(s.class_label ?? "—"),
    },
    {
      icon: School,
      label: tr("School"),
      value: String(s.schoolNameSnapshot ?? "—"),
    },
    { icon: MapPin, label: tr("Area"), value: String(s.area ?? "—") },
    {
      icon: CalendarClock,
      label: tr("Next follow-up"),
      value: p.next_follow_up_at
        ? date(p.next_follow_up_at)
        : tr("Not scheduled"),
    },
  ];
  const preferences = [
    ["Relationship", "guardianRelationship"],
    ["Alternate mobile", "alternateMobile"],
    ["Preferred schedule", "preferredSchedule"],
    ["Preferred days", "preferredDays"],
    ["Referral", "referralNote"],
    ["Student email", "studentEmail"],
    ["Date of birth", "dateOfBirth"],
    ["Gender", "gender"],
    ["Father’s name", "fatherName"],
    ["Mother’s name", "motherName"],
    ["Emergency contact", "emergencyContact"],
    ["Emergency mobile", "emergencyMobile"],
    ["Present address", "guardianAddress"],
    ["Permanent address", "permanentAddress"],
    ["Previous result", "previousResult"],
    ["Learning needs", "learningNeeds"],
    ["Interested programmes", "program_labels"],
    ["Interested subjects", "subject_labels"],
  ];
  return (
    <div className="space-y-7">
      <PageHeader
        eyebrow={tr("CRM & Student Bank")}
        title={p.student_name}
        description={p.id.slice(0, 8).toUpperCase()}
        actions={
          <Link
            href="/dashboard/crm/prospects"
            className="inline-flex min-h-11 items-center gap-2 rounded-xl border bg-background px-4 text-sm font-semibold"
          >
            <ArrowLeft className="size-4" />
            {tr("Back to prospects")}
          </Link>
        }
      />
      {writable && (
        <ProspectAssignmentForm
          prospectId={p.id}
          selected={p.assigned_user_id}
          staff={staff}
        />
      )}
      <div className="grid gap-5 xl:grid-cols-[1.15fr_.85fr]">
        <section className="rounded-2xl border bg-card p-5 sm:p-6">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-sm text-muted-foreground">
                {tr("Current status")}
              </p>
              <p className="mt-2 inline-block rounded-full bg-muted px-3 py-1 text-sm font-semibold">
                {tr(p.stage)}
              </p>
            </div>
            <p className="text-xs text-muted-foreground">
              {date(p.created_at)}
            </p>
          </div>
          <dl className="mt-6 grid gap-4 sm:grid-cols-2">
            {info.map((i) => (
              <div key={i.label} className="flex gap-3 rounded-xl border p-3">
                <div className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-muted">
                  <i.icon className="size-4" />
                </div>
                <div className="min-w-0">
                  <dt className="text-xs text-muted-foreground">{i.label}</dt>
                  <dd className="mt-1 break-words text-sm font-medium">
                    {i.value}
                  </dd>
                </div>
              </div>
            ))}
          </dl>
          <div className="mt-6 border-t pt-5">
            <p className="text-xs text-muted-foreground">{tr("Offering")}</p>
            <p className="mt-1">{String(s.offering_label ?? "—")}</p>
            <p className="mt-4 text-xs text-muted-foreground">{tr("Source")}</p>
            <p>{p.source === "PUBLIC_FORM" ? tr("Public form") : p.source}</p>
          </div>
          <dl className="mt-6 grid gap-4 border-t pt-5 sm:grid-cols-2">
            {preferences
              .filter(
                ([, key]) =>
                  s[key] &&
                  (!Array.isArray(s[key]) || (s[key] as unknown[]).length),
              )
              .map(([label, key]) => (
                <div key={key}>
                  <dt className="text-xs text-muted-foreground">{tr(label)}</dt>
                  <dd className="mt-1 break-words text-sm">
                    {Array.isArray(s[key])
                      ? (s[key] as string[]).map(tr).join(", ")
                      : tr(String(s[key]))}
                  </dd>
                </div>
              ))}
          </dl>
          {p.notes && (
            <div className="mt-5 rounded-xl bg-muted/40 p-4">
              <p className="text-xs font-semibold">{tr("Original note")}</p>
              <p className="mt-2 whitespace-pre-wrap text-sm leading-6">
                {p.notes}
              </p>
            </div>
          )}
          {p.lost_reason && (
            <div className="mt-5 rounded-xl border border-red-500/30 p-4">
              <p className="text-xs font-semibold">{tr("Lost reason")}</p>
              <p className="mt-2 text-sm">{p.lost_reason}</p>
            </div>
          )}
        </section>
        <section className="overflow-hidden rounded-2xl border bg-card">
          <div className="border-b px-5 py-4">
            <h2 className="font-semibold">{tr("Follow-up timeline")}</h2>
            <p className="mt-1 text-xs text-muted-foreground">
              {tr("Newest activity first.")}
            </p>
          </div>
          <div className="divide-y">
            {p.followups.length ? (
              p.followups.map((f) => (
                <article key={f.id} className="px-5 py-4">
                  <p className="font-medium">
                    {f.completed_at
                      ? tr(f.followup_type)
                      : tr("Scheduled follow-up")}
                  </p>
                  <p className="mt-1 text-xs text-muted-foreground">
                    {date(f.completed_at ?? f.due_at)}
                  </p>
                  <p className="mt-3 whitespace-pre-wrap text-sm leading-6">
                    {f.note === "Scheduled follow-up" ? tr(f.note) : f.note}
                  </p>
                  {f.outcome && (
                    <p className="mt-2 text-sm text-muted-foreground">
                      {f.outcome}
                    </p>
                  )}
                </article>
              ))
            ) : (
              <p className="px-5 py-8 text-sm text-muted-foreground">
                {tr("No follow-up activity yet.")}
              </p>
            )}
          </div>
        </section>
      </div>
      {writable && p.stage !== "ADMITTED" && (
        <ProspectFollowupForm prospectId={p.id} currentStatus={p.stage} />
      )}
    </div>
  );
}
