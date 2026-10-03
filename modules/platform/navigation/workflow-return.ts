/** Only known same-origin working pages may be a workflow return destination. */
export function workflowReturnPath(value: string | null) {
  return value &&
    (value === "/dashboard/setup" ||
      /^\/dashboard\/admissions(?:\/[0-9a-f-]{36})?(?:\?[^#]*)?$/.test(value))
    ? value
    : null;
}
export function finishWorkflow(router: {
  push: (path: string) => void;
  refresh: () => void;
}) {
  document.querySelectorAll<HTMLDetailsElement>("details[data-action-panel]").forEach(el => el.open = false);
  window.dispatchEvent(new CustomEvent("erp:saved", { detail: "Saved successfully." }));
  const path = workflowReturnPath(
    new URLSearchParams(window.location.search).get("returnTo"),
  );
  if (path) router.push(path);
  router.refresh();
}
