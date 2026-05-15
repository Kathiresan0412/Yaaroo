import { Router } from "express";
import { authRouter } from "./auth.routes";

export const apiRouter = Router();

apiRouter.get("/health", (_req, res) => {
  res.json({ success: true, service: "yaro0-api" });
});

apiRouter.use("/auth", authRouter);
