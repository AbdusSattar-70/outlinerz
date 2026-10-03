# ERP form inventory

Forms stay mounted while hidden so invalid input survives. Successful mutations show localized confirmation. Primary setup, public/Auth requests and register filters remain available without an extra create action. Teacher records retain their review contract; their secondary create/edit forms now open on demand.

| Owner | Interaction |
| --- | --- |
| `app/dashboard/academics/operations/page.tsx` | Primary task opened by parent action, or setup/auth/filter |
| `app/dashboard/account/page.tsx` | Click-to-open / inline operation |
| `app/dashboard/governance/audit/page.tsx` | Click-to-open / inline operation |
| `modules/academics/assessments/workspace.tsx` | Click-to-open / inline operation |
| `modules/academics/homework/workspace.tsx` | Click-to-open / inline operation |
| `modules/academics/operations/class-log-form.tsx` | Click-to-open / inline operation |
| `modules/academics/operations/command-form.tsx` | Click-to-open / inline operation |
| `modules/academics/questions/workspace.tsx` | Click-to-open / inline operation |
| `modules/admissions/components/command-form.tsx` | Primary task opened by parent action, or setup/auth/filter |
| `modules/admissions/components/extra-charge-form.tsx` | Click-to-open / inline operation |
| `modules/admissions/components/identity-editor.tsx` | Click-to-open / inline operation |
| `modules/admissions/components/physical-consent-form.tsx` | Primary task opened by parent action, or setup/auth/filter |
| `modules/admissions/components/placement-editor.tsx` | Click-to-open / inline operation |
| `modules/admissions/components/referral-form.tsx` | Primary task opened by parent action, or setup/auth/filter |
| `modules/admissions/components/staff-intake-form.tsx` | Primary task opened by parent action, or setup/auth/filter |
| `modules/crm/components/prospect-assignment-form.tsx` | Click-to-open / inline operation |
| `modules/crm/components/prospect-followup-form.tsx` | Click-to-open / inline operation |
| `modules/crm/manage/components/master-data-workspace.tsx` | Click-to-open / inline operation |
| `modules/finance/accounting/workspace.tsx` | Click-to-open / inline operation |
| `modules/finance/operations/collection-form.tsx` | Click-to-open / inline operation |
| `modules/finance/operations/command-form.tsx` | Primary task opened by parent action, or setup/auth/filter |
| `modules/offerings/components/fee-plan-form.tsx` | Primary task opened by parent action, or setup/auth/filter |
| `modules/offerings/components/offering-form.tsx` | Primary task opened by parent action, or setup/auth/filter |
| `modules/offerings/components/public-controls-form.tsx` | Primary task opened by parent action, or setup/auth/filter |
| `modules/platform/access/request-form.tsx` | Primary task opened by parent action, or setup/auth/filter |
| `modules/platform/setup/identity-form.tsx` | Primary task opened by parent action, or setup/auth/filter |
| `modules/referrals/register.tsx` | Click-to-open / inline operation |
| `modules/settings/components/policy-control-center.tsx` | Click-to-open / inline operation |
| `modules/settings/components/referral-policy-editor.tsx` | Click-to-open / inline operation |
| `modules/settings/components/role-permission-editor.tsx` | Click-to-open / inline operation |
| `modules/settings/components/user-access-editor.tsx` | Click-to-open / inline operation |
| `modules/staff/components/create-staff-form.tsx` | Click-to-create panel in Staff register; closes after successful save |
| `modules/staff/components/staff-register.tsx` | Full-width inline Edit row; protected identity/access fields read-only |
| `modules/students/lifecycle/close-enrollment-form.tsx` | Click-to-open / inline operation |
| `modules/students/lifecycle/command-form.tsx` | Primary task opened by parent action, or setup/auth/filter |

