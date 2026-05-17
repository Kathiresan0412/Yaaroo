"use client";

import { FormEvent, useState } from "react";
import { CheckCircle2, Loader2 } from "lucide-react";

type Status = "idle" | "submitting" | "success" | "error";

function SocialLoginButtons() {
  return (
    <div className="social-login">
      <a className="social-button google" href="/api/auth/google">
        <span aria-hidden="true">G</span>
        Continue with Google
      </a>
      <a className="social-button tiktok" href="/api/auth/tiktok">
        <span aria-hidden="true">T</span>
        Continue with TikTok
      </a>
    </div>
  );
}

export function LoginForm() {
  const [status, setStatus] = useState<Status>("idle");
  const [message, setMessage] = useState("");

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus("submitting");
    setMessage("");

    const formData = new FormData(event.currentTarget);

    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: formData.get("email"),
          password: formData.get("password"),
        }),
      });
      const payload = (await response.json()) as { message?: string };

      if (!response.ok) {
        throw new Error(payload.message || "Unable to log in.");
      }

      setStatus("success");
      setMessage(payload.message || "Login request accepted.");
    } catch (error) {
      setStatus("error");
      setMessage(error instanceof Error ? error.message : "Please try again.");
    }
  }

  return (
    <section className="auth-card" aria-labelledby="login-title">
      <p className="modal-kicker">Welcome back</p>
      <h1 id="login-title">Log in to Yaro0</h1>
      <SocialLoginButtons />
      <div className="auth-divider">or use email</div>
      <form className="account-form" onSubmit={onSubmit}>
        <label>
          Email address
          <input name="email" type="email" autoComplete="email" required />
        </label>
        <label>
          Password
          <input name="password" type="password" autoComplete="current-password" required />
        </label>
        <div className="auth-row">
          <label className="check-label">
            <input type="checkbox" name="remember" />
            Remember me
          </label>
          <a href="/forgot-password">Forgot password?</a>
        </div>
        {message ? (
          <p className={status === "error" ? "form-error" : "form-success"} role="status">
            {status === "success" ? <CheckCircle2 size={18} aria-hidden="true" /> : null}
            {message}
          </p>
        ) : null}
        <button className="primary-cta" type="submit" disabled={status === "submitting"}>
          {status === "submitting" ? (
            <>
              <Loader2 className="spin" size={18} aria-hidden="true" />
              Logging in
            </>
          ) : (
            "Log in"
          )}
        </button>
      </form>
      <p className="auth-switch">
        New to Yaro0? <a href="/#create-account">Create account</a>
      </p>
    </section>
  );
}

export function SignupForm() {
  const [status, setStatus] = useState<Status>("idle");
  const [message, setMessage] = useState("");

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus("submitting");
    setMessage("");

    const form = event.currentTarget;
    const formData = new FormData(form);

    try {
      const response = await fetch("/api/auth/signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: formData.get("name"),
          email: formData.get("email"),
          password: formData.get("password"),
        }),
      });
      const payload = (await response.json()) as { message?: string };

      if (!response.ok) {
        throw new Error(payload.message || "Unable to create account.");
      }

      form.reset();
      setStatus("success");
      setMessage(payload.message || "Account request created.");
    } catch (error) {
      setStatus("error");
      setMessage(error instanceof Error ? error.message : "Please try again.");
    }
  }

  return (
    <section className="auth-card" aria-labelledby="signup-title">
      <p className="modal-kicker">Start verified</p>
      <h1 id="signup-title">Create your account</h1>
      <SocialLoginButtons />
      <div className="auth-divider">or create with email</div>
      <form className="account-form" onSubmit={onSubmit}>
        <label>
          Full name
          <input name="name" type="text" autoComplete="name" required />
        </label>
        <label>
          Email address
          <input name="email" type="email" autoComplete="email" required />
        </label>
        <label>
          Password
          <input name="password" type="password" autoComplete="new-password" required />
        </label>
        {message ? (
          <p className={status === "error" ? "form-error" : "form-success"} role="status">
            {status === "success" ? <CheckCircle2 size={18} aria-hidden="true" /> : null}
            {message}
          </p>
        ) : null}
        <button className="primary-cta" type="submit" disabled={status === "submitting"}>
          {status === "submitting" ? (
            <>
              <Loader2 className="spin" size={18} aria-hidden="true" />
              Creating
            </>
          ) : (
            "Create account"
          )}
        </button>
      </form>
      <p className="auth-switch">
        Already have an account? <a href="/login">Log in</a>
      </p>
    </section>
  );
}

export function ForgotPasswordForm() {
  const [status, setStatus] = useState<Status>("idle");
  const [message, setMessage] = useState("");

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus("submitting");
    setMessage("");

    const form = event.currentTarget;
    const formData = new FormData(form);

    try {
      const response = await fetch("/api/auth/request-reset", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: formData.get("email") }),
      });
      const payload = (await response.json()) as { message?: string };

      if (!response.ok) {
        throw new Error(payload.message || "Unable to send reset link.");
      }

      form.reset();
      setStatus("success");
      setMessage(payload.message || "Check your email for the reset link.");
    } catch (error) {
      setStatus("error");
      setMessage(error instanceof Error ? error.message : "Please try again.");
    }
  }

  return (
    <section className="auth-card" aria-labelledby="forgot-title">
      <p className="modal-kicker">Password help</p>
      <h1 id="forgot-title">Reset your password</h1>
      <p className="modal-copy">
        Enter your account email and we will send a secure reset link.
      </p>
      <form className="account-form" onSubmit={onSubmit}>
        <label>
          Email address
          <input name="email" type="email" autoComplete="email" required />
        </label>
        {message ? (
          <p className={status === "error" ? "form-error" : "form-success"} role="status">
            {status === "success" ? <CheckCircle2 size={18} aria-hidden="true" /> : null}
            {message}
          </p>
        ) : null}
        <button className="primary-cta" type="submit" disabled={status === "submitting"}>
          {status === "submitting" ? (
            <>
              <Loader2 className="spin" size={18} aria-hidden="true" />
              Sending
            </>
          ) : (
            "Send reset link"
          )}
        </button>
      </form>
      <p className="auth-switch">
        Remembered it? <a href="/login">Back to login</a>
      </p>
    </section>
  );
}

export function ResetPasswordForm() {
  const [status, setStatus] = useState<Status>("idle");
  const [message, setMessage] = useState("");

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus("submitting");
    setMessage("");

    const form = event.currentTarget;
    const formData = new FormData(form);
    const password = String(formData.get("password") || "");
    const confirmPassword = String(formData.get("confirmPassword") || "");

    if (password !== confirmPassword) {
      setStatus("error");
      setMessage("Passwords do not match.");
      return;
    }

    try {
      const response = await fetch("/api/auth/reset-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          token: formData.get("token"),
          password,
        }),
      });
      const payload = (await response.json()) as { message?: string };

      if (!response.ok) {
        throw new Error(payload.message || "Unable to reset password.");
      }

      form.reset();
      setStatus("success");
      setMessage(payload.message || "Your password has been updated.");
    } catch (error) {
      setStatus("error");
      setMessage(error instanceof Error ? error.message : "Please try again.");
    }
  }

  return (
    <section className="auth-card" aria-labelledby="reset-title">
      <p className="modal-kicker">New password</p>
      <h1 id="reset-title">Choose a secure password</h1>
      <form className="account-form" onSubmit={onSubmit}>
        <label>
          Reset token
          <input name="token" type="text" required />
        </label>
        <label>
          New password
          <input name="password" type="password" autoComplete="new-password" required />
        </label>
        <label>
          Confirm password
          <input name="confirmPassword" type="password" autoComplete="new-password" required />
        </label>
        {message ? (
          <p className={status === "error" ? "form-error" : "form-success"} role="status">
            {status === "success" ? <CheckCircle2 size={18} aria-hidden="true" /> : null}
            {message}
          </p>
        ) : null}
        <button className="primary-cta" type="submit" disabled={status === "submitting"}>
          {status === "submitting" ? (
            <>
              <Loader2 className="spin" size={18} aria-hidden="true" />
              Updating
            </>
          ) : (
            "Reset password"
          )}
        </button>
      </form>
    </section>
  );
}
