import { createClient } from "@/lib/supabase/server";
import type { ProductCardData } from "@/components/student/ProductCard";

/**
 * Tudo aqui roda com a sessão do aluno: o RLS garante que só voltam produtos,
 * módulos e aulas com permissão ativa. Não há filtro de permissão "no frontend".
 */
export async function getDashboardData(userId: string) {
  const supabase = createClient();

  const [productsRes, modulesRes, lessonsRes, progressRes, recentRes, newsRes] = await Promise.all([
    supabase.from("products").select("id,slug,name,short_description,cover_url,sort_order").order("sort_order"),
    supabase.from("product_modules").select("id,product_id"),
    supabase.from("lessons").select("id,product_id"),
    supabase.from("lesson_progress").select("lesson_id,completed").eq("user_id", userId),
    supabase
      .from("lesson_progress")
      .select("last_accessed_at,lessons(slug,title,products(name))")
      .eq("user_id", userId)
      .order("last_accessed_at", { ascending: false })
      .limit(4),
    supabase
      .from("notifications")
      .select("id,title,body,created_at")
      .order("created_at", { ascending: false })
      .limit(5),
  ]);

  const completed = new Set((progressRes.data ?? []).filter((p) => p.completed).map((p) => p.lesson_id));

  const products: ProductCardData[] = (productsRes.data ?? []).map((p) => {
    const lessons = (lessonsRes.data ?? []).filter((l) => l.product_id === p.id);
    return {
      id: p.id,
      slug: p.slug,
      name: p.name,
      short_description: p.short_description,
      cover_url: p.cover_url,
      moduleCount: (modulesRes.data ?? []).filter((m) => m.product_id === p.id).length,
      lessonCount: lessons.length,
      completedCount: lessons.filter((l) => completed.has(l.id)).length,
    };
  });

  type Recent = { last_accessed_at: string; lessons: { slug: string; title: string; products: { name: string } | null } | null };
  const recent = ((recentRes.data ?? []) as unknown as Recent[]).filter((r) => r.lessons);

  return { products, recent, news: newsRes.data ?? [] };
}
