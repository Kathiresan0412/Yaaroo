"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Compass, Flame, MessageCircle, UserRound } from "lucide-react";

const navItems = [
  { href: "/app/discover", label: "Discover", icon: Flame },
  { href: "/app/explore", label: "Explore", icon: Compass },
  { href: "/app/matches", label: "Matches", icon: MessageCircle },
  { href: "/app/profile", label: "Profile", icon: UserRound },
];

export function AppBottomNav() {
  const pathname = usePathname();

  return (
    <nav className="app-bottom-nav" aria-label="Primary app navigation">
      {navItems.map((item) => {
        const Icon = item.icon;
        const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`);

        return (
          <Link className={isActive ? "active" : ""} href={item.href} key={item.href}>
            <Icon size={20} aria-hidden="true" />
            <span>{item.label}</span>
          </Link>
        );
      })}
    </nav>
  );
}
