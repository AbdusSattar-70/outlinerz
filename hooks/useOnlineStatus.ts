// hooks/useOnlineStatus.ts
import { useEffect, useState } from "react";
import { onlineManager } from "@tanstack/react-query";
import { Status } from "@/types";
import { STATUS } from "@/lib/constants";

export function useOnlineStatus(): Status {
  const [status, setStatus] = useState<Status>(STATUS.ONLINE);

  useEffect(() => {
    let wasOffline = !navigator.onLine;
    let timer: ReturnType<typeof setTimeout> | undefined;
    const update = () => {
      const isOnline = navigator.onLine;
      onlineManager.setOnline(isOnline);

      if (isOnline && wasOffline) {
        setStatus(STATUS.BACK_ONLINE);
        timer = setTimeout(() => setStatus(STATUS.ONLINE), 2000);
      } else if (!isOnline) {
        if (timer) clearTimeout(timer);
        setStatus(STATUS.OFFLINE);
      }
      wasOffline = !isOnline;
    };

    update();
    window.addEventListener(STATUS.ONLINE, update);
    window.addEventListener(STATUS.OFFLINE, update);

    return () => {
      if (timer) clearTimeout(timer);
      window.removeEventListener(STATUS.ONLINE, update);
      window.removeEventListener(STATUS.OFFLINE, update);
    };
  }, []);

  return status;
}
