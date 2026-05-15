import express from "express";
import { apiRouter } from "./routes";
import { errorMiddleware } from "./middleware/error.middleware";

export const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use("/api/v1", apiRouter);

app.use(errorMiddleware);
