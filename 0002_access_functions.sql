-- BLACK MEMBERS — 0002: funções de permissão

-- O usuário logado é admin ativo?
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and status = 'active'
  );
$$;

-- O usuário logado tem acesso ativo ao produto? (conta ativa + permissão ativa)
create or replace function public.has_product_access(p_product_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.user_access ua
    join public.profiles pr on pr.id = ua.user_id
    where ua.user_id = auth.uid()
      and ua.product_id = p_product_id
      and ua.access_status = 'active'
      and pr.status = 'active'
  );
$$;

-- Recalcula a permissão de UM produto para UM aluno.
-- Regra: acesso ativo se existir algum item de compra APROVADO
-- (de qualquer transação) para esse aluno+produto, OU liberação manual.
-- Só revoga quando não sobra nenhuma aquisição válida.
-- Usada pelo backend (service role) após cada evento de venda e ação manual.
create or replace function public.recalc_user_access(
  p_user_id uuid,
  p_product_id uuid,
  p_reason text default null
) returns text language plpgsql security definer set search_path = public as $$
declare
  v_purchase uuid;
  v_manual boolean;
  v_existing public.user_access%rowtype;
begin
  select pi.purchase_id into v_purchase
  from public.purchase_items pi
  join public.purchases p on p.id = pi.purchase_id
  where p.user_id = p_user_id
    and pi.product_id = p_product_id
    and pi.status = 'approved'
    and p.status = 'approved'
  order by p.created_at desc
  limit 1;

  select * into v_existing from public.user_access
  where user_id = p_user_id and product_id = p_product_id;

  v_manual := coalesce(v_existing.manual_grant, false);

  if v_purchase is not null or v_manual then
    insert into public.user_access (user_id, product_id, purchase_id, access_status, source, manual_grant)
    values (p_user_id, p_product_id, v_purchase, 'active',
            case when v_purchase is not null then 'purchase' else 'manual' end, v_manual)
    on conflict (user_id, product_id) do update
      set access_status = 'active',
          purchase_id = coalesce(excluded.purchase_id, public.user_access.purchase_id),
          revoked_at = null,
          revocation_reason = null,
          source = excluded.source;
    return 'active';
  elsif v_existing.id is not null then
    update public.user_access
       set access_status = 'revoked',
           revoked_at = now(),
           revocation_reason = coalesce(p_reason, 'Sem aquisição válida')
     where id = v_existing.id and access_status <> 'revoked';
    return 'revoked';
  end if;
  return 'none';
end $$;

-- Somente o backend (service_role) pode executar a recalculação.
revoke all on function public.recalc_user_access(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.recalc_user_access(uuid, uuid, text) to service_role;

-- Protege colunas privilegiadas do profile: aluno não pode se promover a admin
-- nem se reativar. Somente service_role / admin altera role e status.
create or replace function public.protect_profile_privileged()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.role() = 'service_role' or public.is_admin() then
    return new;
  end if;
  if new.role is distinct from old.role
     or new.status is distinct from old.status
     or new.email is distinct from old.email then
    raise exception 'Alteração não permitida';
  end if;
  return new;
end $$;
create trigger trg_profiles_protect before update on public.profiles
  for each row execute function public.protect_profile_privileged();
