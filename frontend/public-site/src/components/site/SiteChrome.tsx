import { ChevronDown, Globe2, Menu } from "lucide-react";
import { BrandLogo } from "./BrandLogo";

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
    links: [
      { label: "About", href: "/about" },
      { label: "Stories", href: "/stories" },
      { label: "Safety", href: "/safety" },
      { label: "Contact", href: "mailto:hello@yaro0.com" },
    ],
  },
  {
    title: "Discover",
    links: [
      { label: "App", href: "/download" },
      { label: "Pricing", href: "/pricing" },
      { label: "Download", href: "/download" }
      // { label: "Create account", href: "/#create-account" },
    ],
  },
  {
    title: "Legal",
    links: [
      { label: "Terms", href: "/terms" },
      { label: "Privacy", href: "/privacy" },
      { label: "Policy", href: "/policy" },
      { label: "Report concern", href: "/safety#support" },
    ],
  },
];

export function SiteHeader() {
  return (
    <header className="site-header page-header">
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
        <a className="login-button" href="/login">
          Log in
        </a>
        {/* <a className="signup-button" href="/#create-account">
          Create account
        </a> */}
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
          <a href="/login">Log in</a>
        </nav>
      </details>
    </header>
  );
}

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="footer-inner page-footer-inner">
        <section className="footer-brand" aria-label="Yaro0 footer">
      <a className="footer-logo" href="/" aria-label="Yaro0 home">
            <BrandLogo />
          </a>
          <p>
            A safer place for Tamil singles to meet with clarity, culture, and
            real intent.
          </p>
          <div className="footer-socials" aria-label="Social links">
            <a href="https://www.instagram.com" aria-label="Instagram">
              In
            </a>
            <a href="https://www.facebook.com" aria-label="Facebook">
              Fb
            </a>
            <a href="https://www.x.com" aria-label="X">
              X
            </a>
          </div>
        </section>

        <nav className="footer-links" aria-label="Footer navigation">
          {footerColumns.map((column) => (
            <div key={column.title}>
              <h2>{column.title}</h2>
              {column.links.map((link) => (
                <a href={link.href} key={link.label}>
                  {link.label}
                </a>
              ))}
            </div>
          ))}
        </nav>

        <section className="download-panel" aria-label="Download Yaro0">
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
  );
}

export function PageShell({ children }: { children: React.ReactNode }) {
  return (
    <main className="page-shell">
      <SiteHeader />
      {children}
      <SiteFooter />
    </main>
  );
}
