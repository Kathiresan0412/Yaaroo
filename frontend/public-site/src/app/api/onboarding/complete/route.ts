import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

export async function PATCH(request: Request) {
  let response: Response;

  try {
    response = await fetch(`${backendUrl}/api/onboarding/complete`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: request.headers.get("authorization") || "",
        Cookie: request.headers.get("cookie") || "",
      },
      body: await request.text(),
      cache: "no-store",
    });
  } catch (error) {
    console.error("Onboarding API proxy failed", error);

    return NextResponse.json(
      { success: false, message: "Unable to reach the onboarding service." },
      { status: 502 },
    );
  }

  const text = await response.text();
  const fallbackBody = JSON.stringify({
    success: response.ok,
    message: response.ok ? "" : "Onboarding service returned an empty response.",
  });

  return new NextResponse(text || fallbackBody, {
    status: response.status,
    headers: {
      "Content-Type": text ? response.headers.get("content-type") || "application/json" : "application/json",
    },
  });
}
