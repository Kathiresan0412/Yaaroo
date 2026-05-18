import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

type RouteContext = {
  params: Promise<{ path: string[] }>;
};

async function proxyProfileRequest(request: Request, context: RouteContext) {
  const { path } = await context.params;
  const targetPath = `/api/profile/${path.join("/")}`;
  const body = request.method === "GET" ? undefined : await request.text();
  const response = await fetch(`${backendUrl}${targetPath}`, {
    method: request.method,
    headers: {
      "Content-Type": request.headers.get("content-type") || "application/json",
      Authorization: request.headers.get("authorization") || "",
      Cookie: request.headers.get("cookie") || "",
    },
    body,
    cache: "no-store",
  });
  const text = await response.text();

  return new NextResponse(text, {
    status: response.status,
    headers: {
      "Content-Type": response.headers.get("content-type") || "application/json",
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
