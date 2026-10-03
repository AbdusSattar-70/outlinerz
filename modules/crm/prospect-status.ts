export const prospectStatuses = [
  "NEW",
  "CONTACTED",
  "INTERESTED",
  "LOST",
  "ADMITTED",
] as const;
export type ProspectStatus = (typeof prospectStatuses)[number];
export function allowedProspectStatuses(
  current: ProspectStatus,
): ProspectStatus[] {
  return current === "ADMITTED"
    ? ["ADMITTED"]
    : ["NEW", "CONTACTED", "INTERESTED", "LOST"];
}
