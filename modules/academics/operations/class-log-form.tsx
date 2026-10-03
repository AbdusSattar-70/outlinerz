"use client";
import { ActionPanel, announceSaved } from "@/components/erp/action-panel";
import { useState, useTransition } from "react";
import { useForm, useFieldArray } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button } from "@/components/ui/button";
import {
  classLogCommandSchema,
  type ClassLogCommand,
  type ClassLogWorkspace,
} from "./schema";
import { runClassLogCommand } from "./actions";
const cls =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm";
export function ClassLogForm({
  sessionId,
  workspace,
}: {
  sessionId: string;
  workspace: ClassLogWorkspace;
}) {
  const last = workspace.logs[0];
  const hasSavedDraft = last?.status === "DRAFT";
  const initialProgress = workspace.units.map((_, unit_index) => {
    const saved = last?.unit_progress.find((x) => x.unit_index === unit_index);
    return {
      unit_index,
      status: saved?.status ?? ("COVERED" as const),
      note: saved?.note ?? "",
    };
  });
  const form = useForm<ClassLogCommand>({
    resolver: zodResolver(classLogCommandSchema),
    mode: "onChange",
    defaultValues: {
      action: "SAVE_DRAFT",
      request_id: crypto.randomUUID(),
      session_id: sessionId,
      reason: hasSavedDraft ? last.reason : "",
      class_summary: last?.class_summary ?? "",
      unfinished_reason: last?.unfinished_reason ?? "",
      homework: last?.homework ?? "",
      next_session_plan: last?.next_session_plan ?? "",
      unit_progress: initialProgress,
    },
  });
  const fields = useFieldArray({
    control: form.control,
    name: "unit_progress",
  });
  const [pending, start] = useTransition();
  const [message, setMessage] = useState("");
  const submit = (action: "SAVE_DRAFT" | "SUBMIT") =>
    form.handleSubmit((values) =>
      start(async () => {
        const result = await runClassLogCommand({
          ...values,
          action,
          request_id: crypto.randomUUID(),
        });
        setMessage(result.message);
        if (result.ok) window.location.reload();
      }),
    )();
  return (
    <ActionPanel title="Record / edit class log"><form
      onSubmit={(e) => {
        e.preventDefault();
        void submit("SAVE_DRAFT");
      }}
      className="space-y-5 rounded-2xl border bg-card p-5"
    >
      <div>
        <h2 className="font-semibold">Actual class log</h2>
        <p className="text-sm text-muted-foreground">
          {last?.status === "SUBMITTED"
            ? `Start correction revision ${(last.revision ?? 0) + 1}. Submitted records stay unchanged.`
            : "Record what was taught. Planned targets remain separate; partial coverage does not silently complete the curriculum."}
        </p>
      </div>
      {workspace.units.length > 0 && (
        <fieldset className="space-y-3">
          <legend className="text-sm font-semibold">
            Pinned curriculum coverage
          </legend>
          {fields.fields.map((field, index) => (
            <div
              key={field.id}
              className="grid gap-2 rounded-xl border p-3 sm:grid-cols-[1fr_180px]"
            >
              <div className="text-sm">
                <strong>{workspace.units[index]?.title}</strong>
                <span className="block text-xs text-muted-foreground">
                  Target {workspace.units[index]?.target_date}
                </span>
              </div>
              <div className="space-y-2">
                <select
                  className={cls}
                  {...form.register(`unit_progress.${index}.status`)}
                >
                  <option value="COVERED">Covered</option>
                  <option value="PARTIAL">Partially covered</option>
                  <option value="NOT_COVERED">Not covered</option>
                </select>
                <input
                  className={cls}
                  placeholder="Short note (optional)"
                  {...form.register(`unit_progress.${index}.note`)}
                />
              </div>
            </div>
          ))}
        </fieldset>
      )}
      {workspace.units.length === 0 && (
        <p className="text-sm text-muted-foreground">
          No curriculum version was pinned to this session. Record the class
          summary below; planned curriculum remains unmodified.
        </p>
      )}
      <label className="block text-sm font-medium">
        What was taught?{" "}
        <textarea
          className={`${cls} mt-1 min-h-24 py-2`}
          {...form.register("class_summary")}
        />
        {form.formState.errors.class_summary && (
          <span className="text-xs text-destructive">
            {form.formState.errors.class_summary.message}
          </span>
        )}
      </label>
      <label className="block text-sm font-medium">
        Why was planned content left incomplete?{" "}
        <span className="font-normal text-muted-foreground">
          Required when a curriculum unit is partial or not covered.
        </span>
        <textarea
          className={`${cls} mt-1 min-h-20 py-2`}
          {...form.register("unfinished_reason")}
        />
        {form.formState.errors.unfinished_reason && (
          <span className="text-xs text-destructive">
            {form.formState.errors.unfinished_reason.message}
          </span>
        )}
      </label>
      <label className="block text-sm font-medium">
        Homework / practice{" "}
        <textarea
          className={`${cls} mt-1 min-h-20 py-2`}
          {...form.register("homework")}
        />
      </label>
      <label className="block text-sm font-medium">
        Plan for next class{" "}
        <textarea
          className={`${cls} mt-1 min-h-20 py-2`}
          {...form.register("next_session_plan")}
        />
      </label>
      <label className="block text-sm font-medium">
        Reason for this record{" "}
        <input className={`${cls} mt-1`} {...form.register("reason")} />
        {form.formState.errors.reason && (
          <span className="text-xs text-destructive">
            {form.formState.errors.reason.message}
          </span>
        )}
      </label>
      <div className="flex flex-wrap gap-2">
        <Button
          type="submit"
          disabled={!form.formState.isValid || !form.formState.isDirty || pending}
        >
          {pending ? "Saving…" : "Save draft"}
        </Button>
        <Button
          type="button"
          variant="outline"
          disabled={
            !hasSavedDraft ||
            !form.formState.isValid ||
            form.formState.isDirty ||
            pending
          }
          onClick={() => void submit("SUBMIT")}
        >
          {pending ? "Submitting…" : "Submit saved class log"}
        </Button>
      </div>
      {form.formState.isDirty && hasSavedDraft && (
        <p className="text-xs text-muted-foreground">
          Save changes before submitting. Submission sends the saved draft.
        </p>
      )}
      <p role="status" className="text-sm">
        {message}
      </p>
    </form></ActionPanel>
  );
}
