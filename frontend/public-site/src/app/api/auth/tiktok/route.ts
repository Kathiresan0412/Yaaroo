import { NextResponse } from "next/server";

export function GET(request: Request) {
  const clientKey = process.env.TIKTOK_CLIENT_KEY;
  const requestUrl = new URL(request.url);
  const origin = requestUrl.origin;
  const redirectUri =
    process.env.TIKTOK_REDIRECT_URI || `${origin}/api/auth/tiktok/callback`;
  const isMobile = requestUrl.searchParams.get("mobile") === "1";
  const linkUserId = requestUrl.searchParams.get("link") || "";
  const stateStr = `${isMobile ? "mobile" : "web"}:${linkUserId ? `link:${linkUserId}` : "auth"}:${crypto.randomUUID()}`;

  // TikTok Sandbox Mode fallback for localhost/development when no client credentials exist
  if (!clientKey) {
    console.log("TIKTOK_CLIENT_KEY is not configured. Redirecting to Sandbox Mode callback...");
    const callbackUrl = new URL("/api/auth/tiktok/callback", origin);
    callbackUrl.searchParams.set("code", "mock-tiktok-code");
    callbackUrl.searchParams.set("state", stateStr);
    return NextResponse.redirect(callbackUrl);
  }

  const url = new URL("https://www.tiktok.com/v2/auth/authorize/");
  url.searchParams.set("client_key", clientKey);
  url.searchParams.set("redirect_uri", redirectUri);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", "user.info.basic");
  url.searchParams.set("state", stateStr);

  return NextResponse.redirect(url);
}

