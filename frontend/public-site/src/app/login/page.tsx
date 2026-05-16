import { LoginForm } from "../../components/auth/AuthForms";
import { PageShell } from "../../components/site/SiteChrome";

export default function LoginPage() {
  return (
    <PageShell>
      <section className="auth-page">
        <LoginForm />
      </section>
    </PageShell>
  );
}
