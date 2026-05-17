import { SignupForm } from "../../components/auth/AuthForms";
import { PageShell } from "../../components/site/SiteChrome";

export default function RegisterPage() {
  return (
    <PageShell>
      <section className="auth-page">
        <SignupForm />
      </section>
    </PageShell>
  );
}
