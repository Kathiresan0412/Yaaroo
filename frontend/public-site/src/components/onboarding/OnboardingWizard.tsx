"use client";

import { ChangeEvent, DragEvent, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  ArrowLeft,
  ArrowRight,
  Check,
  Crop,
  GripVertical,
  Loader2,
  LogOut,
  MapPin,
  Plus,
  Save,
  Trash2,
  Upload,
} from "lucide-react";
import { ProtectedRoute } from "../auth/ProtectedRoute";
import { useAuth } from "../auth/AuthProvider";

function generateGradientAvatar(initial: string, color1: string, color2: string): string {
  if (typeof window === "undefined") return "";
  const canvas = document.createElement("canvas");
  canvas.width = 400;
  canvas.height = 400;
  const ctx = canvas.getContext("2d");
  if (!ctx) return "";

  // Draw gradient background
  const gradient = ctx.createLinearGradient(0, 0, 400, 400);
  gradient.addColorStop(0, color1);
  gradient.addColorStop(1, color2);
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, 400, 400);

  // Draw smooth circle background for the initial
  ctx.fillStyle = "rgba(255, 255, 255, 0.15)";
  ctx.beginPath();
  ctx.arc(200, 200, 100, 0, Math.PI * 2);
  ctx.fill();

  // Draw initial text
  ctx.fillStyle = "#ffffff";
  ctx.font = "bold 120px -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif";
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(initial.toUpperCase(), 200, 200);

  return canvas.toDataURL("image/jpeg", 0.9);
}

type Photo = {
  id: string;
  url: string;
  orderIndex: number;
  isPrimary: boolean;
  status: string;
};

type WizardState = {
  displayName: string;
  pronouns: string;
  sexualOrientation: string[];
  headline: string;
  bio: string;
  heightCm: number;
  heightUnit: "cm" | "ft";
  bodyType: string;
  ethnicity: string[];
  hairColour: string;
  eyeColour: string;
  education: string;
  jobTitle: string;
  company: string;
  industry: string;
  religion: string;
  nationality: string;
  languages: string[];
  smoking: string;
  drinking: string;
  exercise: string;
  diet: string;
  sleepSchedule: string;
  livingSituation: string;
  hasChildren: string;
  wantsChildren: string;
  hasPets: string[];
  wantsPets: string;
  favPet: string;
  favColour: string;
  favFood: string[];
  favMusic: string[];
  favMovieGenre: string[];
  hobbies: string[];
  loveLanguage: string;
  relationshipGoal: string;
  showGender: string;
  minAge: number;
  maxAge: number;
  maxDistanceKm: number;
  globalMode: boolean;
  showVerifiedOnly: boolean;
  showPhotosOnly: boolean;
  latitude: number | null;
  longitude: number | null;
  city: string;
  country: string;
};

type NullableWizardState = {
  [Key in keyof WizardState]?: WizardState[Key] | null;
};

type ApiPayload = {
  message?: string;
  error?: string;
  errors?: unknown;
  details?: unknown;
  issues?: unknown;
  redirectTo?: string;
  photos?: Photo[];
  profile?: NullableWizardState | null;
  hobbies?: string[];
  preferences?: NullableWizardState | null;
  location?: {
    latitude?: number | null;
    longitude?: number | null;
    city?: string | null;
    country?: string | null;
  } | null;
  user?: {
    id?: string | null;
    oauthProvider?: string | null;
    firstName?: string | null;
    lastName?: string | null;
    registeredProfile?: {
      name?: string | null;
    } | null;
  };
};

type IpLocationPayload = {
  city?: string;
  country_name?: string;
  latitude?: number | string;
  longitude?: number | string;
};

type BrowserLocationPayload = {
  city?: string;
  locality?: string;
  principalSubdivision?: string;
  countryName?: string;
};

const steps = [
  "Photos",
  "About You",
  "Physical",
  "Background",
  "Lifestyle",
  "Favourites",
  "Preferences",
  "Location",
];

const defaults: WizardState = {
  displayName: "",
  pronouns: "",
  sexualOrientation: [],
  headline: "",
  bio: "",
  heightCm: 170,
  heightUnit: "cm",
  bodyType: "",
  ethnicity: [],
  hairColour: "",
  eyeColour: "",
  education: "",
  jobTitle: "",
  company: "",
  industry: "",
  religion: "",
  nationality: "",
  languages: [],
  smoking: "",
  drinking: "",
  exercise: "",
  diet: "",
  sleepSchedule: "",
  livingSituation: "",
  hasChildren: "",
  wantsChildren: "",
  hasPets: [],
  wantsPets: "",
  favPet: "",
  favColour: "",
  favFood: [],
  favMusic: [],
  favMovieGenre: [],
  hobbies: [],
  loveLanguage: "",
  relationshipGoal: "",
  showGender: "everyone",
  minAge: 18,
  maxAge: 45,
  maxDistanceKm: 50,
  globalMode: false,
  showVerifiedOnly: false,
  showPhotosOnly: true,
  latitude: null,
  longitude: null,
  city: "",
  country: "",
};

const stringFields = [
  "displayName",
  "pronouns",
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
  "showGender",
  "city",
  "country",
] as const satisfies readonly (keyof WizardState)[];

const textFields = ["headline", "bio"] as const satisfies readonly (keyof WizardState)[];

const stringArrayFields = [
  "sexualOrientation",
  "ethnicity",
  "languages",
  "hasPets",
  "favFood",
  "favMusic",
  "favMovieGenre",
  "hobbies",
] as const satisfies readonly (keyof WizardState)[];

const numberFields = ["heightCm", "minAge", "maxAge", "maxDistanceKm"] as const satisfies readonly (keyof WizardState)[];
const booleanFields = ["globalMode", "showVerifiedOnly", "showPhotosOnly"] as const satisfies readonly (keyof WizardState)[];

const fieldLabels: Partial<Record<keyof WizardState | "photos" | "location", string>> = {
  photos: "Photos",
  displayName: "Display name",
  pronouns: "Pronouns",
  sexualOrientation: "Sexual orientation",
  headline: "Headline",
  bio: "Bio",
  heightCm: "Height",
  bodyType: "Body type",
  ethnicity: "Ethnicity",
  hairColour: "Hair colour",
  eyeColour: "Eye colour",
  education: "Education",
  jobTitle: "Job title",
  company: "Company",
  industry: "Industry",
  religion: "Religion",
  nationality: "Nationality",
  languages: "Languages",
  smoking: "Smoking",
  drinking: "Drinking",
  exercise: "Exercise",
  diet: "Diet",
  sleepSchedule: "Sleep schedule",
  livingSituation: "Living situation",
  hasChildren: "Children",
  wantsChildren: "Want children",
  hasPets: "Pets you have",
  wantsPets: "Want pets",
  favPet: "Favourite pet",
  favColour: "Favourite colour",
  favFood: "Favourite food",
  favMusic: "Music",
  favMovieGenre: "Movie genres",
  hobbies: "Hobbies",
  loveLanguage: "Love language",
  relationshipGoal: "Relationship goal",
  showGender: "Who to show me",
  minAge: "Minimum age",
  maxAge: "Maximum age",
  maxDistanceKm: "Max distance",
  location: "Location",
  city: "City",
  country: "Country",
};

type RequiredField = keyof WizardState | "photos" | "location";

const requiredFieldsByStep: Record<number, RequiredField[]> = {
  0: ["photos"],
  1: ["displayName", "sexualOrientation", "headline", "bio"],
  2: ["bodyType", "ethnicity", "hairColour", "eyeColour"],
  3: ["education", "jobTitle", "industry", "nationality", "languages"],
  4: ["smoking", "drinking", "exercise", "diet", "sleepSchedule", "livingSituation", "hasChildren", "wantsChildren", "wantsPets"],
  5: ["favPet", "favColour", "favFood", "favMusic", "favMovieGenre", "hobbies", "loveLanguage", "relationshipGoal"],
  6: ["showGender", "minAge", "maxDistanceKm"],
  7: ["location"],
};

function mergeWizardState(...sources: Array<NullableWizardState | null | undefined>): WizardState {
  const next: WizardState = { ...defaults };

  for (const source of sources) {
    if (!source) {
      continue;
    }

    for (const field of stringFields) {
      const value = source[field];
      if (typeof value === "string") {
        next[field] = value;
      }
    }

    for (const field of textFields) {
      if (field in source) {
        const value = source[field];
        next[field] = typeof value === "string" ? value : "";
      }
    }

    for (const field of stringArrayFields) {
      const value = source[field];
      if (Array.isArray(value)) {
        next[field] = value.filter((item): item is string => typeof item === "string");
      }
    }

    for (const field of numberFields) {
      const value = source[field];
      if (typeof value === "number" && Number.isFinite(value)) {
        next[field] = value;
      }
    }

    for (const field of booleanFields) {
      const value = source[field];
      if (typeof value === "boolean") {
        next[field] = value;
      }
    }
  }

  return next;
}

async function readApiPayload(response: Response): Promise<ApiPayload> {
  const text = await response.text();

  if (!text) {
    return {};
  }

  try {
    return JSON.parse(text) as ApiPayload;
  } catch {
    return {
      message: response.ok
        ? "The server returned an unreadable response."
        : "Unable to complete the request right now.",
    };
  }
}

function labelForPath(path: unknown) {
  const rawPath = Array.isArray(path) ? path.join(".") : typeof path === "string" ? path : "";
  const key = rawPath.split(".").filter(Boolean).at(-1) || rawPath;

  return fieldLabels[key as keyof typeof fieldLabels] || title(key);
}

function collectValidationMessages(value: unknown): string[] {
  if (!value) {
    return [];
  }

  if (typeof value === "string") {
    return [value];
  }

  if (Array.isArray(value)) {
    return value.flatMap((item) => collectValidationMessages(item));
  }

  if (typeof value !== "object") {
    return [];
  }

  const record = value as Record<string, unknown>;

  if (typeof record.message === "string") {
    const label = labelForPath(record.path ?? record.field ?? record.param);
    return label ? [`${label}: ${record.message}`] : [record.message];
  }

  return Object.entries(record).flatMap(([field, detail]) => {
    const messages = collectValidationMessages(detail);
    const label = labelForPath(field);

    return messages.length > 0 ? messages.map((message) => `${label}: ${message}`) : [];
  });
}

function validationMessage(payload: ApiPayload, fallback: string) {
  const messages = [
    ...collectValidationMessages(payload.errors),
    ...collectValidationMessages(payload.issues),
    ...collectValidationMessages(payload.details),
  ];
  const uniqueMessages = Array.from(new Set(messages.filter(Boolean)));

  if (uniqueMessages.length > 0) {
    return uniqueMessages.join(" ");
  }

  return payload.message || payload.error || fallback;
}

const choices = {
  orientation: ["Straight", "Gay", "Lesbian", "Bisexual", "Asexual", "Queer", "Questioning"],
  body: ["Slim", "Athletic", "Average", "Curvy", "Muscular", "Prefer not to say"],
  ethnicity: ["Tamil", "Sinhalese", "Muslim", "Burgher", "Indian Tamil", "South Asian", "Mixed"],
  hair: ["Black", "Brown", "Blonde", "Grey", "Red", "Other"],
  eyes: ["Brown", "Black", "Hazel", "Blue", "Green", "Other"],
  education: ["High school", "Diploma", "Bachelors", "Masters", "PhD", "Other"],
  industries: ["Technology", "Healthcare", "Education", "Finance", "Arts", "Hospitality", "Public sector"],
  religion: ["Hindu", "Christian", "Muslim", "Buddhist", "Spiritual", "Agnostic", "Other"],
  nationality: ["Sri Lankan", "Indian", "American", "British", "Canadian", "Australian", "German", "French", "Singaporean", "Malaysian", "Other"],
  languages: ["Tamil", "English", "Sinhala", "Hindi", "Malayalam", "French", "German"],
  habits: ["No", "Occasionally", "Socially", "Yes"],
  exercise: ["Daily", "Often", "Sometimes", "Rarely"],
  diet: ["Vegetarian", "Vegan", "Non vegetarian", "Eggetarian", "Halal", "Other"],
  sleep: ["Early bird", "Night owl", "Flexible"],
  living: ["Alone", "With family", "With roommates", "With pets"],
  children: ["No", "Yes", "Prefer not to say"],
  wantsChildren: ["Want someday", "Open to it", "Do not want", "Not sure"],
  pets: ["Dog", "Cat", "Bird", "Fish", "Rabbit", "None"],
  colours: ["Pink", "Red", "Blue", "Green", "Black", "White", "Gold", "Purple"],
  foods: ["Kottu", "Dosa", "Biryani", "Rice & curry", "Sushi", "Pasta", "Street food"],
  music: ["Tamil pop", "Kollywood", "Hip hop", "R&B", "EDM", "Classical", "Indie"],
  movies: ["Romance", "Comedy", "Thriller", "Action", "Drama", "Sci-fi", "Documentary"],
  hobbies: ["Travel", "Cooking", "Cricket", "Gym", "Reading", "Dancing", "Gaming", "Photography", "Hiking", "Volunteering"],
  love: ["Words of affirmation", "Quality time", "Acts of service", "Gifts", "Physical touch"],
  goals: ["Life partner", "Long-term relationship", "New friends", "Still figuring it out"],
  genders: ["everyone", "women", "men", "non_binary"],
  countries: [
    "Sri Lanka",
    "India",
    "United States",
    "United Kingdom",
    "Canada",
    "Australia",
    "Germany",
    "France",
    "Italy",
    "Spain",
    "Netherlands",
    "Norway",
    "Sweden",
    "Denmark",
    "Switzerland",
    "United Arab Emirates",
    "Qatar",
    "Saudi Arabia",
    "Singapore",
    "Malaysia",
    "Thailand",
    "Japan",
    "South Korea",
    "New Zealand",
  ],
};

function title(value: string) {
  return value.replace(/_/g, " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function fileToDataUrl(file: File) {
  return new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = () => reject(new Error("Unable to read image."));
    reader.readAsDataURL(file);
  });
}

function Field({
  label,
  children,
  hint,
  required = false,
}: {
  label: string;
  children: React.ReactNode;
  hint?: string;
  required?: boolean;
}) {
  return (
    <label className="wizard-field">
      <span>
        <span className="wizard-label-text">
          {label}
          {required ? <b aria-label="required">*</b> : null}
        </span>
        {hint ? <small>{hint}</small> : null}
      </span>
      {children}
    </label>
  );
}

function ChipGroup({
  options,
  value,
  onChange,
  max = 20,
}: {
  options: string[];
  value: string[];
  onChange: (value: string[]) => void;
  max?: number;
}) {
  return (
    <div className="chip-grid">
      {options.map((option) => {
        const selected = value.includes(option);
        return (
          <button
            className={selected ? "chip selected" : "chip"}
            key={option}
            type="button"
            onClick={() => {
              if (selected) {
                onChange(value.filter((item) => item !== option));
              } else if (value.length < max) {
                onChange([...value, option]);
              }
            }}
          >
            {selected ? <Check size={15} aria-hidden="true" /> : <Plus size={15} aria-hidden="true" />}
            {option}
          </button>
        );
      })}
    </div>
  );
}

function SelectField({
  value,
  options,
  onChange,
  placeholder = "Choose",
}: {
  value: string;
  options: string[];
  onChange: (value: string) => void;
  placeholder?: string;
}) {
  return (
    <select value={value} onChange={(event) => onChange(event.target.value)}>
      <option value="">{placeholder}</option>
      {options.map((option) => (
        <option key={option} value={option}>
          {title(option)}
        </option>
      ))}
    </select>
  );
}

export function OnboardingWizard({ mode = "onboarding" }: { mode?: "onboarding" | "edit" }) {
  const router = useRouter();
  const { authFetch, logout } = useAuth();
  const [step, setStep] = useState(0);
  const [state, setState] = useState<WizardState>(defaults);
  const [photos, setPhotos] = useState<Photo[]>([]);
  const [oauthProvider, setOauthProvider] = useState<string | null>(null);
  const [userId, setUserId] = useState<string>("");
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [isUploadingPhotos, setIsUploadingPhotos] = useState(false);
  const [furthestStep, setFurthestStep] = useState(mode === "edit" ? steps.length - 1 : 0);
  const [message, setMessage] = useState("");
  const [draggedPhotoId, setDraggedPhotoId] = useState<string | null>(null);
  const [cropFile, setCropFile] = useState<File | null>(null);
  const [cropPreviewUrl, setCropPreviewUrl] = useState("");
  const [cropZoom, setCropZoom] = useState(1);
  const [cropX, setCropX] = useState(50);
  const [cropY, setCropY] = useState(50);
  const [isLocating, setIsLocating] = useState(false);
  const [registeredFirstName, setRegisteredFirstName] = useState("");

  const heightFt = useMemo(() => {
    const totalInches = Math.round(state.heightCm / 2.54);
    return `${Math.floor(totalInches / 12)}'${totalInches % 12}"`;
  }, [state.heightCm]);
  const countryOptions = useMemo(
    () => (state.country && !choices.countries.includes(state.country) ? [state.country, ...choices.countries] : choices.countries),
    [state.country],
  );

  async function handleLogout() {
    setIsLoggingOut(true);
    setMessage("");

    try {
      await logout();
      router.replace("/login");
    } catch {
      setMessage("Unable to log out. Please try again.");
      setIsLoggingOut(false);
    }
  }
  const locationSummary = state.city || state.country ? [state.city, state.country].filter(Boolean).join(", ") : "Location not selected yet";

  function update<K extends keyof WizardState>(key: K, value: WizardState[K]) {
    setState((current) => ({ ...current, [key]: value }));
  }

  function showValidationMessage(nextMessage: string) {
    setMessage(nextMessage);
    window.dispatchEvent(new CustomEvent("yaaro0:toast", { detail: { message: nextMessage, tone: "error" } }));
  }

  function showSuccessMessage(nextMessage: string) {
    setMessage(nextMessage);
    window.dispatchEvent(new CustomEvent("yaaro0:toast", { detail: { message: nextMessage, tone: "success" } }));
  }

  function applyLocationSuggestion({
    city,
    country,
    latitude,
    longitude,
  }: {
    city?: string;
    country?: string;
    latitude?: number | null;
    longitude?: number | null;
  }) {
    setState((current) => ({
      ...current,
      city: current.city || city || "",
      country: current.country || country || "",
      latitude: current.latitude ?? latitude ?? null,
      longitude: current.longitude ?? longitude ?? null,
    }));
  }

  async function suggestLocationFromIp() {
    try {
      const response = await fetch("https://ipapi.co/json/");

      if (!response.ok) {
        return;
      }

      const payload = (await response.json()) as IpLocationPayload;
      applyLocationSuggestion({
        city: payload.city,
        country: payload.country_name,
        latitude: typeof payload.latitude === "string" ? Number(payload.latitude) : payload.latitude,
        longitude: typeof payload.longitude === "string" ? Number(payload.longitude) : payload.longitude,
      });
    } catch {
      // IP location is only a convenience suggestion; manual entry still works.
    }
  }

  async function cityFromCoordinates(latitude: number, longitude: number) {
    const params = new URLSearchParams({
      latitude: String(latitude),
      longitude: String(longitude),
      localityLanguage: "en",
    });
    const response = await fetch(`https://api.bigdatacloud.net/data/reverse-geocode-client?${params.toString()}`);

    if (!response.ok) {
      throw new Error("Unable to find your city from browser location.");
    }

    const payload = (await response.json()) as BrowserLocationPayload;
    const city = payload.city || payload.locality || payload.principalSubdivision;
    const country = payload.countryName;

    if (!city || !country) {
      throw new Error("Unable to find your city from browser location.");
    }

    return {
      city,
      country,
    };
  }

  function missingFieldsForStep(stepIndex: number) {
    return (requiredFieldsByStep[stepIndex] || []).filter((field) => {
      if (field === "photos") {
        return photos.length < 2;
      }

      if (field === "location") {
        return !state.city.trim() || !state.country.trim();
      }

      if (field === "minAge") {
        return state.minAge < 18 || state.maxAge < state.minAge;
      }

      if (field === "maxDistanceKm") {
        return state.maxDistanceKm < 1;
      }

      const value = state[field];

      if (Array.isArray(value)) {
        return value.length === 0;
      }

      if (typeof value === "string") {
        return value.trim().length === 0;
      }

      return false;
    });
  }

  function validationMessageForStep(stepIndex: number) {
    const missing = missingFieldsForStep(stepIndex);

    if (missing.length === 0) {
      return "";
    }

    return `Please complete this step: ${missing
      .map((field) => fieldLabels[field] || title(field))
      .join(", ")}.`;
  }

  function validateStep(stepIndex: number) {
    const nextMessage = validationMessageForStep(stepIndex);

    if (!nextMessage) {
      return true;
    }

    showValidationMessage(nextMessage);
    return false;
  }

  function finalValidationMessage() {
    for (let stepIndex = 0; stepIndex < steps.length; stepIndex += 1) {
      const nextMessage = validationMessageForStep(stepIndex);

      if (nextMessage) {
        setStep(stepIndex);
        return nextMessage;
      }
    }

    return "";
  }

  async function loadProfile() {
    setIsLoading(true);
    setMessage("");

    try {
      const response = await authFetch("/api/profile/me");
      const payload = await readApiPayload(response);

      if (response.ok) {
        const nextState = mergeWizardState(
          payload.profile,
          { hobbies: payload.hobbies },
          payload.preferences,
          {
            city: payload.location?.city,
            country: payload.location?.country,
          },
        );

        setPhotos(payload.photos || []);
        const hasSavedLocation = Boolean(payload.location?.city && payload.location?.country);
        const firstName = payload.user?.firstName || "";
        setRegisteredFirstName(firstName);
        setOauthProvider(payload.user?.oauthProvider || null);
        setUserId(payload.user?.id || "");

        setState({
          ...nextState,
          latitude: payload.location?.latitude ?? null,
          longitude: payload.location?.longitude ?? null,
          displayName:
            nextState.displayName ||
            payload.user?.registeredProfile?.name ||
            firstName ||
            "",
        });

        if (!hasSavedLocation) {
          void suggestLocationFromIp();
        }
      } else {
        showValidationMessage(validationMessage(payload, "Unable to load your profile."));
      }
    } catch {
      showValidationMessage("Unable to load your profile.");
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    loadProfile();
  }, []);

  useEffect(() => {
    return () => {
      if (cropPreviewUrl) {
        URL.revokeObjectURL(cropPreviewUrl);
      }
    };
  }, [cropPreviewUrl]);

  async function uploadPhotoDataUrls(imageDataUrls: string[]) {
    for (const imageDataUrl of imageDataUrls) {
      const response = await authFetch("/api/profile/photos", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ imageDataUrl }),
      });
      const payload = await readApiPayload(response);

      if (!response.ok) {
        throw new Error(validationMessage(payload, "Unable to upload photo."));
      }
    }
  }

  function openCropModal(file: File) {
    if (cropPreviewUrl) {
      URL.revokeObjectURL(cropPreviewUrl);
    }

    setCropFile(file);
    setCropPreviewUrl(URL.createObjectURL(file));
    setCropZoom(1);
    setCropX(50);
    setCropY(50);
  }

  function closeCropModal() {
    if (cropPreviewUrl) {
      URL.revokeObjectURL(cropPreviewUrl);
    }

    setCropFile(null);
    setCropPreviewUrl("");
    setCropZoom(1);
    setCropX(50);
    setCropY(50);
  }

  function cropImageToDataUrl(file: File) {
    return new Promise<string>((resolve, reject) => {
      const image = new Image();
      const imageUrl = URL.createObjectURL(file);

      image.onload = () => {
        URL.revokeObjectURL(imageUrl);

        const outputWidth = 900;
        const outputHeight = 1200;
        const canvas = document.createElement("canvas");
        const context = canvas.getContext("2d");

        if (!context) {
          reject(new Error("Unable to crop image."));
          return;
        }

        canvas.width = outputWidth;
        canvas.height = outputHeight;

        const scale = Math.max(outputWidth / image.naturalWidth, outputHeight / image.naturalHeight) * cropZoom;
        const sourceWidth = Math.min(image.naturalWidth, outputWidth / scale);
        const sourceHeight = Math.min(image.naturalHeight, outputHeight / scale);
        const sourceX = Math.max(0, (image.naturalWidth - sourceWidth) * (cropX / 100));
        const sourceY = Math.max(0, (image.naturalHeight - sourceHeight) * (cropY / 100));

        context.drawImage(image, sourceX, sourceY, sourceWidth, sourceHeight, 0, 0, outputWidth, outputHeight);
        resolve(canvas.toDataURL("image/jpeg", 0.9));
      };

      image.onerror = () => {
        URL.revokeObjectURL(imageUrl);
        reject(new Error("Unable to crop image."));
      };

      image.src = imageUrl;
    });
  }

  async function uploadPhotos(event: ChangeEvent<HTMLInputElement>) {
    const files = Array.from(event.target.files || []).slice(0, Math.max(0, 9 - photos.length));
    const supportedFiles = files.filter((file) => ["image/png", "image/jpeg"].includes(file.type));

    event.target.value = "";

    if (files.length === 0) {
      return;
    }

    if (supportedFiles.length !== files.length) {
      showValidationMessage("Please upload PNG or JPG photos only.");
      return;
    }

    if (supportedFiles.length === 1) {
      openCropModal(supportedFiles[0]);
      return;
    }

    setIsUploadingPhotos(true);
    setIsSaving(true);
    setMessage("");

    try {
      await uploadPhotoDataUrls(await Promise.all(supportedFiles.map(fileToDataUrl)));
      await loadProfile();
    } catch (error) {
      showValidationMessage(error instanceof Error ? error.message : "Unable to upload photo.");
    } finally {
      setIsUploadingPhotos(false);
      setIsSaving(false);
    }
  }

  async function uploadCroppedPhoto() {
    if (!cropFile) {
      return;
    }

    setIsUploadingPhotos(true);
    setIsSaving(true);
    setMessage("");

    try {
      const imageDataUrl = await cropImageToDataUrl(cropFile);
      await uploadPhotoDataUrls([imageDataUrl]);
      closeCropModal();
      await loadProfile();
    } catch (error) {
      showValidationMessage(error instanceof Error ? error.message : "Unable to upload photo.");
    } finally {
      setIsUploadingPhotos(false);
      setIsSaving(false);
    }
  }

  async function deletePhoto(id: string) {
    setIsSaving(true);
    const response = await authFetch(`/api/profile/photos/${id}`, { method: "DELETE" });
    const payload = await readApiPayload(response);

    if (response.ok) {
      setPhotos(payload.photos || []);
    } else {
      showValidationMessage(validationMessage(payload, "Unable to delete photo."));
    }

    setIsSaving(false);
  }

  async function movePhoto(fromIndex: number, toIndex: number) {
    if (fromIndex === toIndex) {
      return;
    }

    const next = [...photos];

    if (fromIndex < 0 || toIndex < 0 || fromIndex >= next.length || toIndex >= next.length) {
      return;
    }

    const [movedPhoto] = next.splice(fromIndex, 1);
    next.splice(toIndex, 0, movedPhoto);
    setPhotos(next.map((photo, photoIndex) => ({ ...photo, orderIndex: photoIndex, isPrimary: photoIndex === 0 })));
    await authFetch("/api/profile/photos/reorder", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ photoIds: next.map((photo) => photo.id) }),
    });
  }

  function dragPhoto(event: DragEvent<HTMLElement>, photoId: string) {
    event.dataTransfer.effectAllowed = "move";
    event.dataTransfer.setData("text/plain", photoId);
    setDraggedPhotoId(photoId);
  }

  async function dropPhoto(event: DragEvent<HTMLElement>, toIndex: number) {
    event.preventDefault();
    const draggedId = event.dataTransfer.getData("text/plain") || draggedPhotoId;
    const fromIndex = photos.findIndex((photo) => photo.id === draggedId);

    setDraggedPhotoId(null);

    if (fromIndex === -1) {
      return;
    }

    await movePhoto(fromIndex, toIndex);
  }

  async function saveCurrentStep() {
    if (!validateStep(step)) {
      return false;
    }

    setIsSaving(true);
    setMessage("");

    const profileBody = {
      displayName: state.displayName,
      pronouns: state.pronouns,
      sexualOrientation: state.sexualOrientation,
      headline: state.headline,
      bio: state.bio,
      heightCm: state.heightCm,
      bodyType: state.bodyType,
      ethnicity: state.ethnicity,
      hairColour: state.hairColour,
      eyeColour: state.eyeColour,
      education: state.education,
      jobTitle: state.jobTitle,
      company: state.company,
      industry: state.industry,
      religion: state.religion,
      nationality: state.nationality,
      languages: state.languages,
      smoking: state.smoking,
      drinking: state.drinking,
      exercise: state.exercise,
      diet: state.diet,
      sleepSchedule: state.sleepSchedule,
      livingSituation: state.livingSituation,
      hasChildren: state.hasChildren,
      wantsChildren: state.wantsChildren,
      hasPets: state.hasPets,
      wantsPets: state.wantsPets,
      favPet: state.favPet,
      favColour: state.favColour,
      favFood: state.favFood,
      favMusic: state.favMusic,
      favMovieGenre: state.favMovieGenre,
      hobbies: state.hobbies,
      interests: { hobbies: state.hobbies },
      loveLanguage: state.loveLanguage,
      relationshipGoal: state.relationshipGoal,
    };

    const requests: Promise<Response>[] = [];

    if (mode === "edit") {
      requests.push(
        authFetch("/api/profile/me", {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(profileBody),
        }),
        authFetch("/api/profile/preferences", {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            showGender: state.showGender,
            minAge: state.minAge,
            maxAge: state.maxAge,
            maxDistanceKm: state.maxDistanceKm,
            globalMode: state.globalMode,
            showVerifiedOnly: state.showVerifiedOnly,
            showPhotosOnly: state.showPhotosOnly,
          }),
        })
      );

      if (state.city && state.country) {
        requests.push(
          authFetch("/api/profile/location", {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              latitude: state.latitude,
              longitude: state.longitude,
              city: state.city,
              country: state.country,
            }),
          })
        );
      }
    } else {
      if (step >= 1 && step <= 5) {
        requests.push(
          authFetch("/api/profile/me", {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(profileBody),
          }),
        );
      }

      if (step === 6) {
        requests.push(
          authFetch("/api/profile/preferences", {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              showGender: state.showGender,
              minAge: state.minAge,
              maxAge: state.maxAge,
              maxDistanceKm: state.maxDistanceKm,
              globalMode: state.globalMode,
              showVerifiedOnly: state.showVerifiedOnly,
              showPhotosOnly: state.showPhotosOnly,
            }),
          }),
        );
      }

      if (step === 7) {
        requests.push(
          authFetch("/api/profile/location", {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              latitude: state.latitude,
              longitude: state.longitude,
              city: state.city,
              country: state.country,
            }),
          }),
        );
      }
    }

    const responses = await Promise.all(requests);
    const failed = responses.find((response) => !response.ok);

    if (failed) {
      const payload = await readApiPayload(failed);
      showValidationMessage(validationMessage(payload, "Unable to save this step."));
      setIsSaving(false);
      return false;
    }

    showSuccessMessage("Saved successfully.");
    setIsSaving(false);
    return true;
  }

  async function nextStep() {
    const saved = await saveCurrentStep();

    if (saved) {
      const next = Math.min(steps.length - 1, step + 1);
      setFurthestStep((furthest) => Math.max(furthest, next));
      setStep(next);
    }
  }

  function goToStep(stepIndex: number) {
    if (mode === "onboarding" && stepIndex > furthestStep) {
      showValidationMessage("Please complete the current step before moving ahead.");
      return;
    }

    setStep(stepIndex);
  }

  async function finish() {
    const saved = await saveCurrentStep();

    if (!saved) {
      return;
    }

    const localValidationMessage = finalValidationMessage();

    if (localValidationMessage) {
      showValidationMessage(localValidationMessage);
      return;
    }

    setIsSaving(true);
    const response = await authFetch("/api/onboarding/complete", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: "{}",
    });
    const payload = await readApiPayload(response);

    if (response.ok) {
      router.push(payload.redirectTo || "/app/discover");
    } else {
      showValidationMessage(validationMessage(payload, "Complete the missing fields before finishing."));
    }

    setIsSaving(false);
  }

  async function handleSkip() {
    setIsSaving(true);
    setMessage("");

    try {
      // 1. Prefill display name from first name or default
      const defaultDisplayName = state.displayName.trim() || registeredFirstName || "User";
      const defaultBio = state.bio.trim() || "Hey! I am using Yaaro0.";
      
      // 2. We need location
      const defaultCity = state.city.trim() || "Colombo";
      const defaultCountry = state.country.trim() || "Sri Lanka";
      const defaultLat = state.latitude ?? 6.9271;
      const defaultLng = state.longitude ?? 79.8612;

      // 3. (Seeding photos on skip is removed, no default photos stored in database)

      // 4. Save profile fields
      const profileBody = {
        ...state,
        displayName: defaultDisplayName,
        bio: defaultBio,
        interests: { hobbies: state.hobbies },
      };

      const saveProfileRes = await authFetch("/api/profile/me", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(profileBody),
      });

      if (!saveProfileRes.ok) {
        const errPayload = await readApiPayload(saveProfileRes);
        throw new Error(validationMessage(errPayload, "Failed to save profile."));
      }

      // 5. Save location
      const saveLocRes = await authFetch("/api/profile/location", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          latitude: defaultLat,
          longitude: defaultLng,
          city: defaultCity,
          country: defaultCountry,
        }),
      });

      if (!saveLocRes.ok) {
        const errPayload = await readApiPayload(saveLocRes);
        throw new Error(validationMessage(errPayload, "Failed to save location."));
      }

      // 6. Save preferences
      const savePrefRes = await authFetch("/api/profile/preferences", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          showGender: state.showGender || "everyone",
          minAge: state.minAge || 18,
          maxAge: state.maxAge || 45,
          maxDistanceKm: state.maxDistanceKm || 50,
          globalMode: state.globalMode || false,
          showVerifiedOnly: state.showVerifiedOnly || false,
          showPhotosOnly: state.showPhotosOnly || true,
        }),
      });

      if (!savePrefRes.ok) {
        const errPayload = await readApiPayload(savePrefRes);
        throw new Error(validationMessage(errPayload, "Failed to save preferences."));
      }

      // 7. Complete onboarding
      const completeRes = await authFetch("/api/onboarding/complete", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: "{}",
      });
      const completePayload = await readApiPayload(completeRes);

      if (completeRes.ok) {
        showSuccessMessage("Onboarding completed successfully.");
        window.location.href = completePayload.redirectTo || "/app/discover";
      } else {
        showValidationMessage(validationMessage(completePayload, "Unable to complete onboarding."));
      }
    } catch (error) {
      showValidationMessage(error instanceof Error ? error.message : "An error occurred while skipping onboarding.");
    } finally {
      setIsSaving(false);
    }
  }

  function useBrowserLocation() {
    if (!navigator.geolocation) {
      showValidationMessage("Browser location is not available. Enter your city manually.");
      return;
    }

    setIsLocating(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const latitude = Number(position.coords.latitude.toFixed(7));
        const longitude = Number(position.coords.longitude.toFixed(7));

        void cityFromCoordinates(latitude, longitude)
          .then((location) => {
            setState((current) => ({
              ...current,
              latitude,
              longitude,
              city: location.city || current.city,
              country: location.country || current.country,
            }));
            showSuccessMessage("Location selected.");
          })
          .catch((error) => {
            setState((current) => ({ ...current, latitude, longitude }));
            showValidationMessage(error instanceof Error ? error.message : "Unable to find your city from browser location.");
          })
          .finally(() => setIsLocating(false));
      },
      () => {
        showValidationMessage("Location permission was not granted. Enter your city manually.");
        setIsLocating(false);
      },
    );
  }

  function renderStep() {
    if (step === 0) {
      return (
        <section className="wizard-panel">
          <div className="wizard-panel-heading">
            <Upload size={24} aria-hidden="true" />
            <div>
              <h2>
                Photos <span className="required-mark">*</span>
              </h2>
              <p>Add 2-9 photos. The first photo becomes your main profile image.</p>
            </div>
          </div>
          <label className={`photo-upload ${isUploadingPhotos ? "uploading" : ""}`} aria-busy={isUploadingPhotos}>
            {isUploadingPhotos ? <Loader2 className="spin" size={24} aria-hidden="true" /> : <Upload size={24} aria-hidden="true" />}
            <span>{isUploadingPhotos ? "Uploading photos..." : "Upload photos"}</span>
            <input accept="image/png,image/jpeg,.png,.jpg,.jpeg" disabled={isUploadingPhotos} multiple type="file" onChange={uploadPhotos} />
          </label>
          <div className="photo-grid">
            {photos.map((photo, index) => (
              <article
                className={`photo-tile ${draggedPhotoId === photo.id ? "dragging" : ""} `}
                draggable
                key={photo.id}
                onDragEnd={() => setDraggedPhotoId(null)}
                onDragOver={(event) => event.preventDefault()}
                onDragStart={(event) => dragPhoto(event, photo.id)}
                onDrop={(event) => dropPhoto(event, index)}
              >
                <img alt="" src={photo.url} />
                <div className="photo-tools">
                  <span>{index === 0 ? "Main" : `#${index + 1}`}</span>
                  <button aria-label="Delete photo" type="button" onClick={() => deletePhoto(photo.id)}>
                    <Trash2 size={16} />
                  </button>
                </div>
              </article>
            ))}
          </div>
        </section>
      );
    }

    if (step === 1) {
      return (
        <section className="wizard-panel two-col">
          <Field label="Display name" required>
            <input value={state.displayName} onChange={(event) => update("displayName", event.target.value)} />
          </Field>
          <Field label="Pronouns">
            <input placeholder="she/her, he/him, they/them" value={state.pronouns} onChange={(event) => update("pronouns", event.target.value)} />
          </Field>
          <Field label="Headline" hint={`${state.headline.length}/60`} required>
            <input maxLength={60} value={state.headline} onChange={(event) => update("headline", event.target.value)} />
          </Field>
          <Field label="Bio" hint={`${state.bio.length}/500`} required>
            <textarea maxLength={500} value={state.bio} onChange={(event) => update("bio", event.target.value)} />
          </Field>
          <div className="wizard-wide">
            <h3>
              Sexual orientation <span className="required-mark">*</span>
            </h3>
            <ChipGroup options={choices.orientation} value={state.sexualOrientation} onChange={(value) => update("sexualOrientation", value)} />
          </div>

          <div className="wizard-wide" style={{ marginTop: "32px" }}>
            <h3 style={{ fontSize: "18px", fontWeight: "900", color: "#ffffff", marginBottom: "16px" }}>
              Linked Social Accounts
            </h3>
            <div style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
              gap: "16px",
            }}>
              {/* TikTok Linking Card */}
              <div style={{
                background: "rgba(255, 255, 255, 0.03)",
                border: "1px solid rgba(255, 255, 255, 0.08)",
                borderRadius: "12px",
                padding: "16px 20px",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                backdropFilter: "blur(8px)",
                transition: "all 0.3s ease",
              }}>
                <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                  <div style={{
                    width: "40px",
                    height: "40px",
                    borderRadius: "50%",
                    background: "linear-gradient(135deg, #010101 0%, #25F4EE 100%)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontWeight: "bold",
                    color: "#fff",
                    fontSize: "18px",
                  }}>
                    🎵
                  </div>
                  <div>
                    <h4 style={{ margin: 0, fontWeight: "700", color: "#ffffff" }}>TikTok</h4>
                    <p style={{ margin: 0, fontSize: "12px", color: "rgba(255, 255, 255, 0.5)" }}>
                      {oauthProvider?.toLowerCase() === "tiktok" ? "Connected" : "Not connected"}
                    </p>
                  </div>
                </div>
                {oauthProvider?.toLowerCase() === "tiktok" ? (
                  <span style={{
                    background: "rgba(20, 184, 166, 0.15)",
                    color: "#14b8a6",
                    border: "1px solid rgba(20, 184, 166, 0.3)",
                    padding: "6px 12px",
                    borderRadius: "20px",
                    fontSize: "12px",
                    fontWeight: "bold",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                  }}>
                    <Check size={14} /> Linked
                  </span>
                ) : (
                  <a
                    href={`/api/auth/tiktok?link=${userId}`}
                    style={{
                      background: "linear-gradient(135deg, #FE2C55 0%, #25F4EE 100%)",
                      color: "#ffffff",
                      padding: "8px 18px",
                      borderRadius: "20px",
                      fontSize: "13px",
                      fontWeight: "bold",
                      textDecoration: "none",
                      boxShadow: "0 4px 12px rgba(254, 44, 85, 0.3)",
                      transition: "all 0.2s ease",
                    }}
                  >
                    Link
                  </a>
                )}
              </div>

              {/* Facebook Linking Card */}
              <div style={{
                background: "rgba(255, 255, 255, 0.03)",
                border: "1px solid rgba(255, 255, 255, 0.08)",
                borderRadius: "12px",
                padding: "16px 20px",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                backdropFilter: "blur(8px)",
                transition: "all 0.3s ease",
              }}>
                <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                  <div style={{
                    width: "40px",
                    height: "40px",
                    borderRadius: "50%",
                    background: "#1877F2",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontWeight: "bold",
                    color: "#fff",
                    fontSize: "20px",
                  }}>
                    f
                  </div>
                  <div>
                    <h4 style={{ margin: 0, fontWeight: "700", color: "#ffffff" }}>Facebook</h4>
                    <p style={{ margin: 0, fontSize: "12px", color: "rgba(255, 255, 255, 0.5)" }}>
                      {oauthProvider?.toLowerCase() === "facebook" ? "Connected" : "Not connected"}
                    </p>
                  </div>
                </div>
                {oauthProvider?.toLowerCase() === "facebook" ? (
                  <span style={{
                    background: "rgba(20, 184, 166, 0.15)",
                    color: "#14b8a6",
                    border: "1px solid rgba(20, 184, 166, 0.3)",
                    padding: "6px 12px",
                    borderRadius: "20px",
                    fontSize: "12px",
                    fontWeight: "bold",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                  }}>
                    <Check size={14} /> Linked
                  </span>
                ) : (
                  <a
                    href={`/api/auth/facebook?link=${userId}`}
                    style={{
                      background: "#1877F2",
                      color: "#ffffff",
                      padding: "8px 18px",
                      borderRadius: "20px",
                      fontSize: "13px",
                      fontWeight: "bold",
                      textDecoration: "none",
                      boxShadow: "0 4px 12px rgba(24, 119, 242, 0.3)",
                      transition: "all 0.2s ease",
                    }}
                  >
                    Link
                  </a>
                )}
              </div>

              {/* Google Linking Card */}
              <div style={{
                background: "rgba(255, 255, 255, 0.03)",
                border: "1px solid rgba(255, 255, 255, 0.08)",
                borderRadius: "12px",
                padding: "16px 20px",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                backdropFilter: "blur(8px)",
                transition: "all 0.3s ease",
              }}>
                <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                  <div style={{
                    width: "40px",
                    height: "40px",
                    borderRadius: "50%",
                    background: "#EA4335",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontWeight: "bold",
                    color: "#fff",
                    fontSize: "18px",
                  }}>
                    G
                  </div>
                  <div>
                    <h4 style={{ margin: 0, fontWeight: "700", color: "#ffffff" }}>Google</h4>
                    <p style={{ margin: 0, fontSize: "12px", color: "rgba(255, 255, 255, 0.5)" }}>
                      {oauthProvider?.toLowerCase() === "google" ? "Connected" : "Not connected"}
                    </p>
                  </div>
                </div>
                {oauthProvider?.toLowerCase() === "google" ? (
                  <span style={{
                    background: "rgba(20, 184, 166, 0.15)",
                    color: "#14b8a6",
                    border: "1px solid rgba(20, 184, 166, 0.3)",
                    padding: "6px 12px",
                    borderRadius: "20px",
                    fontSize: "12px",
                    fontWeight: "bold",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                  }}>
                    <Check size={14} /> Linked
                  </span>
                ) : (
                  <a
                    href={`/api/auth/google?link=${userId}`}
                    style={{
                      background: "#EA4335",
                      color: "#ffffff",
                      padding: "8px 18px",
                      borderRadius: "20px",
                      fontSize: "13px",
                      fontWeight: "bold",
                      textDecoration: "none",
                      boxShadow: "0 4px 12px rgba(234, 67, 53, 0.3)",
                      transition: "all 0.2s ease",
                    }}
                  >
                    Link
                  </a>
                )}
              </div>
            </div>
          </div>
        </section>
      );
    }

    if (step === 2) {
      return (
        <section className="wizard-panel two-col">
          <Field label="Height" hint={state.heightUnit === "cm" ? `${state.heightCm} cm` : heightFt}>
            <div className="inline-control">
              <input max={240} min={90} type="range" value={state.heightCm} onChange={(event) => update("heightCm", Number(event.target.value))} />
              <button type="button" onClick={() => update("heightUnit", state.heightUnit === "cm" ? "ft" : "cm")}>
                {state.heightUnit}
              </button>
            </div>
          </Field>
          <Field label="Body type" required>
            <SelectField options={choices.body} value={state.bodyType} onChange={(value) => update("bodyType", value)} />
          </Field>
          <Field label="Hair colour" required>
            <SelectField options={choices.hair} value={state.hairColour} onChange={(value) => update("hairColour", value)} />
          </Field>
          <Field label="Eye colour" required>
            <SelectField options={choices.eyes} value={state.eyeColour} onChange={(value) => update("eyeColour", value)} />
          </Field>
          <div className="wizard-wide">
            <h3>
              Ethnicity <span className="required-mark">*</span>
            </h3>
            <ChipGroup options={choices.ethnicity} value={state.ethnicity} onChange={(value) => update("ethnicity", value)} />
          </div>
        </section>
      );
    }

    if (step === 3) {
      return (
        <section className="wizard-panel two-col">
          <Field label="Education" required>
            <SelectField options={choices.education} value={state.education} onChange={(value) => update("education", value)} />
          </Field>
          <Field label="Job title" required>
            <input value={state.jobTitle} onChange={(event) => update("jobTitle", event.target.value)} />
          </Field>
          <Field label="Company">
            <input value={state.company} onChange={(event) => update("company", event.target.value)} />
          </Field>
          <Field label="Industry" required>
            <SelectField options={choices.industries} value={state.industry} onChange={(value) => update("industry", value)} />
          </Field>
          <Field label="Religion">
            <SelectField options={choices.religion} value={state.religion} onChange={(value) => update("religion", value)} />
          </Field>
          <Field label="Nationality" required>
            <SelectField options={choices.nationality} value={state.nationality} onChange={(value) => update("nationality", value)} />
          </Field>
          <div className="wizard-wide">
            <h3>
              Languages <span className="required-mark">*</span>
            </h3>
            <ChipGroup options={choices.languages} value={state.languages} onChange={(value) => update("languages", value)} />
          </div>
        </section>
      );
    }

    if (step === 4) {
      return (
        <section className="wizard-panel two-col">
          <Field label="Smoking" required>
            <SelectField options={choices.habits} value={state.smoking} onChange={(value) => update("smoking", value)} />
          </Field>
          <Field label="Drinking" required>
            <SelectField options={choices.habits} value={state.drinking} onChange={(value) => update("drinking", value)} />
          </Field>
          <Field label="Exercise" required>
            <SelectField options={choices.exercise} value={state.exercise} onChange={(value) => update("exercise", value)} />
          </Field>
          <Field label="Diet" required>
            <SelectField options={choices.diet} value={state.diet} onChange={(value) => update("diet", value)} />
          </Field>
          <Field label="Sleep schedule" required>
            <SelectField options={choices.sleep} value={state.sleepSchedule} onChange={(value) => update("sleepSchedule", value)} />
          </Field>
          <Field label="Living situation" required>
            <SelectField options={choices.living} value={state.livingSituation} onChange={(value) => update("livingSituation", value)} />
          </Field>
          <Field label="Children" required>
            <SelectField options={choices.children} value={state.hasChildren} onChange={(value) => update("hasChildren", value)} />
          </Field>
          <Field label="Want children" required>
            <SelectField options={choices.wantsChildren} value={state.wantsChildren} onChange={(value) => update("wantsChildren", value)} />
          </Field>
          <Field label="Want pets" required>
            <SelectField options={choices.children} value={state.wantsPets} onChange={(value) => update("wantsPets", value)} />
          </Field>
          <div className="wizard-wide">
            <h3>Pets you have</h3>
            <ChipGroup options={choices.pets} value={state.hasPets} onChange={(value) => update("hasPets", value)} />
          </div>
        </section>
      );
    }

    if (step === 5) {
      return (
        <section className="wizard-panel">
          <div className="two-col">
            <Field label="Favourite pet" required>
              <SelectField options={choices.pets} value={state.favPet} onChange={(value) => update("favPet", value)} />
            </Field>
            <Field label="Favourite colour" required>
              <SelectField options={choices.colours} value={state.favColour} onChange={(value) => update("favColour", value)} />
            </Field>
            <Field label="Love language" required>
              <SelectField options={choices.love} value={state.loveLanguage} onChange={(value) => update("loveLanguage", value)} />
            </Field>
            <Field label="Relationship goal" required>
              <SelectField options={choices.goals} value={state.relationshipGoal} onChange={(value) => update("relationshipGoal", value)} />
            </Field>
          </div>
          <h3>
            Favourite food <span className="required-mark">*</span>
          </h3>
          <ChipGroup options={choices.foods} value={state.favFood} onChange={(value) => update("favFood", value)} />
          <h3>
            Music <span className="required-mark">*</span>
          </h3>
          <ChipGroup options={choices.music} value={state.favMusic} onChange={(value) => update("favMusic", value)} />
          <h3>
            Movie genres <span className="required-mark">*</span>
          </h3>
          <ChipGroup options={choices.movies} value={state.favMovieGenre} onChange={(value) => update("favMovieGenre", value)} />
          <h3>
            Hobbies <span className="required-mark">*</span>
          </h3>
          <ChipGroup max={10} options={choices.hobbies} value={state.hobbies} onChange={(value) => update("hobbies", value)} />
        </section>
      );
    }

    if (step === 6) {
      return (
        <section className="wizard-panel two-col">
          <Field label="Who to show me" required>
            <SelectField options={choices.genders} value={state.showGender} onChange={(value) => update("showGender", value)} />
          </Field>
          <Field label="Age range" hint={`${state.minAge}-${state.maxAge}`} required>
            <div className="range-pair">
              <input max={99} min={18} type="range" value={state.minAge} onChange={(event) => update("minAge", Math.min(Number(event.target.value), state.maxAge))} />
              <input max={100} min={18} type="range" value={state.maxAge} onChange={(event) => update("maxAge", Math.max(Number(event.target.value), state.minAge))} />
            </div>
          </Field>
          <Field label="Max distance" hint={`${state.maxDistanceKm} km`} required>
            <input max={500} min={1} type="range" value={state.maxDistanceKm} onChange={(event) => update("maxDistanceKm", Number(event.target.value))} />
          </Field>
          <div className="toggle-list">
            {[
              ["globalMode", "Global mode"],
              ["showVerifiedOnly", "Verified only"],
              ["showPhotosOnly", "Photos only"],
            ].map(([key, label]) => (
              <label className="toggle-row" key={key}>
                <span>{label}</span>
                <input checked={Boolean(state[key as keyof WizardState])} type="checkbox" onChange={(event) => update(key as keyof WizardState, event.target.checked as never)} />
              </label>
            ))}
          </div>
        </section>
      );
    }

    return (
      <section className="wizard-panel one-col">
        <Field label="Country" required>
          <div className="location-select-row">
            <SelectField options={countryOptions} value={state.country} onChange={(value) => update("country", value)} />
            <button
              className="location-icon-button"
              type="button"
              disabled={isLocating}
              onClick={useBrowserLocation}
              aria-label="Fetch city from browser location"
              title="Fetch city"
            >
              {isLocating ? <Loader2 className="spin" size={18} aria-hidden="true" /> : <MapPin size={18} aria-hidden="true" />}
            </button>
          </div>
        </Field>
        <Field label="City" required>
          <input value={state.city} onChange={(event) => update("city", event.target.value)} />
        </Field>
      </section>
    );
  }

  return (
    <ProtectedRoute>
      <main className="wizard-page">
        <section className="wizard-shell">
          <aside className="wizard-sidebar">
            <a className="wizard-brand" href="/">
              Yaaro0
            </a>
            <h1>{mode === "edit" ? "Edit profile" : "Set up your profile"}</h1>
            <p>{mode === "edit" ? "Keep your profile fresh and specific." : "Complete the essentials so better matches can find you."}</p>
            <ol>
              {steps.map((label, index) => {
                const isLocked = mode === "onboarding" && index > furthestStep;

                return (
                  <li className={index === step ? "active" : index < furthestStep ? "done" : ""} key={label}>
                    <button type="button" disabled={isLocked} onClick={() => goToStep(index)}>
                      <GripVertical size={16} aria-hidden="true" />
                      <span>{label}</span>
                    </button>
                  </li>
                );
              })}
            </ol>
            {mode === "edit" ? (
              <button className="wizard-logout" type="button" disabled={isLoggingOut} onClick={handleLogout}>
                {isLoggingOut ? <Loader2 className="spin" size={18} aria-hidden="true" /> : <LogOut size={18} aria-hidden="true" />}
                Log out
              </button>
            ) : mode === "onboarding" ? (
              <button
                className="wizard-logout"
                style={{ background: "transparent", marginTop: "18px" }}
                type="button"
                disabled={isSaving}
                onClick={handleSkip}
              >
                {isSaving ? <Loader2 className="spin" size={18} aria-hidden="true" /> : <ArrowRight size={18} aria-hidden="true" />}
                Skip Onboarding
              </button>
            ) : null}
          </aside>

          <section className="wizard-main">
            <div className="wizard-topbar">
              <span>
                Step {step + 1} of {steps.length}
              </span>
              <strong>{steps[step]}</strong>
            </div>

            {isLoading ? (
              <div className="wizard-loading">
                <Loader2 size={28} aria-hidden="true" />
              </div>
            ) : (
              renderStep()
            )}

            {/* {message ? <p className="wizard-message">{message}</p> : null} */}

            <div className="wizard-actions">
              <button disabled={step === 0 || isSaving} type="button" onClick={() => setStep((current) => Math.max(0, current - 1))}>
                <ArrowLeft size={18} aria-hidden="true" />
                Back
              </button>
              {step === 0 ? null : (
                <button disabled={isSaving} type="button" onClick={saveCurrentStep}>
                  {isSaving ? <Loader2 size={18} aria-hidden="true" /> : <Save size={18} aria-hidden="true" />}
                  Save
                </button>
              )}
              {step === steps.length - 1 && mode === "onboarding" ? (
                <button className="primary" disabled={isSaving} type="button" onClick={finish}>
                  Finish
                  <Check size={18} aria-hidden="true" />
                </button>
              ) : step === steps.length - 1 ? null : (
                <button className="primary" disabled={step === steps.length - 1 || isSaving} type="button" onClick={nextStep}>
                  Next
                  <ArrowRight size={18} aria-hidden="true" />
                </button>
              )}
            </div>
          </section>
        </section>
        {cropFile && cropPreviewUrl ? (
          <div className="crop-modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="crop-modal-title">
            <section className="crop-modal">
              <div className="crop-modal-heading">
                <div>
                  <h2 id="crop-modal-title">Crop photo</h2>
                  <p>Frame your profile photo before upload.</p>
                </div>
                <Crop size={22} aria-hidden="true" />
              </div>

              <div className="crop-frame">
                <img
                  alt=""
                  src={cropPreviewUrl}
                  style={{
                    objectPosition: `${cropX}% ${cropY}%`,
                    transform: `scale(${cropZoom})`,
                  }}
                />
              </div>

              <div className="crop-controls">
                <label>
                  <span>Zoom</span>
                  <input min="1" max="2.4" step="0.05" type="range" value={cropZoom} onChange={(event) => setCropZoom(Number(event.target.value))} />
                </label>
                <label>
                  <span>Horizontal</span>
                  <input min="0" max="100" type="range" value={cropX} onChange={(event) => setCropX(Number(event.target.value))} />
                </label>
                <label>
                  <span>Vertical</span>
                  <input min="0" max="100" type="range" value={cropY} onChange={(event) => setCropY(Number(event.target.value))} />
                </label>
              </div>

              <div className="crop-actions">
                <button disabled={isUploadingPhotos} type="button" onClick={closeCropModal}>
                  Cancel
                </button>
                <button className="primary" disabled={isUploadingPhotos} type="button" onClick={uploadCroppedPhoto}>
                  {isUploadingPhotos ? <Loader2 className="spin" size={18} aria-hidden="true" /> : <Check size={18} aria-hidden="true" />}
                  Upload
                </button>
              </div>
            </section>
          </div>
        ) : null}
      </main>
    </ProtectedRoute>
  );
}
