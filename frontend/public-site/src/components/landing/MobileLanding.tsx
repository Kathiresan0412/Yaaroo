"use client";

import { useEffect, useRef, useState } from "react";
import "./mobile-landing.css";

export function MobileLanding() {
  const containerRef = useRef<HTMLDivElement>(null);
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    function onScroll() {
      const scrollTop = window.scrollY;
      const maxScroll = container!.scrollHeight - window.innerHeight;
      const p = Math.min(Math.max(scrollTop / maxScroll, 0), 1);
      setProgress(p);
    }

    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // Scene breakpoints (0-1 range)
  const scene1End = 0.15;
  const scene2End = 0.35;
  const scene3End = 0.55;
  const scene4End = 0.7;
  const scene5End = 0.85;

  // Calculate scene-local progress
  const sceneProgress = (start: number, end: number) =>
    Math.min(Math.max((progress - start) / (end - start), 0), 1);

  const s1 = sceneProgress(0, scene1End);
  const s2 = sceneProgress(scene1End, scene2End);
  const s3 = sceneProgress(scene2End, scene3End);
  const s4 = sceneProgress(scene3End, scene4End);
  const s5 = sceneProgress(scene4End, scene5End);
  const s6 = sceneProgress(scene5End, 1);

  // Background transition
  const bgOpacity = Math.min(s2 * 1.5, 1);
  const cafeOpacity = Math.min(s3, 1);

  // Characters walking toward each other
  const maleX = -40 + s2 * 40; // starts at -40%, moves to 0
  const femaleX = 40 - s2 * 40; // starts at 40%, moves to 0

  // Zoom effect
  const zoom = 1 + s2 * 0.15 + s3 * 0.2 + s4 * 0.15 + s5 * 0.5;

  // Silhouette to real people transition
  const silhouetteOpacity = 1 - Math.min(s3 * 2, 1);
  const realPeopleOpacity = Math.min(s3 * 1.5, 1);

  // Tea cup focus
  const teaCupScale = 0.3 + s5 * 0.7;
  const teaCupOpacity = Math.min((s4 * 0.5 + s5) * 1.2, 1);
  const surroundBlur = s5 * 12;

  // CTA
  const ctaOpacity = s6;
  const ctaTranslate = 30 - s6 * 30;

  return (
    <div className="ml-root" ref={containerRef}>
      {/* Scroll spacer */}
      <div className="ml-scroll-spacer" />

      {/* Fixed viewport */}
      <div className="ml-viewport">
        {/* Background layers */}
        <div className="ml-bg-base" />
        <div className="ml-bg-ambient" style={{ opacity: bgOpacity }} />
        <div className="ml-bg-cafe" style={{ opacity: cafeOpacity }} />

        {/* Scene 1 — Logo & Hero */}
        <header className="ml-header" style={{ opacity: 1 - s1 * 0.3 }}>
          <div className="ml-logo">
            <img src="/brand-assets/logo.png" alt="YaaroO" width={36} height={36} />
            <span>YaaroO</span>
          </div>
        </header>

        {/* Hero text */}
        <div
          className="ml-hero-text"
          style={{
            opacity: 1 - s1 * 2,
            transform: `translateY(${-s1 * 60}px)`,
          }}
        >
          <h1>Meet with trust,<br />not noise.</h1>
          <p className="ml-subtitle">Scroll to discover</p>
          <div className="ml-scroll-arrow" aria-hidden="true">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
              <path d="M12 5v14M5 12l7 7 7-7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
        </div>

        {/* Scene 2 & 3 — Characters */}
        <div
          className="ml-stage"
          style={{ transform: `scale(${zoom})` }}
        >
          {/* Silhouettes */}
          <div
            className="ml-silhouette ml-male"
            style={{
              opacity: silhouetteOpacity,
              transform: `translateX(${maleX}vw)`,
            }}
          >
            <svg viewBox="0 0 80 200" className="ml-person-svg">
              <circle cx="40" cy="30" r="18" fill="currentColor" />
              <rect x="25" y="52" width="30" height="60" rx="12" fill="currentColor" />
              <rect x="22" y="116" width="14" height="55" rx="7" fill="currentColor" />
              <rect x="44" y="116" width="14" height="55" rx="7" fill="currentColor" />
            </svg>
          </div>
          <div
            className="ml-silhouette ml-female"
            style={{
              opacity: silhouetteOpacity,
              transform: `translateX(${femaleX}vw)`,
            }}
          >
            <svg viewBox="0 0 80 200" className="ml-person-svg">
              <circle cx="40" cy="30" r="18" fill="currentColor" />
              <path d="M20 52 C20 52 25 52 40 52 C55 52 60 52 60 52 L55 120 L25 120 Z" rx="12" fill="currentColor" />
              <rect x="22" y="116" width="14" height="55" rx="7" fill="currentColor" />
              <rect x="44" y="116" width="14" height="55" rx="7" fill="currentColor" />
            </svg>
          </div>

          {/* Real people layer */}
          <div
            className="ml-real-people"
            style={{ opacity: realPeopleOpacity }}
          >
            <div className="ml-couple-scene">
              {/* Café table scene */}
              <div className="ml-cafe-scene" style={{ filter: `blur(${surroundBlur}px)` }}>
                <div className="ml-person-real ml-person-left">
                  <div className="ml-avatar-glow" />
                </div>
                <div className="ml-cafe-table">
                  <div className="ml-table-surface" />
                </div>
                <div className="ml-person-real ml-person-right">
                  <div className="ml-avatar-glow" />
                </div>
              </div>

              {/* Tea cup — moves to center focus */}
              <div
                className="ml-tea-cup"
                style={{
                  opacity: teaCupOpacity,
                  transform: `scale(${teaCupScale})`,
                }}
              >
                <div className="ml-cup-body">
                  <div className="ml-cup-handle" />
                  <div className="ml-cup-saucer" />
                </div>
                <div className="ml-steam">
                  <span /><span /><span />
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Scene 4 — Conversation indicators */}
        {s4 > 0.2 && s5 < 0.8 && (
          <div className="ml-conversation-hints" style={{ opacity: Math.min((s4 - 0.2) * 2, 1) * (1 - s5) }}>
            <div className="ml-chat-bubble ml-bubble-left">
              <span className="ml-bubble-dot" /><span className="ml-bubble-dot" /><span className="ml-bubble-dot" />
            </div>
            <div className="ml-chat-bubble ml-bubble-right">
              <span className="ml-bubble-dot" /><span className="ml-bubble-dot" /><span className="ml-bubble-dot" />
            </div>
          </div>
        )}

        {/* Scene 6 — CTA */}
        <div
          className="ml-cta-section"
          style={{
            opacity: ctaOpacity,
            transform: `translateY(${ctaTranslate}px)`,
            pointerEvents: ctaOpacity > 0.5 ? "auto" : "none",
          }}
        >
          <div className="ml-cta-card">
            <h2>Every meaningful connection starts with a conversation.</h2>
            <p>Verified profiles. Genuine people. Real connections.</p>
            <a href="/register" className="ml-cta-button">
              Start Your Journey
            </a>
          </div>
        </div>

        {/* Progress indicator */}
        <div className="ml-progress" aria-hidden="true">
          <div className="ml-progress-fill" style={{ height: `${progress * 100}%` }} />
        </div>
      </div>
    </div>
  );
}
