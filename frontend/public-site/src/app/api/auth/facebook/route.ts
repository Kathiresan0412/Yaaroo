import { NextResponse } from "next/server";

export function GET(request: Request) {
  const clientId = process.env.FACEBOOK_CLIENT_ID;
  const origin = new URL(request.url).origin;
  const redirectUri =
    process.env.FACEBOOK_REDIRECT_URI || `${origin}/api/auth/facebook/callback`;

  if (!clientId) {
    return NextResponse.redirect(
      new URL("/login?error=facebook-not-configured", origin),
    );
  }

  const url = new URL("https://www.facebook.com/v19.0/dialog/oauth");
  url.searchParams.set("client_id", clientId);
  url.searchParams.set("redirect_uri", redirectUri);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", "email,public_profile");

  return NextResponse.redirect(url);
}
