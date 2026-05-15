"use client";

import {
  BadgeCheck,
  Bell,
  Check,
  Crown,
  Globe2,
  Heart,
  MessageCircle,
  Search,
  ShieldCheck,
  SlidersHorizontal,
  Sparkles,
  Star,
  UserRound,
  Video,
  X,
} from "lucide-react";
import { useMemo, useState } from "react";

const profiles = [
  {
    name: "Anjali",
    age: 27,
    city: "Colombo",
    distance: "4 km away",
    match: 94,
    tags: ["Tamil", "Doctor", "Carnatic music"],
    bio: "Looking for a warm, family-minded connection with room for travel, temple festivals, and late-night tea.",
    image:
      "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=1200&q=85",
  },
  {
    name: "Meera",
    age: 25,
    city: "Jaffna",
    distance: "18 km away",
    match: 89,
    tags: ["Engineer", "Verified", "Family first"],
    bio: "Soft spot for beach walks, Tamil books, and people who can make a serious room laugh.",
    image:
      "https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=1200&q=85",
  },
  {
    name: "Kavya",
    age: 29,
    city: "Toronto",
    distance: "Diaspora",
    match: 86,
    tags: ["Canada", "Premium", "Video call"],
    bio: "Tamil roots, global rhythm. Hoping for someone kind, ambitious, and clear about commitment.",
    image:
      "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=1200&q=85",
  },
];

const nearby = [
  { name: "Nila", city: "Kandy", score: "92%" },
  { name: "Divya", city: "Chennai", score: "88%" },
  { name: "Sara", city: "London", score: "84%" },
];

export function SwipeExperience() {
  const [index, setIndex] = useState(0);
  const [liked, setLiked] = useState<string[]>(["Anjali"]);
  const profile = profiles[index % profiles.length];
  const nextProfile = profiles[(index + 1) % profiles.length];

  const initials = useMemo(
    () =>
      profile.name
        .split(" ")
        .map((part) => part[0])
        .join(""),
    [profile.name],
  );

  function move(choice: "like" | "pass" | "super") {
    if (choice !== "pass") {
      setLiked((current) =>
        current.includes(profile.name) ? current : [...current, profile.name],
      );
    }

    setIndex((current) => current + 1);
  }

  return (
    <main className="app-shell">
      <aside className="sidebar" aria-label="Yaro0 account">
        <div className="brand-row">
          <div className="brand-mark">Y</div>
          <span>Yaro0</span>
        </div>

        <div className="member-panel">
          <div className="avatar">{initials}</div>
          <div>
            <p className="eyebrow">Good evening</p>
            <h2>Jathusan</h2>
          </div>
          <BadgeCheck className="verified-icon" size={20} aria-hidden="true" />
        </div>

        <nav className="nav-list" aria-label="Primary">
          <a className="nav-item active" href="#discover">
            <Search size={18} aria-hidden="true" />
            Discover
          </a>
          <a className="nav-item" href="#matches">
            <Heart size={18} aria-hidden="true" />
            Matches
          </a>
          <a className="nav-item" href="#messages">
            <MessageCircle size={18} aria-hidden="true" />
            Messages
          </a>
          <a className="nav-item" href="#profile">
            <UserRound size={18} aria-hidden="true" />
            Profile
          </a>
        </nav>

        <section className="trial-band" aria-label="Premium access">
          <Crown size={18} aria-hidden="true" />
          <div>
            <h3>7-day full access</h3>
            <p>Unlimited chats, diaspora filters, video calls.</p>
          </div>
        </section>

        <section className="mini-list" id="matches" aria-label="Nearby matches">
          <div className="section-heading">
            <h3>Nearby</h3>
            <button aria-label="Filter matches">
              <SlidersHorizontal size={17} aria-hidden="true" />
            </button>
          </div>
          {nearby.map((item) => (
            <div className="mini-match" key={item.name}>
              <span>{item.name[0]}</span>
              <div>
                <strong>{item.name}</strong>
                <p>{item.city}</p>
              </div>
              <em>{item.score}</em>
            </div>
          ))}
        </section>
      </aside>

      <section className="swipe-stage" id="discover" aria-label="Discover profiles">
        <header className="topbar">
          <div>
            <p className="eyebrow">Tamil dating and matrimony</p>
            <h1>Swipe into something real.</h1>
          </div>
          <div className="top-actions">
            <button aria-label="Change language">
              <Globe2 size={19} aria-hidden="true" />
            </button>
            <button aria-label="Notifications">
              <Bell size={19} aria-hidden="true" />
            </button>
          </div>
        </header>

        <div className="deck-layout">
          <article className="profile-card" aria-label={`${profile.name}, ${profile.age}`}>
            <img src={profile.image} alt={`${profile.name} profile portrait`} />
            <div className="image-wash" />
            <div className="compatibility">
              <Sparkles size={16} aria-hidden="true" />
              {profile.match}% match
            </div>
            <div className="profile-copy">
              <div>
                <h2>
                  {profile.name}, {profile.age}
                </h2>
                <p>
                  {profile.city} · {profile.distance}
                </p>
              </div>
              <p className="bio">{profile.bio}</p>
              <div className="tag-row">
                {profile.tags.map((tag) => (
                  <span key={tag}>{tag}</span>
                ))}
              </div>
            </div>
          </article>

          <aside className="details-rail" aria-label="Match details">
            <div className="next-preview">
              <img src={nextProfile.image} alt={`${nextProfile.name} preview`} />
              <div>
                <p className="eyebrow">Up next</p>
                <h3>{nextProfile.name}</h3>
              </div>
            </div>

            <div className="signal-grid">
              <div>
                <ShieldCheck size={20} aria-hidden="true" />
                <strong>ID checked</strong>
                <p>Women-safe mode enabled.</p>
              </div>
              <div>
                <Video size={20} aria-hidden="true" />
                <strong>Video ready</strong>
                <p>Premium call unlock.</p>
              </div>
              <div>
                <Check size={20} aria-hidden="true" />
                <strong>Jathagam</strong>
                <p>Compatibility visible.</p>
              </div>
            </div>

            <div className="liked-strip" id="messages">
              <p className="eyebrow">Liked you</p>
              <div>
                {liked.slice(-4).map((name) => (
                  <span key={name}>{name[0]}</span>
                ))}
              </div>
            </div>
          </aside>
        </div>

        <div className="swipe-actions" aria-label="Swipe actions">
          <button className="reject" onClick={() => move("pass")} aria-label="Pass">
            <X size={30} aria-hidden="true" />
          </button>
          <button className="super" onClick={() => move("super")} aria-label="Super like">
            <Star size={25} aria-hidden="true" />
          </button>
          <button className="accept" onClick={() => move("like")} aria-label="Like">
            <Heart size={31} aria-hidden="true" />
          </button>
        </div>
      </section>
    </main>
  );
}
