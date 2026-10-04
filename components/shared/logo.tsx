"use client";

import Image from "next/image";

interface LogoProps {
  size?: number;
  priority?: boolean;
  className?: string;
  variant?: "full" | "mark";
}

export default function Logo({
  size = 88,
  priority = false,
  className = "",
  variant = "full",
}: LogoProps) {
  const isMark = variant === "mark";

  return (
    <Image
      src={
        isMark
          ? "/branding/sohoj-academy-mark.webp"
          : "/branding/sohoj-academy-logo.webp"
      }
      alt={
        isMark
          ? "Sohoj Academy"
          : "সহজ একাডেমি — SOHOJ ACADEMY — Learning made easy & fun"
      }
      width={isMark ? 512 : 192}
      height={isMark ? 512 : 192}
      priority={priority}
      sizes={`${size}px`}
      style={{ width: size, height: "auto" }}
      className={`shrink-0 object-contain ${className}`}
    />
  );
}
