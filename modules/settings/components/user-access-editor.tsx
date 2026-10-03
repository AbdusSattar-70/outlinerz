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
import { Save, ShieldCheck, UserCog } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ErpFormField, ErpFormStatus } from "@/components/erp/form-field";
import { updateUserOperationalAccess } from "@/modules/settings/actions";
import {
  userAccessUpdateSchema,
  type UserAccessUpdateInput,
} from "@/modules/settings/schema";
import type {
  SettingsAccessUserRow,
  SettingsRoleRow,
} from "@/modules/settings/queries";

const inputClass =
  "min-h-11 w-full rounded-xl border border-input bg-background px-3 text-sm text-foreground outline-none transition focus-visible:border-ring focus-visible:ring-2 focus-visible:ring-ring/30 aria-[invalid=true]:border-destructive";

export function UserAccessEditor({
  users,
  roles,
}: {
  users: SettingsAccessUserRow[];
  roles: SettingsRoleRow[];
}) {
  const router = useRouter();
  const operationalRoles = useMemo(
    () => roles.filter((role) => role.code !== "ADMIN"),
    [roles]
  );
  const [selectedProfileId, setSelectedProfileId] = useState(
    users[0]?.profileId ?? ""
  );
  const [pending, startTransition] = useTransition();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(
    null
  );

  const selectedUser = users.find(
    (user) => user.profileId === selectedProfileId
  );
  const currentRoleCodes = useMemo(
    () => selectedUser?.operationalRoleCodes ?? [],
    [selectedUser]
  );

  const {
    register,
    handleSubmit,
    control,
    reset,
    setError,
    formState: { errors, isValid },
  } = useForm<UserAccessUpdateInput>({
    resolver: zodResolver(userAccessUpdateSchema),
    mode: "onChange",
    defaultValues: {
      profileId: selectedProfileId,
      roleCodes: currentRoleCodes,
      reason: "",
    },
  });

  const watchedRoleCodesValue = useWatch({ control, name: "roleCodes" });
  const watchedRoleCodes = useMemo(
    () => watchedRoleCodesValue ?? [],
    [watchedRoleCodesValue]
  );
  const reason = useWatch({ control, name: "reason" }) ?? "";

  const normalizedCurrent = useMemo(
    () => [...currentRoleCodes].sort(),
    [currentRoleCodes]
  );
  const normalizedNext = useMemo(
    () => [...watchedRoleCodes].sort(),
    [watchedRoleCodes]
  );

  const hasChange =
    normalizedCurrent.length !== normalizedNext.length ||
    normalizedCurrent.some((code, index) => code !== normalizedNext[index]);

  const canSubmit =
    Boolean(selectedUser) &&
    hasChange &&
    isValid &&
    reason.trim().length >= 5 &&
    !pending;

  const submit = handleSubmit((input) => {
    setMessage(null);

    startTransition(async () => {
      const result = await updateUserOperationalAccess(input);

      if (!result.ok) {
        if (result.field) {
          setError(result.field as FieldPath<UserAccessUpdateInput>, {
            type: "server",
            message: result.error,
          });
        }
        setMessage({ ok: false, text: result.error });
        return;
      }

      reset({
        profileId: input.profileId,
        roleCodes: input.roleCodes,
        reason: "",
      });
      setMessage({
        ok: true,
        text: `Operational access updated for ${selectedUser?.displayName ?? "the selected user"}.`,
      });
      router.refresh();
    });
  });

  if (!users.length) {
    return (
      <div className="rounded-xl border border-dashed p-5 text-sm text-muted-foreground">
        No active sign-in profiles are available for access assignment.
      </div>
    );
  }

  return (
    <ActionPanel title="Edit account access"><form onSubmit={submit} noValidate className="grid gap-5">
      <input type="hidden" {...register("profileId")} />

      <div className="grid gap-4 lg:grid-cols-[360px_1fr]">
        <ErpFormField
          id="access-user"
          label="User"
          required
          hint="Choose the signed-in profile whose organization-wide operational roles you want to change."
        >
          {({ id, describedBy, invalid }) => (
            <select
              id={id}
              value={selectedProfileId}
              onChange={(event) => {
                const nextId = event.target.value;
                const nextUser = users.find(
                  (user) => user.profileId === nextId
                );

                setSelectedProfileId(nextId);
                reset({
                  profileId: nextId,
                  roleCodes: nextUser?.operationalRoleCodes ?? [],
                  reason: "",
                });
                setMessage(null);
              }}
              aria-describedby={describedBy}
              aria-invalid={invalid}
              className={inputClass}
            >
              {users.map((user) => (
                <option key={user.profileId} value={user.profileId}>
                  {user.displayName}
                  {user.staffNo ? ` — ${user.staffNo}` : ""}
                </option>
              ))}
            </select>
          )}
        </ErpFormField>

        <div className="rounded-xl border bg-muted/30 p-4">
          <div className="flex items-start gap-3">
            <UserCog
              className="mt-0.5 size-5 shrink-0 text-blue-700 dark:text-blue-300"
              aria-hidden="true"
            />
            <div className="min-w-0">
              <p className="font-semibold">
                {selectedUser?.staffName ?? selectedUser?.displayName}
              </p>
              <p className="mt-1 text-xs leading-5 text-muted-foreground">
                {selectedUser?.staffNo
                  ? `Linked Staff identity: ${selectedUser.staffNo}`
                  : "No linked Staff identity."}
              </p>
              {selectedUser?.protectedAdmin && (
                <div className="mt-3 inline-flex items-center gap-2 rounded-full border border-emerald-300 bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-900 dark:border-emerald-900 dark:bg-emerald-950/30 dark:text-emerald-100">
                  <ShieldCheck className="size-3.5" aria-hidden="true" />
                  Protected ADMIN access remains unchanged
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      <fieldset className="rounded-xl border p-4">
        <legend className="px-1 text-sm font-semibold">
          Organization-wide Operational Roles
        </legend>
        <p className="mt-1 text-xs leading-5 text-muted-foreground">
          These roles determine the user&apos;s permission bundles. Branch-scoped
          assignments will be exposed only after branch scope is enforced by all
          authorization checks.
        </p>

        <div className="mt-4 grid gap-2 sm:grid-cols-2 xl:grid-cols-3">
          {operationalRoles.map((role) => (
            <label
              key={role.code}
              className="flex cursor-pointer items-start gap-3 rounded-xl border bg-background p-3 hover:bg-muted/30"
            >
              <input
                type="checkbox"
                value={role.code}
                className="mt-1 size-4 shrink-0"
                {...register("roleCodes")}
              />
              <span>
                <span className="block text-sm font-medium">{role.name}</span>
                <span className="mt-1 block text-xs text-muted-foreground">
                  {role.code} • {role.permissions.length} permission(s)
                </span>
              </span>
            </label>
          ))}
        </div>
      </fieldset>

      {errors.roleCodes?.message && (
        <p role="alert" className="text-xs font-medium text-destructive">
          {errors.roleCodes.message}
        </p>
      )}

      <div className="rounded-xl border bg-muted/20 p-4">
        <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
          Effective access change
        </p>
        <div className="mt-3 grid gap-3 sm:grid-cols-2">
          <div>
            <p className="text-xs text-muted-foreground">Current operational roles</p>
            <p className="mt-1 text-sm">
              {normalizedCurrent.length
                ? normalizedCurrent.join(", ")
                : "No operational roles"}
            </p>
          </div>
          <div>
            <p className="text-xs text-muted-foreground">After save</p>
            <p className="mt-1 text-sm">
              {normalizedNext.length
                ? normalizedNext.join(", ")
                : "No operational roles"}
            </p>
          </div>
        </div>
      </div>

      <ErpFormField
        id="user-access-reason"
        label="Change Reason"
        required
        hint="Explain why this user is receiving or losing operational access. Previous assignments remain in history."
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
            ? "Saving will end removed role assignments and create any newly selected assignments."
            : "Change at least one operational role to enable saving."}
        </p>
        <Button type="submit" disabled={!canSubmit} className="min-h-11">
          <Save className="mr-2 size-4" aria-hidden="true" />
          {pending ? "Saving User Access…" : "Save User Access"}
        </Button>
      </div>
    </form></ActionPanel>
  );
}
