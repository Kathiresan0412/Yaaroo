import { NextResponse } from "next/server";
import { appendSetCookieHeaders } from "../../backend";
import { cookies } from "next/headers";

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

  // Determine if we should run in mock Sandbox Mode (if client Key is missing and we received the mock code)
  const isSandboxMode = !clientKey && code === "mock-tiktok-code";

  if (!code || (!isSandboxMode && (!clientKey || !clientSecret))) {
    return fail("tiktok-callback");
  }

  let profile = {
    open_id: "",
    display_name: "",
  };

  if (isSandboxMode) {
    console.log("Processing mock TikTok Sandbox Mode login...");
    profile = {
      open_id: "mock-tiktok-oauth-id-12345",
      display_name: "TikTok Sandbox User",
    };
  } else {
    let tokenResponse: Response;

    try {
      tokenResponse = await fetch("https://open.tiktokapis.com/v2/oauth/token/", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          client_key: clientKey!,
          client_secret: clientSecret!,
          code: code!,
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
    const fetchedProfile = profilePayload.data?.user;

    if (!profileResponse.ok || !fetchedProfile?.open_id) {
      return fail("tiktok-profile");
    }

    profile = {
      open_id: fetchedProfile.open_id,
      display_name: fetchedProfile.display_name?.trim() || "TikTok User",
    };
  }

  let authResponse: Response;

  try {
    authResponse = await fetch(`${backendUrl}/api/auth/oauth/tiktok`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        oauthId: profile.open_id,
        email: `${profile.open_id}@tiktok.yaaro0.local`,
        firstName: profile.display_name,
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

  // Next.js App Router sets cookies reliably using the cookies() helper before redirecting
  const cookieStore = await cookies();
  const rawCookies = authResponse.headers.getSetCookie?.() || [];
  for (const cookieStr of rawCookies) {
    const parts = cookieStr.split(";").map((p) => p.trim());
    const [nameValue, ...directives] = parts;
    const eqIdx = nameValue.indexOf("=");
    if (eqIdx !== -1) {
      const name = nameValue.substring(0, eqIdx);
      const value = decodeURIComponent(nameValue.substring(eqIdx + 1));

      const options: any = { path: "/" };
      for (const dir of directives) {
        const lowerDir = dir.toLowerCase();
        if (lowerDir.startsWith("max-age=")) {
          options.maxAge = parseInt(dir.substring(8), 10);
        } else if (lowerDir.startsWith("path=")) {
          options.path = dir.substring(5);
        } else if (lowerDir === "httponly") {
          options.httpOnly = true;
        } else if (lowerDir === "secure") {
          options.secure = true;
        } else if (lowerDir.startsWith("samesite=")) {
          options.sameSite = dir.substring(9).toLowerCase();
        }
      }
      cookieStore.set(name, value, options);
    }
  }

  return NextResponse.redirect(new URL(authPayload.redirectTo || "/onboarding", origin));
}
