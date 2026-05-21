import { PageShell } from "../../components/site/SiteChrome";

export default function PrivacyPage() {
  return (
    <PageShell>
      <article className="legal-page">
        <p className="modal-kicker">Privacy</p>
        <h1>Privacy Policy</h1>
        <p>Last updated: May 16, 2026</p>
        <h2>Information we collect</h2>
        <p>
          We collect account details, profile content, preferences, app activity,
          and safety reports needed to operate Yaro0.
        </p>
        <h2>How we use information</h2>
        <p>
          We use information for matching, verification, safety moderation,
          customer support, analytics, and product improvement.
        </p>
        <h2>Your controls</h2>
        <p>
          You can manage profile visibility, communication preferences, and
          account deletion through app settings or support.
        </p>
      </article>
    </PageShell>
  );
}
