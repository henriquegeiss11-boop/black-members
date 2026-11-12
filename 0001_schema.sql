-- BLACK MEMBERS — 0001: schema base
-- Aplicar em ordem: 0001 -> 0002 -> 0003

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- ---------------------------------------------------------------
-- profiles (1:1 com auth.users)
-- ---------------------------------------------------------------
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  full_name   text,
  avatar_url  text,
  role        text not null default 'student' check (role in ('student','admin')),
  status      text not null default 'active'  check (status in ('active','suspended')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
-- e-mail único sem diferenciar maiúsculas (evita contas duplicadas)
create unique index profiles_email_unique on public.profiles (lower(email));
create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();

-- Cria o profile automaticamente quando um usuário é criado no Supabase Auth.
-- O papel NUNCA vem de metadados do usuário: sempre começa como 'student'.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', null))
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------
-- Catálogo
-- ---------------------------------------------------------------
create table public.products (
  id                uuid primary key default gen_random_uuid(),
  name              text not null,
  slug              text not null unique,
  short_description text,
  description       text,
  cover_url         text,
  category          text,
  is_active         boolean not null default true,
  sort_order        int not null default 0,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index products_active_sort_idx on public.products (is_active, sort_order);
create trigger trg_products_updated before update on public.products
  for each row execute function public.set_updated_at();

create table public.product_modules (
  id          uuid primary key default gen_random_uuid(),
  product_id  uuid not null references public.products(id) on delete cascade,
  title       text not null,
  description text,
  sort_order  int not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index product_modules_product_idx on public.product_modules (product_id, sort_order);
create trigger trg_modules_updated before update on public.product_modules
  for each row execute function public.set_updated_at();

create table public.lessons (
  id             uuid primary key default gen_random_uuid(),
  module_id      uuid not null references public.product_modules(id) on delete cascade,
  -- denormalizado para RLS rápido; mantido por trigger abaixo
  product_id     uuid not null references public.products(id) on delete cascade,
  slug           text not null unique,
  title          text not null,
  description    text,
  video_provider text check (video_provider in ('youtube','vimeo','url')),
  video_url      text,
  content_text   text,
  is_published   boolean not null default true,
  sort_order     int not null default 0,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index lessons_module_idx  on public.lessons (module_id, sort_order);
create index lessons_product_idx on public.lessons (product_id);
create trigger trg_lessons_updated before update on public.lessons
  for each row execute function public.set_updated_at();

create or replace function public.lessons_sync_product()
returns trigger language plpgsql as $$
begin
  select product_id into new.product_id from public.product_modules where id = new.module_id;
  return new;
end $$;
create trigger trg_lessons_sync_product before insert or update of module_id on public.lessons
  for each row execute function public.lessons_sync_product();

create table public.lesson_materials (
  id           uuid primary key default gen_random_uuid(),
  lesson_id    uuid not null references public.lessons(id) on delete cascade,
  kind         text not null check (kind in ('pdf','file','link','image')),
  title        text not null,
  url          text,            -- links externos
  storage_path text,            -- arquivos no bucket privado "materials"
  sort_order   int not null default 0,
  created_at   timestamptz not null default now(),
  check (url is not null or storage_path is not null)
);
create index lesson_materials_lesson_idx on public.lesson_materials (lesson_id, sort_order);

create table public.lesson_progress (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles(id) on delete cascade,
  lesson_id        uuid not null references public.lessons(id) on delete cascade,
  completed        boolean not null default false,
  completed_at     timestamptz,
  last_accessed_at timestamptz not null default now(),
  unique (user_id, lesson_id)
);
create index lesson_progress_user_idx on public.lesson_progress (user_id, last_accessed_at desc);

-- ---------------------------------------------------------------
-- Vendas
-- ---------------------------------------------------------------
create table public.purchases (
  id                        uuid primary key default gen_random_uuid(),
  provider                  text not null default 'perfectpay',
  provider_transaction_code text not null,
  user_id                   uuid references public.profiles(id) on delete set null,
  buyer_email               text not null,
  buyer_name                text,
  amount                    numeric(12,2),
  currency                  text default 'BRL',
  payment_method            text,
  status                    text not null default 'pending'
                            check (status in ('pending','approved','canceled','refused','refunded','chargeback')),
  status_updated_at         timestamptz not null default now(),
  -- timestamp do último evento aplicado (controle de eventos fora de ordem)
  last_event_at             timestamptz,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now(),
  unique (provider, provider_transaction_code)
);
create index purchases_user_idx  on public.purchases (user_id);
create index purchases_email_idx on public.purchases (lower(buyer_email));
create index purchases_status_idx on public.purchases (status, created_at desc);
create trigger trg_purchases_updated before update on public.purchases
  for each row execute function public.set_updated_at();

-- Mapeamento código Perfect Pay -> produto interno (configurável no admin)
create table public.product_integrations (
  id                    uuid primary key default gen_random_uuid(),
  provider              text not null default 'perfectpay',
  external_product_code text not null,
  external_plan_code    text,
  product_id            uuid not null references public.products(id) on delete cascade,
  kind                  text not null default 'main'
                        check (kind in ('main','order_bump','upsell','downsell')),
  is_active             boolean not null default true,
  created_at            timestamptz not null default now()
);
create unique index product_integrations_unique
  on public.product_integrations (provider, external_product_code, coalesce(external_plan_code, ''));
create index product_integrations_product_idx on public.product_integrations (product_id);

-- Um registro por item adquirido (principal, order bump, upsell...)
create table public.purchase_items (
  id                    uuid primary key default gen_random_uuid(),
  purchase_id           uuid not null references public.purchases(id) on delete cascade,
  product_id            uuid not null references public.products(id) on delete restrict,
  integration_id        uuid references public.product_integrations(id) on delete set null,
  external_product_code text not null,
  kind                  text not null default 'main'
                        check (kind in ('main','order_bump','upsell','downsell')),
  amount                numeric(12,2),
  status                text not null default 'pending'
                        check (status in ('pending','approved','canceled','refused','refunded','chargeback')),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  unique (purchase_id, external_product_code)
);
create index purchase_items_purchase_idx on public.purchase_items (purchase_id);
create index purchase_items_product_idx  on public.purchase_items (product_id, status);
create trigger trg_purchase_items_updated before update on public.purchase_items
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------
-- Permissões
-- Uma linha por (aluno, produto). O histórico de transações fica em
-- purchase_items; a validade é recalculada por recalc_user_access().
-- ---------------------------------------------------------------
create table public.user_access (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.profiles(id) on delete cascade,
  product_id        uuid not null references public.products(id) on delete cascade,
  purchase_id       uuid references public.purchases(id) on delete set null, -- última compra que sustentou o acesso
  access_status     text not null default 'active' check (access_status in ('active','revoked')),
  manual_grant      boolean not null default false,  -- liberado manualmente pelo admin
  source            text not null default 'purchase' check (source in ('purchase','manual')),
  granted_at        timestamptz not null default now(),
  revoked_at        timestamptz,
  revocation_reason text,
  updated_at        timestamptz not null default now(),
  unique (user_id, product_id)
);
create index user_access_user_idx on public.user_access (user_id, access_status);
create index user_access_product_idx on public.user_access (product_id);
create trigger trg_user_access_updated before update on public.user_access
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------
-- Webhooks, auditoria, configurações, notificações
-- ---------------------------------------------------------------
create table public.webhook_events (
  id                 uuid primary key default gen_random_uuid(),
  provider           text not null default 'perfectpay',
  -- chave de idempotência: derivada de transação + status + timestamp do evento
  event_key          text not null,
  transaction_code   text,
  event_status       text,
  signature_valid    boolean not null default false,
  payload            jsonb not null,
  processing_status  text not null default 'received'
                     check (processing_status in ('received','processed','failed','ignored')),
  error              text,
  attempts           int not null default 0,
  received_at        timestamptz not null default now(),
  processed_at       timestamptz,
  unique (provider, event_key)
);
create index webhook_events_received_idx on public.webhook_events (received_at desc);
create index webhook_events_status_idx   on public.webhook_events (processing_status, received_at desc);
create index webhook_events_tx_idx       on public.webhook_events (transaction_code);

create table public.admin_audit_logs (
  id              uuid primary key default gen_random_uuid(),
  admin_id        uuid references public.profiles(id) on delete set null,
  action          text not null,
  target_user_id  uuid references public.profiles(id) on delete set null,
  target_product_id uuid references public.products(id) on delete set null,
  reason          text,
  metadata        jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now()
);
create index admin_audit_logs_created_idx on public.admin_audit_logs (created_at desc);
create index admin_audit_logs_target_idx  on public.admin_audit_logs (target_user_id);

create table public.support_settings (
  id            int primary key default 1 check (id = 1),  -- linha única
  platform_name text not null default 'BLACK MEMBERS',
  logo_url      text,
  favicon_url   text,
  public_url    text,
  whatsapp_url  text,
  support_email text,
  hours         text,
  help_message  text,
  theme_colors  jsonb not null default '{}'::jsonb,
  updated_at    timestamptz not null default now()
);
insert into public.support_settings (id) values (1) on conflict do nothing;
create trigger trg_support_updated before update on public.support_settings
  for each row execute function public.set_updated_at();

create table public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references public.profiles(id) on delete cascade, -- null = para todos com acesso ao produto
  product_id  uuid references public.products(id) on delete cascade,
  title       text not null,
  body        text,
  created_at  timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);
create index notifications_product_idx on public.notifications (product_id, created_at desc);
