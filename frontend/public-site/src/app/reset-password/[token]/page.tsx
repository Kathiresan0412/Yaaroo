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
        <ResetPasswordForm token={token} />
      </section>
    </PageShell>
  );
}
