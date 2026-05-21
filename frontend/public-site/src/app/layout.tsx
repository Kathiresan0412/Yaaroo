import "./globals.css";
import type { Metadata } from "next";
import { AuthProvider } from "../components/auth/AuthProvider";
import { PwaRuntime } from "../components/site/PwaRuntime";

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000"),
  applicationName: "Yaaro0",
  title: {
    default: "Yaaro0 | Tamil dating, friendship, and matrimony",
    template: "%s | Yaaro0",
  },
  description:
    "Meet Tamil singles for dating, friendship, and matrimony with safety-first matching, chat, and cultural profile prompts.",
  manifest: "/manifest.webmanifest",
  keywords: ["Tamil dating", "Sri Lanka dating", "Tamil matrimony", "Tamil friendship", "Yaaro0"],
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "Yaaro0",
    description: "Tamil dating, friendship, and matrimony connections with safety-first matching.",
    url: "/",
    siteName: "Yaaro0",
    images: [{ url: "/brand-assets/yaaro-reference.png", width: 1200, height: 630, alt: "Yaaro0 app preview" }],
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Yaaro0",
    description: "Tamil dating, friendship, and matrimony connections with safety-first matching.",
    images: ["/brand-assets/yaaro-reference.png"],
  },
  icons: {
    icon: "/brand-assets/logo.png",
    shortcut: "/brand-assets/logo.png",
    apple: "/brand-assets/logo.png",
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "Yaaro0",
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
        <PwaRuntime>
          <AuthProvider>{children}</AuthProvider>
        </PwaRuntime>
      </body>
    </html>
  );
}
