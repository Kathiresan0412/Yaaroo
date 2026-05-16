import { Check, Sparkles } from "lucide-react";
import { PageShell } from "../../components/site/SiteChrome";

const plans = [
  {
    name: "Free",
    price: "$0",
    summary: "Start with verified browsing and basic matching.",
    features: ["Profile creation", "Basic discovery", "Safety reporting"],
  },
  {
    name: "Premium",
    price: "$9",
    summary: "More visibility and richer profile controls.",
    features: ["Priority profile review", "Advanced filters", "Read receipts"],
  },
  {
    name: "Intent",
    price: "$19",
    summary: "For serious dating and matrimony-style matching.",
    features: ["Jathagam-aware preferences", "Family-ready profile sections", "Concierge support"],
  },
];

export default function PricingPage() {
  return (
    <PageShell>
      <section className="page-hero compact">
        <p className="hero-kicker">
          <Sparkles size={18} aria-hidden="true" />
          Pricing
        </p>
        <h1>Simple plans for real intent.</h1>
        <p>Choose the level of visibility and support that matches your goal.</p>
      </section>

      <section className="pricing-grid">
        {plans.map((plan) => (
          <article className="price-card" key={plan.name}>
            <h2>{plan.name}</h2>
            <p className="price">{plan.price}<span>/month</span></p>
            <p>{plan.summary}</p>
            <ul>
              {plan.features.map((feature) => (
                <li key={feature}>
                  <Check size={17} aria-hidden="true" />
                  {feature}
                </li>
              ))}
            </ul>
            <a className={plan.name === "Free" ? "secondary-cta" : "primary-cta"} href="/signup">
              Choose {plan.name}
            </a>
          </article>
        ))}
      </section>
    </PageShell>
  );
}
