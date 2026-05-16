import { ResetPasswordForm } from "../../components/auth/AuthForms";
import { PageShell } from "../../components/site/SiteChrome";

export default function ResetPasswordPage() {
  return (
    <PageShell>
      <section className="auth-page">
        <ResetPasswordForm />
      </section>
    </PageShell>
  );
}
