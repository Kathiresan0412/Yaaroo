import type { Metadata } from "next";
import { SwipeExperience } from "../components/SwipeExperience";

export const metadata: Metadata = {
  title: "Tamil dating, friendship, and matrimony",
  description:
    "Join Yaaro0 to discover Tamil singles, explore shared interests, match safely, and start meaningful conversations.",
  alternates: { canonical: "/" },
};

export default function HomePage() {
  return <SwipeExperience />;
}
