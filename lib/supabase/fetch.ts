/** Bound each network call. Never automatically retry financial mutations. */
export const SUPABASE_REQUEST_TIMEOUT_MS = 20_000;
export const boundedFetch: typeof fetch = async (input, init) => {
  const timeout = AbortSignal.timeout(SUPABASE_REQUEST_TIMEOUT_MS);
  const incoming = init?.signal ?? (input instanceof Request ? input.signal : undefined);
  const signal = incoming ? AbortSignal.any([incoming, timeout]) : timeout;
  return fetch(input, { ...init, signal, cache: "no-store" });
};
