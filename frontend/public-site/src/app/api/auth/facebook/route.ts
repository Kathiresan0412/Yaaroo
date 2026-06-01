import { NextResponse } from "next/server";

export function GET(request: Request) {
  const clientId = process.env.FACEBOOK_CLIENT_ID;
  const requestUrl = new URL(request.url);
  const origin = requestUrl.origin;
  const redirectUri =
    process.env.FACEBOOK_REDIRECT_URI || `${origin}/api/auth/facebook/callback`;
  const isMobile = requestUrl.searchParams.get("mobile") === "1";
  const linkUserId = requestUrl.searchParams.get("link") || "";
  const stateStr = `${isMobile ? "mobile" : "web"}:${linkUserId ? `link:${linkUserId}` : "auth"}:${crypto.randomUUID()}`;

  // Facebook Sandbox Mode fallback for localhost/development when no client credentials exist
  if (!clientId) {
    console.log("FACEBOOK_CLIENT_ID is not configured. Redirecting to Sandbox Mode callback...");
    const callbackUrl = new URL("/api/auth/facebook/callback", origin);
    callbackUrl.searchParams.set("code", "mock-facebook-code");
    callbackUrl.searchParams.set("state", stateStr);
    return NextResponse.redirect(callbackUrl);
  }

  const url = new URL("https://www.facebook.com/v19.0/dialog/oauth");
  url.searchParams.set("client_id", clientId);
  url.searchParams.set("redirect_uri", redirectUri);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", "email,public_profile");
  url.searchParams.set("state", stateStr);

  return NextResponse.redirect(url);
}

