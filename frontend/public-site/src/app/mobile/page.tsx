import type { Metadata } from "next";
import { MobileLanding } from "../../components/landing/MobileLanding";

export const metadata: Metadata = {
  title: "Meet with trust, not noise",
  description:
    "YaaroO — Premium Tamil dating, friendship, and matrimony. Verified profiles, genuine people, real connections.",
  alternates: { canonical: "/mobile" },
};

export default function MobileLandingPage() {
  return <MobileLanding />;
}
