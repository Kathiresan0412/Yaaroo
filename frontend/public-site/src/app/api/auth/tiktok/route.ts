import { NextResponse } from "next/server";

export function GET(request: Request) {
  const clientKey = process.env.TIKTOK_CLIENT_KEY;
  const origin = new URL(request.url).origin;
  const redirectUri =
    process.env.TIKTOK_REDIRECT_URI || `${origin}/api/auth/tiktok/callback`;

  if (!clientKey) {
    return NextResponse.redirect(
      new URL("/login?error=tiktok-not-configured", origin),
    );
  }

  const url = new URL("https://www.tiktok.com/v2/auth/authorize/");
  url.searchParams.set("client_key", clientKey);
  url.searchParams.set("redirect_uri", redirectUri);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", "user.info.basic");
  url.searchParams.set("state", crypto.randomUUID());

  return NextResponse.redirect(url);
}
