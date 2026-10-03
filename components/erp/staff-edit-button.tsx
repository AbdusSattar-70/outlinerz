"use client";
import { useState, useTransition, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { editStaffRecord } from "@/modules/staff/edit-actions";
export function StaffEditButton({
  id,
  name,
  mobile,
}: {
  id: string;
  name: string;
  mobile: string | null;
}) {
  const [open, setOpen] = useState(false),
    [message, setMessage] = useState("");
  const [pending, start] = useTransition();
  const router = useRouter();
  function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    start(async () => {
      const r = await editStaffRecord({ id, ...Object.fromEntries(form) });
      setMessage(r.message);
      if (r.ok) {
        setOpen(false);
        router.refresh();
      }
    });
  }
  return (
    <div>
      <button
        type="button"
        className="rounded-lg border px-3 py-2 text-xs"
        onClick={() => setOpen(!open)}
      >
        Edit details
      </button>
      {open && (
        <form
          onSubmit={submit}
          className="mt-2 w-64 space-y-2 rounded-xl border bg-background p-3"
        >
          <label className="block text-xs">
            Name
            <input
              required
              name="full_name"
              defaultValue={name}
              className="w-full rounded border bg-background p-2"
            />
          </label>
          <label className="block text-xs">
            Mobile
            <input
              name="mobile"
              defaultValue={mobile ?? ""}
              className="w-full rounded border bg-background p-2"
            />
          </label>
          <input
            type="hidden"
            name="reason"
            value="Corrected staff name and contact details"
          />
          <button
            disabled={pending}
            className="rounded border px-3 py-2 text-xs"
          >
            Save
          </button>
        </form>
      )}
      {message && (
        <p role="status" className="text-xs">
          {message}
        </p>
      )}
    </div>
  );
}
