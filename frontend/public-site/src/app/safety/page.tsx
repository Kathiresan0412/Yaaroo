import { LockKeyhole, MessageCircleWarning, ShieldCheck, UserCheck } from "lucide-react";
import { PageShell } from "../../components/site/SiteChrome";

export default function SafetyPage() {
  return (
    <PageShell>
      <section className="page-hero compact">
        <p className="hero-kicker">
          <ShieldCheck size={18} aria-hidden="true" />
          Safety centre
        </p>
        <h1>Meet with more control.</h1>
        <p>
          Yaro0 combines verification, privacy settings, and human support so
          members can connect with more confidence.
        </p>
      </section>

      <section className="feature-grid">
        <article className="feature-panel" id="verified">
          <UserCheck size={28} aria-hidden="true" />
          <h2>Verified profiles</h2>
          <p>Identity and profile-quality checks help reduce fake accounts.</p>
        </article>
        <article className="feature-panel" id="women-safe">
          <LockKeyhole size={28} aria-hidden="true" />
          <h2>Women-safe controls</h2>
          <p>Control who can message, view, and discover your profile.</p>
        </article>
        <article className="feature-panel" id="support">
          <MessageCircleWarning size={28} aria-hidden="true" />
          <h2>Report and support</h2>
          <p>Flag concerns quickly and reach the Yaro0 support team.</p>
        </article>
      </section>
    </PageShell>
  );
}
