import { NextResponse } from "next/server";
import { appendSetCookieHeaders } from "../../backend";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

function redirectWithCookies(url: URL, response: Response) {
  const redirect = NextResponse.redirect(url);
  appendSetCookieHeaders(redirect.headers, response.headers);

  return redirect;
}

function mobileRedirect(error: string) {
  return NextResponse.redirect(`yaaro0://oauth/tiktok?error=${encodeURIComponent(error)}`);
}

function mobileSuccessRedirect(payload: unknown) {
  const encoded = Buffer.from(JSON.stringify(payload), "utf8").toString("base64url");
  return NextResponse.redirect(`yaaro0://oauth/tiktok?payload=${encoded}`);
}

export async function GET(request: Request) {
  const url = new URL(request.url);
  const origin = url.origin;
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state") || "";
  const isMobile = state.startsWith("mobile:");
  const clientKey = process.env.TIKTOK_CLIENT_KEY;
  const clientSecret = process.env.TIKTOK_CLIENT_SECRET;
  const redirectUri =
    process.env.TIKTOK_REDIRECT_URI || `${origin}/api/auth/tiktok/callback`;

  const fail = (error: string) =>
    isMobile
      ? mobileRedirect(error)
      : NextResponse.redirect(new URL(`/login?error=${error}`, origin));

  if (!code || !clientKey || !clientSecret) {
    return fail("tiktok-callback");
  }

  let tokenResponse: Response;

  try {
    tokenResponse = await fetch("https://open.tiktokapis.com/v2/oauth/token/", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_key: clientKey,
        client_secret: clientSecret,
        code,
        grant_type: "authorization_code",
        redirect_uri: redirectUri,
      }),
    });
  } catch (error) {
    console.error("TikTok token request failed", error);
    return fail("tiktok-token");
  }

  const tokenPayload = (await tokenResponse.json()) as { access_token?: string };

  if (!tokenResponse.ok || !tokenPayload.access_token) {
    return fail("tiktok-token");
  }

  let profileResponse: Response;

  try {
    profileResponse = await fetch(
      "https://open.tiktokapis.com/v2/user/info/?fields=open_id,display_name,avatar_url",
      {
        headers: { Authorization: `Bearer ${tokenPayload.access_token}` },
      },
    );
  } catch (error) {
    console.error("TikTok profile request failed", error);
    return fail("tiktok-profile");
  }

  const profilePayload = (await profileResponse.json()) as {
    data?: {
      user?: {
        open_id?: string;
        display_name?: string;
      };
    };
  };
  const profile = profilePayload.data?.user;

  if (!profileResponse.ok || !profile?.open_id) {
    return fail("tiktok-profile");
  }

  const displayName = profile.display_name?.trim() || "TikTok User";

  let authResponse: Response;

  try {
    authResponse = await fetch(`${backendUrl}/api/auth/oauth/tiktok`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        oauthId: profile.open_id,
        email: `${profile.open_id}@tiktok.yaaro0.local`,
        firstName: displayName,
        lastName: "",
      }),
    });
  } catch (error) {
    console.error("TikTok backend login failed", error);
    return fail("tiktok-login");
  }

  const authPayload = (await authResponse.json()) as { redirectTo?: string };

  if (!authResponse.ok) {
    return fail("tiktok-login");
  }

  if (isMobile) {
    return mobileSuccessRedirect(authPayload);
  }

  return redirectWithCookies(new URL(authPayload.redirectTo || "/onboarding", origin), authResponse);
}
