import "dotenv/config";
import { randomBytes, scryptSync, timingSafeEqual } from "node:crypto";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

function requireEnv(name: string) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`${name} is required to seed the admin user`);
  }
  return value;
}

function hashPassword(password: string) {
  const salt = randomBytes(16).toString("base64url");
  const hash = scryptSync(password, salt, 64).toString("base64url");

  return `scrypt$${salt}$${hash}`;
}

export function verifyPassword(password: string, storedHash: string) {
  const [algorithm, salt, hash] = storedHash.split("$");
  if (algorithm !== "scrypt" || !salt || !hash) {
    return false;
  }

  const passwordHash = scryptSync(password, salt, 64);
  const storedPasswordHash = Buffer.from(hash, "base64url");

  return (
    passwordHash.length === storedPasswordHash.length &&
    timingSafeEqual(passwordHash, storedPasswordHash)
  );
}

async function main() {
  const email = requireEnv("ADMIN_EMAIL").toLowerCase();
  const phone = requireEnv("ADMIN_PHONE");
  const password = requireEnv("ADMIN_PASSWORD");
  const passwordHash = hashPassword(password);

  const admin = await prisma.user.upsert({
    where: { phone },
    update: {
      email,
      role: "super_admin",
      isActive: true,
      isBanned: false,
      passwordHash,
      passwordUpdatedAt: new Date(),
    },
    create: {
      phone,
      email,
      role: "super_admin",
      isActive: true,
      phoneVerifiedAt: new Date(),
      passwordHash,
      passwordUpdatedAt: new Date(),
    },
    select: {
      id: true,
      email: true,
      phone: true,
      role: true,
    },
  });

  console.log(
    JSON.stringify({
      seeded: true,
      admin: {
        ...admin,
        id: admin.id.toString(),
      },
    }),
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
