import { CircleHelp } from "lucide-react";

export function WorkflowHelp({
  title = "How to use this page",
  steps,
}: {
  title?: string;
  steps: string[];
}) {
  return (
    <details className="group rounded-xl border bg-muted/20">
      <summary className="flex min-h-11 cursor-pointer list-none items-center gap-2 px-4 py-3 text-sm font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">
        <CircleHelp className="size-4" aria-hidden="true" />
        <span>{title}</span>
        <span className="ml-auto text-xs text-muted-foreground group-open:hidden">Show guide</span>
        <span className="ml-auto hidden text-xs text-muted-foreground group-open:inline">Hide guide</span>
      </summary>
      <ol className="space-y-2 border-t px-4 py-3 text-sm text-muted-foreground">
        {steps.map((step, index) => (
          <li key={step} className="flex gap-3">
            <span className="flex size-6 shrink-0 items-center justify-center rounded-full border bg-background text-xs font-semibold text-foreground">
              {index + 1}
            </span>
            <span className="pt-0.5">{step}</span>
          </li>
        ))}
      </ol>
    </details>
  );
}
