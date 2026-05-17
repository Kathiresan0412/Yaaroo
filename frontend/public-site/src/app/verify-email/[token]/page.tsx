import { CheckCircle2 } from "lucide-react";
import { PageShell } from "../../../components/site/SiteChrome";

type Props = {
  params: Promise<{ token: string }>;
};

export default async function VerifyEmailPage({ params }: Props) {
  const { token } = await params;
  let message = "Email verified. You can now log in.";
  let isSuccess = true;

  try {
    const response = await fetch(
      `${process.env.YAARO0_API_URL || "http://127.0.0.1:8000"}/api/auth/verify-email/${encodeURIComponent(token)}`,
      { cache: "no-store" },
    );
    const payload = (await response.json()) as { message?: string };

    message = payload.message || message;
    isSuccess = response.ok;
  } catch {
    message = "Unable to verify this link right now.";
    isSuccess = false;
  }

  return (
    <PageShell>
      <section className="auth-page">
        <section className="auth-card" aria-labelledby="verify-title">
          <p className="modal-kicker">Email verification</p>
          <h1 id="verify-title">{isSuccess ? "You're verified" : "Link problem"}</h1>
          <p className={isSuccess ? "form-success" : "form-error"} role="status">
            {isSuccess ? <CheckCircle2 size={18} aria-hidden="true" /> : null}
            {message}
          </p>
          <a className="primary-cta" href="/login">
            Go to login
          </a>
        </section>
      </section>
    </PageShell>
  );
}
