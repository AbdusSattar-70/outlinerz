"use client";
import { ActionPanel, announceSaved } from "@/components/erp/action-panel";

import { useMemo, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  useForm,
  useWatch,
  type FieldPath,
} from "react-hook-form";
import { KeyRound, Save, ShieldAlert } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ErpFormField, ErpFormStatus } from "@/components/erp/form-field";
import { updateRolePermissions } from "@/modules/settings/actions";
import {
  rolePermissionUpdateSchema,
  type RolePermissionUpdateInput,
} from "@/modules/settings/schema";
import type {
  SettingsPermissionRow,
  SettingsRoleRow,
} from "@/modules/settings/queries";

const inputClass =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm text-foreground outline-none transition focus-visible:border-ring focus-visible:ring-2 focus-visible:ring-ring/30 aria-[invalid=true]:border-destructive";

const groupNames: Record<string, string> = {
  dashboard: "Dashboard",
  action_center: "Action Center",
  crm: "CRM",
  admissions: "Admissions",
  students: "Students",
  academics: "Academics",
  finance: "Finance",
  staff: "Staff",
  assets: "Assets",
  procurement: "Procurement",
  accounting: "Accounting",
  analytics: "Analytics",
  system: "System",
  audit: "Audit",
  approvals: "Approvals",
};

function permissionGroup(code: string) {
  return code.split(".")[0] ?? "other";
}

export function RolePermissionEditor({
  roles,
  permissions,
}: {
  roles: SettingsRoleRow[];
  permissions: SettingsPermissionRow[];
}) {
  const router = useRouter();
  const editableRoles = useMemo(
    () => roles.filter((role) => role.code !== "ADMIN"),
    [roles]
  );
  const [selectedRoleCode, setSelectedRoleCode] = useState(
    editableRoles[0]?.code ?? ""
  );
  const [pending, startTransition] = useTransition();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(
    null
  );

  const selectedRole = editableRoles.find(
    (role) => role.code === selectedRoleCode
  );

  const currentPermissionCodes = useMemo(
    () => selectedRole?.permissions.map((permission) => permission.code) ?? [],
    [selectedRole]
  );

  const {
    register,
    handleSubmit,
    control,
    reset,
    setError,
    formState: { errors, isValid },
  } = useForm<RolePermissionUpdateInput>({
    resolver: zodResolver(rolePermissionUpdateSchema),
    mode: "onChange",
    defaultValues: {
      roleCode: selectedRoleCode,
      permissionCodes: currentPermissionCodes,
      reason: "",
    },
  });

  const watchedPermissionsValue = useWatch({
    control,
    name: "permissionCodes",
  });
  const watchedPermissions = useMemo(
    () => watchedPermissionsValue ?? [],
    [watchedPermissionsValue]
  );
  const reason = useWatch({ control, name: "reason" }) ?? "";

  const normalizedCurrent = useMemo(
    () => [...currentPermissionCodes].sort(),
    [currentPermissionCodes]
  );
  const normalizedNext = useMemo(
    () => [...watchedPermissions].sort(),
    [watchedPermissions]
  );

  const hasChange =
    normalizedCurrent.length !== normalizedNext.length ||
    normalizedCurrent.some((code, index) => code !== normalizedNext[index]);

  const currentSet = useMemo(
    () => new Set(currentPermissionCodes),
    [currentPermissionCodes]
  );
  const nextSet = useMemo(
    () => new Set(watchedPermissions),
    [watchedPermissions]
  );

  const added = normalizedNext.filter((code) => !currentSet.has(code));
  const removed = normalizedCurrent.filter((code) => !nextSet.has(code));

  const permissionsByGroup = useMemo(() => {
    const map = new Map<string, SettingsPermissionRow[]>();

    for (const permission of permissions) {
      const group = permissionGroup(permission.code);
      const list = map.get(group) ?? [];
      list.push(permission);
      map.set(group, list);
    }

    return Array.from(map.entries()).sort(([a], [b]) => a.localeCompare(b));
  }, [permissions]);

  const canSubmit =
    Boolean(selectedRole) &&
    hasChange &&
    isValid &&
    reason.trim().length >= 5 &&
    !pending;

  const submit = handleSubmit((input) => {
    setMessage(null);

    startTransition(async () => {
      const result = await updateRolePermissions(input);

      if (!result.ok) {
        if (result.field) {
          setError(result.field as FieldPath<RolePermissionUpdateInput>, {
            type: "server",
            message: result.error,
          });
        }
        setMessage({ ok: false, text: result.error });
        return;
      }

      reset({
        roleCode: input.roleCode,
        permissionCodes: input.permissionCodes,
        reason: "",
      });
      setMessage({
        ok: true,
        text: `Permissions updated for ${selectedRole?.name ?? input.roleCode}. The change is recorded in the audit trail.`,
      });
      router.refresh();
    });
  });

  if (!editableRoles.length) {
    return (
      <div className="rounded-xl border border-dashed p-5 text-sm text-muted-foreground">
        No editable operational roles are configured yet. The protected ADMIN
        recovery role is intentionally not editable here.
      </div>
    );
  }

  return (
    <div className="grid gap-5">
      <div className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm leading-6 text-amber-950 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-100">
        <div className="flex items-start gap-3">
          <ShieldAlert className="mt-0.5 size-5 shrink-0" aria-hidden="true" />
          <p>
            The bootstrap <strong>ADMIN</strong> role is protected from this
            editor so recovery access cannot be accidentally removed. Configure
            day-to-day access through operational roles.
          </p>
        </div>
      </div>

      <ActionPanel title="Edit role permissions"><form onSubmit={submit} noValidate className="grid gap-5">
        <input type="hidden" {...register("roleCode")} />

        <div className="grid gap-4 lg:grid-cols-[320px_1fr]">
          <ErpFormField
            id="access-role"
            label="Operational Role"
            required
            hint="Choose the role bundle you want to review or change."
          >
            {({ id, describedBy, invalid }) => (
              <select
                id={id}
                value={selectedRoleCode}
                onChange={(event) => {
                  const nextCode = event.target.value;
                  const nextRole = editableRoles.find(
                    (role) => role.code === nextCode
                  );
                  const nextPermissions =
                    nextRole?.permissions.map((permission) => permission.code) ??
                    [];

                  setSelectedRoleCode(nextCode);
                  reset({
                    roleCode: nextCode,
                    permissionCodes: nextPermissions,
                    reason: "",
                  });
                  setMessage(null);
                }}
                aria-describedby={describedBy}
                aria-invalid={invalid}
                className={inputClass}
              >
                {editableRoles.map((role) => (
                  <option key={role.code} value={role.code}>
                    {role.name} ({role.code})
                  </option>
                ))}
              </select>
            )}
          </ErpFormField>

          <div className="rounded-xl border bg-muted/30 p-4">
            <div className="flex items-start gap-3">
              <KeyRound
                className="mt-0.5 size-5 shrink-0 text-blue-700 dark:text-blue-300"
                aria-hidden="true"
              />
              <div>
                <p className="text-sm font-semibold">
                  {selectedRole?.name ?? "Role"}
                </p>
                <p className="mt-1 text-xs leading-5 text-muted-foreground">
                  {currentPermissionCodes.length} permissions currently active.
                  Changes take effect for users assigned this role after the
                  policy save/refresh cycle.
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="grid gap-4 xl:grid-cols-2">
          {permissionsByGroup.map(([group, items]) => (
            <fieldset key={group} className="rounded-xl border p-4">
              <legend className="px-1 text-sm font-semibold">
                {groupNames[group] ?? group.replaceAll("_", " ")}
              </legend>

              <div className="mt-2 grid gap-2">
                {items.map((permission) => (
                  <label
                    key={permission.code}
                    className="flex cursor-pointer items-start gap-3 rounded-lg border bg-background p-3 hover:bg-muted/30"
                  >
                    <input
                      type="checkbox"
                      value={permission.code}
                      className="mt-1 size-4 shrink-0"
                      {...register("permissionCodes")}
                    />
                    <span className="min-w-0">
                      <span className="block text-sm font-medium">
                        {permission.name}
                      </span>
                      <span className="mt-0.5 block break-all text-[11px] font-medium text-blue-700 dark:text-blue-300">
                        {permission.code}
                      </span>
                      {permission.description && (
                        <span className="mt-1 block text-xs leading-5 text-muted-foreground">
                          {permission.description}
                        </span>
                      )}
                    </span>
                  </label>
                ))}
              </div>
            </fieldset>
          ))}
        </div>

        {errors.permissionCodes?.message && (
          <p role="alert" className="text-xs font-medium text-destructive">
            {errors.permissionCodes.message}
          </p>
        )}

        <div className="grid gap-3 rounded-xl border bg-muted/20 p-4 sm:grid-cols-2">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
              Permissions to add
            </p>
            <p className="mt-2 text-sm">
              {added.length ? added.join(", ") : "None"}
            </p>
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
              Permissions to remove
            </p>
            <p className="mt-2 text-sm">
              {removed.length ? removed.join(", ") : "None"}
            </p>
          </div>
        </div>

        <ErpFormField
          id="access-change-reason"
          label="Change Reason"
          required
          hint="Explain why this role needs more or less access. This reason is preserved in the audit event."
          error={errors.reason?.message}
        >
          {({ id, describedBy, invalid }) => (
            <textarea
              id={id}
              rows={3}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={`${inputClass} py-2.5`}
              {...register("reason")}
            />
          )}
        </ErpFormField>

        <ErpFormStatus message={message} />

        <div className="flex flex-col gap-2 border-t pt-4 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-xs text-muted-foreground">
            {hasChange
              ? `${added.length} permission(s) will be added and ${removed.length} removed.`
              : "Change at least one permission to enable saving."}
          </p>
          <Button type="submit" disabled={!canSubmit} className="min-h-11">
            <Save className="mr-2 size-4" aria-hidden="true" />
            {pending ? "Saving Access…" : "Save Role Permissions"}
          </Button>
        </div>
      </form></ActionPanel>
    </div>
  );
}
