export type ErpContext = {
  profileId: string;
  displayName: string;
  email: string;
  status: "ACTIVE" | "SUSPENDED" | "ARCHIVED";
  staffId: string | null;
  staffNo: string | null;
  staffName: string | null;
  roles: string[];
  permissions: string[];
};

export type ErpNavIcon =
  | "dashboard"
  | "action-center"
  | "prospects"
  | "students"
  | "staff"
  | "offerings"
  | "fee-plans"
  | "approvals"
  | "audit"
  | "rules"
  | "settings"
  | "teacher"
  | "accounting"
  | "help";

export type ErpNavItem = {
  id: string;
  title: string;
  href: string;
  permission: string;
  icon: ErpNavIcon;
};

export type ErpNavGroup = {
  title: string;
  items: ErpNavItem[];
};

export function can(context: ErpContext, permission: string) {
  return context.permissions.includes(permission);
}
