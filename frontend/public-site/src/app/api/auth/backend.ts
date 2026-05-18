import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

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
    },
  });
  const setCookie = response.headers.get("set-cookie");

  if (setCookie) {
    nextResponse.headers.set("set-cookie", setCookie);
  }

  return nextResponse;
}
