import { proxyAuthRequest } from "../../backend";

export async function POST(request: Request) {
  return proxyAuthRequest("/api/auth/oauth/facebook", request);
}
