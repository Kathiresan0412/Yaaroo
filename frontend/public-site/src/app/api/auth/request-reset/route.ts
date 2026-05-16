import { NextResponse } from "next/server";

function cleanText(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function isEmail(value: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

export async function POST(request: Request) {
  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ message: "Send the reset request as JSON." }, { status: 400 });
  }

  const email = cleanText((body as Record<string, unknown> | null)?.email).toLowerCase();

  if (!email || !isEmail(email)) {
    return NextResponse.json({ message: "Enter a valid email address." }, { status: 400 });
  }

  return NextResponse.json({
    message: "If that email exists, a password reset link has been sent.",
  });
}
