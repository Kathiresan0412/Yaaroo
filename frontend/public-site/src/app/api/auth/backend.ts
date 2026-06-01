import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

function splitSetCookieHeader(header: string) {
  return header.split(/,(?=\s*[^;,]+=)/).map((cookie) => cookie.trim());
}

export function appendSetCookieHeaders(target: Headers, source: Headers) {
  const headersWithCookies = source as Headers & { getSetCookie?: () => string[] };
  const cookies = headersWithCookies.getSetCookie?.() ?? splitSetCookieHeader(source.get("set-cookie") || "");

  for (const cookie of cookies) {
    if (cookie) {
      target.append("set-cookie", cookie);
    }
  }
}

export async function proxyAuthRequest(
  path: string,
  request: Request,
  init: RequestInit = {},
) {
  const body = init.body ?? (request.method === "GET" ? undefined : await request.text());
  let response: Response;

  try {
    response = await fetch(`${backendUrl}${path}`, {
      ...init,
      method: init.method || request.method,
      headers: {
        "Content-Type": "application/json",
        Cookie: request.headers.get("cookie") || "",
        ...(init.headers || {}),
      },
      body,
      cache: "no-store",
    });
  } catch (error) {
    console.error(`Auth API proxy failed for ${path}`, error);

    return NextResponse.json(
      { success: false, message: "Unable to reach the authentication service." },
      { status: 502 },
    );
  }

  const text = await response.text();
  const fallbackBody = JSON.stringify({
    success: response.ok,
    message: response.ok ? "" : "Authentication service returned an empty response.",
  });
  const nextResponse = new NextResponse(text || fallbackBody, {
    status: response.status,
    headers: {
      "Content-Type": text ? response.headers.get("content-type") || "application/json" : "application/json",
      "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0",
    },
  });
  appendSetCookieHeaders(nextResponse.headers, response.headers);

  return nextResponse;
}
