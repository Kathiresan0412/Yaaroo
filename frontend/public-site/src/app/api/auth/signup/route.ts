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
    return NextResponse.json({ message: "Send the signup request as JSON." }, { status: 400 });
  }

  const data = body as Record<string, unknown> | null;
  const name = cleanText(data?.name);
  const email = cleanText(data?.email).toLowerCase();
  const password = cleanText(data?.password);

  if (!name || !email || !password) {
    return NextResponse.json({ message: "Please complete all required fields." }, { status: 400 });
  }

  if (!isEmail(email)) {
    return NextResponse.json({ message: "Enter a valid email address." }, { status: 400 });
  }

  if (password.length < 8) {
    return NextResponse.json(
      { message: "Password must be at least 8 characters." },
      { status: 400 },
    );
  }

  return NextResponse.json(
    {
      message: "Signup API is ready for account creation.",
      user: { name, email },
    },
    { status: 201 },
  );
}
