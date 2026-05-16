import type { Request, Response } from "express";
import { env } from "../config/env";
import { prisma } from "../config/database";
import { verifyPassword } from "../utils/password";
import { createAccessToken } from "../utils/token";

export async function sendOtp(_req: Request, res: Response) {
  res.json({ success: true, message: "OTP send endpoint ready" });
}

export async function verifyOtp(_req: Request, res: Response) {
  res.json({ success: true, message: "OTP verify endpoint ready" });
}

export async function adminLogin(req: Request, res: Response) {
  const email = typeof req.body.email === "string" ? req.body.email.trim() : "";
  const password =
    typeof req.body.password === "string" ? req.body.password : "";

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: "Email and password are required.",
    });
  }

  if (!env.jwtSecret) {
    return res.status(500).json({
      success: false,
      message: "JWT_SECRET is not configured.",
    });
  }

  const admin = await prisma.user.findFirst({
    where: {
      email: email.toLowerCase(),
      role: { in: ["admin", "super_admin"] },
    },
    select: {
      id: true,
      email: true,
      phone: true,
      role: true,
      isActive: true,
      isBanned: true,
      passwordHash: true,
    },
  });

  if (
    !admin ||
    !admin.passwordHash ||
    !admin.isActive ||
    admin.isBanned ||
    !verifyPassword(password, admin.passwordHash)
  ) {
    return res.status(401).json({
      success: false,
      message: "Invalid email or password.",
    });
  }

  const token = createAccessToken(
    {
      sub: admin.id.toString(),
      role: admin.role,
      email: admin.email,
    },
    env.jwtSecret,
  );

  return res.json({
    success: true,
    token,
    admin: {
      id: admin.id.toString(),
      email: admin.email,
      phone: admin.phone,
      role: admin.role,
    },
  });
}
