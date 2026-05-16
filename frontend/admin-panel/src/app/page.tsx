"use client";

import { FormEvent, useEffect, useState } from "react";

const sessionKey = "yaro0_admin_session";
const apiBaseUrl =
  process.env.NEXT_PUBLIC_API_URL?.replace(/\/$/, "") ??
  "http://localhost:8000/api/v1";

type AdminSession = {
  token: string;
  admin: {
    id: string;
    email: string | null;
    phone: string;
    role: string;
  };
};

export default function AdminHomePage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [session, setSession] = useState<AdminSession | null>(null);
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    const storedSession = window.localStorage.getItem(sessionKey);

    if (storedSession) {
      try {
        setSession(JSON.parse(storedSession) as AdminSession);
      } catch {
        window.localStorage.removeItem(sessionKey);
      }
    }
  }, []);

  async function handleLogin(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      const response = await fetch(`${apiBaseUrl}/auth/admin/login`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email, password }),
      });
      const data = await response.json();

      if (!response.ok || !data.success) {
        throw new Error(data.message ?? "Login failed.");
      }

      const nextSession = {
        token: data.token,
        admin: data.admin,
      } satisfies AdminSession;

      window.localStorage.setItem(sessionKey, JSON.stringify(nextSession));
      setSession(nextSession);
      setPassword("");
    } catch (caughtError) {
      setError(
        caughtError instanceof Error
          ? caughtError.message
          : "Could not sign in right now.",
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  function handleLogout() {
    window.localStorage.removeItem(sessionKey);
    setSession(null);
  }

  if (session) {
    return (
      <main className="dashboard-shell">
        <section className="dashboard-panel">
          <div>
            <p className="eyebrow">Admin panel</p>
            <h1>Welcome back</h1>
            <p className="muted">
              Signed in as {session.admin.email ?? session.admin.phone}
            </p>
          </div>
          <button className="secondary-button" type="button" onClick={handleLogout}>
            Sign out
          </button>
        </section>
      </main>
    );
  }

  return (
    <main className="login-shell">
      <section className="login-panel" aria-labelledby="login-title">
        <div className="login-copy">
          <p className="eyebrow">Yaro0 Admin</p>
          <h1 id="login-title">Sign in</h1>
          <p className="muted">Access moderation, profiles, and operations.</p>
        </div>

        <form className="login-form" onSubmit={handleLogin}>
          <label>
            Email
            <input
              autoComplete="email"
              name="email"
              onChange={(event) => setEmail(event.target.value)}
              required
              type="email"
              value={email}
            />
          </label>

          <label>
            Password
            <input
              autoComplete="current-password"
              name="password"
              onChange={(event) => setPassword(event.target.value)}
              required
              type="password"
              value={password}
            />
          </label>

          {error ? <p className="error-message">{error}</p> : null}

          <button disabled={isSubmitting} type="submit">
            {isSubmitting ? "Signing in..." : "Sign in"}
          </button>
        </form>
      </section>
    </main>
  );
}
