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

    try {
      const response = await fetch("/api/create-account", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          name: formData.get("name"),
          email: formData.get("email"),
          city: formData.get("city"),
          intent: formData.get("intent"),
        }),
      });

      const payload = (await response.json()) as { message?: string };

      if (!response.ok) {
        throw new Error(payload.message || "Please check the form and try again.");
      }

      form.reset();
      setStatus("success");
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
      const payload = (await response.json()) as { message?: string };

      if (!response.ok) {
        throw new Error(payload.message || "Unable to log in.");
      }

      setLoginStatus("success");
      setLoginMessage(payload.message || "Login request accepted.");
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
                <span aria-hidden="true">G</span>
                Continue with Google
              </a>
              <a className="social-button tiktok" href="/api/auth/tiktok">
                <span aria-hidden="true">T</span>
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
                <input
                  name="password"
                  type="password"
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
            <p className="modal-kicker">Request received</p>
            <h2 id="create-account-modal-title">We will invite you soon.</h2>
            <p>
              Thanks for joining early access. The Yaro0 team will send the next
              step once your profile request is reviewed.
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
              Start with a reviewed profile request for Tamil dating,
              friendship, or matrimony.
            </p>
            <p className="modal-agreement">
              By continuing, you agree to our <a href="/terms">Terms</a>, Privacy,
              and safety review policy.
            </p>

            <form className="account-form" onSubmit={handleCreateAccount}>
              <label>
                Full name
                <input
                  name="name"
                  type="text"
                  autoComplete="name"
                  placeholder="Your full name"
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
                City
                <input
                  name="city"
                  type="text"
                  autoComplete="address-level2"
                  placeholder="Colombo, Toronto, London"
                  required
                />
              </label>
              <label>
                Looking for
                <select name="intent" defaultValue="dating" required>
                  <option value="dating">Dating</option>
                  <option value="friendship">Friendship</option>
                  <option value="matrimony">Matrimony</option>
                </select>
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
                  "Request account"
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
