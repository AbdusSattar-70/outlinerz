"use client";
import { BookOpenCheck } from "lucide-react";
export default function Logo({
  size = 88,
  className = "",
  variant = "full",
}: {
  size?: number;
  priority?: boolean;
  className?: string;
  variant?: "full" | "mark";
}) {
  return (
    <span className={`inline-flex shrink-0 items-center gap-2 ${className}`}>
      <BookOpenCheck
        aria-hidden="true"
        style={{
          width: variant === "mark" ? size : Math.min(size, 36),
          height: variant === "mark" ? size : Math.min(size, 36),
        }}
        className="text-primary"
      />
      {variant === "full" && (
        <span className="text-lg font-bold tracking-tight">Outlinerz</span>
      )}
    </span>
  );
}
