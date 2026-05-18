import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

type RouteContext = {
  params: Promise<{ path: string[] }>;
};

async function proxyProfileRequest(request: Request, context: RouteContext) {
  const { path } = await context.params;
  const targetPath = `/api/profile/${path.join("/")}`;
  const body = request.method === "GET" ? undefined : await request.text();
  let response: Response;

  try {
    response = await fetch(`${backendUrl}${targetPath}`, {
      method: request.method,
      headers: {
        "Content-Type": request.headers.get("content-type") || "application/json",
        Authorization: request.headers.get("authorization") || "",
        Cookie: request.headers.get("cookie") || "",
      },
      body,
      cache: "no-store",
    });
  } catch (error) {
    console.error(`Profile API proxy failed for ${targetPath}`, error);

    return NextResponse.json(
      { success: false, message: "Unable to reach the profile service." },
      { status: 502 },
    );
  }

  const text = await response.text();
  const contentType = response.headers.get("content-type") || "application/json";

  const fallbackBody = JSON.stringify({
    success: response.ok,
    message: response.ok ? "" : "Profile service returned an empty response.",
  });

  return new NextResponse(text || fallbackBody, {
    status: response.status,
    headers: {
      "Content-Type": text ? contentType : "application/json",
    },
  });
}

export async function GET(request: Request, context: RouteContext) {
  return proxyProfileRequest(request, context);
}

export async function POST(request: Request, context: RouteContext) {
  return proxyProfileRequest(request, context);
}

export async function PUT(request: Request, context: RouteContext) {
  return proxyProfileRequest(request, context);
}

export async function PATCH(request: Request, context: RouteContext) {
  return proxyProfileRequest(request, context);
}

export async function DELETE(request: Request, context: RouteContext) {
  return proxyProfileRequest(request, context);
}
