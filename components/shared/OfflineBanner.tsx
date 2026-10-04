"use client";

import { useOnlineStatus } from "@/hooks/useOnlineStatus";
import { FEEDBACK_MSG, STATUS } from "@/lib/constants";
import { cn } from "@/lib/utils";

export function OfflineBanner() {
  const status = useOnlineStatus();

  if (status === STATUS.ONLINE) return null;

  return (
    <div
      className={cn(
        "fixed top-4 right-4 z-50 rounded-md px-4 py-2 text-sm font-medium shadow-md border transition-colors duration-300",
        status === STATUS.OFFLINE
          ? "bg-red-600 text-white border-red-700"
          : "bg-emerald-500 text-white border-emerald-700"
      )}
      role="status"
    >
      {status === STATUS.OFFLINE
        ? FEEDBACK_MSG[STATUS.OFFLINE]
        : FEEDBACK_MSG[STATUS.BACK_ONLINE]}
    </div>
  );
}
