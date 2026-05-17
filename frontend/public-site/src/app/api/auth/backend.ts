import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

export async function proxyAuthRequest(
  path: string,
  request: Request,
  init: RequestInit = {},
) {
  const body = init.body ?? (request.method === "GET" ? undefined : await request.text());
  const response = await fetch(`${backendUrl}${path}`, {
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

  const text = await response.text();
  const nextResponse = new NextResponse(text, {
    status: response.status,
    headers: {
      "Content-Type": response.headers.get("content-type") || "application/json",
    },
  });
  const setCookie = response.headers.get("set-cookie");

  if (setCookie) {
    nextResponse.headers.set("set-cookie", setCookie);
  }

  return nextResponse;
}
