import "dotenv/config";

export const env = {
  nodeEnv: process.env.NODE_ENV ?? "development",
  port: Number(process.env.PORT ?? 8000),
  databaseUrl: process.env.DATABASE_URL ?? "",
  jwtSecret: process.env.JWT_SECRET ?? "",
  redisUrl: process.env.REDIS_URL ?? "",
  cdnUrl: process.env.CDN_URL ?? "",
};
