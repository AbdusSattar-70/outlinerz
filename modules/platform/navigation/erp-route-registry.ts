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
  {id:"purchases",title:"Purchases & supplier expenses",eyebrow:"Finance",href:"/dashboard/finance/purchases",navGroup:"Finance",permission:"accounting.expense.manage",icon:"accounting"},
  {id:"financial-reports",title:"Monthly accounts & period close",eyebrow:"Finance",href:"/dashboard/finance/reports",navGroup:"Finance",permission:"accounting.view",icon:"accounting"},
  {id:"daily-close",title:"Daily cash & statement close",eyebrow:"Finance",href:"/dashboard/finance/daily-close",navGroup:"Finance",permission:"accounting.reconcile",icon:"accounting"},
  {id:"payroll",title:"Payroll & payslips",eyebrow:"Finance",href:"/dashboard/finance/payroll",navGroup:"Finance",permission:"workforce.self.view",icon:"accounting"},
  {id:"my-work",title:"My work & attendance",eyebrow:"Workspace",href:"/dashboard/my-work",navGroup:"Workspace",permission:"workforce.self.view",icon:"staff"},
  {id:"staff-operations",title:"Staff attendance & terms",eyebrow:"People",href:"/dashboard/staff/operations",navGroup:"People",permission:"workforce.manage",icon:"staff"},
  { id: "referrals", title: "Referrers / My referrals", eyebrow: "People", href: "/dashboard/referrals", navGroup: "People", permission: "referrals.portal.view", icon: "students" },
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
  {
    id: "student-accounts",
    title: "Student Accounts",
    eyebrow: "Finance",
    href: "/dashboard/finance/billing",
    navGroup: "Finance",
    permission: "finance.view",
    icon: "fee-plans",
  },
  {
    id: "accounting",
    title: "Accounting & Settlements",
    eyebrow: "Finance",
    href: "/dashboard/finance/accounting",
    navGroup: "Finance",
    permission: "accounting.view",
    icon: "accounting",
  },

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
    id: "fee-plans",
    title: "Fee Plans",
    eyebrow: "Academy Setup",
    href: "/dashboard/finance/fee-plans",
    navGroup: "Academy Setup",
    permission: "finance.view",
    icon: "fee-plans",
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
