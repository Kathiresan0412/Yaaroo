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
          
          {isSuccess && (
            <div style={{
              marginTop: "4px",
              marginBottom: "20px",
              padding: "16px",
              background: "rgba(255, 79, 109, 0.08)",
              border: "1px solid rgba(255, 79, 109, 0.25)",
              borderRadius: "12px",
              textAlign: "center",
              display: "flex",
              flexDirection: "column",
              gap: "10px",
              boxShadow: "0 8px 32px rgba(255, 79, 109, 0.1)"
            }}>
              <p style={{ fontSize: "14px", color: "rgba(255, 255, 255, 0.85)", fontWeight: "500", margin: 0 }}>
                Using a phone? Verify directly in our app:
              </p>
              <a 
                className="primary-cta" 
                href={`yaaro0://verify-email/${token}`}
                style={{
                  background: "linear-gradient(135deg, #FF4F6D 0%, #FF8A9F 100%)",
                  boxShadow: "0 4px 15px rgba(255, 79, 109, 0.4)",
                  border: "none",
                  margin: 0
                }}
              >
                Open in Yaaro0 App
              </a>
            </div>
          )}

          <a className="primary-cta" href="/login">
            Go to login
          </a>
        </section>
      </section>
      <script
        dangerouslySetInnerHTML={{
          __html: `
            if (/Android|iPhone|iPad|iPod/i.test(navigator.userAgent)) {
              setTimeout(function() {
                window.location.href = "yaaro0://verify-email/${token}";
              }, 600);
            }
          `
        }}
      />
    </PageShell>
  );
}
