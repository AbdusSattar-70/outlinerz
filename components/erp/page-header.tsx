import { OverviewReturnLink } from "./overview-return-link";
import type { ReactNode } from "react";

export function PageHeader({
  eyebrow,
  title,
  description,
  actions,
}: {
  eyebrow?: ReactNode;
  title: ReactNode;
  description: ReactNode;
  actions?: ReactNode;
}) {
  return (
    <div className="flex flex-col gap-4 border-b pb-5 sm:flex-row sm:items-end sm:justify-between">
      <div className="max-w-3xl">
        <OverviewReturnLink />
        {eyebrow && (
          <p className="text-xs font-bold uppercase tracking-[0.18em] text-blue-700 dark:text-blue-300">
            {eyebrow}
          </p>
        )}
        <h2 className="mt-1 text-2xl font-bold tracking-[-0.03em] sm:text-3xl">
          {title}
        </h2>
        <p className="mt-2 text-sm leading-6 text-muted-foreground sm:text-base">
          {description}
        </p>
      </div>
      {actions && <div className="shrink-0">{actions}</div>}
    </div>
  );
}
