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
  return NextResponse.redirect(`yaaro0://oauth/facebook?error=${encodeURIComponent(error)}`);
}

function mobileSuccessRedirect(payload: unknown) {
  const encoded = Buffer.from(JSON.stringify(payload), "utf8").toString("base64url");
  return NextResponse.redirect(`yaaro0://oauth/facebook?payload=${encoded}`);
}

export async function GET(request: Request) {
  const url = new URL(request.url);
  const origin = url.origin;
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state") || "";
  const stateParts = state.split(":");
  const isMobile = stateParts[0] === "mobile";
  const linkUserId = stateParts[1] === "link" ? stateParts[2] : "";
  const clientId = process.env.FACEBOOK_CLIENT_ID;
  const clientSecret = process.env.FACEBOOK_CLIENT_SECRET;
  const redirectUri =
    process.env.FACEBOOK_REDIRECT_URI || `${origin}/api/auth/facebook/callback`;

  const fail = (error: string) =>
    isMobile
      ? mobileRedirect(error)
      : NextResponse.redirect(new URL(`/login?error=${error}`, origin));

  const isSandboxMode = !clientId && code === "mock-facebook-code";

  if (!code || (!isSandboxMode && (!clientId || !clientSecret))) {
    return fail("facebook-callback");
  }

  let profile = {
    id: "",
    email: "",
    first_name: "",
    last_name: "",
  };

  if (isSandboxMode) {
    console.log("Processing mock Facebook Sandbox Mode login...");
    profile = {
      id: "mock-facebook-oauth-id-12345",
      email: "sandbox-facebook-user@yaaro0.local",
      first_name: "Facebook Sandbox",
      last_name: "User",
    };
  } else {
    const tokenUrl = new URL("https://graph.facebook.com/v19.0/oauth/access_token");
    tokenUrl.searchParams.set("client_id", clientId!);
    tokenUrl.searchParams.set("client_secret", clientSecret!);
    tokenUrl.searchParams.set("redirect_uri", redirectUri);
    tokenUrl.searchParams.set("code", code!);

    let tokenResponse: Response;

    try {
      tokenResponse = await fetch(tokenUrl);
    } catch (error) {
      console.error("Facebook token request failed", error);
      return fail("facebook-token");
    }

    const tokenPayload = (await tokenResponse.json()) as { access_token?: string };

    if (!tokenResponse.ok || !tokenPayload.access_token) {
      return fail("facebook-token");
    }

    const profileUrl = new URL("https://graph.facebook.com/me");
    profileUrl.searchParams.set("fields", "id,email,first_name,last_name");
    profileUrl.searchParams.set("access_token", tokenPayload.access_token);

    let profileResponse: Response;

    try {
      profileResponse = await fetch(profileUrl);
    } catch (error) {
      console.error("Facebook profile request failed", error);
      return fail("facebook-profile");
    }

    const fetchedProfile = (await profileResponse.json()) as {
      id?: string;
      email?: string;
      first_name?: string;
      last_name?: string;
    };

    if (!profileResponse.ok || !fetchedProfile.id || !fetchedProfile.email) {
      return fail("facebook-profile");
    }

    profile = {
      id: fetchedProfile.id,
      email: fetchedProfile.email,
      first_name: fetchedProfile.first_name || "Facebook",
      last_name: fetchedProfile.last_name || "User",
    };
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
        userId: linkUserId || undefined,
      }),
    });
  } catch (error) {
    console.error("Facebook backend login failed", error);
    return fail("facebook-login");
  }

  const authPayload = (await authResponse.json()) as { redirectTo?: string };

  if (!authResponse.ok) {
    return fail("facebook-login");
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
