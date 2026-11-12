-- BLACK MEMBERS — 0004: endurecimento (resultado do advisor de segurança do Supabase)

alter function public.set_updated_at() set search_path = public;
alter function public.lessons_sync_product() set search_path = public;

-- Funções de trigger: nunca devem ser chamadas via API
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.protect_profile_privileged() from public, anon, authenticated;

-- Funções usadas pelas policies: só usuários logados (e backend)
revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.has_product_access(uuid) from public, anon;
grant execute on function public.is_admin() to authenticated, service_role;
grant execute on function public.has_product_access(uuid) to authenticated, service_role;

-- Visitante sem login não precisa de acesso a nenhuma tabela do BLACK MEMBERS
revoke all on table
  public.profiles, public.products, public.product_modules, public.lessons,
  public.lesson_materials, public.lesson_progress, public.purchases,
  public.purchase_items, public.product_integrations, public.user_access,
  public.webhook_events, public.admin_audit_logs, public.support_settings,
  public.notifications
from anon;
