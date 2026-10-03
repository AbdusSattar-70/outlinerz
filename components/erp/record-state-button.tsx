"use client";
import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { changeRecordState } from "@/modules/platform/lifecycle-actions";
export function RecordStateButton({
  entity,
  id,
  active,
}: {
  entity: "batch" | "offering" | "student" | "staff" | "referrer";
  id: string;
  active: boolean;
}) {
  const [open, setOpen] = useState(false),
    [note, setNote] = useState(""),
    [message, setMessage] = useState("");
  const [pending, start] = useTransition();
  const router = useRouter();
  return (
    <div>
      <button
        className="min-h-9 rounded-lg border px-3 text-xs font-semibold"
        type="button"
        onClick={() => setOpen(!open)}
      >
        {active ? "Mark inactive" : "Reactivate"}
      </button>
      {open && (
        <div className="mt-2 max-w-sm space-y-2 rounded-xl border bg-background p-3 text-left">
          <p className="text-xs">
            History remains available. New use stops when inactive.
          </p>
          <label className="block text-xs">
            Reason
            <input
              className="mt-1 w-full rounded border bg-background p-2"
              value={note}
              onChange={(e) => setNote(e.target.value)}
            />
          </label>
          <button
            disabled={pending || note.trim().length < 5}
            className="rounded border px-3 py-2 text-xs disabled:opacity-40"
            onClick={() =>
              start(async () => {
                const r = await changeRecordState({
                  entity,
                  id,
                  active: !active,
                  reason: note,
                });
                setMessage(r.message);
                if (r.ok) {
                  setOpen(false);
                  router.refresh();
                }
              })
            }
          >
            Confirm
          </button>
          <button
            type="button"
            className="ml-2 text-xs underline"
            onClick={() => setOpen(false)}
          >
            Cancel
          </button>
        </div>
      )}
      {message && (
        <p role="status" className="mt-1 text-xs">
          {message}
        </p>
      )}
    </div>
  );
}
