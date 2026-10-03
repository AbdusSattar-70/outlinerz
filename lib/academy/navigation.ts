import { CalendarDays, CircleDollarSign, GraduationCap, LayoutDashboard, Settings2, Users } from "lucide-react";

export const academyNavigation = [
  { title: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { title: "Academic", icon: GraduationCap, children: [
    ["Admissions", "/dashboard/admissions"], ["Students", "/dashboard/students"], ["Guardians", "/dashboard/guardians"],
    ["Attendance", "/dashboard/attendance"], ["Assessments", "/dashboard/assessments"], ["Progress", "/dashboard/progress"],
  ]},
  { title: "Finance", icon: CircleDollarSign, children: [["Fees", "/dashboard/fees"], ["Payments", "/dashboard/payments"]] },
  { title: "Communication", icon: Users, children: [["Parents", "/dashboard/parents"], ["Notices", "/dashboard/notices"]] },
  { title: "Management", icon: CalendarDays, children: [["Teachers", "/dashboard/teachers"], ["Routine", "/dashboard/routine"]] },
  { title: "System", icon: Settings2, children: [["Print Center", "/dashboard/print"], ["Settings", "/dashboard/settings"], ["Audit & Recovery", "/dashboard/audit"]] },
] as const;
