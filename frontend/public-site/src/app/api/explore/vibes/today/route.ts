import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

export async function GET(request: Request) {
  try {
    const response = await fetch(`${backendUrl}/api/explore/vibes/today`, {
      headers: {
        Authorization: request.headers.get("authorization") || "",
        Cookie: request.headers.get("cookie") || "",
      },
      cache: "no-store",
    });
    const text = await response.text();

    return new NextResponse(text || JSON.stringify({ success: response.ok }), {
      status: response.status,
      headers: { "Content-Type": response.headers.get("content-type") || "application/json" },
    });
  } catch (error) {
    console.error("Vibes today proxy failed", error);

    return NextResponse.json({ success: false, message: "Unable to reach Vibes." }, { status: 502 });
  }
}
