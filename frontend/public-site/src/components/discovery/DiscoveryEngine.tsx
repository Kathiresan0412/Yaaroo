"use client";

import { PointerEvent, useCallback, useEffect, useMemo, useState } from "react";
import {
  ChevronDown,
  Heart,
  Loader2,
  RefreshCw,
  RotateCcw,
  Send,
  Star,
  X,
  Zap,
} from "lucide-react";
import { ProtectedRoute } from "../auth/ProtectedRoute";
import { useAuth } from "../auth/AuthProvider";

type SwipeAction = "like" | "pass" | "superlike";

type DiscoveryCard = {
  id: string;
  displayName: string;
  age: number;
  distanceKm: number | null;
  headline: string;
  mainPhotoUrl: string | null;
  photos: { id: string; url: string; isPrimary: boolean }[];
  city: string | null;
  country: string | null;
  isVerified: boolean;
  sharedInterests: string[];
  compatibilityScore: number;
  profile: {
    bio: string | null;
    pronouns: string | null;
    heightCm: number | null;
    relationshipGoal: string | null;
    loveLanguage: string | null;
    lifestyle: Record<string, string | null>;
    interests: {
      hobbies: string[];
      favFood: string[];
      favMusic: string[];
      favMovieGenre: string[];
      favColour: string | null;
      favPet: string | null;
    };
  };
};

type Limits = {
  likesRemaining: number;
  superLikesRemaining: number;
  likeLimit: number;
  superLikeLimit: number;
  likeResetAt: string;
  superLikeResetAt: string;
};

type DragState = {
  active: boolean;
  startX: number;
  startY: number;
  x: number;
  y: number;
};

const emptyDrag: DragState = { active: false, startX: 0, startY: 0, x: 0, y: 0 };

function parsePayload<T>(response: Response) {
  return response.json() as Promise<T & { success?: boolean; message?: string }>;
}

function formatDistance(distanceKm: number | null) {
  if (distanceKm === null) {
    return "Nearby";
  }

  return `${distanceKm} km away`;
}

function actionFromDrag(x: number, y: number): SwipeAction | null {
  if (y < -110 && Math.abs(y) > Math.abs(x)) {
    return "superlike";
  }

  if (x > 110) {
    return "like";
  }

  if (x < -110) {
    return "pass";
  }

  return null;
}

function profileRows(card: DiscoveryCard) {
  return [
    ["Intent", card.profile.relationshipGoal],
    ["Love language", card.profile.loveLanguage],
    ["Height", card.profile.heightCm ? `${card.profile.heightCm} cm` : null],
    ["Exercise", card.profile.lifestyle.exercise],
    ["Diet", card.profile.lifestyle.diet],
    ["Smoking", card.profile.lifestyle.smoking],
    ["Drinking", card.profile.lifestyle.drinking],
  ].filter((row): row is [string, string] => Boolean(row[1]));
}

function DiscoveryEngineContent() {
  const { authFetch, user } = useAuth();
  const [cards, setCards] = useState<DiscoveryCard[]>([]);
  const [limits, setLimits] = useState<Limits | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSwiping, setIsSwiping] = useState(false);
  const [message, setMessage] = useState("");
  const [drag, setDrag] = useState<DragState>(emptyDrag);
  const [expandedCard, setExpandedCard] = useState<DiscoveryCard | null>(null);
  const [matchedCard, setMatchedCard] = useState<DiscoveryCard | null>(null);

  const topCard = cards[0] ?? null;
  const projectedAction = actionFromDrag(drag.x, drag.y);

  const loadCards = useCallback(async () => {
    setIsLoading(true);
    setMessage("");

    try {
      const response = await authFetch("/api/discover");
      const payload = await parsePayload<{ cards?: DiscoveryCard[]; limits?: Limits }>(response);

      if (!response.ok) {
        throw new Error(payload.message || "Unable to load discovery cards.");
      }

      setCards(payload.cards || []);
      setLimits(payload.limits || null);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Discovery is unavailable.");
    } finally {
      setIsLoading(false);
    }
  }, [authFetch]);

  useEffect(() => {
    loadCards();
  }, [loadCards]);

  const commitSwipe = useCallback(
    async (action: SwipeAction) => {
      if (!topCard || isSwiping) {
        return;
      }

      const swipedCard = topCard;
      setIsSwiping(true);
      setMessage("");
      setCards((currentCards) => currentCards.slice(1));
      setDrag(emptyDrag);

      try {
        const response = await authFetch("/api/swipe", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ target_user_id: swipedCard.id, action }),
        });
        const payload = await parsePayload<{
          matched?: boolean;
          matchId?: string | null;
          limits?: Limits;
          limitReached?: boolean;
          resetAt?: string;
        }>(response);

        if (!response.ok) {
          setCards((currentCards) => [swipedCard, ...currentCards]);

          if (payload.limitReached) {
            setMessage(payload.message || "Limit reached. Upgrade to keep swiping.");
            return;
          }

          throw new Error(payload.message || "Swipe failed.");
        }

        if (payload.limits) {
          setLimits(payload.limits);
        }

        if (payload.matched) {
          setMatchedCard(swipedCard);
        }
      } catch (error) {
        setMessage(error instanceof Error ? error.message : "Swipe failed.");
      } finally {
        setIsSwiping(false);
      }
    },
    [authFetch, isSwiping, topCard],
  );

  async function undoSwipe() {
    setMessage("");

    try {
      const response = await authFetch("/api/swipe/undo", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: "{}",
      });
      const payload = await parsePayload<{ limits?: Limits; upgradeRequired?: boolean }>(response);

      if (!response.ok) {
        throw new Error(payload.message || "Undo is unavailable.");
      }

      if (payload.limits) {
        setLimits(payload.limits);
      }

      await loadCards();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Undo is unavailable.");
    }
  }

  function onPointerDown(event: PointerEvent<HTMLDivElement>) {
    if (!topCard || isSwiping) {
      return;
    }

    event.currentTarget.setPointerCapture(event.pointerId);
    setDrag({
      active: true,
      startX: event.clientX,
      startY: event.clientY,
      x: 0,
      y: 0,
    });
  }

  function onPointerMove(event: PointerEvent<HTMLDivElement>) {
    if (!drag.active) {
      return;
    }

    setDrag((current) => ({
      ...current,
      x: event.clientX - current.startX,
      y: event.clientY - current.startY,
    }));
  }

  function onPointerUp() {
    if (!drag.active) {
      return;
    }

    const action = actionFromDrag(drag.x, drag.y);
    if (action) {
      commitSwipe(action);
      return;
    }

    setDrag(emptyDrag);
  }

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (expandedCard || matchedCard) {
        return;
      }

      if (event.key === "ArrowLeft") {
        commitSwipe("pass");
      }

      if (event.key === "ArrowRight") {
        commitSwipe("like");
      }

      if (event.key === "ArrowUp") {
        commitSwipe("superlike");
      }

      if (event.key.toLowerCase() === "u") {
        undoSwipe();
      }
    };

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [commitSwipe, expandedCard, matchedCard]);

  const likeWarning = useMemo(() => {
    if (!limits) {
      return "";
    }

    if (limits.likesRemaining === 0) {
      return "No likes remaining. Upgrade to keep swiping.";
    }

    if (limits.likesRemaining < 5) {
      return `${limits.likesRemaining} likes left in this window.`;
    }

    return "";
  }, [limits]);

  return (
    <main className="discover-page">
      <section className="discover-shell" aria-label="Discovery">
        <div className="discover-topbar">
          <div>
            <span>Yaaro0</span>
            <strong>Discover</strong>
          </div>
          <div className="discover-meter" aria-live="polite">
            <Heart size={16} />
            {limits ? `${limits.likesRemaining}/${limits.likeLimit}` : "--"}
          </div>
        </div>

        <div className="discover-stage">
          {isLoading ? (
            <div className="discover-empty">
              <Loader2 className="spin" size={34} />
            </div>
          ) : cards.length === 0 ? (
            <div className="discover-empty">
              <Zap size={38} />
              <h1>You&apos;ve seen everyone nearby.</h1>
              <p>Try expanding your distance!</p>
              <button type="button" onClick={loadCards}>
                <RefreshCw size={18} />
                Refresh
              </button>
            </div>
          ) : (
            <div className="card-stack">
              {cards.slice(0, 3).map((card, index) => {
                const isTop = index === 0;
                const style = isTop
                  ? {
                      transform: `translate3d(${drag.x}px, ${drag.y}px, 0) rotate(${drag.x / 18}deg)`,
                    }
                  : {
                      transform: `translateY(${index * 12}px) scale(${1 - index * 0.045})`,
                    };

                return (
                  <article
                    className={`discover-card ${isTop ? "top" : ""}`}
                    key={card.id}
                    onPointerDown={isTop ? onPointerDown : undefined}
                    onPointerMove={isTop ? onPointerMove : undefined}
                    onPointerUp={isTop ? onPointerUp : undefined}
                    onPointerCancel={isTop ? onPointerUp : undefined}
                    style={{ zIndex: 10 - index, ...style }}
                  >
                    {card.mainPhotoUrl ? (
                      <img src={card.mainPhotoUrl} alt="" draggable={false} />
                    ) : (
                      <div className="discover-photo-fallback" />
                    )}
                    {projectedAction && isTop ? (
                      <div className={`swipe-stamp ${projectedAction}`}>
                        {projectedAction === "pass" ? (
                          <X size={52} />
                        ) : projectedAction === "like" ? (
                          <Heart size={52} />
                        ) : (
                          <Star size={52} />
                        )}
                      </div>
                    ) : null}
                    <button
                      aria-label={`View ${card.displayName}'s full profile`}
                      className="card-expand"
                      type="button"
                      onClick={() => setExpandedCard(card)}
                    >
                      <ChevronDown size={22} />
                    </button>
                    <div className="card-info">
                      <div className="match-chip">{card.compatibilityScore}%</div>
                      <h1>
                        {card.displayName}, {card.age}
                      </h1>
                      <p>{formatDistance(card.distanceKm)}</p>
                      {card.headline ? <strong>{card.headline}</strong> : null}
                      <div className="shared-row">
                        {card.sharedInterests.length > 0
                          ? card.sharedInterests.map((interest) => <span key={interest}>{interest}</span>)
                          : [card.city, card.country].filter(Boolean).map((place) => <span key={place}>{place}</span>)}
                      </div>
                    </div>
                  </article>
                );
              })}
            </div>
          )}
        </div>

        {likeWarning || message ? (
          <p className={`discover-message ${limits?.likesRemaining === 0 ? "limit" : ""}`}>
            {message || likeWarning}
          </p>
        ) : null}

        <div className="discover-actions">
          <button type="button" aria-label="Pass" onClick={() => commitSwipe("pass")} disabled={!topCard || isSwiping}>
            <X size={28} />
          </button>
          <button
            type="button"
            aria-label="Super Like"
            className="super"
            onClick={() => commitSwipe("superlike")}
            disabled={!topCard || isSwiping}
          >
            <Star size={28} />
          </button>
          <button
            type="button"
            aria-label="Like"
            className="like"
            onClick={() => commitSwipe("like")}
            disabled={!topCard || isSwiping}
          >
            <Heart size={30} />
          </button>
          <button type="button" aria-label="Undo" onClick={undoSwipe}>
            <RotateCcw size={25} />
          </button>
        </div>
      </section>

      {expandedCard ? (
        <div className="profile-modal" role="dialog" aria-modal="true">
          <button
            aria-label="Close profile"
            className="modal-close"
            type="button"
            onClick={() => setExpandedCard(null)}
          >
            <X size={22} />
          </button>
          <div className="profile-modal-body">
            <div className="profile-photo-strip">
              {(expandedCard.photos.length ? expandedCard.photos : [{ id: "fallback", url: "", isPrimary: true }]).map(
                (photo) =>
                  photo.url ? (
                    <img src={photo.url} alt="" key={photo.id} />
                  ) : (
                    <div className="discover-photo-fallback" key={photo.id} />
                  ),
              )}
            </div>
            <div className="profile-modal-content">
              <span>{expandedCard.compatibilityScore}% match</span>
              <h2>
                {expandedCard.displayName}, {expandedCard.age}
              </h2>
              <p>{expandedCard.profile.bio || expandedCard.headline || formatDistance(expandedCard.distanceKm)}</p>
              <div className="profile-grid">
                {profileRows(expandedCard).map(([label, value]) => (
                  <div key={label}>
                    <small>{label}</small>
                    <strong>{value}</strong>
                  </div>
                ))}
              </div>
              <div className="profile-tags">
                {[
                  ...expandedCard.profile.interests.hobbies,
                  ...expandedCard.profile.interests.favMusic,
                  ...expandedCard.profile.interests.favFood,
                ]
                  .slice(0, 16)
                  .map((item) => (
                    <span key={item}>{item}</span>
                  ))}
              </div>
            </div>
          </div>
        </div>
      ) : null}

      {matchedCard ? (
        <div className="match-modal" role="dialog" aria-modal="true">
          <div className="confetti" />
          <div className="match-panel">
            <div className="match-photos">
              <div>{user?.firstName?.charAt(0) || "Y"}</div>
              {matchedCard.mainPhotoUrl ? <img src={matchedCard.mainPhotoUrl} alt="" /> : <div />}
            </div>
            <h2>It&apos;s a Match!</h2>
            <p>You and {matchedCard.displayName} liked each other.</p>
            <div className="match-buttons">
              <button type="button" onClick={() => setMatchedCard(null)}>
                <Send size={18} />
                Send Message
              </button>
              <button type="button" onClick={() => setMatchedCard(null)}>
                Keep Swiping
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </main>
  );
}

export function DiscoveryEngine() {
  return (
    <ProtectedRoute>
      <DiscoveryEngineContent />
    </ProtectedRoute>
  );
}
