import { Router } from "express";
import { prisma } from "../config/database";
import { authRouter } from "./auth.routes";
import { completeOnboarding, profileRouter } from "./profile.routes";
import { profilesRouter } from "./profiles.routes";
import { requireAuth } from "../middleware/auth.middleware";

export const apiRouter = Router();

apiRouter.get("/health", (_req, res) => {
  res.json({ success: true, service: "yaro0-api" });
});

apiRouter.get("/health/db", async (_req, res, next) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ success: true, database: "postgresql", status: "connected" });
  } catch (error) {
    next(error);
  }
});

apiRouter.use("/auth", authRouter);
apiRouter.use("/profile", profileRouter);
apiRouter.patch("/onboarding/complete", requireAuth, completeOnboarding);
apiRouter.use("/profiles", profilesRouter);
