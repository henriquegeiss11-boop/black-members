"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { requireUser } from "@/lib/auth";

const schema = z.object({ full_name: z.string().trim().max(80) });

export async function updateProfile(formData: FormData) {
  const { supabase, profile } = await requireUser();
  const parsed = schema.safeParse({ full_name: formData.get("full_name") ?? "" });
  if (!parsed.success) return;
  // RLS + trigger garantem que só o nome do próprio usuário é alterável.
  await supabase.from("profiles").update({ full_name: parsed.data.full_name || null }).eq("id", profile.id);
  revalidatePath("/perfil");
  revalidatePath("/dashboard");
}
