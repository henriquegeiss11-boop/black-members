import Link from "next/link";
import { Headphones, LogOut, Shield } from "lucide-react";
import { Logo } from "@/components/ui/Logo";
import { signOut } from "@/app/actions/auth";
import { firstName, initials } from "@/lib/utils";
import type { Profile } from "@/lib/auth";

export function StudentHeader({ profile }: { profile: Profile }) {
  return (
    <header className="sticky top-0 z-30 border-b border-line bg-bg/85 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between gap-3 px-4 sm:px-6">
        <Logo />
        <nav className="flex items-center gap-1 sm:gap-2">
          <Link href="/dashboard" className="hidden rounded-lg px-3 py-2 text-sm text-ink-muted hover:text-ink sm:block">
            Início
          </Link>
          {profile.role === "admin" && (
            <Link href="/admin" className="flex min-h-[44px] items-center gap-2 rounded-lg px-3 text-sm text-ink-muted hover:text-gold" aria-label="Painel admin">
              <Shield size={16} />
              <span className="hidden sm:inline">Admin</span>
            </Link>
          )}
          <Link href="/suporte" className="flex min-h-[44px] items-center gap-2 rounded-lg px-3 text-sm text-ink-muted hover:text-gold" aria-label="Suporte">
            <Headphones size={16} />
            <span className="hidden sm:inline">Suporte</span>
          </Link>
          <Link
            href="/perfil"
            className="flex min-h-[44px] items-center gap-2 rounded-lg px-2 text-sm hover:text-gold"
            aria-label="Perfil"
          >
            <span className="flex h-8 w-8 items-center justify-center rounded-full border border-gold/50 bg-card text-xs font-semibold text-gold">
              {initials(profile.full_name, profile.email)}
            </span>
            <span className="hidden max-w-[120px] truncate sm:inline">{firstName(profile.full_name, profile.email)}</span>
          </Link>
          <form action={signOut}>
            <button type="submit" className="flex min-h-[44px] min-w-[44px] items-center justify-center rounded-lg text-ink-muted hover:text-ink" aria-label="Sair">
              <LogOut size={16} />
            </button>
          </form>
        </nav>
      </div>
    </header>
  );
}
