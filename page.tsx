import Link from "next/link";
import { PlayCircle, Bell } from "lucide-react";
import { requireUser } from "@/lib/auth";
import { getDashboardData } from "@/lib/data/dashboard";
import { getSupportSettings } from "@/lib/data/support";
import { ProductCard } from "@/components/student/ProductCard";
import { firstName } from "@/lib/utils";

export const metadata = { title: "Dashboard" };

export default async function DashboardPage() {
  const { profile } = await requireUser();
  const [{ products, recent, news }, support] = await Promise.all([
    getDashboardData(profile.id),
    getSupportSettings(),
  ]);

  return (
    <div className="space-y-12">
      <section className="animate-fade-up">
        <h1 className="text-2xl font-semibold sm:text-3xl">
          Olá, <span className="text-gold">{firstName(profile.full_name, profile.email)}</span>
        </h1>
        <p className="mt-2 text-sm text-ink-muted">Bem-vindo à sua área de membros.</p>
      </section>

      {recent.length > 0 && (
        <section>
          <h2 className="mb-4 text-xs font-semibold uppercase tracking-[0.2em] text-ink-muted">Continue de onde parou</h2>
          <div className="grid gap-3 sm:grid-cols-2">
            {recent.map((r) => (
              <Link
                key={r.lessons!.slug}
                href={`/aula/${r.lessons!.slug}`}
                className="bm-card flex min-h-[64px] items-center gap-4 px-5 py-4 transition hover:border-gold/50"
              >
                <PlayCircle className="shrink-0 text-gold" size={28} />
                <div className="min-w-0">
                  <p className="truncate text-sm font-medium">{r.lessons!.title}</p>
                  <p className="truncate text-xs text-ink-muted">{r.lessons!.products?.name}</p>
                </div>
              </Link>
            ))}
          </div>
        </section>
      )}

      <section>
        <h2 className="mb-4 text-xs font-semibold uppercase tracking-[0.2em] text-ink-muted">Seus produtos</h2>
        {products.length === 0 ? (
          <div className="bm-card p-8 text-center">
            <p className="text-sm text-ink-muted">
              Você ainda não possui produtos liberados. Se acabou de comprar, a liberação pode levar alguns minutos.
            </p>
            <Link href="/suporte" className="bm-btn-ghost mt-5">Falar com o suporte</Link>
          </div>
        ) : (
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {products.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        )}
      </section>

      {news.length > 0 && (
        <section>
          <h2 className="mb-4 text-xs font-semibold uppercase tracking-[0.2em] text-ink-muted">Novidades</h2>
          <ul className="space-y-3">
            {news.map((n) => (
              <li key={n.id} className="bm-card flex gap-4 px-5 py-4">
                <Bell className="mt-0.5 shrink-0 text-gold" size={18} />
                <div>
                  <p className="text-sm font-medium">{n.title}</p>
                  {n.body && <p className="mt-1 text-sm text-ink-muted">{n.body}</p>}
                </div>
              </li>
            ))}
          </ul>
        </section>
      )}

      {support.whatsapp_url && (
        <a
          href={support.whatsapp_url}
          target="_blank"
          rel="noopener noreferrer"
          className="bm-btn-primary fixed bottom-5 right-5 z-20 shadow-lg shadow-black/50"
        >
          Suporte
        </a>
      )}
    </div>
  );
}
