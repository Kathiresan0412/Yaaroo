import { Router, type NextFunction, type Response } from "express";
import { prisma } from "../config/database";
import { requireAuth, type AuthenticatedRequest } from "../middleware/auth.middleware";
import { isSupportedImageUploadSource, uploadProfilePhoto } from "../services/media.service";

export const profileRouter = Router();

profileRouter.use(requireAuth);

const scalarProfileFields = [
  "displayName",
  "pronouns",
  "headline",
  "bio",
  "heightCm",
  "bodyType",
  "hairColour",
  "eyeColour",
  "education",
  "jobTitle",
  "company",
  "industry",
  "religion",
  "nationality",
  "smoking",
  "drinking",
  "exercise",
  "diet",
  "sleepSchedule",
  "livingSituation",
  "hasChildren",
  "wantsChildren",
  "wantsPets",
  "favPet",
  "favColour",
  "loveLanguage",
  "relationshipGoal",
  "mbti",
  "spotifyAnthemId",
  "spotifyAnthemName",
] as const;

const arrayProfileFields = [
  "sexualOrientation",
  "ethnicity",
  "languages",
  "hasPets",
  "favFood",
  "favMusic",
  "favMovieGenre",
] as const;

function userId(req: AuthenticatedRequest) {
  if (!req.auth?.userId) {
    throw new Error("Authenticated user missing.");
  }

  return req.auth.userId;
}

function cleanString(value: unknown, max = 255) {
  if (typeof value !== "string") {
    return null;
  }

  const cleaned = value.trim();
  return cleaned ? cleaned.slice(0, max) : null;
}

function cleanArray(value: unknown, maxItems = 20) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => cleanString(item, 80))
    .filter((item): item is string => Boolean(item))
    .slice(0, maxItems);
}

function cleanInteger(value: unknown, min: number, max: number) {
  const numberValue = Number(value);

  if (!Number.isInteger(numberValue)) {
    return null;
  }

  return Math.min(max, Math.max(min, numberValue));
}

function starSign(dateOfBirth?: Date | null) {
  if (!dateOfBirth) {
    return null;
  }

  const day = dateOfBirth.getUTCDate();
  const month = dateOfBirth.getUTCMonth() + 1;
  const signs = [
    ["Capricorn", 20],
    ["Aquarius", 19],
    ["Pisces", 20],
    ["Aries", 20],
    ["Taurus", 21],
    ["Gemini", 21],
    ["Cancer", 22],
    ["Leo", 23],
    ["Virgo", 23],
    ["Libra", 23],
    ["Scorpio", 22],
    ["Sagittarius", 22],
    ["Capricorn", 32],
  ] as const;

  return day < signs[month - 1][1] ? signs[month - 1][0] : signs[month][0];
}

function serializePhoto(photo: {
  id: bigint;
  url: string;
  orderIndex: number;
  isPrimary: boolean;
  status: string;
  createdAt: Date;
}) {
  return {
    id: photo.id.toString(),
    url: photo.url,
    orderIndex: photo.orderIndex,
    isPrimary: photo.isPrimary,
    status: photo.status,
    createdAt: photo.createdAt.toISOString(),
  };
}

async function getProfilePayload(currentUserId: bigint) {
  const [user, profile, hobbies, photos, location, preferences] = await Promise.all([
    prisma.user.findUnique({
      where: { id: currentUserId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        onboardingCompleted: true,
        profile: {
          select: {
            nameEn: true,
            gender: true,
            dateOfBirth: true,
          },
        },
      },
    }),
    prisma.userProfile.findUnique({ where: { userId: currentUserId } }),
    prisma.userHobby.findMany({ where: { userId: currentUserId }, orderBy: { hobby: "asc" } }),
    prisma.userPhoto.findMany({
      where: { userId: currentUserId },
      orderBy: [{ orderIndex: "asc" }, { id: "asc" }],
    }),
    prisma.userLocation.findUnique({ where: { userId: currentUserId } }),
    prisma.userPreference.upsert({
      where: { userId: currentUserId },
      update: {},
      create: { userId: currentUserId },
    }),
  ]);

  return {
    user: user && {
      id: user.id.toString(),
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      onboardingCompleted: user.onboardingCompleted,
      registeredProfile: user.profile && {
        name: user.profile.nameEn,
        gender: user.profile.gender,
        dateOfBirth: user.profile.dateOfBirth.toISOString().slice(0, 10),
      },
    },
    profile,
    hobbies: hobbies.map((item) => item.hobby),
    photos: photos.map(serializePhoto),
    location:
      location &&
      ({
        latitude: location.latitude ? Number(location.latitude) : null,
        longitude: location.longitude ? Number(location.longitude) : null,
        city: location.city,
        country: location.country,
        updatedAt: location.updatedAt.toISOString(),
      } as const),
    preferences: {
      showGender: preferences.showGender,
      minAge: preferences.minAge,
      maxAge: preferences.maxAge,
      maxDistanceKm: preferences.maxDistanceKm,
      globalMode: preferences.globalMode,
      showVerifiedOnly: preferences.showVerifiedOnly,
      showPhotosOnly: preferences.showPhotosOnly,
    },
  };
}

profileRouter.get("/me", async (req: AuthenticatedRequest, res, next) => {
  try {
    res.json({ success: true, ...(await getProfilePayload(userId(req))) });
  } catch (error) {
    next(error);
  }
});

profileRouter.put("/me", async (req: AuthenticatedRequest, res, next) => {
  try {
    const currentUserId = userId(req);
    const existingCoreProfile = await prisma.profile.findUnique({
      where: { userId: currentUserId },
      select: { dateOfBirth: true, nameEn: true },
    });
    const data: Record<string, string | number | string[] | null> = {
      starSign: starSign(existingCoreProfile?.dateOfBirth),
    };

    for (const field of scalarProfileFields) {
      if (field in req.body) {
        const max = field === "headline" ? 60 : field === "bio" ? 500 : 255;
        data[field] = field === "heightCm" ? cleanInteger(req.body[field], 90, 240) : cleanString(req.body[field], max);
      }
    }

    for (const field of arrayProfileFields) {
      if (field in req.body) {
        data[field] = cleanArray(req.body[field]);
      }
    }

    if (!data.displayName && !("displayName" in req.body)) {
      data.displayName = existingCoreProfile?.nameEn ?? null;
    }

    const hobbies = cleanArray(req.body.hobbies, 10);

    await prisma.$transaction(async (tx) => {
      await tx.userProfile.upsert({
        where: { userId: currentUserId },
        update: data,
        create: { userId: currentUserId, ...data },
      });

      if ("hobbies" in req.body) {
        await tx.userHobby.deleteMany({ where: { userId: currentUserId } });
        if (hobbies.length > 0) {
          await tx.userHobby.createMany({
            data: hobbies.map((hobby) => ({ userId: currentUserId, hobby })),
            skipDuplicates: true,
          });
        }
      }
    });

    res.json({ success: true, ...(await getProfilePayload(currentUserId)) });
  } catch (error) {
    next(error);
  }
});

profileRouter.post("/photos", async (req: AuthenticatedRequest, res, next) => {
  try {
    const currentUserId = userId(req);
    const source = cleanString(req.body.imageDataUrl, 5000000) || cleanString(req.body.url, 5000);

    if (!source || !isSupportedImageUploadSource(source)) {
      return res.status(400).json({ success: false, message: "A photo URL or image data URL is required." });
    }

    const count = await prisma.userPhoto.count({ where: { userId: currentUserId } });

    if (count >= 9) {
      return res.status(400).json({ success: false, message: "You can upload up to 9 photos." });
    }

    const upload = await uploadProfilePhoto(source, currentUserId);

    const photo = await prisma.userPhoto.create({
      data: {
        userId: currentUserId,
        url: upload.secure_url,
        orderIndex: count,
        isPrimary: count === 0,
      },
    });

    res.status(201).json({ success: true, photo: serializePhoto(photo) });
  } catch (error) {
    next(error);
  }
});

profileRouter.delete("/photos/:id", async (req: AuthenticatedRequest, res, next) => {
  try {
    const currentUserId = userId(req);
    const id = BigInt(req.params.id);

    await prisma.userPhoto.deleteMany({ where: { id, userId: currentUserId } });

    const photos = await prisma.userPhoto.findMany({
      where: { userId: currentUserId },
      orderBy: [{ orderIndex: "asc" }, { id: "asc" }],
    });

    await prisma.$transaction(
      photos.map((photo, index) =>
        prisma.userPhoto.update({
          where: { id: photo.id },
          data: { orderIndex: index, isPrimary: index === 0 },
        }),
      ),
    );

    res.json({ success: true, ...(await getProfilePayload(currentUserId)) });
  } catch (error) {
    next(error);
  }
});

profileRouter.put("/photos/reorder", async (req: AuthenticatedRequest, res, next) => {
  try {
    const currentUserId = userId(req);
    const ids: unknown[] = Array.isArray(req.body.photoIds) ? req.body.photoIds : [];

    if (ids.length < 1) {
      return res.status(400).json({ success: false, message: "Photo order is required." });
    }

    const photoIds = ids.map((id) => BigInt(String(id)));
    const ownedCount = await prisma.userPhoto.count({
      where: { userId: currentUserId, id: { in: photoIds } },
    });

    if (ownedCount !== photoIds.length) {
      return res.status(400).json({ success: false, message: "Photo order contains an unknown photo." });
    }

    await prisma.$transaction(
      photoIds.map((id, index) =>
        prisma.userPhoto.update({
          where: { id },
          data: { orderIndex: index, isPrimary: index === 0 },
        }),
      ),
    );

    res.json({ success: true, ...(await getProfilePayload(currentUserId)) });
  } catch (error) {
    next(error);
  }
});

profileRouter.put("/preferences", async (req: AuthenticatedRequest, res, next) => {
  try {
    const currentUserId = userId(req);
    const minAge = cleanInteger(req.body.minAge, 18, 100) ?? 18;
    const maxAge = cleanInteger(req.body.maxAge, minAge, 100) ?? Math.max(45, minAge);
    const maxDistanceKm = cleanInteger(req.body.maxDistanceKm, 1, 20000) ?? 50;
    const showGender = cleanString(req.body.showGender, 40) || "everyone";

    const preferences = await prisma.userPreference.upsert({
      where: { userId: currentUserId },
      update: {
        showGender,
        minAge,
        maxAge,
        maxDistanceKm,
        globalMode: Boolean(req.body.globalMode),
        showVerifiedOnly: Boolean(req.body.showVerifiedOnly),
        showPhotosOnly: req.body.showPhotosOnly !== false,
      },
      create: {
        userId: currentUserId,
        showGender,
        minAge,
        maxAge,
        maxDistanceKm,
        globalMode: Boolean(req.body.globalMode),
        showVerifiedOnly: Boolean(req.body.showVerifiedOnly),
        showPhotosOnly: req.body.showPhotosOnly !== false,
      },
    });

    res.json({
      success: true,
      preferences: {
        showGender: preferences.showGender,
        minAge: preferences.minAge,
        maxAge: preferences.maxAge,
        maxDistanceKm: preferences.maxDistanceKm,
        globalMode: preferences.globalMode,
        showVerifiedOnly: preferences.showVerifiedOnly,
        showPhotosOnly: preferences.showPhotosOnly,
      },
    });
  } catch (error) {
    next(error);
  }
});

profileRouter.put("/location", async (req: AuthenticatedRequest, res, next) => {
  try {
    const currentUserId = userId(req);
    const latitude = req.body.latitude === null || req.body.latitude === undefined ? null : Number(req.body.latitude);
    const longitude = req.body.longitude === null || req.body.longitude === undefined ? null : Number(req.body.longitude);
    const city = cleanString(req.body.city, 120);
    const country = cleanString(req.body.country, 120);

    if (!city && (!Number.isFinite(latitude) || !Number.isFinite(longitude))) {
      return res.status(400).json({ success: false, message: "Share your location or enter a city." });
    }

    const location = await prisma.userLocation.upsert({
      where: { userId: currentUserId },
      update: { latitude, longitude, city, country },
      create: { userId: currentUserId, latitude, longitude, city, country },
    });

    res.json({
      success: true,
      location: {
        latitude: location.latitude ? Number(location.latitude) : null,
        longitude: location.longitude ? Number(location.longitude) : null,
        city: location.city,
        country: location.country,
        updatedAt: location.updatedAt.toISOString(),
      },
    });
  } catch (error) {
    next(error);
  }
});

export async function completeOnboarding(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
) {
  try {
    const currentUserId = userId(req);
    const [profile, photos, location] = await Promise.all([
      prisma.userProfile.findUnique({ where: { userId: currentUserId } }),
      prisma.userPhoto.count({ where: { userId: currentUserId } }),
      prisma.userLocation.findUnique({ where: { userId: currentUserId } }),
    ]);

    if (!profile?.displayName || !profile.bio || photos < 2 || photos > 9 || !location) {
      return res.status(400).json({
        success: false,
        message: "Complete your profile, add 2-9 photos, and set your location before finishing.",
      });
    }

    const user = await prisma.user.update({
      where: { id: currentUserId },
      data: { onboardingCompleted: true },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        emailVerified: true,
        onboardingCompleted: true,
        role: true,
      },
    });

    res.json({
      success: true,
      user: {
        id: user.id.toString(),
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        emailVerified: user.emailVerified,
        onboardingCompleted: user.onboardingCompleted,
        role: user.role,
      },
      redirectTo: "/app/discover",
    });
  } catch (error) {
    next(error);
  }
}

profileRouter.patch("/onboarding/complete", completeOnboarding);
