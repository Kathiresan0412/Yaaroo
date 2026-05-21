import { PageShell } from "../../components/site/SiteChrome";

export default function TermsPage() {
  return (
    <PageShell>
      <article className="legal-page">
        <p className="modal-kicker">Legal</p>
        <h1>Terms of Service</h1>
        <p>Last updated: May 16, 2026</p>
        <h2>Using Yaro0</h2>
        <p>
          You must provide accurate account information, use Yaro0 respectfully,
          and follow community safety rules.
        </p>
        <h2>Accounts</h2>
        <p>
          We may review, limit, suspend, or remove accounts that create safety,
          fraud, harassment, or policy risks.
        </p>
        <h2>Subscriptions</h2>
        <p>
          Paid features may renew unless cancelled through the relevant app
          store or payment provider.
        </p>
      </article>
    </PageShell>
  );
}
