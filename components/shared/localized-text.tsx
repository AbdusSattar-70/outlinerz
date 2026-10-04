"use client";

import { useLanguage } from "@/components/providers/language-provider";

/** Decode accidental literal \\uXXXX sequences from bad encoding pipelines. */
function decodeUnicodeEscapes(value: string): string {
  if (!value.includes("\\u")) return value;
  return value.replace(/\\u([0-9a-fA-F]{4})/g, (_, hex: string) =>
    String.fromCharCode(Number.parseInt(hex, 16)),
  );
}

export function LocalizedText({
  en,
  bn,
}: {
  en: string;
  bn: string;
}) {
  const { locale } = useLanguage();
  const text = locale === "bn" ? decodeUnicodeEscapes(bn) : decodeUnicodeEscapes(en);
  return <>{text}</>;
}
