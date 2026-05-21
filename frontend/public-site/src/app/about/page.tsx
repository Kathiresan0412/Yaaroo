import { Heart, ShieldCheck, Users } from "lucide-react";
import type { Metadata } from "next";
import { PageShell } from "../../components/site/SiteChrome";

export const metadata: Metadata = {
  title: "About",
  description:
    "Yaaro0 helps Tamil singles meet across Sri Lanka and the diaspora with stronger privacy, cultural profile prompts, and safety tools.",
  alternates: { canonical: "/about" },
};

export default function AboutPage() {
  return (
    <PageShell>
      <section className="page-hero compact">
        <p className="hero-kicker">
          <Heart size={18} aria-hidden="true" />
          About Yaro0
        </p>
        <h1>Built for Tamil connection with care.</h1>
        <p>
          Yaro0 helps Tamil singles meet across Sri Lanka and the diaspora with
          clearer intent, stronger privacy, and culturally aware profiles.
        </p>
      </section>

      <section className="feature-grid">
        <article className="feature-panel">
          <Users size={28} aria-hidden="true" />
          <h2>Community first</h2>
          <p>Profiles are designed for dating, friendship, and matrimony needs.</p>
        </article>
        <article className="feature-panel">
          <ShieldCheck size={28} aria-hidden="true" />
          <h2>Safety by default</h2>
          <p>Verification, reporting, and visibility controls are central.</p>
        </article>
        <article className="feature-panel">
          <Heart size={28} aria-hidden="true" />
          <h2>Intent matters</h2>
          <p>Yaro0 focuses on respectful conversations that can go somewhere.</p>
        </article>
      </section>
    </PageShell>
  );
}
