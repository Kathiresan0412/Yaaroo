"use client";

import { ReactNode, useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { WifiOff, X } from "lucide-react";

type Toast = {
  id: number;
  message: string;
  tone?: "info" | "error" | "success";
};

function track(eventName: string, properties: Record<string, unknown> = {}) {
  const payload = JSON.stringify({
    eventName,
    properties,
    url: window.location.pathname,
    referrer: document.referrer,
  });

  if (navigator.sendBeacon) {
    navigator.sendBeacon("/api/analytics", new Blob([payload], { type: "application/json" }));
    return;
  }

  void fetch("/api/analytics", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: payload,
    keepalive: true,
  });
}

export function PwaRuntime({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const [isOffline, setIsOffline] = useState(false);
  const [toasts, setToasts] = useState<Toast[]>([]);

  useEffect(() => {
    setIsOffline(!navigator.onLine);

    if ("serviceWorker" in navigator) {
      const registerServiceWorker = () => {
        void navigator.serviceWorker.register("/sw.js");
      };

      if (document.readyState === "complete") {
        registerServiceWorker();
      } else {
        window.addEventListener("load", registerServiceWorker, { once: true });
      }
    }

    const onOnline = () => {
      setIsOffline(false);
      setToasts((current) => [
        ...current,
        { id: Date.now(), message: "Back online. Fresh profiles will sync now.", tone: "success" },
      ]);
    };
    const onOffline = () => {
      setIsOffline(true);
      setToasts((current) => [
        ...current,
        { id: Date.now(), message: "Offline mode. Showing saved matches and messages when available.", tone: "info" },
      ]);
    };
    const onToast = (event: Event) => {
      const detail = (event as CustomEvent<{ message?: string; tone?: Toast["tone"] }>).detail;
      if (!detail?.message) {
        return;
      }

      const message = detail.message;
      setToasts((current) => {
        const tone = detail.tone || "error";

        if (current.some((toast) => toast.message === message && (toast.tone || "error") === tone)) {
          return current;
        }

        return [...current, { id: Date.now() + Math.random(), message, tone }];
      });
    };

    window.addEventListener("online", onOnline);
    window.addEventListener("offline", onOffline);
    window.addEventListener("yaaro0:toast", onToast);

    return () => {
      window.removeEventListener("online", onOnline);
      window.removeEventListener("offline", onOffline);
      window.removeEventListener("yaaro0:toast", onToast);
    };
  }, []);

  useEffect(() => {
    if (pathname) {
      track("page_view", { pathname });
    }
  }, [pathname]);

  useEffect(() => {
    if (toasts.length === 0) {
      return;
    }

    const timeout = window.setTimeout(() => {
      setToasts((current) => current.slice(1));
    }, 4500);

    return () => window.clearTimeout(timeout);
  }, [toasts]);

  return (
    <>
      {children}
      {isOffline ? (
        <div className="offline-banner" role="status">
          <WifiOff size={16} />
          Offline
        </div>
      ) : null}
      <div className="toast-stack" aria-live="polite" aria-relevant="additions">
        {toasts.map((toast) => (
          <div className={`app-toast ${toast.tone || "error"}`} key={toast.id}>
            <span>{toast.message}</span>
            <button
              type="button"
              aria-label="Dismiss notification"
              onClick={() => setToasts((current) => current.filter((item) => item.id !== toast.id))}
            >
              <X size={14} />
            </button>
          </div>
        ))}
      </div>
    </>
  );
}
