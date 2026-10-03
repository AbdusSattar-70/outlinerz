"use client";

import { useId, useMemo, useState } from "react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useLanguage } from "@/components/providers/language-provider";

export type SmartSelectOption = {
  id: string;
  label: string;
};

export function SmartSelect({
  name,
  snapshotName,
  label,
  options,
  hint,
  required = false,
  placeholder,
}: {
  name: string;
  snapshotName?: string;
  label: string;
  options: SmartSelectOption[];
  hint?: string;
  required?: boolean;
  placeholder?: string;
}) {
  const { locale } = useLanguage();
  const id = useId();
  const listId = `${id}-options`;
  const hintId = hint ? `${id}-hint` : undefined;
  const [text, setText] = useState("");

  const matched = useMemo(
    () =>
      options.find(
        (option) => option.label.trim().toLocaleLowerCase() === text.trim().toLocaleLowerCase()
      ) ?? null,
    [options, text]
  );

  return (
    <div>
      <div className="mb-2 flex items-center justify-between gap-3">
        <Label htmlFor={id}>{label}</Label>
        <span className="text-xs text-muted-foreground">{required ? (locale === "bn" ? "আবশ্যক" : "Required") : (locale === "bn" ? "ঐচ্ছিক" : "Optional")}</span>
      </div>
      <Input
        id={id}
        list={listId}
        value={text}
        onChange={(event) => setText(event.target.value)}
        placeholder={placeholder}
        aria-describedby={hintId}
        required={required}
        className="h-11"
        autoComplete="off"
      />
      <datalist id={listId}>
        {options.map((option) => (
          <option key={option.id} value={option.label} />
        ))}
      </datalist>
      <input type="hidden" name={name} value={matched?.id ?? ""} />
      {snapshotName && <input type="hidden" name={snapshotName} value={text.trim()} />}
      {hint && (
        <p id={hintId} className="mt-1.5 text-xs leading-5 text-muted-foreground">
          {hint}
        </p>
      )}
    </div>
  );
}
