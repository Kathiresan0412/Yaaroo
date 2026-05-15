import { Router } from "express";
import { sendOtp, verifyOtp } from "../controllers/auth.controller";

export const authRouter = Router();

authRouter.post("/otp/send", sendOtp);
authRouter.post("/otp/verify", verifyOtp);
