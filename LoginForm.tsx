"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { loginSchema } from "@/lib/validation";

export function LoginForm() {
  const router = useRouter();
  const params = useSearchParams();
  const [error, setError] = useState<string | null>(
    params.get("erro") === "conta-suspensa" ? "Sua conta está suspensa. Fale com o suporte." : null
  );
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    const form = new FormData(e.currentTarget);
    const parsed = loginSchema.safeParse({ email: form.get("email"), password: form.get("password") });
    if (!parsed.success) {
      setError(parsed.error.issues[0].message);
      return;
    }
    setLoading(true);
    const supabase = createClient();
    const { error: authError } = await supabase.auth.signInWithPassword(parsed.data);
    if (authError) {
      setLoading(false);
      setError("E-mail ou senha incorretos.");
      return;
    }
    const next = params.get("next");
    // Evita open redirect: só caminhos internos.
    router.replace(next && next.startsWith("/") && !next.startsWith("//") ? next : "/dashboard");
    router.refresh();
  }

  return (
    <form onSubmit={onSubmit} className="space-y-5" noValidate>
      <div>
        <label htmlFor="email" className="bm-label">E-mail</label>
        <input id="email" name="email" type="email" autoComplete="email" required className="bm-input" placeholder="voce@email.com" />
      </div>
      <div>
        <label htmlFor="password" className="bm-label">Senha</label>
        <input id="password" name="password" type="password" autoComplete="current-password" required className="bm-input" placeholder="••••••••" />
      </div>
      {error && (
        <p role="alert" className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300">
          {error}
        </p>
      )}
      <button type="submit" disabled={loading} className="bm-btn-primary w-full">
        {loading ? "Entrando..." : "Entrar"}
      </button>
      <div className="flex items-center justify-between text-sm text-ink-muted">
        <Link href="/recuperar-senha" className="hover:text-gold">Esqueci minha senha</Link>
        <Link href="/primeiro-acesso" className="hover:text-gold">Primeiro acesso</Link>
      </div>
    </form>
  );
}
