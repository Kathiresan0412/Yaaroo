"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useMemo, useState } from "react";
import { ArrowLeft, Clock3, Heart, Loader2, MapPin, Sparkles, X } from "lucide-react";
import { ProtectedRoute } from "../auth/ProtectedRoute";
import { useAuth } from "../auth/AuthProvider";

type ExploreCategory = {
  key: string;
  label: string;
  emoji: string;
  hobbies: string[];
  count: number;
};

type ExploreCard = {
  id: string;
  displayName: string;
  age: number;
  distanceKm: number | null;
  headline: string;
  mainPhotoUrl: string | null;
  city: string | null;
  country: string | null;
  isVerified: boolean;
  sharedInterests: string[];
  compatibilityScore: number;
  profile: {
    bio: string | null;
    relationshipGoal: string | null;
    loveLanguage: string | null;
    interests: {
      hobbies: string[];
      favFood: string[];
      favMusic: string[];
      favMovieGenre: string[];
    };
  };
};

type VibeQuestion = {
  id: string;
  prompt: string;
  answers: string[];
};

const goalFilters = ["Long-term", "Casual", "Friends", "Not sure"];

function parsePayload<T>(response: Response) {
  return response.json() as Promise<T & { success?: boolean; message?: string }>;
}

function formatDistance(distanceKm: number | null) {
  if (distanceKm === null) {
    return "Nearby";
  }

  return distanceKm <= 2 ? "Within 2 km" : `${distanceKm} km away`;
}

function ExploreCardTile({
  card,
  onDecision,
}: {
  card: ExploreCard;
  onDecision: (card: ExploreCard, action: "like" | "pass") => void;
}) {
  const tags = [...card.sharedInterests, card.profile.relationshipGoal].filter(Boolean).slice(0, 2);

  return (
    <article className="explore-person-card">
      <div className="explore-person-photo">
        {card.mainPhotoUrl ? <img src={card.mainPhotoUrl} alt="" /> : <div className="explore-photo-fallback" />}
        <span>{card.compatibilityScore}%</span>
      </div>
      <div className="explore-person-body">
        <div>
          <h3>
            {card.displayName}, {card.age}
          </h3>
          <p>{card.headline || formatDistance(card.distanceKm)}</p>
        </div>
        <div className="explore-tags">
          {tags.length > 0 ? tags.map((tag) => <span key={tag}>{tag}</span>) : <span>New nearby</span>}
        </div>
        <div className="explore-card-actions">
          <button type="button" onClick={() => onDecision(card, "pass")} aria-label={`Pass on ${card.displayName}`}>
            <X size={18} aria-hidden="true" />
          </button>
          <button type="button" onClick={() => onDecision(card, "like")} aria-label={`Like ${card.displayName}`}>
            <Heart size={18} aria-hidden="true" />
          </button>
        </div>
      </div>
    </article>
  );
}

function ExploreExperienceContent() {
  const { authFetch } = useAuth();
  const params = useParams<{ category?: string }>();
  const categoryFromRoute = typeof params.category === "string" ? decodeURIComponent(params.category) : "";
  const [categories, setCategories] = useState<ExploreCategory[]>([]);
  const [cards, setCards] = useState<ExploreCard[]>([]);
  const [vibeCards, setVibeCards] = useState<ExploreCard[]>([]);
  const [vibeQuestion, setVibeQuestion] = useState<VibeQuestion | null>(null);
  const [vibeAnswer, setVibeAnswer] = useState<string | null>(null);
  const [activeGoal, setActiveGoal] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [isCardsLoading, setIsCardsLoading] = useState(false);
  const [message, setMessage] = useState("");

  const selectedCategory = useMemo(
    () => categories.find((category) => category.key === categoryFromRoute),
    [categories, categoryFromRoute],
  );

  const loadCategories = useCallback(async () => {
    const response = await authFetch("/api/explore/categories");
    const payload = await parsePayload<{ categories?: ExploreCategory[] }>(response);

    if (!response.ok) {
      throw new Error(payload.message || "Explore categories are unavailable.");
    }

    setCategories(payload.categories || []);
  }, [authFetch]);

  const loadVibes = useCallback(async () => {
    const response = await authFetch("/api/explore/vibes/today");
    const payload = await parsePayload<{ question?: VibeQuestion; answer?: string | null }>(response);

    if (!response.ok) {
      throw new Error(payload.message || "Vibes are unavailable.");
    }

    setVibeQuestion(payload.question || null);
    setVibeAnswer(payload.answer || null);
  }, [authFetch]);

  const loadCards = useCallback(
    async (path: string) => {
      setIsCardsLoading(true);
      setMessage("");

      try {
        const response = await authFetch(path);
        const payload = await parsePayload<{ cards?: ExploreCard[] }>(response);

        if (!response.ok) {
          throw new Error(payload.message || "No profiles found for this filter.");
        }

        setCards(payload.cards || []);
      } catch (error) {
        setCards([]);
        setMessage(error instanceof Error ? error.message : "Explore is unavailable.");
      } finally {
        setIsCardsLoading(false);
      }
    },
    [authFetch],
  );

  useEffect(() => {
    Promise.all([loadCategories(), loadVibes()])
      .catch((error) => setMessage(error instanceof Error ? error.message : "Explore is unavailable."))
      .finally(() => setIsLoading(false));
  }, [loadCategories, loadVibes]);

  useEffect(() => {
    if (categoryFromRoute) {
      loadCards(`/api/explore/by-interest/${encodeURIComponent(categoryFromRoute)}`);
    } else {
      loadCards("/api/explore/nearby");
    }
  }, [categoryFromRoute, loadCards]);

  async function chooseGoal(goal: string) {
    setActiveGoal(goal);
    await loadCards(`/api/explore/by-goal/${encodeURIComponent(goal)}`);
  }

  async function respondToVibe(answer: string) {
    setMessage("");

    try {
      const response = await authFetch("/api/explore/vibes/respond", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ answer }),
      });
      const payload = await parsePayload<{ cards?: ExploreCard[]; answer?: string }>(response);

      if (!response.ok) {
        throw new Error(payload.message || "Unable to save your vibe.");
      }

      setVibeAnswer(payload.answer || answer);
      setVibeCards(payload.cards || []);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Unable to save your vibe.");
    }
  }

  async function decide(card: ExploreCard, action: "like" | "pass") {
    setCards((currentCards) => currentCards.filter((item) => item.id !== card.id));
    setVibeCards((currentCards) => currentCards.filter((item) => item.id !== card.id));

    try {
      const response = await authFetch("/api/swipe", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ target_user_id: card.id, action }),
      });
      const payload = await parsePayload<{ matched?: boolean }>(response);

      if (!response.ok) {
        throw new Error(payload.message || "Action failed.");
      }

      if (payload.matched) {
        setMessage(`It's a match with ${card.displayName}.`);
      }
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Action failed.");
    }
  }

  if (isLoading) {
    return (
      <main className="explore-page">
        <Loader2 className="spin" size={30} aria-hidden="true" />
      </main>
    );
  }

  return (
    <main className="explore-page">
      <section className="explore-hero">
        <div>
          {categoryFromRoute ? (
            <Link className="explore-back" href="/app/explore">
              <ArrowLeft size={18} aria-hidden="true" />
              Explore
            </Link>
          ) : (
            <span className="explore-kicker">Explore</span>
          )}
          <h1>{selectedCategory ? selectedCategory.label : "Find people by what you both love"}</h1>
          <p>Browse shared interests, intent, nearby profiles, daily Vibes, and quick Hot Takes.</p>
        </div>
      </section>

      {message ? <p className="explore-message">{message}</p> : null}

      {!categoryFromRoute ? (
        <section className="explore-section">
          <div className="explore-section-title">
            <h2>By interest</h2>
            <MapPin size={18} aria-hidden="true" />
          </div>
          <div className="explore-category-grid">
            {categories.map((category) => (
              <Link className="explore-category-tile" href={`/app/explore/${category.key}`} key={category.key}>
                <span>{category.emoji}</span>
                <strong>{category.label}</strong>
                <small>{category.count} people</small>
              </Link>
            ))}
          </div>
        </section>
      ) : null}

      <section className="explore-section">
        <div className="explore-section-title">
          <h2>{categoryFromRoute ? "People in this interest" : "Nearby picks"}</h2>
          {isCardsLoading ? <Loader2 className="spin" size={18} aria-hidden="true" /> : null}
        </div>
        <div className="goal-chip-row" aria-label="Relationship goal filters">
          {goalFilters.map((goal) => (
            <button
              className={activeGoal === goal ? "active" : ""}
              key={goal}
              type="button"
              onClick={() => chooseGoal(goal)}
            >
              {goal}
            </button>
          ))}
        </div>
        <div className="explore-people-grid">
          {cards.map((card) => (
            <ExploreCardTile card={card} key={card.id} onDecision={decide} />
          ))}
        </div>
        {!isCardsLoading && cards.length === 0 ? <p className="explore-empty">No profiles in this lane yet.</p> : null}
      </section>

      <section className="explore-section explore-vibes">
        <div className="explore-section-title">
          <h2>Vibes</h2>
          <Sparkles size={18} aria-hidden="true" />
        </div>
        {vibeQuestion ? (
          <>
            <p>{vibeQuestion.prompt}</p>
            <div className="vibe-answer-row">
              {vibeQuestion.answers.map((answer) => (
                <button
                  className={vibeAnswer === answer ? "active" : ""}
                  key={answer}
                  type="button"
                  onClick={() => respondToVibe(answer)}
                >
                  {answer}
                </button>
              ))}
            </div>
          </>
        ) : null}
        {vibeCards.length > 0 ? (
          <div className="explore-people-grid compact">
            {vibeCards.map((card) => (
              <ExploreCardTile card={card} key={card.id} onDecision={decide} />
            ))}
          </div>
        ) : vibeAnswer ? (
          <p className="explore-empty">Your answer is saved. Matching Vibes will appear here as more people answer.</p>
        ) : null}
      </section>

      <section className="explore-section hot-takes">
        <div className="explore-section-title">
          <h2>Hot Takes</h2>
          <Clock3 size={18} aria-hidden="true" />
        </div>
        <p>30-second text dates are warming up. This speed chat lane is coming soon.</p>
      </section>
    </main>
  );
}

export function ExploreExperience() {
  return (
    <ProtectedRoute>
      <ExploreExperienceContent />
    </ProtectedRoute>
  );
}
