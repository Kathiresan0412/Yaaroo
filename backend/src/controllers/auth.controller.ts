import type { Request, Response } from "express";

export async function sendOtp(_req: Request, res: Response) {
  res.json({ success: true, message: "OTP send endpoint ready" });
}

export async function verifyOtp(_req: Request, res: Response) {
  res.json({ success: true, message: "OTP verify endpoint ready" });
}
