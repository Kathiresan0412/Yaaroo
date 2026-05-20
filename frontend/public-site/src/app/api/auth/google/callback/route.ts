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
  const origin = url.origin;
  const code = url.searchParams.get("code");
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
  const redirectUri =
    process.env.GOOGLE_REDIRECT_URI || `${origin}/api/auth/google/callback`;

  if (!code || !clientId || !clientSecret) {
    return NextResponse.redirect(new URL("/login?error=google-callback", origin));
  }

  let tokenResponse: Response;

  try {
    tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        code,
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirectUri,
        grant_type: "authorization_code",
      }),
    });
  } catch (error) {
    console.error("Google token request failed", error);
    return NextResponse.redirect(new URL("/login?error=google-token", origin));
  }

  const tokenPayload = (await tokenResponse.json()) as { access_token?: string };

  if (!tokenResponse.ok || !tokenPayload.access_token) {
    return NextResponse.redirect(new URL("/login?error=google-token", origin));
  }

  let profileResponse: Response;

  try {
    profileResponse = await fetch("https://www.googleapis.com/oauth2/v2/userinfo", {
      headers: { Authorization: `Bearer ${tokenPayload.access_token}` },
    });
  } catch (error) {
    console.error("Google profile request failed", error);
    return NextResponse.redirect(new URL("/login?error=google-profile", origin));
  }

  const profile = (await profileResponse.json()) as {
    id?: string;
    email?: string;
    given_name?: string;
    family_name?: string;
  };

  if (!profileResponse.ok || !profile.id || !profile.email) {
    return NextResponse.redirect(new URL("/login?error=google-profile", origin));
  }

  let authResponse: Response;

  try {
    authResponse = await fetch(`${backendUrl}/api/auth/oauth/google`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        oauthId: profile.id,
        email: profile.email,
        firstName: profile.given_name,
        lastName: profile.family_name,
      }),
    });
  } catch (error) {
    console.error("Google backend login failed", error);
    return NextResponse.redirect(new URL("/login?error=google-login", origin));
  }

  const authPayload = (await authResponse.json()) as { redirectTo?: string };

  if (!authResponse.ok) {
    return NextResponse.redirect(new URL("/login?error=google-login", origin));
  }

  return redirectWithCookies(new URL(authPayload.redirectTo || "/onboarding", origin), authResponse);
}
