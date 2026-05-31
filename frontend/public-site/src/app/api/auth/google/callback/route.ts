import { NextResponse } from "next/server";
import { appendSetCookieHeaders } from "../../backend";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

function redirectWithCookies(url: URL, response: Response) {
  const redirect = NextResponse.redirect(url);
  appendSetCookieHeaders(redirect.headers, response.headers);

  return redirect;
}

function mobileRedirect(error: string) {
  return NextResponse.redirect(`yaaro0://oauth/google?error=${encodeURIComponent(error)}`);
}

function mobileSuccessRedirect(payload: unknown) {
  const encoded = Buffer.from(JSON.stringify(payload), "utf8").toString("base64url");
  return NextResponse.redirect(`yaaro0://oauth/google?payload=${encoded}`);
}

export async function GET(request: Request) {
  const url = new URL(request.url);
  const origin = url.origin;
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state") || "";
  const isMobile = state.startsWith("mobile:");
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
  const redirectUri =
    process.env.GOOGLE_REDIRECT_URI || `${origin}/api/auth/google/callback`;

  const fail = (error: string) =>
    isMobile
      ? mobileRedirect(error)
      : NextResponse.redirect(new URL(`/login?error=${error}`, origin));

  // Determine if we should run in mock Sandbox Mode (if client ID is missing and we received the mock code)
  const isSandboxMode = !clientId && code === "mock-google-code";

  if (!code || (!isSandboxMode && !clientId)) {
    return fail("google-callback");
  }

  let profile = {
    id: "",
    email: "",
    given_name: "",
    family_name: "",
  };

  if (isSandboxMode) {
    console.log("Processing mock Sandbox Mode login...");
    profile = {
      id: "mock-google-oauth-id-12345",
      email: "sandbox-google-user@yaaro0.local",
      given_name: "Google Sandbox",
      family_name: "User",
    };
  } else {
    let tokenResponse: Response;

    const bodyParams = new URLSearchParams({
      code: code!,
      client_id: clientId!,
      redirect_uri: redirectUri,
      grant_type: "authorization_code",
    });
    if (clientSecret) {
      bodyParams.set("client_secret", clientSecret);
    }

    try {
      tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: bodyParams,
      });
    } catch (error) {
      console.error("Google token request failed", error);
      return fail("google-token");
    }

    const tokenPayload = (await tokenResponse.json()) as { access_token?: string };

    if (!tokenResponse.ok || !tokenPayload.access_token) {
      return fail("google-token");
    }

    let profileResponse: Response;

    try {
      profileResponse = await fetch("https://www.googleapis.com/oauth2/v2/userinfo", {
        headers: { Authorization: `Bearer ${tokenPayload.access_token}` },
      });
    } catch (error) {
      console.error("Google profile request failed", error);
      return fail("google-profile");
    }

    const fetchedProfile = (await profileResponse.json()) as {
      id?: string;
      email?: string;
      given_name?: string;
      family_name?: string;
    };

    if (!profileResponse.ok || !fetchedProfile.id || !fetchedProfile.email) {
      return fail("google-profile");
    }

    profile = {
      id: fetchedProfile.id,
      email: fetchedProfile.email,
      given_name: fetchedProfile.given_name || "Google",
      family_name: fetchedProfile.family_name || "User",
    };
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
    return fail("google-login");
  }

  const authPayload = (await authResponse.json()) as { redirectTo?: string };

  if (!authResponse.ok) {
    return fail("google-login");
  }

  if (isMobile) {
    return mobileSuccessRedirect(authPayload);
  }

  return redirectWithCookies(new URL(authPayload.redirectTo || "/onboarding", origin), authResponse);
}

