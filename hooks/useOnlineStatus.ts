// hooks/useOnlineStatus.ts
import { useEffect, useState } from "react";
import { onlineManager } from "@tanstack/react-query";
import { Status } from "@/types";
import { STATUS } from "@/lib/constants";

export function useOnlineStatus(): Status {
  const [status, setStatus] = useState<Status>(STATUS.ONLINE);

  useEffect(() => {
    const update = () => {
      const isOnline = navigator.onLine;
      onlineManager.setOnline(isOnline);

      if (isOnline) {
        setStatus(STATUS.BACK_ONLINE);
        setTimeout(() => setStatus(STATUS.ONLINE), 2000);
      } else {
        setStatus(STATUS.OFFLINE);
      }
    };

    update();
    window.addEventListener(STATUS.ONLINE, update);
    window.addEventListener(STATUS.OFFLINE, update);

    return () => {
      window.removeEventListener(STATUS.ONLINE, update);
      window.removeEventListener(STATUS.OFFLINE, update);
    };
  }, []);

  return status;
}
