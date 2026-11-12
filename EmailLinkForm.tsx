"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { emailSchema } from "@/lib/validation";

/** Envia o link para definir/redefinir senha. Usado em "recuperar senha" e "primeiro acesso". */
export function EmailLinkForm({ buttonLabel }: { buttonLabel: string }) {
  const [error, setError] = useState<string | null>(null);
  const [sent, setSent] = useState(false);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    const parsed = emailSchema.safeParse({ email: new FormData(e.currentTarget).get("email") });
    if (!parsed.success) {
      setError(parsed.error.issues[0].message);
      return;
    }
    setLoading(true);
    const supabase = createClient();
    await supabase.auth.resetPasswordForEmail(parsed.data.email, {
      redirectTo: `${window.location.origin}/auth/callback?next=/redefinir-senha`,
    });
    setLoading(false);
    // Resposta neutra: não revela se o e-mail existe.
    setSent(true);
  }

  if (sent) {
    return (
      <div className="space-y-5">
        <p className="rounded-xl border border-gold/30 bg-gold/10 px-4 py-3 text-sm text-gold">
          Se este e-mail tiver uma conta, você receberá um link em instantes. Verifique também o spam.
        </p>
        <Link href="/login" className="bm-btn-ghost w-full">Voltar ao login</Link>
      </div>
    );
  }

  return (
    <form onSubmit={onSubmit} className="space-y-5" noValidate>
      <div>
        <label htmlFor="email" className="bm-label">E-mail da compra</label>
        <input id="email" name="email" type="email" autoComplete="email" required className="bm-input" placeholder="voce@email.com" />
      </div>
      {error && (
        <p role="alert" className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300">{error}</p>
      )}
      <button type="submit" disabled={loading} className="bm-btn-primary w-full">
        {loading ? "Enviando..." : buttonLabel}
      </button>
      <Link href="/login" className="block text-center text-sm text-ink-muted hover:text-gold">Voltar ao login</Link>
    </form>
  );
}
