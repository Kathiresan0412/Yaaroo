"use client";

import {
  createContext,
  ReactNode,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
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
  login: (email: string, password: string, remember?: boolean) => Promise<string>;
  logout: () => Promise<void>;
  authFetch: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;
};

const AuthContext = createContext<AuthContextValue | null>(null);
const storedUserKey = "yaaro0.auth.user";

function readStoredUser() {
  if (typeof window === "undefined") {
    return null;
  }

  try {
    const raw = window.localStorage.getItem(storedUserKey);
    return raw ? (JSON.parse(raw) as AuthUser) : null;
  } catch {
    window.localStorage.removeItem(storedUserKey);
    return null;
  }
}

function storeUser(user: AuthUser | null) {
  if (typeof window === "undefined") {
    return;
  }

  if (user) {
    window.localStorage.setItem(storedUserKey, JSON.stringify(user));
  } else {
    window.localStorage.removeItem(storedUserKey);
  }
}

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

  const accessTokenRef = useRef(accessToken);
  useEffect(() => {
    accessTokenRef.current = accessToken;
  }, [accessToken]);

  const refresh = useCallback(async () => {
    let response: Response;

    try {
      response = await fetch("/api/auth/refresh", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: "{}",
      });
    } catch {
      return "";
    }

    if (response.status === 401 || response.status === 403) {
      setUser(null);
      setAccessToken("");
      storeUser(null);
      return "";
    }

    if (!response.ok) {
      return "";
    }

    const payload = await parseJson(response);
    setUser(payload.user || null);
    setAccessToken(payload.accessToken || "");
    storeUser(payload.user || null);

    return payload.accessToken || "";
  }, []);

  const login = useCallback(async (email: string, password: string, remember = true) => {
    const response = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "include",
      body: JSON.stringify({ email, password, remember }),
    });
    const payload = await parseJson(response);

    if (!response.ok) {
      throw new Error(payload.message || "Unable to log in.");
    }

    setUser(payload.user || null);
    setAccessToken(payload.accessToken || "");
    storeUser(payload.user || null);

    return payload.redirectTo || "/onboarding";
  }, []);

  const logout = useCallback(async () => {
    await fetch("/api/auth/logout", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "include",
      body: "{}",
    });
    setUser(null);
    setAccessToken("");
    storeUser(null);
  }, []);

  useEffect(() => {
    const storedUser = readStoredUser();

    if (storedUser) {
      setUser(storedUser);
    }

    refresh().finally(() => setIsLoading(false));
  }, [refresh]);

  const authFetch = useCallback(
    async (input: RequestInfo | URL, init: RequestInit = {}) => {
      const headers = new Headers(init.headers);
      let token = accessTokenRef.current;

      if (!token) {
        token = await refresh();
      }

      if (token) {
        headers.set("Authorization", `Bearer ${token}`);
      }

      let response = await fetch(input, { ...init, headers, credentials: init.credentials ?? "include" });

      if (response.status === 401 || response.status === 403) {
        const freshToken = await refresh();

        if (freshToken) {
          headers.set("Authorization", `Bearer ${freshToken}`);
          response = await fetch(input, { ...init, headers, credentials: init.credentials ?? "include" });
        }

        if (response.status === 401 || response.status === 403) {
          setUser(null);
          setAccessToken("");
          storeUser(null);
        }
      }

      if (!response.ok && typeof window !== "undefined") {
        const message =
          response.status >= 500
            ? "Yaaro0 is having trouble reaching the server."
            : response.status === 429
              ? "You are moving fast. Please try again in a moment."
              : "";

        if (message) {
          window.dispatchEvent(new CustomEvent("yaaro0:toast", { detail: { message, tone: "error" } }));
        }
      }

      return response;
    },
    [refresh],
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
