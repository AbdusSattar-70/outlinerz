export const prospectStatuses = [
  "NEW",
  "CONTACTED",
  "COUNSELLING",
  "TRIAL_SCHEDULED",
  "TRIAL_ATTENDED",
  "REGISTERED",
  "CONVERTED",
  "FUTURE_FOLLOW_UP",
  "LOST",
] as const;

export type ProspectStatus = (typeof prospectStatuses)[number];

const transitions: Record<ProspectStatus, ProspectStatus[]> = {
  NEW: ["NEW", "CONTACTED", "COUNSELLING", "FUTURE_FOLLOW_UP", "LOST"],
  CONTACTED: ["CONTACTED", "COUNSELLING", "TRIAL_SCHEDULED", "FUTURE_FOLLOW_UP", "LOST"],
  COUNSELLING: ["COUNSELLING", "TRIAL_SCHEDULED", "REGISTERED", "FUTURE_FOLLOW_UP", "LOST"],
  TRIAL_SCHEDULED: ["TRIAL_SCHEDULED", "TRIAL_ATTENDED", "FUTURE_FOLLOW_UP", "LOST"],
  TRIAL_ATTENDED: ["TRIAL_ATTENDED", "COUNSELLING", "REGISTERED", "FUTURE_FOLLOW_UP", "LOST"],
  REGISTERED: ["REGISTERED", "LOST"],
  CONVERTED: ["CONVERTED"],
  FUTURE_FOLLOW_UP: ["FUTURE_FOLLOW_UP", "CONTACTED", "COUNSELLING", "TRIAL_SCHEDULED", "LOST"],
  LOST: ["LOST", "FUTURE_FOLLOW_UP"],
};

export function allowedProspectStatuses(current: ProspectStatus) {
  return transitions[current];
}
