"use client";

import {
  createContext,
  ReactNode,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

type AuthUser = {
  id: string;
  email: string | null;
  firstName: string | null;
  lastName: string | null;
  emailVerified: boolean;
  onboardingCompleted: boolean;
  role: string;
};

type AuthContextValue = {
  user: AuthUser | null;
  accessToken: string;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<string>;
  logout: () => Promise<void>;
  authFetch: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

async function parseJson(response: Response) {
  return (await response.json()) as {
    accessToken?: string;
    message?: string;
    redirectTo?: string;
    user?: AuthUser;
  };
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [accessToken, setAccessToken] = useState("");
  const [isLoading, setIsLoading] = useState(true);

  const refresh = useCallback(async () => {
    const response = await fetch("/api/auth/refresh", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: "{}",
    });

    if (!response.ok) {
      setUser(null);
      setAccessToken("");
      return "";
    }

    const payload = await parseJson(response);
    setUser(payload.user || null);
    setAccessToken(payload.accessToken || "");

    return payload.accessToken || "";
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const response = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    const payload = await parseJson(response);

    if (!response.ok) {
      throw new Error(payload.message || "Unable to log in.");
    }

    setUser(payload.user || null);
    setAccessToken(payload.accessToken || "");

    return payload.redirectTo || "/onboarding";
  }, []);

  const logout = useCallback(async () => {
    await fetch("/api/auth/logout", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: "{}",
    });
    setUser(null);
    setAccessToken("");
  }, []);

  useEffect(() => {
    refresh().finally(() => setIsLoading(false));
  }, [refresh]);

  const authFetch = useCallback(
    async (input: RequestInfo | URL, init: RequestInit = {}) => {
      const headers = new Headers(init.headers);

      if (accessToken) {
        headers.set("Authorization", `Bearer ${accessToken}`);
      }

      let response = await fetch(input, { ...init, headers });

      if (response.status === 401) {
        const freshToken = await refresh();

        if (freshToken) {
          headers.set("Authorization", `Bearer ${freshToken}`);
          response = await fetch(input, { ...init, headers });
        }
      }

      return response;
    },
    [accessToken, refresh],
  );

  const value = useMemo(
    () => ({ user, accessToken, isLoading, login, logout, authFetch }),
    [user, accessToken, isLoading, login, logout, authFetch],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const value = useContext(AuthContext);

  if (!value) {
    throw new Error("useAuth must be used inside AuthProvider.");
  }

  return value;
}
