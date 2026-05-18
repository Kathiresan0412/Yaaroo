import { NextResponse } from "next/server";

const backendUrl = process.env.YAARO0_API_URL || "http://127.0.0.1:8000";

export async function PATCH(request: Request) {
  const response = await fetch(`${backendUrl}/api/onboarding/complete`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      Authorization: request.headers.get("authorization") || "",
      Cookie: request.headers.get("cookie") || "",
    },
    body: await request.text(),
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
