import { Router } from "express";
import { adminLogin, sendOtp, verifyOtp } from "../controllers/auth.controller";

export const authRouter = Router();

authRouter.post("/admin/login", adminLogin);
authRouter.post("/otp/send", sendOtp);
authRouter.post("/otp/verify", verifyOtp);
