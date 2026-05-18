import { AppBottomNav } from "../../components/site/AppBottomNav";

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="app-tab-shell">
      {children}
      <AppBottomNav />
    </div>
  );
}
