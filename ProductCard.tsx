import Link from "next/link";
import Image from "next/image";
import { ArrowRight } from "lucide-react";

export type ProductCardData = {
  id: string;
  slug: string;
  name: string;
  short_description: string | null;
  cover_url: string | null;
  moduleCount: number;
  lessonCount: number;
  completedCount: number;
};

export function ProductCard({ product }: { product: ProductCardData }) {
  const pct = product.lessonCount > 0 ? Math.round((product.completedCount / product.lessonCount) * 100) : 0;
  return (
    <article className="bm-card group flex flex-col overflow-hidden transition hover:border-gold/50">
      <div className="relative aspect-video w-full bg-surface">
        {product.cover_url ? (
          <Image src={product.cover_url} alt={product.name} fill sizes="(max-width: 640px) 100vw, 33vw" className="object-cover" />
        ) : (
          <div className="flex h-full items-center justify-center text-sm tracking-[0.3em] text-gold/60">
            {product.name.slice(0, 2).toUpperCase()}
          </div>
        )}
      </div>
      <div className="flex flex-1 flex-col p-5">
        <h3 className="text-base font-semibold">{product.name}</h3>
        {product.short_description && (
          <p className="mt-1 line-clamp-2 text-sm text-ink-muted">{product.short_description}</p>
        )}
        <p className="mt-3 text-xs text-ink-muted">
          {product.moduleCount} {product.moduleCount === 1 ? "módulo" : "módulos"} · {product.lessonCount}{" "}
          {product.lessonCount === 1 ? "aula" : "aulas"}
        </p>
        <div className="mt-4">
          <div className="mb-1.5 flex justify-between text-xs text-ink-muted">
            <span>Progresso</span>
            <span className="text-gold">{pct}%</span>
          </div>
          <div className="h-1.5 overflow-hidden rounded-full bg-surface" role="progressbar" aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100}>
            <div className="h-full rounded-full bg-gold transition-all" style={{ width: `${pct}%` }} />
          </div>
        </div>
        <Link href={`/produto/${product.slug}`} className="bm-btn-primary mt-5 w-full">
          Acessar conteúdo <ArrowRight size={16} />
        </Link>
      </div>
    </article>
  );
}
