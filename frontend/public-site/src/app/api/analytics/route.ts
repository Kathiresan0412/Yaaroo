import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

export async function POST(request: Request) {
  let response: Response;

  try {
    response = await fetch(`${backendUrl}/api/analytics`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: request.headers.get("authorization") || "",
        Cookie: request.headers.get("cookie") || "",
      },
      body: await request.text(),
      cache: "no-store",
    });
  } catch (error) {
    console.error("Analytics API proxy failed", error);

    return NextResponse.json({ success: true, queued: false }, { status: 202 });
  }

  return NextResponse.json({ success: response.ok }, { status: response.ok ? 202 : 204 });
}
