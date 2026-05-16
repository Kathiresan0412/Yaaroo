"use client";

import { FormEvent, useEffect, useState } from "react";
import {
  ChevronDown,
  CheckCircle2,
  Globe2,
  Heart,
  Loader2,
  LockKeyhole,
  MessageCircle,
  ShieldCheck,
  Sparkles,
  UserCheck,
  X,
} from "lucide-react";

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

const safetyLinks = [
  "Verified profiles",
  "Women-safe controls",
  "Report & support",
  "Privacy promise",
];

const footerColumns = [
  {
    title: "Yaro0",
    links: ["About", "Stories", "Safety", "Terms"],
  },
  {
    title: "Discover",
    links: ["Download", "Pricing", "Login", "Signup"],
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

export function SwipeExperience() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [status, setStatus] = useState<FormStatus>("idle");
  const [errorMessage, setErrorMessage] = useState("");

  useEffect(() => {
    if (!isModalOpen) {
      return;
    }

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setIsModalOpen(false);
      }
    };

    document.body.classList.add("modal-open");
    window.addEventListener("keydown", onKeyDown);

    return () => {
      document.body.classList.remove("modal-open");
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [isModalOpen]);

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

  return (
    <main className="landing-shell">
      <section className="hero" aria-label="Yaro0 landing page">
        <div className="profile-collage" aria-hidden="true">
          {profileCards.map((card) => (
            <article className={`phone-card ${card.className}`} key={card.name}>
              <img src={card.image} alt="" />
              <div className="phone-shade" />
              <div className="profile-meta">
                <strong>
                  {card.name}, {card.age}
                </strong>
                <span>{card.city}</span>
              </div>
              <div className="card-actions">
                <span>
                  <MessageCircle size={14} />
                </span>
                <span>
                  <Heart size={15} />
                </span>
                <span>
                  <Sparkles size={14} />
                </span>
              </div>
            </article>
          ))}
        </div>

        <div className="hero-overlay" />

        <header className="site-header">
          <a className="brand" href="/" aria-label="Yaro0 home">
            <span className="brand-flame">
              <Heart size={24} fill="currentColor" />
            </span>
            Yaro0
          </a>

          <nav className="site-nav" aria-label="Primary navigation">
            <a href="/download">App</a>
            <a href="/stories">Stories</a>
            <div className="nav-menu">
              <button type="button" aria-haspopup="true">
                Safety
                <ChevronDown size={18} aria-hidden="true" />
              </button>
              <div className="safety-menu" aria-label="Safety links">
                {safetyLinks.map((item) => (
                  <a href="/safety" key={item}>
                    {item}
                  </a>
                ))}
              </div>
            </div>
            <a href="/pricing">Pricing</a>
            <a href="/download">Download</a>
          </nav>

          <div className="header-actions">
            <button className="language-button" type="button">
              <Globe2 size={18} aria-hidden="true" />
              Language
            </button>
            <a className="login-button" href="/login">
              Log in
            </a>
          </div>
        </header>

        <div className="hero-content">
          <p className="hero-kicker">
            <ShieldCheck size={18} aria-hidden="true" />
            Tamil dating, friendship, and matrimony
          </p>
          <h1>Meet with intention.</h1>
          <p className="hero-copy">
            Discover verified Tamil singles across Sri Lanka and the diaspora,
            with safer matching, richer profiles, and conversations that can
            actually go somewhere.
          </p>
          <div className="hero-buttons">
            <button
              className="primary-cta"
              type="button"
              onClick={() => {
                setStatus("idle");
                setErrorMessage("");
                setIsModalOpen(true);
              }}
            >
              Create account
            </button>
            <a className="secondary-cta" href="/safety">
              <LockKeyhole size={18} aria-hidden="true" />
              See safety tools
            </a>
          </div>
        </div>

        <div className="trust-strip" aria-label="Yaro0 highlights">
          <div>
            <UserCheck size={20} aria-hidden="true" />
            <span>Profile checks</span>
          </div>
          <div>
            <ShieldCheck size={20} aria-hidden="true" />
            <span>Women-safe mode</span>
          </div>
          <div>
            <Sparkles size={20} aria-hidden="true" />
            <span>Jathagam-aware matching</span>
          </div>
        </div>
      </section>

      <footer className="site-footer">
        <div className="footer-inner">
          <section className="footer-brand" aria-label="Yaro0 footer">
            <a className="footer-logo" href="/" aria-label="Yaro0 home">
              <span className="brand-flame">
                <Heart size={24} fill="currentColor" />
              </span>
              Yaro0
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
                  <a href={`/${link.toLowerCase().replaceAll(" ", "-")}`} key={link}>
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

      {isModalOpen ? (
        <div
          className="account-modal-backdrop"
          role="presentation"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) {
              setIsModalOpen(false);
            }
          }}
        >
          <section
            className="account-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="account-modal-title"
          >
            <button
              className="modal-close"
              type="button"
              aria-label="Close create account modal"
              onClick={() => setIsModalOpen(false)}
            >
              <X size={20} aria-hidden="true" />
            </button>

            {status === "success" ? (
              <div className="modal-success">
                <CheckCircle2 size={44} aria-hidden="true" />
                <p className="modal-kicker">Request received</p>
                <h2 id="account-modal-title">We will invite you soon.</h2>
                <p>
                  Thanks for joining early access. The Yaro0 team will send the
                  next step once your profile request is reviewed.
                </p>
                <button
                  className="primary-cta"
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                >
                  Done
                </button>
              </div>
            ) : (
              <>
                <p className="modal-kicker">Early access</p>
                <h2 id="account-modal-title">Create your Yaro0 profile</h2>
                <p className="modal-copy">
                  Share the basics and we will start your verified account
                  request.
                </p>

                <form className="account-form" onSubmit={handleCreateAccount}>
                  <label>
                    Full name
                    <input name="name" type="text" autoComplete="name" required />
                  </label>
                  <label>
                    Email address
                    <input name="email" type="email" autoComplete="email" required />
                  </label>
                  <label>
                    City
                    <input name="city" type="text" autoComplete="address-level2" required />
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
              </>
            )}
          </section>
        </div>
      ) : null}
    </main>
  );
}
