import "./globals.css";
import type { Metadata } from "next";
import { AuthProvider } from "../components/auth/AuthProvider";

export const metadata: Metadata = {
  title: "Yaaro0",
  icons: {
    icon: "/brand-assets/logo.png",
    shortcut: "/brand-assets/logo.png",
    apple: "/brand-assets/logo.png",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
