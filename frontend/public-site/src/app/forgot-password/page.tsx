import { ForgotPasswordForm } from "../../components/auth/AuthForms";
import { PageShell } from "../../components/site/SiteChrome";

export default function ForgotPasswordPage() {
  return (
    <PageShell>
      <section className="auth-page">
        <ForgotPasswordForm />
      </section>
    </PageShell>
  );
}
