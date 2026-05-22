import { ResetPasswordForm } from "../../../components/auth/AuthForms";
import { PageShell } from "../../../components/site/SiteChrome";

type Props = {
  params: Promise<{ token: string }>;
};

export default async function ResetPasswordTokenPage({ params }: Props) {
  const { token } = await params;

  return (
    <PageShell>
      <section className="auth-page">
        <div style={{ display: "flex", flexDirection: "column", width: "100%", maxWidth: "440px", gap: "20px" }}>
          <ResetPasswordForm token={token} />
          
          <div style={{
            padding: "18px",
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
              Using a phone? Reset directly in our app:
            </p>
            <a 
              className="primary-cta" 
              href={`yaaro0://reset-password/${token}`}
              style={{
                background: "linear-gradient(135deg, #FF4F6D 0%, #FF8A9F 100%)",
                boxShadow: "0 4px 15px rgba(255, 79, 109, 0.4)",
                border: "none",
                margin: 0,
                display: "block",
                textAlign: "center"
              }}
            >
              Open in Yaaro0 App
            </a>
          </div>
        </div>
      </section>
      <script
        dangerouslySetInnerHTML={{
          __html: `
            if (/Android|iPhone|iPad|iPod/i.test(navigator.userAgent)) {
              setTimeout(function() {
                window.location.href = "yaaro0://reset-password/${token}";
              }, 600);
            }
          `
        }}
      />
    </PageShell>
  );
}
