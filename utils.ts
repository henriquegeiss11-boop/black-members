import clsx, { type ClassValue } from "clsx";

export function cn(...inputs: ClassValue[]) {
  return clsx(inputs);
}

export function firstName(name?: string | null, email?: string | null) {
  const base = name?.trim() || email?.split("@")[0] || "aluno";
  return base.split(" ")[0];
}

export function initials(name?: string | null, email?: string | null) {
  const base = name?.trim() || email?.split("@")[0] || "?";
  const parts = base.split(/\s+/).filter(Boolean);
  return ((parts[0]?.[0] ?? "?") + (parts[1]?.[0] ?? "")).toUpperCase();
}
