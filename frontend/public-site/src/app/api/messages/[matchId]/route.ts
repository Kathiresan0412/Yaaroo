import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

type RouteContext = {
  params: Promise<{ matchId: string }>;
};

function authHeaders(request: Request) {
  return {
    Authorization: request.headers.get("authorization") || "",
    Cookie: request.headers.get("cookie") || "",
  };
}

async function proxy(request: Request, url: string, init: RequestInit = {}) {
  let response: Response;

  try {
    response = await fetch(url, {
      ...init,
      headers: {
        ...authHeaders(request),
        ...(init.body instanceof FormData ? {} : { "Content-Type": "application/json" }),
        ...(init.headers || {}),
      },
      cache: "no-store",
    });
  } catch (error) {
    console.error("Messages API proxy failed", error);

    return NextResponse.json(
      { success: false, message: "Unable to reach the messaging service." },
      { status: 502 },
    );
  }

  const text = await response.text();

  return new NextResponse(text || JSON.stringify({ success: response.ok }), {
    status: response.status,
    headers: {
      "Content-Type": response.headers.get("content-type") || "application/json",
    },
  });
}

export async function GET(request: Request, context: RouteContext) {
  const { matchId } = await context.params;
  const sourceUrl = new URL(request.url);
  const targetUrl = new URL(`${backendUrl}/api/messages/${matchId}`);
  sourceUrl.searchParams.forEach((value, key) => targetUrl.searchParams.set(key, value));

  return proxy(request, targetUrl.toString(), { method: "GET" });
}

export async function POST(request: Request, context: RouteContext) {
  const { matchId } = await context.params;

  return proxy(request, `${backendUrl}/api/messages/${matchId}`, {
    method: "POST",
    body: await request.text(),
  });
}
