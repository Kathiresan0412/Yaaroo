"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { io } from "socket.io-client";
import {
  BadgeCheck,
  Ban,
  Flag,
  Heart,
  Loader2,
  MessageCircle,
  MoreVertical,
  Search,
  Shield,
  UserX,
  X,
} from "lucide-react";
import { ProtectedRoute } from "../auth/ProtectedRoute";
import { useAuth } from "../auth/AuthProvider";
import { readOfflineCache, trackClientEvent, writeOfflineCache } from "../../lib/offline-cache";

const socketUrl = process.env.NEXT_PUBLIC_YAARO0_SOCKET_URL || "http://127.0.0.1:8000";

type MatchItem = {
  id: string;
  matchedAt: string;
  isNew: boolean;
  compatibilityScore: number;
  user: {
    id: string;
    displayName: string;
    age: number | null;
    mainPhotoUrl: string | null;
    lastActiveAt: string | null;
    isVerified: boolean;
  };
  lastMessage: { preview: string; sentAt: string | null } | null;
  unreadCount: number;
};

type LikeItem = {
  id: string;
  action: "like" | "superlike";
  likedAt: string;
  user: {
    id: string;
    displayName: string;
    age: number | null;
    mainPhotoUrl: string | null;
    isVerified: boolean;
  };
};

type PublicProfile = {
  id: string;
  displayName: string;
  age: number | null;
  mainPhotoUrl: string | null;
  photos: { id: string; url: string; isPrimary: boolean }[];
  headline: string | null;
  bio: string | null;
  pronouns: string | null;
  city: string | null;
  country: string | null;
  distanceKm: number | null;
  lastActiveAt: string | null;
  isVerified: boolean;
  compatibilityScore: number;
  sharedInterests: string[];
  basics: Record<string, string | number | string[] | null>;
  lifestyle: Record<string, string | string[] | null>;
  interests: Record<string, string | string[] | null>;
};

function parsePayload<T>(response: Response) {
  return response.json() as Promise<T & { success?: boolean; message?: string }>;
}

function initials(name: string) {
  return name
    .split(" ")
    .map((part) => part.charAt(0))
    .join("")
    .slice(0, 2)
    .toUpperCase();
}

function formatTimestamp(value: string | null) {
  if (!value) {
    return "";
  }

  const date = new Date(value);
  const diffMs = Date.now() - date.getTime();
  const minutes = Math.floor(diffMs / 60000);

  if (minutes < 1) {
    return "now";
  }

  if (minutes < 60) {
    return `${minutes}m`;
  }

  const hours = Math.floor(minutes / 60);
  if (hours < 24) {
    return `${hours}h`;
  }

  return date.toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

function formatValue(value: string | number | string[] | null) {
  if (Array.isArray(value)) {
    return value.join(", ");
  }

  if (typeof value === "number") {
    return String(value);
  }

  return value || "";
}

function sectionRows(section: Record<string, string | number | string[] | null>) {
  return Object.entries(section)
    .map(([key, value]) => ({
      label: key.replace(/([A-Z])/g, " $1").replace(/^./, (char) => char.toUpperCase()),
      value: formatValue(value),
    }))
    .filter((row) => row.value.length > 0);
}

function MatchesExperienceContent() {
  const { accessToken, authFetch, user } = useAuth();
  const router = useRouter();
  const [matches, setMatches] = useState<MatchItem[]>([]);
  const [likes, setLikes] = useState<LikeItem[]>([]);
  const [likesCount, setLikesCount] = useState(0);
  const [likesBlurred, setLikesBlurred] = useState(true);
  const [query, setQuery] = useState("");
  const [profile, setProfile] = useState<PublicProfile | null>(null);
  const [profileMatchId, setProfileMatchId] = useState("");
  const [selectedPhotoIndex, setSelectedPhotoIndex] = useState(0);
  const [openMenuMatchId, setOpenMenuMatchId] = useState("");
  const [confirmUnmatch, setConfirmUnmatch] = useState<MatchItem | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [message, setMessage] = useState("");

  const loadMatches = useCallback(async () => {
    setMessage("");
    setIsLoading(true);

    try {
      const [matchesResponse, likesResponse] = await Promise.all([
        authFetch("/api/matches"),
        authFetch("/api/likes/received"),
      ]);
      const matchesPayload = await parsePayload<{ matches?: MatchItem[] }>(matchesResponse);
      const likesPayload = await parsePayload<{
        likes?: LikeItem[];
        count?: number;
        blurred?: boolean;
      }>(likesResponse);

      if (!matchesResponse.ok) {
        throw new Error(matchesPayload.message || "Unable to load matches.");
      }

      if (!likesResponse.ok) {
        throw new Error(likesPayload.message || "Unable to load likes.");
      }

      setMatches(matchesPayload.matches || []);
      setLikes(likesPayload.likes || []);
      setLikesCount(likesPayload.count || 0);
      setLikesBlurred(Boolean(likesPayload.blurred));
      writeOfflineCache("matches", {
        matches: matchesPayload.matches || [],
        likes: likesPayload.likes || [],
        likesCount: likesPayload.count || 0,
        likesBlurred: Boolean(likesPayload.blurred),
      });
    } catch (error) {
      const cached = readOfflineCache<{
        matches: MatchItem[];
        likes: LikeItem[];
        likesCount: number;
        likesBlurred: boolean;
      }>("matches");

      if (cached) {
        setMatches(cached.matches);
        setLikes(cached.likes);
        setLikesCount(cached.likesCount);
        setLikesBlurred(cached.likesBlurred);
        setMessage("Showing saved matches while Yaaro0 reconnects.");
        return;
      }

      setMessage(error instanceof Error ? error.message : "Matches are unavailable.");
    } finally {
      setIsLoading(false);
    }
  }, [authFetch]);

  useEffect(() => {
    loadMatches();
  }, [loadMatches]);

  useEffect(() => {
    if (!accessToken) {
      return;
    }

    const socket = io(socketUrl, { auth: { token: accessToken }, transports: ["websocket", "polling"] });

    socket.on("new_message", (chatMessage: {
      matchId: string;
      senderId: string;
      content: string | null;
      type: string;
      createdAt: string;
    }) => {
      if (chatMessage.senderId === user?.id) {
        return;
      }

      setMatches((current) =>
        current.map((match) =>
          match.id === chatMessage.matchId
            ? {
                ...match,
                lastMessage: {
                  preview:
                    chatMessage.type === "photo" || chatMessage.type === "image"
                      ? "Photo"
                      : chatMessage.type === "gif"
                        ? "GIF"
                        : chatMessage.type === "voice"
                          ? "Voice message"
                          : chatMessage.content || "Message",
                  sentAt: chatMessage.createdAt,
                },
                unreadCount: match.unreadCount + 1,
              }
            : match,
        ),
      );
    });

    return () => {
      socket.disconnect();
    };
  }, [accessToken, user?.id]);

  const filteredMatches = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();

    if (!normalizedQuery) {
      return matches;
    }

    return matches.filter((match) =>
      match.user.displayName.toLowerCase().includes(normalizedQuery),
    );
  }, [matches, query]);

  const newMatches = useMemo(
    () => filteredMatches.filter((match) => match.isNew),
    [filteredMatches],
  );

  async function openProfile(userId: string, matchId = "") {
    setMessage("");
    setSelectedPhotoIndex(0);
    setProfileMatchId(matchId);

    try {
      const response = await authFetch(`/api/users/${userId}/profile`);
      const payload = await parsePayload<{ profile?: PublicProfile }>(response);

      if (!response.ok || !payload.profile) {
        throw new Error(payload.message || "Unable to open profile.");
      }

      setProfile(payload.profile);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Unable to open profile.");
    }
  }

  async function unmatch(match: MatchItem) {
    setMessage("");

    try {
      const response = await authFetch(`/api/matches/${match.id}`, { method: "DELETE" });
      const payload = await parsePayload<Record<string, never>>(response);

      if (!response.ok) {
        throw new Error(payload.message || "Unable to unmatch.");
      }

      setMatches((currentMatches) => currentMatches.filter((item) => item.id !== match.id));
      setConfirmUnmatch(null);
      setOpenMenuMatchId("");
      trackClientEvent("unmatch", { matchId: match.id });
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Unable to unmatch.");
    }
  }

  async function likeBack(userId: string) {
    setMessage("");

    try {
      const response = await authFetch("/api/swipe", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ target_user_id: userId, action: "like" }),
      });
      const payload = await parsePayload<{ matched?: boolean }>(response);

      if (!response.ok) {
        throw new Error(payload.message || "Unable to like back.");
      }

      setLikes((currentLikes) => currentLikes.filter((like) => like.user.id !== userId));
      trackClientEvent("like_back", { targetUserId: userId });
      await loadMatches();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Unable to like back.");
    }
  }

  const activePhoto = profile?.photos[selectedPhotoIndex] ?? null;

  return (
    <main className="matches-page">
      <section className="matches-shell" aria-label="Matches">
        <header className="matches-header">
          <div>
            <span>Yaaro0</span>
            <h1>Matches</h1>
          </div>
          <div className="matches-count">{matches.length}</div>
        </header>

        <label className="matches-search">
          <Search size={18} />
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Search matches"
            aria-label="Search matches by name"
          />
        </label>

        {message ? <p className="matches-message">{message}</p> : null}

        <section className="likes-strip" aria-label="Likes you">
          <div className="section-heading">
            <h2>Likes You</h2>
            <span>{likesCount}</span>
          </div>
          {likesBlurred ? (
            <div className="blurred-likes">
              {[0, 1, 2].map((item) => (
                <div key={item} />
              ))}
              <strong>{likesCount} people liked you</strong>
              <button type="button">Upgrade to See</button>
            </div>
          ) : (
            <div className="likes-grid">
              {likes.map((like) => (
                <article key={like.id} className="like-card">
                  <button type="button" onClick={() => openProfile(like.user.id)}>
                    {like.user.mainPhotoUrl ? <img src={like.user.mainPhotoUrl} alt="" /> : <span />}
                  </button>
                  <strong>
                    {like.user.displayName}
                    {like.user.age ? `, ${like.user.age}` : ""}
                  </strong>
                  <button type="button" onClick={() => likeBack(like.user.id)}>
                    <Heart size={16} />
                    Like Back
                  </button>
                </article>
              ))}
            </div>
          )}
        </section>

        <section className="new-matches" aria-label="New matches">
          <div className="section-heading">
            <h2>New Matches</h2>
            <span>{newMatches.length}</span>
          </div>
          <div className="new-match-row">
            {newMatches.length === 0 ? (
              <p>No new matches yet.</p>
            ) : (
              newMatches.map((match) => (
                <button type="button" key={match.id} onClick={() => openProfile(match.user.id, match.id)}>
                  {match.user.mainPhotoUrl ? (
                    <img src={match.user.mainPhotoUrl} alt="" />
                  ) : (
                    <span>{initials(match.user.displayName)}</span>
                  )}
                  <strong>{match.user.displayName}</strong>
                </button>
              ))
            )}
          </div>
        </section>

        <section className="messages-list" aria-label="Messages">
          <div className="section-heading">
            <h2>Messages</h2>
            <span>{filteredMatches.length}</span>
          </div>
          {isLoading ? (
            <div className="matches-skeleton" aria-label="Loading matches">
              {[0, 1, 2, 3].map((item) => (
                <div className="match-row skeleton-row" key={item}>
                  <span />
                  <div>
                    <i />
                    <i />
                  </div>
                </div>
              ))}
            </div>
          ) : filteredMatches.length === 0 ? (
            <div className="matches-empty">
              <MessageCircle size={32} />
              <h2>No matches yet</h2>
              <p>Start swiping to find your match.</p>
            </div>
          ) : (
            filteredMatches.map((match) => (
              <article className={`match-row ${match.isNew ? "fresh" : ""}`} key={match.id}>
                <button
                  className="match-avatar"
                  type="button"
                  onClick={() => openProfile(match.user.id, match.id)}
                  aria-label={`View ${match.user.displayName}'s profile`}
                >
                  {match.user.mainPhotoUrl ? (
                    <img src={match.user.mainPhotoUrl} alt="" loading="lazy" />
                  ) : (
                    <span>{initials(match.user.displayName)}</span>
                  )}
                </button>
                <button
                  className="match-copy"
                  type="button"
                  onClick={() => router.push(`/app/messages/${match.id}`)}
                >
                  <span>
                    <strong>
                      {match.user.displayName}
                      {match.user.age ? `, ${match.user.age}` : ""}
                    </strong>
                    {match.user.isVerified ? <BadgeCheck size={16} /> : null}
                  </span>
                  <small>{match.lastMessage?.preview || "Say hello"}</small>
                </button>
                <div className="match-meta">
                  <time>{formatTimestamp(match.lastMessage?.sentAt || match.matchedAt)}</time>
                  {match.unreadCount > 0 ? <b>{match.unreadCount}</b> : null}
                  {match.isNew ? <em>New Match</em> : null}
                </div>
                <div className="match-menu">
                  <button
                    type="button"
                    aria-label={`Open options for ${match.user.displayName}`}
                    onClick={() =>
                      setOpenMenuMatchId((current) => (current === match.id ? "" : match.id))
                    }
                  >
                    <MoreVertical size={20} />
                  </button>
                  {openMenuMatchId === match.id ? (
                    <div>
                      <button type="button" onClick={() => setConfirmUnmatch(match)}>
                        <UserX size={16} />
                        Unmatch
                      </button>
                    </div>
                  ) : null}
                </div>
              </article>
            ))
          )}
        </section>
      </section>

      {profile ? (
        <div className="profile-modal match-profile-modal" role="dialog" aria-modal="true">
          <button
            aria-label="Close profile"
            className="modal-close"
            type="button"
            onClick={() => {
              setProfile(null);
              setProfileMatchId("");
            }}
          >
            <X size={22} />
          </button>
          <div className="profile-modal-body">
            <div className="profile-hero">
              {activePhoto?.url || profile.mainPhotoUrl ? (
                <img src={activePhoto?.url || profile.mainPhotoUrl || ""} alt="" loading="lazy" />
              ) : (
                <div className="discover-photo-fallback" />
              )}
              <div className="profile-dots">
                {(profile.photos.length ? profile.photos : [{ id: "fallback" }]).map((photo, index) => (
                  <button
                    aria-label={`Show photo ${index + 1}`}
                    className={index === selectedPhotoIndex ? "active" : ""}
                    key={photo.id}
                    type="button"
                    onClick={() => setSelectedPhotoIndex(index)}
                  />
                ))}
              </div>
            </div>
            <div className="profile-modal-content">
              <div className="profile-title-row">
                <div>
                  <h2>
                    {profile.displayName}
                    {profile.age ? `, ${profile.age}` : ""}
                  </h2>
                  <p>
                    {[profile.city, profile.country].filter(Boolean).join(", ") ||
                      (profile.distanceKm === null ? "Nearby" : `${profile.distanceKm} km away`)}
                  </p>
                </div>
                <div className="compat-ring">{profile.compatibilityScore}%</div>
              </div>

              {profile.isVerified ? (
                <span className="verified-pill">
                  <BadgeCheck size={16} />
                  Verified
                </span>
              ) : null}

              <p>{profile.bio || profile.headline || "This profile is keeping things concise."}</p>

              <section>
                <h3>Shared Interests</h3>
                <div className="profile-tags shared-highlight">
                  {profile.sharedInterests.length > 0 ? (
                    profile.sharedInterests.map((interest) => <span key={interest}>{interest}</span>)
                  ) : (
                    <span>Discover more in chat</span>
                  )}
                </div>
              </section>

              {[
                ["About", { headline: profile.headline, pronouns: profile.pronouns }],
                ["Basics", profile.basics],
                ["Lifestyle", profile.lifestyle],
                ["Interests", profile.interests],
              ].map(([title, section]) => {
                const rows = sectionRows(section as Record<string, string | number | string[] | null>);

                return rows.length > 0 ? (
                  <section key={title as string}>
                    <h3>{title as string}</h3>
                    <div className="profile-grid">
                      {rows.map((row) => (
                        <div key={row.label}>
                          <small>{row.label}</small>
                          <strong>{row.value}</strong>
                        </div>
                      ))}
                    </div>
                  </section>
                ) : null;
              })}

              <div className="profile-action-bar">
                <button type="button">
                  <Flag size={18} />
                  Report
                </button>
                <button type="button">
                  <Ban size={18} />
                  Block
                </button>
                <button
                  type="button"
                  disabled={!profileMatchId}
                  onClick={() => profileMatchId && router.push(`/app/messages/${profileMatchId}`)}
                >
                  <MessageCircle size={18} />
                  Message
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : null}

      {confirmUnmatch ? (
        <div className="confirm-modal" role="dialog" aria-modal="true">
          <div>
            <Shield size={30} />
            <h2>Unmatch {confirmUnmatch.user.displayName}?</h2>
            <p>This removes the match from your list.</p>
            <div>
              <button type="button" onClick={() => unmatch(confirmUnmatch)}>
                Unmatch
              </button>
              <button type="button" onClick={() => setConfirmUnmatch(null)}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </main>
  );
}

export function MatchesExperience() {
  return (
    <ProtectedRoute>
      <MatchesExperienceContent />
    </ProtectedRoute>
  );
}
