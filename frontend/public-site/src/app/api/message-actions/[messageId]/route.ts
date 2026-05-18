import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

type RouteContext = {
  params: Promise<{ messageId: string }>;
};

async function proxy(request: Request, url: string, init: RequestInit = {}) {
  let response: Response;

  try {
    response = await fetch(url, {
      ...init,
      headers: {
        "Content-Type": "application/json",
        Authorization: request.headers.get("authorization") || "",
        Cookie: request.headers.get("cookie") || "",
        ...(init.headers || {}),
      },
      cache: "no-store",
    });
  } catch (error) {
    console.error("Message action proxy failed", error);

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

export async function DELETE(request: Request, context: RouteContext) {
  const { messageId } = await context.params;

  return proxy(request, `${backendUrl}/api/messages/${messageId}`, { method: "DELETE" });
}

export async function POST(request: Request, context: RouteContext) {
  const { messageId } = await context.params;
  const action = new URL(request.url).searchParams.get("action") || "react";

  return proxy(request, `${backendUrl}/api/messages/${messageId}/${action}`, {
    method: "POST",
    body: await request.text(),
  });
}
