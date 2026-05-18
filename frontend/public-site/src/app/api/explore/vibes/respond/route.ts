import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

export async function POST(request: Request) {
  try {
    const response = await fetch(`${backendUrl}/api/explore/vibes/respond`, {
      method: "POST",
      headers: {
        "Content-Type": request.headers.get("content-type") || "application/json",
        Authorization: request.headers.get("authorization") || "",
        Cookie: request.headers.get("cookie") || "",
      },
      body: await request.text(),
      cache: "no-store",
    });
    const text = await response.text();

    return new NextResponse(text || JSON.stringify({ success: response.ok }), {
      status: response.status,
      headers: { "Content-Type": response.headers.get("content-type") || "application/json" },
    });
  } catch (error) {
    console.error("Vibes response proxy failed", error);

    return NextResponse.json({ success: false, message: "Unable to reach Vibes." }, { status: 502 });
  }
}
