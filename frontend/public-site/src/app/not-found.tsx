import Link from "next/link";
import { HeartCrack } from "lucide-react";

export default function NotFoundPage() {
  return (
    <main className="error-page">
      <section>
        <HeartCrack size={34} aria-hidden="true" />
        <h1>Page not found.</h1>
        <p>This Yaaro0 screen may have moved or expired.</p>
        <Link href="/app/discover">Back to discover</Link>
      </section>
    </main>
  );
}
