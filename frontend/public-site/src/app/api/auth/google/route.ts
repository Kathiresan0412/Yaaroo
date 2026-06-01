import { NextResponse } from "next/server";

export function GET(request: Request) {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const requestUrl = new URL(request.url);
  const origin = requestUrl.origin;
  const redirectUri =
    process.env.GOOGLE_REDIRECT_URI || `${origin}/api/auth/google/callback`;
  const isMobile = requestUrl.searchParams.get("mobile") === "1";
  const linkUserId = requestUrl.searchParams.get("link") || "";
  const stateStr = `${isMobile ? "mobile" : "web"}:${linkUserId ? `link:${linkUserId}` : "auth"}:${crypto.randomUUID()}`;

  // Google Sandbox Mode fallback for localhost/development when no client credentials exist
  if (!clientId) {
    console.log("GOOGLE_CLIENT_ID is not configured. Redirecting to Sandbox Mode callback...");
    const callbackUrl = new URL("/api/auth/google/callback", origin);
    callbackUrl.searchParams.set("code", "mock-google-code");
    callbackUrl.searchParams.set("state", stateStr);
    return NextResponse.redirect(callbackUrl);
  }

  const url = new URL("https://accounts.google.com/o/oauth2/v2/auth");
  url.searchParams.set("client_id", clientId);
  url.searchParams.set("redirect_uri", redirectUri);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", "openid email profile");
  url.searchParams.set("prompt", "select_account");
  url.searchParams.set("state", stateStr);

  return NextResponse.redirect(url);
}

