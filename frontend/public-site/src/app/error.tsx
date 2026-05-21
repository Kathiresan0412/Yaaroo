"use client";

import { useEffect } from "react";
import { RefreshCw, TriangleAlert } from "lucide-react";

export default function AppError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <main className="error-page">
      <section>
        <TriangleAlert size={34} aria-hidden="true" />
        <h1>Something needs a refresh.</h1>
        <p>Yaaro0 hit a temporary problem while loading this screen.</p>
        <button type="button" onClick={reset}>
          <RefreshCw size={18} />
          Try again
        </button>
      </section>
    </main>
  );
}
