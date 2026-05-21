import { MessageCircleHeart, Sparkles, Users } from "lucide-react";
import { PageShell } from "../../components/site/SiteChrome";

const stories = [
  "Met through a verified profile and started with family values upfront.",
  "Found friends in a new city before deciding to date seriously.",
  "Used privacy controls to move slowly and comfortably.",
];

export default function StoriesPage() {
  return (
    <PageShell>
      <section className="page-hero compact">
        <p className="hero-kicker">
          <Sparkles size={18} aria-hidden="true" />
          Stories
        </p>
        <h1>Real connection starts with trust.</h1>
        <p>Early Yaro0 stories from Tamil singles across Sri Lanka and abroad.</p>
      </section>

      <section className="feature-grid">
        {stories.map((story, index) => (
          <article className="feature-panel" key={story}>
            {index === 0 ? (
              <MessageCircleHeart size={28} aria-hidden="true" />
            ) : (
              <Users size={28} aria-hidden="true" />
            )}
            <h2>Story {index + 1}</h2>
            <p>{story}</p>
          </article>
        ))}
      </section>
    </PageShell>
  );
}
