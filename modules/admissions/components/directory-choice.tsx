"use client";
import { useState, useTransition } from "react";
import { createAdmissionDirectoryChoice } from "../directory-actions";
export function DirectoryChoice({
  entity,
  name,
  label,
  options,
}: {
  entity: "school" | "relationship";
  name: string;
  label: string;
  options: { id: string; name: string }[];
}) {
  const [rows, setRows] = useState(options),
    [selected, setSelected] = useState(""),
    [creating, setCreating] = useState(false),
    [newName, setNewName] = useState(""),
    [message, setMessage] = useState("");
  const [pending, start] = useTransition();
  return (
    <div className="space-y-2 text-sm">
      <label className="block font-medium">
        {label}
        <select
          name={name}
          value={selected}
          className="mt-1 min-h-11 w-full rounded-xl border bg-background px-3"
          onChange={(e) => {
            if (e.target.value === "__new__") {
              setCreating(true);
              return;
            }
            setSelected(e.target.value);
          }}
        >
          <option value="">Not provided</option>
          {rows.map((r) => (
            <option key={r.id} value={r.name}>
              {r.name}
            </option>
          ))}
          <option value="__new__">+ Create missing {entity}</option>
        </select>
      </label>
      {creating && (
        <div className="space-y-2 rounded-lg border p-3">
          <label className="block text-xs">
            New {entity} name
            <input
              value={newName}
              maxLength={160}
              onChange={(e) => setNewName(e.target.value)}
              className="mt-1 w-full rounded border bg-background p-2"
            />
          </label>
          <button
            type="button"
            disabled={pending || newName.trim().length < 2}
            className="rounded border px-3 py-2 text-xs"
            onClick={() =>
              start(async () => {
                const r = await createAdmissionDirectoryChoice({
                  entity,
                  name: newName,
                });
                if (!r.ok) {
                  setMessage(r.message);
                  return;
                }
                setRows((old) =>
                  old.some((v) => v.id === r.row.id) ? old : [...old, r.row],
                );
                setSelected(r.row.name);
                setCreating(false);
                setMessage("Created and selected.");
              })
            }
          >
            Create and select
          </button>
          <button
            type="button"
            className="ml-3 text-xs underline"
            onClick={() => setCreating(false)}
          >
            Cancel
          </button>
        </div>
      )}
      {message && (
        <p role="status" className="text-xs">
          {message}
        </p>
      )}
    </div>
  );
}
