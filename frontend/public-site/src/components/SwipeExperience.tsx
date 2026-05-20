"use client";

import { FormEvent, MouseEvent, useEffect, useState } from "react";
import { createPortal } from "react-dom";
import {
  ChevronDown,
  CheckCircle2,
  Globe2,
  Heart,
  Loader2,
  LockKeyhole,
  Menu,
  MessageCircle,
  ShieldCheck,
  UserCheck,
  X,
} from "lucide-react";
import { PasswordField, TikTokIcon } from "./auth/AuthControls";
import { BrandLogo } from "./site/BrandLogo";

const profileCards = [
  {
    name: "Aaravi",
    age: 26,
    city: "Colombo",
    image:
      "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=760&q=82",
    className: "card-one",
  },
  {
    name: "Naveen",
    age: 29,
    city: "Toronto",
    image:
      "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=760&q=82",
    className: "card-two",
  },
  {
    name: "Maya",
    age: 25,
    city: "London",
    image:
      "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=760&q=82",
    className: "card-three",
  },
  {
    name: "Kavin",
    age: 31,
    city: "Jaffna",
    image:
      "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=760&q=82",
    className: "card-four",
  },
  {
    name: "Ishani",
    age: 27,
    city: "Melbourne",
    image:
      "https://images.unsplash.com/photo-1520813792240-56fc4a3765a7?auto=format&fit=crop&w=760&q=82",
    className: "card-five",
  },
  {
    name: "Arjun",
    age: 28,
    city: "Chennai",
    image:
      "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=760&q=82",
    className: "card-six",
  },
  {
    name: "Thara",
    age: 24,
    city: "Kandy",
    image:
      "https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=760&q=82",
    className: "card-seven",
  },
  {
    name: "Sanjay",
    age: 30,
    city: "Doha",
    image:
      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=760&q=82",
    className: "card-eight",
  },
];

const featuredProfile = {
  label: "Sample reviewed profile",
  summary: "Shared values - reviewed intent - private by default",
  reviewScore: "92%",
  image:
    "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=760&q=82",
  traits: ["Values-led", "Reviewed", "Private"],
};

const safetyLinks = [
  { label: "Community Guidelines", href: "/policy" },
  { label: "Safety Tips", href: "/safety" },
  { label: "Safety & Policy", href: "/safety#policy" },
  { label: "Safety & Reporting", href: "/safety#support" },
  { label: "Security", href: "/privacy" },
];

const footerColumns = [
  {
    title: "Yaro0",
    links: ["About", "Stories", "Safety", "Terms"],
  },
  {
    title: "Discover",
    links: ["Download", "Pricing", "Login"],
  },
  {
    title: "Safety",
    links: ["Safety", "Policy", "Privacy", "Terms"],
  },
  {
    title: "Connect",
    links: ["About", "Stories", "Download", "Pricing"],
  },
];

type FormStatus = "idle" | "submitting" | "success" | "error";
type ModalKind = "create-account" | "login";

export function SwipeExperience() {
  const [isMounted, setIsMounted] = useState(false);
  const [modalKind, setModalKind] = useState<ModalKind | null>(null);
  const [status, setStatus] = useState<FormStatus>("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const [loginStatus, setLoginStatus] = useState<FormStatus>("idle");
  const [loginMessage, setLoginMessage] = useState("");

  function openCreateAccountModal(event?: MouseEvent<HTMLButtonElement>) {
    event?.preventDefault();
    event?.stopPropagation();
    setStatus("idle");
    setErrorMessage("");
    setModalKind("create-account");
  }

  function openLoginModal(event?: MouseEvent<HTMLButtonElement>) {
    event?.preventDefault();
    event?.stopPropagation();
    setLoginStatus("idle");
    setLoginMessage("");
    setModalKind("login");
  }

  function closeModal() {
    setModalKind(null);

    if (window.location.hash === "#create-account" || window.location.hash === "#login") {
      window.history.replaceState(null, "", window.location.pathname);
    }
  }

  function getFooterHref(link: string) {
    if (link === "Create account") {
      return "#create-account";
    }

    if (link === "Login") {
      return "#login";
    }

    return `/${link.toLowerCase().replaceAll(" ", "-")}`;
  }

  useEffect(() => {
    setIsMounted(true);
  }, []);

  useEffect(() => {
    const openFromHash = () => {
      if (window.location.hash === "#create-account") {
        openCreateAccountModal();
      }

      if (window.location.hash === "#login") {
        openLoginModal();
      }
    };

    openFromHash();
    window.addEventListener("hashchange", openFromHash);

    return () => {
      window.removeEventListener("hashchange", openFromHash);
    };
  }, []);

  useEffect(() => {
    if (!modalKind) {
      return;
    }

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        closeModal();
      }
    };

    document.body.classList.add("modal-open");
    window.addEventListener("keydown", onKeyDown);

    return () => {
      document.body.classList.remove("modal-open");
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [modalKind]);

  async function handleCreateAccount(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus("submitting");
    setErrorMessage("");

    const form = event.currentTarget;
    const formData = new FormData(form);
    const password = String(formData.get("password") || "");
    const confirmPassword = String(formData.get("confirmPassword") || "");

    if (password !== confirmPassword) {
      setStatus("error");
      setErrorMessage("Passwords do not match.");
      return;
    }

    try {
      const response = await fetch("/api/auth/signup", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          firstName: formData.get("firstName"),
          lastName: formData.get("lastName"),
          email: formData.get("email"),
          password,
          dateOfBirth: formData.get("dateOfBirth"),
          gender: formData.get("gender"),
        }),
      });

      const payload = (await response.json()) as { message?: string };

      if (!response.ok) {
        throw new Error(payload.message || "Please check the form and try again.");
      }

      form.reset();
      setStatus("success");
      setErrorMessage(payload.message || "");
    } catch (error) {
      setStatus("error");
      setErrorMessage(
        error instanceof Error
          ? error.message
          : "Something went wrong. Please try again.",
      );
    }
  }

  async function handleLogin(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoginStatus("submitting");
    setLoginMessage("");

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
      const payload = (await response.json()) as { message?: string; redirectTo?: string };

      if (!response.ok) {
        throw new Error(payload.message || "Unable to log in.");
      }

      setLoginStatus("success");
      setLoginMessage(payload.message || "Login request accepted.");
      window.location.href = payload.redirectTo || "/onboarding";
    } catch (error) {
      setLoginStatus("error");
      setLoginMessage(error instanceof Error ? error.message : "Please try again.");
    }
  }

  const modal = modalKind ? (
    <div
      className="account-modal-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) {
          closeModal();
        }
      }}
    >
      <section
        className="account-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby={`${modalKind}-modal-title`}
      >
        <button
          className="modal-close"
          type="button"
          aria-label="Close modal"
          onClick={closeModal}
        >
          <X size={20} aria-hidden="true" />
        </button>

        {modalKind === "login" ? (
          <>
            <div className="modal-brand-mark" aria-hidden="true">
              <Heart size={30} fill="currentColor" />
            </div>
            <p className="modal-kicker">Welcome back</p>
            <h2 id="login-modal-title">Log in to Yaro0</h2>
            <p className="modal-copy">
              Continue to your conversations, profile review, and safer matches.
            </p>

            <div className="modal-socials">
              <a className="social-button google" href="/api/auth/google">
                <svg className="social-icon" viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                </svg>
                Continue with Google
              </a>
              <a className="social-button tiktok" href="/api/auth/tiktok">
                <TikTokIcon />
                Continue with TikTok
              </a>
            </div>

            <div className="auth-divider">or use email</div>

            <form className="account-form" onSubmit={handleLogin}>
              <label>
                Email address
                <input
                  name="email"
                  type="email"
                  autoComplete="email"
                  placeholder="email@example.com"
                  required
                />
              </label>
              <label>
                Password
                <PasswordField
                  name="password"
                  autoComplete="current-password"
                  placeholder="Your password"
                  required
                />
              </label>
              <div className="auth-row">
                <label className="check-label">
                  <input type="checkbox" name="remember" />
                  Remember me
                </label>
                <a href="/forgot-password">Forgot password?</a>
              </div>

              {loginMessage ? (
                <p
                  className={loginStatus === "error" ? "form-error" : "form-success"}
                  role="status"
                >
                  {loginStatus === "success" ? (
                    <CheckCircle2 size={18} aria-hidden="true" />
                  ) : null}
                  {loginMessage}
                </p>
              ) : null}

              <button
                className="primary-cta"
                type="submit"
                disabled={loginStatus === "submitting"}
              >
                {loginStatus === "submitting" ? (
                  <>
                    <Loader2 className="spin" size={18} aria-hidden="true" />
                    Logging in
                  </>
                ) : (
                  "Log in"
                )}
              </button>
            </form>
            <p className="auth-switch modal-switch">
              New to Yaro0?{" "}
              <button type="button" onClick={openCreateAccountModal}>
                Create account
              </button>
            </p>
          </>
        ) : status === "success" ? (
          <div className="modal-success">
            <CheckCircle2 size={44} aria-hidden="true" />
            <p className="modal-kicker">Account created</p>
            <h2 id="create-account-modal-title">Verify your email.</h2>
            <p>
              {errorMessage ||
                "We sent a verification link. Open it before logging in to your account."}
            </p>
            <button
              className="primary-cta"
              type="button"
              onClick={closeModal}
            >
              Done
            </button>
          </div>
        ) : (
          <>
            <div className="modal-brand-mark" aria-hidden="true">
              <Heart size={30} fill="currentColor" />
            </div>
            <p className="modal-kicker">Verified early access</p>
            <h2 id="create-account-modal-title">Create your Yaro0 profile</h2>
            <p className="modal-copy">
              Create your password now. You will need to verify your email before login.
            </p>
            <p className="modal-agreement">
              By continuing, you agree to our <a href="/terms">Terms</a>, Privacy,
              and safety review policy.
            </p>

            <form className="account-form" onSubmit={handleCreateAccount}>
              <label>
                First name
                <input
                  name="firstName"
                  type="text"
                  autoComplete="given-name"
                  placeholder="First name"
                  required
                />
              </label>
              <label>
                Last name
                <input
                  name="lastName"
                  type="text"
                  autoComplete="family-name"
                  placeholder="Last name"
                  required
                />
              </label>
              <label>
                Email address
                <input
                  name="email"
                  type="email"
                  autoComplete="email"
                  placeholder="email@example.com"
                  required
                />
              </label>
              <label>
                Date of birth
                <input name="dateOfBirth" type="date" required />
              </label>
              <label>
                Gender
                <select name="gender" defaultValue="" required>
                  <option value="" disabled>
                    Select gender
                  </option>
                  <option value="female">Female</option>
                  <option value="male">Male</option>
                  <option value="non_binary">Non-binary</option>
                  <option value="other">Other</option>
                </select>
              </label>
              <label>
                Password
                <PasswordField
                  name="password"
                  autoComplete="new-password"
                  placeholder="Strong password"
                  required
                />
              </label>
              <label>
                Confirm password
                <PasswordField
                  name="confirmPassword"
                  autoComplete="new-password"
                  placeholder="Repeat password"
                  required
                />
              </label>

              {status === "error" ? (
                <p className="form-error" role="alert">
                  {errorMessage}
                </p>
              ) : null}

              <button
                className="primary-cta"
                type="submit"
                disabled={status === "submitting"}
              >
                {status === "submitting" ? (
                  <>
                    <Loader2 className="spin" size={18} aria-hidden="true" />
                    Sending
                  </>
                ) : (
                  "Create account"
                )}
              </button>
            </form>
            <p className="auth-switch modal-switch">
              Already have an account?{" "}
              <button type="button" onClick={openLoginModal}>
                Log in
              </button>
            </p>
          </>
        )}
      </section>
    </div>
  ) : null;

  return (
    <>
      <main className="landing-shell">
        <section className="hero product-hero" aria-label="Yaro0 landing page">
          <div className="hero-overlay" />

          <header className="site-header">
            <a className="brand" href="/" aria-label="Yaro0 home">
              <BrandLogo />
            </a>

            <nav className="site-nav" aria-label="Primary navigation">
              <a href="/pricing">Products</a>
              <a href="/stories">Learn</a>
              <div className="nav-menu">
                <button type="button" aria-haspopup="true">
                  Safety
                  <ChevronDown size={18} aria-hidden="true" />
                </button>
                <div className="safety-menu" aria-label="Safety links">
                  {safetyLinks.map((item) => (
                    <a href={item.href} key={item.label}>
                      {item.label}
                    </a>
                  ))}
                </div>
              </div>
              <a href="/safety#support">Support</a>
              <a href="/download">Download</a>
            </nav>

            <div className="header-actions">
              <button className="language-button" type="button">
                <Globe2 size={18} aria-hidden="true" />
                Language
              </button>
              <button className="login-button" type="button" onClick={openLoginModal}>
                Log in
              </button>
            </div>

            <details className="mobile-nav">
              <summary aria-label="Open navigation">
                <Menu size={30} aria-hidden="true" />
              </summary>
              <nav className="mobile-nav-panel" aria-label="Mobile navigation">
                <a href="/pricing">Products</a>
                <a href="/stories">Learn</a>
                <a href="/safety">Safety</a>
                <a href="/safety#support">Support</a>
                <a href="/download">Download</a>
                <button type="button" onClick={openLoginModal}>
                  Log in
                </button>
              </nav>
            </details>
          </header>

          <div className="hero-product-grid">
            <div className="hero-content">
              <p className="hero-kicker">
                <ShieldCheck size={17} aria-hidden="true" />
                Reviewed profiles for serious Tamil connections
              </p>
              <h1>Meet with trust, not noise.</h1>
              <p className="hero-copy">
                Yaro0 is a private relationship app for Tamil singles and families
                who want verified profiles, clear intent, and safer conversations.
              </p>
              <div className="hero-buttons">
                <button
                  className="primary-cta"
                  type="button"
                  onClick={openCreateAccountModal}
                >
                  Request early access
                </button>
                <a className="secondary-cta hero-secondary" href="/safety">
                  <LockKeyhole size={18} aria-hidden="true" />
                  View safety standards
                </a>
              </div>
              <dl className="hero-metrics" aria-label="Yaro0 trust signals">
                <div>
                  <dt>3-step</dt>
                  <dd>profile review</dd>
                </div>
                <div>
                  <dt>24h</dt>
                  <dd>support response</dd>
                </div>
                <div>
                  <dt>Private</dt>
                  <dd>by default</dd>
                </div>
              </dl>
            </div>

            <aside className="product-preview" aria-label="Yaro0 app preview">
              <div className="preview-toolbar">
                <span>Profile review</span>
                <strong>{featuredProfile.reviewScore}</strong>
              </div>
              <div className="preview-profile">
                <img
                  src={featuredProfile.image}
                  alt="Sample reviewed Yaro0 profile preview"
                />
                <div>
                  <p>{featuredProfile.label}</p>
                  <span>{featuredProfile.summary}</span>
                  <ul className="preview-tags" aria-label="Profile highlights">
                    {featuredProfile.traits.map((trait) => (
                      <li key={trait}>{trait}</li>
                    ))}
                  </ul>
                </div>
              </div>
              <div className="preview-checklist">
                <div>
                  <UserCheck size={19} aria-hidden="true" />
                  Identity reviewed
                </div>
                <div>
                  <Heart size={19} aria-hidden="true" />
                  Intent selected
                </div>
                <div>
                  <MessageCircle size={19} aria-hidden="true" />
                  Conversation limits on
                </div>
              </div>
              <div className="preview-message">
                <span>Today</span>
                <p>Match suggested after shared values, city preference, and safety review.</p>
              </div>
            </aside>
          </div>

          <div className="neon-feature-row" id="how-it-works" aria-label="Yaro0 highlights">
            <article>
              <UserCheck size={28} aria-hidden="true" />
              <h2>Reviewed people</h2>
              <p>Identity, intent, and profile quality checks before discovery.</p>
            </article>
            <article>
              <Heart size={28} aria-hidden="true" />
              <h2>Better matches</h2>
              <p>Preferences, lifestyle, and values shape each introduction.</p>
            </article>
            <article>
              <ShieldCheck size={28} aria-hidden="true" />
              <h2>Safer dating</h2>
              <p>Reporting, privacy controls, and human support are built in.</p>
            </article>
          </div>
      </section>

      <footer className="site-footer">
        <div className="footer-inner">
          <section className="footer-brand" aria-label="Yaro0 footer">
            <a className="footer-logo" href="/" aria-label="Yaro0 home">
              <BrandLogo />
            </a>
            <p>
              A safer place for Tamil singles to meet with clarity, culture,
              and real intent.
            </p>
            <div className="footer-socials" aria-label="Social links">
              <a href="#instagram" aria-label="Instagram">
                In
              </a>
              <a href="#facebook" aria-label="Facebook">
                Fb
              </a>
              <a href="#twitter" aria-label="X">
                X
              </a>
            </div>
          </section>

          <nav className="footer-links" aria-label="Footer navigation">
            {footerColumns.map((column) => (
              <div key={column.title}>
                <h2>{column.title}</h2>
                {column.links.map((link) => (
                  <a href={getFooterHref(link)} key={link}>
                    {link}
                  </a>
                ))}
              </div>
            ))}
          </nav>

          <section className="download-panel" id="download" aria-label="Download Yaro0">
            <p className="footer-kicker">Start today</p>
            <h2>Find people who understand your world.</h2>
            <div className="store-buttons">
              <a href="/download#ios">
                <span>Download on the</span>
                App Store
              </a>
              <a href="/download#android">
                <span>Get it on</span>
                Google Play
              </a>
            </div>
          </section>
        </div>

        <div className="footer-bottom">
          <p>© 2026 Yaro0. All rights reserved.</p>
          <div>
            <a href="/terms">Terms</a>
            <a href="/privacy">Privacy</a>
            <a href="/policy">Policy</a>
          </div>
        </div>
      </footer>

      </main>
      {isMounted && modal ? createPortal(modal, document.body) : null}
    </>
  );
}
