import { revalidatePath } from "next/cache";
import type { SupabaseClient } from "@supabase/supabase-js";
import { getErpContext } from "./auth/erp-context";
import type { Json } from "@/types/database";

/**
 * Revalidate a set of dashboard routes after a mutation. Centralised so new
 * dashboard surfaces are added in one place instead of in every action module.
 */
export function revalidateDashboard(...paths: string[]) {
  for (const path of paths) revalidatePath(path);
}

export type CommandFailure = {
  ok: false;
  message: string;
  field?: string;
};

export type CommandResult<T = Record<string, unknown>> =
  | ({ ok: true } & T)
  | CommandFailure;

type RpcClient = {
  rpc: (
    fn: string,
    args: Record<string, unknown>,
  ) => Promise<{ data: unknown; error: { message: string } | null }>;
};

export type RunCommandActionOptions<TInput, TSuccess> = {
  schema: {
    safeParse: (
      input: TInput,
    ) =>
      | { success: true; data: unknown }
      | { success: false; error: { issues?: readonly { message: string; path?: readonly PropertyKey[] }[] } };
  };
  input: TInput;
  client: () => Promise<SupabaseClient<never, "academy"> | SupabaseClient | RpcClient>;
  rpc: string;
  permission: string | string[];
  revalidate: string[];
  revalidateType?: "page" | "layout";
  /** Additional revalidation for non-dynamic routes, e.g. revalidateDashboard(...). */
  revalidateExtra?: () => void;
  /** Wrap the raw RPC payload into the success shape; return a failure to short-circuit. */
  mapResult?: (data: unknown) => TSuccess | CommandFailure;
  /** Message used when the RPC returns no payload. */
  emptyMessage?: string;
};

/**
 * Shared server-action pipeline: zod validation → permission check → RPC call →
 * path revalidation. Keeps the failure shape ({ ok: false, message, field? })
 * consistent across command actions.
 */
export async function runCommandAction<TInput, TSuccess = Record<string, never>>(
  options: RunCommandActionOptions<TInput, TSuccess>,
): Promise<CommandResult<TSuccess>> {
  const parsed = options.schema.safeParse(options.input);
  if (!parsed.success) {
    const issue = parsed.error.issues?.[0];
    return {
      ok: false,
      message: issue?.message ?? "Please check the submitted details.",
      field: issue?.path?.[0]?.toString(),
    };
  }

  const context = await getErpContext();
  const required = Array.isArray(options.permission)
    ? options.permission
    : [options.permission];
  const granted = required.some((p) => context?.permissions.includes(p));
  if (!granted)
    return { ok: false, message: "You do not have permission for this action." };

  const db = (await options.client()) as RpcClient;
  const { data, error } = await db.rpc(options.rpc, { p_input: parsed.data as Json });
  if (error) return { ok: false, message: error.message };

  if (data === null || data === undefined)
    return {
      ok: false,
      message: options.emptyMessage ?? "The command returned no response.",
    };

  const mapped = options.mapResult
    ? options.mapResult(data)
    : ({ message: String((data as { message?: unknown })?.message ?? "") } as TSuccess);
  if (mapped && (mapped as CommandFailure).ok === false)
    return mapped as CommandFailure;

  for (const path of options.revalidate)
    revalidatePath(path, options.revalidateType);
  options.revalidateExtra?.();
  return { ok: true, ...(mapped as TSuccess) };
}
