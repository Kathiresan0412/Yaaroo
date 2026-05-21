import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

type RouteContext = {
  params: Promise<{ userId: string }>;
};

export async function GET(request: Request, context: RouteContext) {
  const { userId } = await context.params;
  let response: Response;

  try {
    response = await fetch(`${backendUrl}/api/users/${userId}/profile`, {
      method: "GET",
      headers: {
        Authorization: request.headers.get("authorization") || "",
        Cookie: request.headers.get("cookie") || "",
      },
      cache: "no-store",
    });
  } catch (error) {
    console.error("Public profile API proxy failed", error);

    return NextResponse.json(
      { success: false, message: "Unable to reach the profile service." },
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
