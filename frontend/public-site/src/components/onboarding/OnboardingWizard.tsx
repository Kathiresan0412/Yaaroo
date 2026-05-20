"use client";

import { ChangeEvent, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  ArrowLeft,
  ArrowRight,
  Check,
  GripVertical,
  Loader2,
  MapPin,
  Plus,
  Save,
  Trash2,
  Upload,
} from "lucide-react";
import { ProtectedRoute } from "../auth/ProtectedRoute";
import { useAuth } from "../auth/AuthProvider";

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
    firstName?: string | null;
    lastName?: string | null;
    registeredProfile?: {
      name?: string | null;
    } | null;
  };
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

const choices = {
  orientation: ["Straight", "Gay", "Lesbian", "Bisexual", "Asexual", "Queer", "Questioning"],
  body: ["Slim", "Athletic", "Average", "Curvy", "Muscular", "Prefer not to say"],
  ethnicity: ["Tamil", "Sinhalese", "Muslim", "Burgher", "Indian Tamil", "South Asian", "Mixed"],
  hair: ["Black", "Brown", "Blonde", "Grey", "Red", "Other"],
  eyes: ["Brown", "Black", "Hazel", "Blue", "Green", "Other"],
  education: ["High school", "Diploma", "Bachelors", "Masters", "PhD", "Other"],
  industries: ["Technology", "Healthcare", "Education", "Finance", "Arts", "Hospitality", "Public sector"],
  religion: ["Hindu", "Christian", "Muslim", "Buddhist", "Spiritual", "Agnostic", "Other"],
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
}: {
  label: string;
  children: React.ReactNode;
  hint?: string;
}) {
  return (
    <label className="wizard-field">
      <span>
        {label}
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
  const { authFetch } = useAuth();
  const [step, setStep] = useState(0);
  const [state, setState] = useState<WizardState>(defaults);
  const [photos, setPhotos] = useState<Photo[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [message, setMessage] = useState("");

  const heightFt = useMemo(() => {
    const totalInches = Math.round(state.heightCm / 2.54);
    return `${Math.floor(totalInches / 12)}'${totalInches % 12}"`;
  }, [state.heightCm]);

  function update<K extends keyof WizardState>(key: K, value: WizardState[K]) {
    setState((current) => ({ ...current, [key]: value }));
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
        setState({
          ...nextState,
          latitude: payload.location?.latitude ?? null,
          longitude: payload.location?.longitude ?? null,
          displayName:
            nextState.displayName ||
            payload.user?.registeredProfile?.name ||
            [payload.user?.firstName, payload.user?.lastName].filter(Boolean).join(" "),
        });
      } else {
        setMessage(payload.message || "Unable to load your profile.");
      }
    } catch {
      setMessage("Unable to load your profile.");
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    loadProfile();
  }, []);

  async function uploadPhotos(event: ChangeEvent<HTMLInputElement>) {
    const files = Array.from(event.target.files || []).slice(0, Math.max(0, 9 - photos.length));

    if (files.length === 0) {
      return;
    }

    setIsSaving(true);
    setMessage("");

    try {
      for (const file of files) {
        const imageDataUrl = await fileToDataUrl(file);
        const response = await authFetch("/api/profile/photos", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ imageDataUrl }),
        });
        const payload = await readApiPayload(response);

        if (!response.ok) {
          throw new Error(payload.message || "Unable to upload photo.");
        }
      }

      await loadProfile();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Unable to upload photo.");
    } finally {
      setIsSaving(false);
      event.target.value = "";
    }
  }

  async function deletePhoto(id: string) {
    setIsSaving(true);
    const response = await authFetch(`/api/profile/photos/${id}`, { method: "DELETE" });
    const payload = await readApiPayload(response);

    if (response.ok) {
      setPhotos(payload.photos || []);
    } else {
      setMessage(payload.message || "Unable to delete photo.");
    }

    setIsSaving(false);
  }

  async function movePhoto(index: number, direction: -1 | 1) {
    const next = [...photos];
    const target = index + direction;

    if (target < 0 || target >= next.length) {
      return;
    }

    [next[index], next[target]] = [next[target], next[index]];
    setPhotos(next.map((photo, photoIndex) => ({ ...photo, orderIndex: photoIndex, isPrimary: photoIndex === 0 })));
    await authFetch("/api/profile/photos/reorder", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ photoIds: next.map((photo) => photo.id) }),
    });
  }

  async function saveCurrentStep() {
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
      loveLanguage: state.loveLanguage,
      relationshipGoal: state.relationshipGoal,
    };

    const requests: Promise<Response>[] = [];

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

    const responses = await Promise.all(requests);
    const failed = responses.find((response) => !response.ok);

    if (failed) {
      const payload = await readApiPayload(failed);
      setMessage(payload.message || "Unable to save this step.");
      setIsSaving(false);
      return false;
    }

    setMessage("Saved");
    setIsSaving(false);
    return true;
  }

  async function nextStep() {
    const saved = await saveCurrentStep();

    if (saved) {
      setStep((current) => Math.min(steps.length - 1, current + 1));
    }
  }

  async function finish() {
    const saved = await saveCurrentStep();

    if (!saved) {
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
      setMessage(payload.message || "Complete the missing fields before finishing.");
    }

    setIsSaving(false);
  }

  function useBrowserLocation() {
    if (!navigator.geolocation) {
      setMessage("Browser location is not available. Enter your city manually.");
      return;
    }

    setIsSaving(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        update("latitude", Number(position.coords.latitude.toFixed(7)));
        update("longitude", Number(position.coords.longitude.toFixed(7)));
        setIsSaving(false);
      },
      () => {
        setMessage("Location permission was not granted. Enter your city manually.");
        setIsSaving(false);
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
              <h2>Photos</h2>
              <p>Add 2-9 photos. The first photo becomes your main profile image.</p>
            </div>
          </div>
          <label className="photo-upload">
            <Upload size={24} aria-hidden="true" />
            <span>Upload photos</span>
            <input accept="image/*" multiple type="file" onChange={uploadPhotos} />
          </label>
          <div className="photo-grid">
            {photos.map((photo, index) => (
              <article className="photo-tile" key={photo.id}>
                <img alt="" src={photo.url} />
                <div className="photo-tools">
                  <span>{index === 0 ? "Main" : `#${index + 1}`}</span>
                  <button aria-label="Move earlier" disabled={index === 0} type="button" onClick={() => movePhoto(index, -1)}>
                    <ArrowLeft size={16} />
                  </button>
                  <button aria-label="Move later" disabled={index === photos.length - 1} type="button" onClick={() => movePhoto(index, 1)}>
                    <ArrowRight size={16} />
                  </button>
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
          <Field label="Display name">
            <input value={state.displayName} onChange={(event) => update("displayName", event.target.value)} />
          </Field>
          <Field label="Pronouns">
            <input placeholder="she/her, he/him, they/them" value={state.pronouns} onChange={(event) => update("pronouns", event.target.value)} />
          </Field>
          <Field label="Headline" hint={`${state.headline.length}/60`}>
            <input maxLength={60} value={state.headline} onChange={(event) => update("headline", event.target.value)} />
          </Field>
          <Field label="Bio" hint={`${state.bio.length}/500`}>
            <textarea maxLength={500} value={state.bio} onChange={(event) => update("bio", event.target.value)} />
          </Field>
          <div className="wizard-wide">
            <h3>Sexual orientation</h3>
            <ChipGroup options={choices.orientation} value={state.sexualOrientation} onChange={(value) => update("sexualOrientation", value)} />
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
          <Field label="Body type">
            <SelectField options={choices.body} value={state.bodyType} onChange={(value) => update("bodyType", value)} />
          </Field>
          <Field label="Hair colour">
            <SelectField options={choices.hair} value={state.hairColour} onChange={(value) => update("hairColour", value)} />
          </Field>
          <Field label="Eye colour">
            <SelectField options={choices.eyes} value={state.eyeColour} onChange={(value) => update("eyeColour", value)} />
          </Field>
          <div className="wizard-wide">
            <h3>Ethnicity</h3>
            <ChipGroup options={choices.ethnicity} value={state.ethnicity} onChange={(value) => update("ethnicity", value)} />
          </div>
        </section>
      );
    }

    if (step === 3) {
      return (
        <section className="wizard-panel two-col">
          <Field label="Education">
            <SelectField options={choices.education} value={state.education} onChange={(value) => update("education", value)} />
          </Field>
          <Field label="Job title">
            <input value={state.jobTitle} onChange={(event) => update("jobTitle", event.target.value)} />
          </Field>
          <Field label="Company">
            <input value={state.company} onChange={(event) => update("company", event.target.value)} />
          </Field>
          <Field label="Industry">
            <SelectField options={choices.industries} value={state.industry} onChange={(value) => update("industry", value)} />
          </Field>
          <Field label="Religion">
            <SelectField options={choices.religion} value={state.religion} onChange={(value) => update("religion", value)} />
          </Field>
          <Field label="Nationality">
            <input value={state.nationality} onChange={(event) => update("nationality", event.target.value)} />
          </Field>
          <div className="wizard-wide">
            <h3>Languages</h3>
            <ChipGroup options={choices.languages} value={state.languages} onChange={(value) => update("languages", value)} />
          </div>
        </section>
      );
    }

    if (step === 4) {
      return (
        <section className="wizard-panel two-col">
          <Field label="Smoking">
            <SelectField options={choices.habits} value={state.smoking} onChange={(value) => update("smoking", value)} />
          </Field>
          <Field label="Drinking">
            <SelectField options={choices.habits} value={state.drinking} onChange={(value) => update("drinking", value)} />
          </Field>
          <Field label="Exercise">
            <SelectField options={choices.exercise} value={state.exercise} onChange={(value) => update("exercise", value)} />
          </Field>
          <Field label="Diet">
            <SelectField options={choices.diet} value={state.diet} onChange={(value) => update("diet", value)} />
          </Field>
          <Field label="Sleep schedule">
            <SelectField options={choices.sleep} value={state.sleepSchedule} onChange={(value) => update("sleepSchedule", value)} />
          </Field>
          <Field label="Living situation">
            <SelectField options={choices.living} value={state.livingSituation} onChange={(value) => update("livingSituation", value)} />
          </Field>
          <Field label="Children">
            <SelectField options={choices.children} value={state.hasChildren} onChange={(value) => update("hasChildren", value)} />
          </Field>
          <Field label="Want children">
            <SelectField options={choices.wantsChildren} value={state.wantsChildren} onChange={(value) => update("wantsChildren", value)} />
          </Field>
          <Field label="Want pets">
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
            <Field label="Favourite pet">
              <SelectField options={choices.pets} value={state.favPet} onChange={(value) => update("favPet", value)} />
            </Field>
            <Field label="Favourite colour">
              <SelectField options={choices.colours} value={state.favColour} onChange={(value) => update("favColour", value)} />
            </Field>
            <Field label="Love language">
              <SelectField options={choices.love} value={state.loveLanguage} onChange={(value) => update("loveLanguage", value)} />
            </Field>
            <Field label="Relationship goal">
              <SelectField options={choices.goals} value={state.relationshipGoal} onChange={(value) => update("relationshipGoal", value)} />
            </Field>
          </div>
          <h3>Favourite food</h3>
          <ChipGroup options={choices.foods} value={state.favFood} onChange={(value) => update("favFood", value)} />
          <h3>Music</h3>
          <ChipGroup options={choices.music} value={state.favMusic} onChange={(value) => update("favMusic", value)} />
          <h3>Movie genres</h3>
          <ChipGroup options={choices.movies} value={state.favMovieGenre} onChange={(value) => update("favMovieGenre", value)} />
          <h3>Hobbies</h3>
          <ChipGroup max={10} options={choices.hobbies} value={state.hobbies} onChange={(value) => update("hobbies", value)} />
        </section>
      );
    }

    if (step === 6) {
      return (
        <section className="wizard-panel two-col">
          <Field label="Who to show me">
            <SelectField options={choices.genders} value={state.showGender} onChange={(value) => update("showGender", value)} />
          </Field>
          <Field label="Age range" hint={`${state.minAge}-${state.maxAge}`}>
            <div className="range-pair">
              <input max={99} min={18} type="range" value={state.minAge} onChange={(event) => update("minAge", Math.min(Number(event.target.value), state.maxAge))} />
              <input max={100} min={18} type="range" value={state.maxAge} onChange={(event) => update("maxAge", Math.max(Number(event.target.value), state.minAge))} />
            </div>
          </Field>
          <Field label="Max distance" hint={`${state.maxDistanceKm} km`}>
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
      <section className="wizard-panel two-col">
        <div className="location-box">
          <MapPin size={28} aria-hidden="true" />
          <strong>{state.latitude && state.longitude ? `${state.latitude}, ${state.longitude}` : "Location not shared yet"}</strong>
          <button type="button" onClick={useBrowserLocation}>
            Use browser location
          </button>
        </div>
        <Field label="City">
          <input value={state.city} onChange={(event) => update("city", event.target.value)} />
        </Field>
        <Field label="Country">
          <input value={state.country} onChange={(event) => update("country", event.target.value)} />
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
              {steps.map((label, index) => (
                <li className={index === step ? "active" : index < step ? "done" : ""} key={label}>
                  <button type="button" onClick={() => setStep(index)}>
                    <GripVertical size={16} aria-hidden="true" />
                    <span>{label}</span>
                  </button>
                </li>
              ))}
            </ol>
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

            {message ? <p className="wizard-message">{message}</p> : null}

            <div className="wizard-actions">
              <button disabled={step === 0 || isSaving} type="button" onClick={() => setStep((current) => Math.max(0, current - 1))}>
                <ArrowLeft size={18} aria-hidden="true" />
                Back
              </button>
              <button disabled={isSaving} type="button" onClick={saveCurrentStep}>
                {isSaving ? <Loader2 size={18} aria-hidden="true" /> : <Save size={18} aria-hidden="true" />}
                Save
              </button>
              {step === steps.length - 1 && mode === "onboarding" ? (
                <button className="primary" disabled={isSaving} type="button" onClick={finish}>
                  Finish
                  <Check size={18} aria-hidden="true" />
                </button>
              ) : (
                <button className="primary" disabled={step === steps.length - 1 || isSaving} type="button" onClick={nextStep}>
                  Next
                  <ArrowRight size={18} aria-hidden="true" />
                </button>
              )}
            </div>
          </section>
        </section>
      </main>
    </ProtectedRoute>
  );
}
