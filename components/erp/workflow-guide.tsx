import { CircleHelp } from "lucide-react";

export function WorkflowGuide({
  title = "How this workflow works",
  steps,
}: {
  title?: string;
  steps: string[];
}) {
  return (
    <aside className="rounded-2xl border bg-muted/35 p-4">
      <div className="flex items-center gap-2">
        <CircleHelp className="size-4 text-blue-700 dark:text-blue-300" aria-hidden="true" />
        <h3 className="text-sm font-semibold">{title}</h3>
      </div>
      <ol className="mt-3 grid gap-2 text-sm leading-6 text-muted-foreground">
        {steps.map((step, index) => (
          <li key={step} className="flex gap-3">
            <span className="mt-0.5 flex size-5 shrink-0 items-center justify-center rounded-full border bg-background text-[11px] font-bold text-foreground">
              {index + 1}
            </span>
            <span>{step}</span>
          </li>
        ))}
      </ol>
    </aside>
  );
}
