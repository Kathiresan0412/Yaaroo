import { NextResponse } from "next/server";

function cleanText(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

export async function POST(request: Request) {
  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ message: "Send the password reset as JSON." }, { status: 400 });
  }

  const data = body as Record<string, unknown> | null;
  const token = cleanText(data?.token);
  const password = cleanText(data?.password);

  if (!token) {
    return NextResponse.json({ message: "Reset token is required." }, { status: 400 });
  }

  if (password.length < 8) {
    return NextResponse.json(
      { message: "Password must be at least 8 characters." },
      { status: 400 },
    );
  }

  return NextResponse.json({ message: "Your password has been updated." });
}
