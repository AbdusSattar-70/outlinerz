"use client";
import { useActionState, useState } from "react";
import { useCrmText } from "@/modules/crm/translations";
import {
  onboardOrganization,
  switchOrganization,
  addSetupRecord,
  type FormState,
} from "./actions";
const input = "w-full rounded-xl border bg-background px-3 py-3 text-sm";
const button =
  "rounded-xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground disabled:opacity-50";
function Feedback({ state }: { state: FormState }) {
  const tr = useCrmText();
  return (
    <div aria-live="polite">
      {state.error && (
        <p role="alert" className="text-sm text-red-400">
          {tr(state.error)}
        </p>
      )}
      {state.success && (
        <p className="text-sm text-emerald-400">{tr(state.success)}</p>
      )}
    </div>
  );
}
export function OnboardingForm({ request }: { request: string }) {
  const tr = useCrmText();
  const [state, action, pending] = useActionState(onboardOrganization, {});
  const [requestId] = useState(request);
  const [values, setValues] = useState({ name: "", slug: "", branch: "" });
  return (
    <form action={action} className="space-y-5">
      <input type="hidden" name="request" value={requestId} />
      {(["name", "slug", "branch"] as const).map((key) => (
        <label key={key} className="block space-y-2">
          <span>
            {tr(
              {
                name: "Organization name",
                slug: "Unique slug",
                branch: "First branch",
              }[key],
            )}
          </span>
          <input
            className={input}
            name={key}
            value={values[key]}
            disabled={pending}
            required
            maxLength={key === "slug" ? 63 : 160}
            onChange={(e) => setValues({ ...values, [key]: e.target.value })}
          />
        </label>
      ))}
      <p className="text-sm text-muted-foreground">
        {tr(
          "Slug example: rahman-tuition. Use lowercase letters, numbers and hyphens.",
        )}
      </p>
      <Feedback state={state} />
      <button className={button} disabled={pending}>
        {tr(pending ? "Creating…" : "Create organization")}
      </button>
    </form>
  );
}
export function OrganizationPicker({
  organizations,
}: {
  organizations: { id: string; name: string; role: string }[];
}) {
  const tr = useCrmText();
  const [state, action, pending] = useActionState(switchOrganization, {});
  return (
    <form action={action} className="space-y-4">
      <label className="block space-y-2">
        <span>{tr("Choose an organization")}</span>
        <select
          name="organization"
          className={input}
          required
          disabled={pending}
        >
          {organizations.map((o) => (
            <option key={o.id} value={o.id}>
              {o.name} · {tr(o.role)}
            </option>
          ))}
        </select>
      </label>
      <Feedback state={state} />
      <button className={button} disabled={pending}>
        {tr(pending ? "Opening…" : "Open dashboard")}
      </button>
    </form>
  );
}
export function SetupRecordForm({
  kind,
  title,
}: {
  kind: "year" | "class" | "subject";
  title: string;
}) {
  const tr = useCrmText();
  const [state, action, pending] = useActionState(addSetupRecord, {});
  const [name, setName] = useState("");
  const [dates, setDates] = useState({ start: "", end: "" });
  return (
    <form action={action} className="space-y-3 rounded-2xl border p-5">
      <h2 className="font-semibold">{tr(title)}</h2>
      <input type="hidden" name="kind" value={kind} />
      <label className="block space-y-1">
        <span className="text-sm">{tr("Name")}</span>
        <input
          className={input}
          name="name"
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
          maxLength={160}
          disabled={pending}
        />
      </label>
      {kind === "year" && (
        <div className="grid gap-3 sm:grid-cols-2">
          <label>
            {tr("Starts on")}
            <input
              type="date"
              name="starts_on"
              value={dates.start}
              onChange={(e) => setDates({ ...dates, start: e.target.value })}
              className={input}
              required
              disabled={pending}
            />
          </label>
          <label>
            {tr("Ends on")}
            <input
              type="date"
              name="ends_on"
              value={dates.end}
              onChange={(e) => setDates({ ...dates, end: e.target.value })}
              className={input}
              required
              disabled={pending}
            />
          </label>
        </div>
      )}
      <Feedback state={state} />
      <button className={button} disabled={pending}>
        {tr(pending ? "Saving…" : "Add record")}
      </button>
    </form>
  );
}
