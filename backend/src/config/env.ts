import "dotenv/config";

export const env = {
  nodeEnv: process.env.NODE_ENV ?? "development",
  port: Number(process.env.PORT ?? 8000),
  databaseUrl: process.env.DATABASE_URL ?? "",
  jwtSecret: process.env.JWT_SECRET ?? "",
  publicWebUrl: process.env.PUBLIC_WEB_URL ?? "http://localhost:3000",
  redisUrl: process.env.REDIS_URL ?? "",
  cdnUrl: process.env.CDN_URL ?? "",
};
