import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

export async function POST(request: Request) {
  let response: Response;

  try {
    response = await fetch(`${backendUrl}/api/swipe`, {
      method: "POST",
      headers: {
        "Content-Type": request.headers.get("content-type") || "application/json",
        Authorization: request.headers.get("authorization") || "",
        Cookie: request.headers.get("cookie") || "",
      },
      body: await request.text(),
      cache: "no-store",
    });
  } catch (error) {
    console.error("Swipe API proxy failed", error);

    return NextResponse.json(
      { success: false, message: "Unable to reach the swipe service." },
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
