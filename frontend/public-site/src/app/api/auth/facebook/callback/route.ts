import { NextResponse } from "next/server";

export function GET(request: Request) {
  const origin = new URL(request.url).origin;

  return NextResponse.redirect(
    new URL("/login?error=facebook-callback-needs-provider-token-exchange", origin),
  );
}
