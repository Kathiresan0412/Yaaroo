import { NextResponse } from "next/server";

const intents = new Set(["dating", "friendship", "matrimony"]);

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
    return NextResponse.json(
      { message: "Send the account request as JSON." },
      { status: 400 },
    );
  }

  if (!body || typeof body !== "object") {
    return NextResponse.json(
      { message: "Please complete all required fields." },
      { status: 400 },
    );
  }

  const data = body as Record<string, unknown>;
  const name = cleanText(data.name);
  const email = cleanText(data.email).toLowerCase();
  const city = cleanText(data.city);
  const intent = cleanText(data.intent);

  if (!name || !email || !city || !intent) {
    return NextResponse.json(
      { message: "Please complete all required fields." },
      { status: 400 },
    );
  }

  if (!isEmail(email)) {
    return NextResponse.json(
      { message: "Enter a valid email address." },
      { status: 400 },
    );
  }

  if (!intents.has(intent)) {
    return NextResponse.json(
      { message: "Choose a valid account type." },
      { status: 400 },
    );
  }

  return NextResponse.json(
    {
      message: "Account request received.",
      request: {
        name,
        email,
        city,
        intent,
      },
    },
    { status: 201 },
  );
}
