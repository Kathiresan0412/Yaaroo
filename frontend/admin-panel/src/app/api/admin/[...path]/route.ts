import { NextRequest, NextResponse } from "next/server";

const backendAdminApiUrl =
  process.env.ADMIN_API_URL?.replace(/\/$/, "") ??
  "http://localhost:8000/admin/api";

type RouteContext = {
  params: Promise<{
    path?: string[];
  }>;
};

async function proxyAdminRequest(request: NextRequest, context: RouteContext) {
  const { path = [] } = await context.params;
  const targetUrl = new URL(`${backendAdminApiUrl}/${path.map(encodeURIComponent).join("/")}`);
  targetUrl.search = request.nextUrl.search;

  const headers = new Headers(request.headers);
  headers.delete("host");

  const response = await fetch(targetUrl, {
    method: request.method,
    headers,
    body: request.method === "GET" || request.method === "HEAD" ? undefined : await request.text(),
    cache: "no-store",
  });

  return new NextResponse(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
  });
}

export async function GET(request: NextRequest, context: RouteContext) {
  return proxyAdminRequest(request, context);
}

export async function POST(request: NextRequest, context: RouteContext) {
  return proxyAdminRequest(request, context);
}

export async function PUT(request: NextRequest, context: RouteContext) {
  return proxyAdminRequest(request, context);
}

export async function PATCH(request: NextRequest, context: RouteContext) {
  return proxyAdminRequest(request, context);
}

export async function DELETE(request: NextRequest, context: RouteContext) {
  return proxyAdminRequest(request, context);
}
