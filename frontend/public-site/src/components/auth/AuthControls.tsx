"use client";

import { InputHTMLAttributes, useId, useState } from "react";
import { Eye, EyeOff } from "lucide-react";

type PasswordFieldProps = InputHTMLAttributes<HTMLInputElement>;

export function TikTokIcon() {
  return (
    <svg
      className="social-icon tiktok-icon"
      viewBox="0 0 24 24"
      width="24"
      height="24"
      aria-hidden="true"
      focusable="false"
    >
      <path
        fill="#25F4EE"
        d="M10.84 9.08v8.01a2.25 2.25 0 1 1-1.83-2.21v-3.12a5.33 5.33 0 1 0 4.96 5.31v-7.4a7.7 7.7 0 0 0 4.51 1.45V8a4.56 4.56 0 0 1-4.51-4.52h-3.13v5.6Z"
      />
      <path
        fill="#FE2C55"
        d="M12.17 7.76v8.01a2.25 2.25 0 1 1-1.84-2.21v-3.12a5.33 5.33 0 1 0 4.97 5.31v-7.4a7.7 7.7 0 0 0 4.5 1.45V6.68a4.56 4.56 0 0 1-4.5-4.52h-3.13v5.6Z"
      />
      <path
        fill="#fff"
        d="M11.5 8.42v8.01a2.25 2.25 0 1 1-1.83-2.21V11.1a5.33 5.33 0 1 0 4.96 5.31v-7.4a7.7 7.7 0 0 0 4.51 1.45V7.34a4.56 4.56 0 0 1-4.51-4.52H11.5v5.6Z"
      />
    </svg>
  );
}

export function PasswordField(props: PasswordFieldProps) {
  const [isVisible, setIsVisible] = useState(false);
  const generatedId = useId();
  const inputId = props.id ?? generatedId;

  return (
    <div className="password-field">
      <input {...props} id={inputId} type={isVisible ? "text" : "password"} />
      <button
        className="password-toggle"
        type="button"
        aria-label={isVisible ? "Hide password" : "Show password"}
        aria-controls={inputId}
        onClick={() => setIsVisible((value) => !value)}
      >
        {isVisible ? (
          <EyeOff size={19} aria-hidden="true" />
        ) : (
          <Eye size={19} aria-hidden="true" />
        )}
      </button>
    </div>
  );
}
