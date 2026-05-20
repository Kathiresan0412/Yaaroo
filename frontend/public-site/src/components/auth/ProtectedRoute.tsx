"use client";

import { ReactNode, useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "./AuthProvider";

export function ProtectedRoute({ children }: { children: ReactNode }) {
  const { accessToken, user, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && (!user || !accessToken)) {
      router.replace("/login");
    }
  }, [accessToken, isLoading, router, user]);

  if (isLoading || !user || !accessToken) {
    return null;
  }

  return children;
}
