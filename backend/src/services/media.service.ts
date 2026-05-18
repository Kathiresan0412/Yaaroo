import { v2 as cloudinary, type UploadApiResponse } from "cloudinary";
import { env } from "../config/env";

cloudinary.config({
  cloud_name: env.cloudinaryCloudName,
  api_key: env.cloudinaryApiKey,
  api_secret: env.cloudinaryApiSecret,
  secure: true,
});

function ensureCloudinaryConfigured() {
  if (!env.cloudinaryCloudName || !env.cloudinaryApiKey || !env.cloudinaryApiSecret) {
    throw new Error("Cloudinary is not configured.");
  }
}

export function isSupportedImageUploadSource(value: string) {
  return /^data:image\/(jpeg|jpg|png|webp);base64,/i.test(value) || /^https?:\/\//i.test(value);
}

export async function uploadProfilePhoto(source: string, userId: bigint): Promise<UploadApiResponse> {
  ensureCloudinaryConfigured();

  return cloudinary.uploader.upload(source, {
    folder: `yaaro0/profile-photos/${userId.toString()}`,
    resource_type: "image",
    overwrite: false,
    unique_filename: true,
    use_filename: false,
    transformation: [
      {
        width: 1600,
        height: 1600,
        crop: "limit",
        quality: "auto",
        fetch_format: "auto",
      },
    ],
  });
}
