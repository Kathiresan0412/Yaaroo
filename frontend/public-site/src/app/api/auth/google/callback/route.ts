import { NextResponse } from "next/server";

export function GET(request: Request) {
  const url = new URL(request.url);
  const origin = url.origin;
  const code = url.searchParams.get("code");

  if (!code) {
    return NextResponse.redirect(new URL("/login?error=google-callback", origin));
  }

  return NextResponse.redirect(new URL("/login?connected=google", origin));
}
