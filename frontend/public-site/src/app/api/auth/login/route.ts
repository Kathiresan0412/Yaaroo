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
    return NextResponse.json({ message: "Send the login request as JSON." }, { status: 400 });
  }

  const data = body as Record<string, unknown> | null;
  const email = cleanText(data?.email).toLowerCase();
  const password = cleanText(data?.password);

  if (!email || !isEmail(email)) {
    return NextResponse.json({ message: "Enter a valid email address." }, { status: 400 });
  }

  if (!password) {
    return NextResponse.json({ message: "Password is required." }, { status: 400 });
  }

  return NextResponse.json({ message: "Login API is ready for backend authentication." });
}
