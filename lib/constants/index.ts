export const RoleEnum = ["ADMIN", "OPERATOR", "TEACHER", "GUARDIAN", "STUDENT"] as const;
export type AppRole = (typeof RoleEnum)[number];

export const ROUTES = {
  ROOT: "/",
  AUTH: "/auth",
  SIGN_IN: "/auth/sign-in",
  DASHBOARD: "/dashboard",
} as const;

export const SENTENCES = [
  "learn with clarity and confidence",
  "track progress every week",
  "prepare smarter for every exam",
];

export const STATUS = {
  ONLINE: "online",
  OFFLINE: "offline",
  BACK_ONLINE: "back-online",
} as const;

export const FEEDBACK_MSG = {
  [STATUS.OFFLINE]: "You are offline.",
  [STATUS.BACK_ONLINE]: "You're back online!",
} as const;
