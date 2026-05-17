import { proxyAuthRequest } from "../../backend";

type Params = {
  params: Promise<{ token: string }>;
};

export async function GET(request: Request, { params }: Params) {
  const { token } = await params;

  return proxyAuthRequest(`/api/auth/verify-email/${encodeURIComponent(token)}`, request, {
    method: "GET",
  });
}
