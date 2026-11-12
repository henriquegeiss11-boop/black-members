"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { newPasswordSchema } from "@/lib/validation";

export function NewPasswordForm() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    const form = new FormData(e.currentTarget);
    const parsed = newPasswordSchema.safeParse({ password: form.get("password"), confirm: form.get("confirm") });
    if (!parsed.success) {
      setError(parsed.error.issues[0].message);
      return;
    }
    setLoading(true);
    const supabase = createClient();
    const { error: updError } = await supabase.auth.updateUser({ password: parsed.data.password });
    setLoading(false);
    if (updError) {
      setError("Não foi possível salvar a senha. Solicite um novo link.");
      return;
    }
    router.replace("/dashboard");
    router.refresh();
  }

  return (
    <form onSubmit={onSubmit} className="space-y-5" noValidate>
      <div>
        <label htmlFor="password" className="bm-label">Nova senha</label>
        <input id="password" name="password" type="password" autoComplete="new-password" required className="bm-input" />
      </div>
      <div>
        <label htmlFor="confirm" className="bm-label">Confirmar senha</label>
        <input id="confirm" name="confirm" type="password" autoComplete="new-password" required className="bm-input" />
      </div>
      {error && (
        <p role="alert" className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300">{error}</p>
      )}
      <button type="submit" disabled={loading} className="bm-btn-primary w-full">
        {loading ? "Salvando..." : "Salvar senha"}
      </button>
    </form>
  );
}
