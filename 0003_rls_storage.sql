-- BLACK MEMBERS — 0003: Row Level Security e Storage
-- Escritas de vendas/permissões/webhooks acontecem SOMENTE via service_role
-- (backend). service_role ignora RLS, então não há policies de escrita para clientes.

alter table public.profiles            enable row level security;
alter table public.products            enable row level security;
alter table public.product_modules     enable row level security;
alter table public.lessons             enable row level security;
alter table public.lesson_materials    enable row level security;
alter table public.lesson_progress     enable row level security;
alter table public.purchases           enable row level security;
alter table public.purchase_items      enable row level security;
alter table public.product_integrations enable row level security;
alter table public.user_access         enable row level security;
alter table public.webhook_events      enable row level security;
alter table public.admin_audit_logs    enable row level security;
alter table public.support_settings    enable row level security;
alter table public.notifications       enable row level security;

-- profiles --------------------------------------------------------
create policy profiles_select_own   on public.profiles for select using (id = auth.uid());
create policy profiles_select_admin on public.profiles for select using (public.is_admin());
create policy profiles_update_own   on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());  -- trigger bloqueia role/status/email
create policy profiles_admin_all    on public.profiles for all
  using (public.is_admin()) with check (public.is_admin());

-- Catálogo: aluno só enxerga produtos que tem permissão ativa ------------
create policy products_select_access on public.products for select
  using (is_active and public.has_product_access(id));
create policy products_admin_all on public.products for all
  using (public.is_admin()) with check (public.is_admin());

create policy modules_select_access on public.product_modules for select
  using (public.has_product_access(product_id)
         and exists (select 1 from public.products p where p.id = product_id and p.is_active));
create policy modules_admin_all on public.product_modules for all
  using (public.is_admin()) with check (public.is_admin());

create policy lessons_select_access on public.lessons for select
  using (is_published and public.has_product_access(product_id)
         and exists (select 1 from public.products p where p.id = product_id and p.is_active));
create policy lessons_admin_all on public.lessons for all
  using (public.is_admin()) with check (public.is_admin());

create policy materials_select_access on public.lesson_materials for select
  using (exists (
    select 1 from public.lessons l
    where l.id = lesson_id and l.is_published and public.has_product_access(l.product_id)
  ));
create policy materials_admin_all on public.lesson_materials for all
  using (public.is_admin()) with check (public.is_admin());

-- Progresso: somente o próprio aluno, e só em aulas que ele pode acessar --
create policy progress_select_own on public.lesson_progress for select
  using (user_id = auth.uid());
create policy progress_insert_own on public.lesson_progress for insert
  with check (user_id = auth.uid() and exists (
    select 1 from public.lessons l where l.id = lesson_id and public.has_product_access(l.product_id)));
create policy progress_update_own on public.lesson_progress for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy progress_admin_select on public.lesson_progress for select
  using (public.is_admin());

-- Vendas e permissões: aluno lê só os seus; admin lê tudo; escrita só backend --
create policy purchases_select_own   on public.purchases for select using (user_id = auth.uid());
create policy purchases_select_admin on public.purchases for select using (public.is_admin());

create policy purchase_items_select_own on public.purchase_items for select
  using (exists (select 1 from public.purchases p where p.id = purchase_id and p.user_id = auth.uid()));
create policy purchase_items_select_admin on public.purchase_items for select using (public.is_admin());

create policy user_access_select_own   on public.user_access for select using (user_id = auth.uid());
create policy user_access_select_admin on public.user_access for select using (public.is_admin());

-- Integração, webhooks, auditoria: somente admin ------------------------
create policy integrations_admin_all on public.product_integrations for all
  using (public.is_admin()) with check (public.is_admin());
create policy webhook_events_admin_select on public.webhook_events for select using (public.is_admin());
create policy audit_admin_select on public.admin_audit_logs for select using (public.is_admin());

-- Suporte: qualquer logado lê; só admin altera ---------------------------
create policy support_select_auth on public.support_settings for select
  using (auth.uid() is not null);
create policy support_admin_write on public.support_settings for update
  using (public.is_admin()) with check (public.is_admin());

-- Notificações -------------------------------------------------------------
create policy notifications_select on public.notifications for select
  using (
    user_id = auth.uid()
    or (user_id is null and (product_id is null or public.has_product_access(product_id)))
  );
create policy notifications_admin_all on public.notifications for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------
-- Storage
--   covers    : público (capas de produto)
--   branding  : público (logo/favicon)
--   materials : PRIVADO; caminho = {product_id}/{lesson_id}/{arquivo}
-- ---------------------------------------------------------------
insert into storage.buckets (id, name, public) values
  ('covers', 'covers', true),
  ('branding', 'branding', true),
  ('materials', 'materials', false)
on conflict (id) do nothing;

create policy "covers_public_read" on storage.objects for select
  using (bucket_id in ('covers','branding'));
create policy "covers_admin_write" on storage.objects for all
  using (bucket_id in ('covers','branding') and public.is_admin())
  with check (bucket_id in ('covers','branding') and public.is_admin());

create policy "materials_read_access" on storage.objects for select
  using (
    bucket_id = 'materials'
    and (public.is_admin()
         or (
           (storage.foldername(name))[1] ~ '^[0-9a-fA-F-]{36}$'
           and public.has_product_access(((storage.foldername(name))[1])::uuid)
         ))
  );
create policy "materials_admin_write" on storage.objects for all
  using (bucket_id = 'materials' and public.is_admin())
  with check (bucket_id = 'materials' and public.is_admin());
