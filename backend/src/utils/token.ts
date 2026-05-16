import { createHmac } from "node:crypto";

type TokenPayload = {
  sub: string;
  role: string;
  email: string | null;
  exp: number;
  iat: number;
};

function base64UrlEncode(value: object | string) {
  const input = typeof value === "string" ? value : JSON.stringify(value);

  return Buffer.from(input).toString("base64url");
}

export function createAccessToken(
  payload: Omit<TokenPayload, "exp" | "iat">,
  secret: string,
) {
  const now = Math.floor(Date.now() / 1000);
  const tokenPayload: TokenPayload = {
    ...payload,
    iat: now,
    exp: now + 60 * 60 * 8,
  };

  const header = base64UrlEncode({ alg: "HS256", typ: "JWT" });
  const body = base64UrlEncode(tokenPayload);
  const signature = createHmac("sha256", secret)
    .update(`${header}.${body}`)
    .digest("base64url");

  return `${header}.${body}.${signature}`;
}
