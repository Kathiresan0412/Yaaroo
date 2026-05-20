import { NextResponse } from "next/server";
import { appendSetCookieHeaders } from "../../backend";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

function redirectWithCookies(url: URL, response: Response) {
  const redirect = NextResponse.redirect(url);
  appendSetCookieHeaders(redirect.headers, response.headers);

  return redirect;
}

export async function GET(request: Request) {
  const url = new URL(request.url);
  const origin = new URL(request.url).origin;
  const code = url.searchParams.get("code");
  const clientId = process.env.FACEBOOK_CLIENT_ID;
  const clientSecret = process.env.FACEBOOK_CLIENT_SECRET;
  const redirectUri =
    process.env.FACEBOOK_REDIRECT_URI || `${origin}/api/auth/facebook/callback`;

  if (!code || !clientId || !clientSecret) {
    return NextResponse.redirect(new URL("/login?error=facebook-callback", origin));
  }

  const tokenUrl = new URL("https://graph.facebook.com/v19.0/oauth/access_token");
  tokenUrl.searchParams.set("client_id", clientId);
  tokenUrl.searchParams.set("client_secret", clientSecret);
  tokenUrl.searchParams.set("redirect_uri", redirectUri);
  tokenUrl.searchParams.set("code", code);

  let tokenResponse: Response;

  try {
    tokenResponse = await fetch(tokenUrl);
  } catch (error) {
    console.error("Facebook token request failed", error);
    return NextResponse.redirect(new URL("/login?error=facebook-token", origin));
  }

  const tokenPayload = (await tokenResponse.json()) as { access_token?: string };

  if (!tokenResponse.ok || !tokenPayload.access_token) {
    return NextResponse.redirect(new URL("/login?error=facebook-token", origin));
  }

  const profileUrl = new URL("https://graph.facebook.com/me");
  profileUrl.searchParams.set("fields", "id,email,first_name,last_name");
  profileUrl.searchParams.set("access_token", tokenPayload.access_token);

  let profileResponse: Response;

  try {
    profileResponse = await fetch(profileUrl);
  } catch (error) {
    console.error("Facebook profile request failed", error);
    return NextResponse.redirect(new URL("/login?error=facebook-profile", origin));
  }

  const profile = (await profileResponse.json()) as {
    id?: string;
    email?: string;
    first_name?: string;
    last_name?: string;
  };

  if (!profileResponse.ok || !profile.id || !profile.email) {
    return NextResponse.redirect(new URL("/login?error=facebook-profile", origin));
  }

  let authResponse: Response;

  try {
    authResponse = await fetch(`${backendUrl}/api/auth/oauth/facebook`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        oauthId: profile.id,
        email: profile.email,
        firstName: profile.first_name,
        lastName: profile.last_name,
      }),
    });
  } catch (error) {
    console.error("Facebook backend login failed", error);
    return NextResponse.redirect(new URL("/login?error=facebook-login", origin));
  }

  const authPayload = (await authResponse.json()) as { redirectTo?: string };

  if (!authResponse.ok) {
    return NextResponse.redirect(new URL("/login?error=facebook-login", origin));
  }

  return redirectWithCookies(new URL(authPayload.redirectTo || "/onboarding", origin), authResponse);
}
