import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

type RouteContext = {
  params: Promise<{ matchId: string }>;
};

export async function POST(request: Request, context: RouteContext) {
  const { matchId } = await context.params;
  let response: Response;

  try {
    response = await fetch(`${backendUrl}/api/messages/${matchId}/voice`, {
      method: "POST",
      headers: {
        Authorization: request.headers.get("authorization") || "",
        Cookie: request.headers.get("cookie") || "",
      },
      body: await request.formData(),
      cache: "no-store",
    });
  } catch (error) {
    console.error("Voice message API proxy failed", error);

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
