export type ErpRouteIcon =
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

export type ErpRouteDefinition = {
  id: string;
  title: string;
  eyebrow: string;
  href: string;
  navGroup: string;
  permission: string;
  icon: ErpRouteIcon;
  exact?: boolean;
};

export const erpRouteRegistry: ErpRouteDefinition[] = [
 {id:"branches",title:"Branches",eyebrow:"Academy Setup",href:"/branches",navGroup:"Academy Setup",permission:"dashboard.view",icon:"settings"},




  {id:"my-work",title:"My work & attendance",eyebrow:"Workspace",href:"/dashboard/my-work",navGroup:"Workspace",permission:"workforce.self.view",icon:"staff"},
  {id:"staff-operations",title:"Staff attendance",eyebrow:"People",href:"/dashboard/staff/operations",navGroup:"People",permission:"workforce.manage",icon:"staff"},

  // Workspace
  {
    id: "dashboard",
    title: "Overview",
    eyebrow: "Workspace",
    href: "/dashboard",
    navGroup: "Workspace",
    permission: "dashboard.view",
    icon: "dashboard",
    exact: true,
  },
  {
    id: "action-center",
    title: "My Tasks",
    eyebrow: "Workspace",
    href: "/dashboard/action-center",
    navGroup: "Workspace",
    permission: "action_center.view",
    icon: "action-center",
  },

  // Admissions & Students
  {
    id: "admissions",
    title: "Admissions",
    eyebrow: "Admissions & Students",
    href: "/dashboard/admissions",
    navGroup: "Admissions & Students",
    permission: "admissions.view",
    icon: "students",
  },
  {
    id: "students",
    title: "Students",
    eyebrow: "Admissions & Students",
    href: "/dashboard/students",
    navGroup: "Admissions & Students",
    permission: "students.view",
    icon: "students",
  },
  {
    id: "prospects",
    title: "Enquiries",
    eyebrow: "Admissions & Students",
    href: "/dashboard/crm/prospects",
    navGroup: "Admissions & Students",
    permission: "crm.prospects.view",
    icon: "prospects",
  },

  // Teaching & Academics
  {
    id: "teacher-dashboard",
    title: "My Classes",
    eyebrow: "Teaching & Academics",
    href: "/dashboard/teacher",
    navGroup: "Teaching & Academics",
    permission: "academics.view",
    icon: "teacher",
  },
  {
    id: "academic-operations",
    title: "Sessions & Attendance",
    eyebrow: "Teaching & Academics",
    href: "/dashboard/academics/operations",
    navGroup: "Teaching & Academics",
    permission: "academics.view",
    icon: "offerings",
  },
  {
    id: "assessments",
    title: "Assessments",
    eyebrow: "Teaching & Academics",
    href: "/dashboard/academics/assessments",
    navGroup: "Teaching & Academics",
    permission: "academics.view",
    icon: "offerings",
  },
  {
    id: "question-bank",
    title: "Question Bank",
    eyebrow: "Teaching & Academics",
    href: "/dashboard/academics/questions",
    navGroup: "Teaching & Academics",
    permission: "academics.view",
    icon: "offerings",
  },
  {
    id: "batches",
    title: "Batches",
    eyebrow: "Teaching & Academics",
    href: "/dashboard/academics/batches",
    navGroup: "Teaching & Academics",
    permission: "academics.view",
    icon: "offerings",
  },

  // Finance



  // People
  {
    id: "staff",
    title: "Staff & Teaching Assignments",
    eyebrow: "People",
    href: "/dashboard/staff",
    navGroup: "People",
    permission: "staff.view",
    icon: "staff",
  },

  // Academy Setup
  {
    id: "academic-directory",
    title: "Academic Directory",
    eyebrow: "Academy Setup",
    href: "/dashboard/crm/manage",
    navGroup: "Academy Setup",
    permission: "system.master_data.manage",
    icon: "settings",
  },
  {
    id: "programme-offerings",
    title: "Programme Offerings",
    eyebrow: "Academy Setup",
    href: "/dashboard/academics/offerings",
    navGroup: "Academy Setup",
    permission: "academics.view",
    icon: "offerings",
  },

  {
    id: "operating-rules",
    title: "Operating Rules",
    eyebrow: "Academy Setup",
    href: "/dashboard/governance/rules",
    navGroup: "Academy Setup",
    permission: "system.rules.view",
    icon: "rules",
  },
  {
    id: "access-security",
    title: "Settings",
    eyebrow: "Academy Setup",
    href: "/dashboard/settings",
    navGroup: "Academy Setup",
    permission: "system.settings.view",
    icon: "settings",
  },

  // Governance
  {
    id: "admin-review-queue",
    title: "Admin Review Queue",
    eyebrow: "Governance",
    href: "/dashboard/governance/approvals",
    navGroup: "Governance",
    permission: "approvals.view",
    icon: "approvals",
  },
  {
    id: "audit",
    title: "Audit Trail",
    eyebrow: "Governance",
    href: "/dashboard/governance/audit",
    navGroup: "Governance",
    permission: "audit.view",
    icon: "audit",
  }
];

export function routeMatches(pathname: string, route: ErpRouteDefinition) {
  if (
    route.id === "academic-operations" &&
    pathname.startsWith("/dashboard/academics/sessions/")
  ) {
    return true;
  }

  if (route.exact) return pathname === route.href;
  return pathname === route.href || pathname.startsWith(`${route.href}/`);
}

export function getErpRoute(pathname: string) {
  return (
    erpRouteRegistry
      .filter((route) => routeMatches(pathname, route))
      .sort((a, b) => b.href.length - a.href.length)[0] ?? null
  );
}
