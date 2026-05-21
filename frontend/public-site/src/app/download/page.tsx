import { Apple, Play, QrCode, ShieldCheck, Smartphone } from "lucide-react";
import { PageShell } from "../../components/site/SiteChrome";

export default function DownloadPage() {
  return (
    <PageShell>
      <section className="page-hero compact">
        <p className="hero-kicker">
          <Smartphone size={18} aria-hidden="true" />
          Yaro0 mobile app
        </p>
        <h1>Download Yaro0</h1>
        <p>
          Meet verified Tamil singles with privacy controls, profile checks,
          and intent-first matching on iOS and Android.
        </p>
      </section>

      <section className="feature-grid download-grid">
        <article className="feature-panel" id="ios">
          <Apple size={28} aria-hidden="true" />
          <h2>App Store</h2>
          <p>Install Yaro0 for iPhone and get early access updates.</p>
          <a className="primary-cta" href="#app-store">
            Download for iOS
          </a>
        </article>
        <article className="feature-panel" id="android">
          <Play size={28} aria-hidden="true" />
          <h2>Google Play</h2>
          <p>Install Yaro0 for Android and keep profile verification moving.</p>
          <a className="primary-cta" href="#google-play">
            Download for Android
          </a>
        </article>
        <article className="feature-panel">
          <QrCode size={28} aria-hidden="true" />
          <h2>Invite code</h2>
          <p>Use an invite code from the team to unlock early profile review.</p>
          <a className="secondary-cta" href="/#create-account">
            Request access
          </a>
        </article>
        <article className="feature-panel">
          <ShieldCheck size={28} aria-hidden="true" />
          <h2>Safe setup</h2>
          <p>Set privacy, discovery, and notification controls before matching.</p>
          <a className="secondary-cta" href="/safety">
            Safety tools
          </a>
        </article>
      </section>
    </PageShell>
  );
}
