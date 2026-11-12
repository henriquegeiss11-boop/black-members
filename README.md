# BLACK MEMBERS

Plataforma de área de membros (Next.js 14 App Router + TypeScript + Tailwind + Supabase), preparada para vender vários produtos via Perfect Pay com order bumps/upsells.

## Estado atual (Etapas 1 e 2)

Pronto e compilando (`tsc` e `next build` sem erros):

- Identidade visual dark/dourada, layout mobile-first
- Login, logout, recuperar senha, redefinir senha, primeiro acesso
- Proteção de rotas no middleware (valida token no Supabase) e em `requireUser()` / `requireAdmin()`
- Dashboard do aluno (seus produtos, continue de onde parou, novidades), suporte e perfil
- Banco completo com RLS (`supabase/migrations`)

Próximas etapas: catálogo + player (3), painel admin (4), webhook Perfect Pay (6/7), testes (8), deploy (9).

## Estrutura

```
src/
  app/
    (student)/        dashboard, perfil, suporte (layout exige login)
    login, recuperar-senha, primeiro-acesso, redefinir-senha, auth/callback
    actions/          server actions (signOut, updateProfile)
  components/         auth/, student/, ui/
  lib/
    supabase/         client.ts (browser) · server.ts (sessão + RLS) · admin.ts (service role, só servidor) · middleware.ts
    auth.ts           requireUser / requireAdmin
    data/             consultas do dashboard e suporte
supabase/migrations/  0001 schema · 0002 funções de acesso · 0003 RLS + storage
```

## Como o bloqueio de produtos funciona

1. `product_integrations` mapeia código Perfect Pay -> produto interno (configurado no admin).
2. Cada item comprado vira uma linha em `purchase_items`.
3. `recalc_user_access()` mantém **uma** linha em `user_access` por (aluno, produto): ativa se houver item aprovado em qualquer compra (ou liberação manual), revogada só quando não sobra nenhuma aquisição válida.
4. O RLS usa `has_product_access()`: produto, módulos, aulas, materiais e arquivos privados só aparecem para quem tem permissão ativa. O frontend não é a barreira.
5. Só o backend (service role) escreve em compras, permissões e webhooks.

## Configuração

### 1. Supabase
1. Crie o projeto em supabase.com.
2. SQL Editor: execute `0001_schema.sql`, `0002_access_functions.sql`, `0003_rls_storage.sql`, nessa ordem (ou `supabase db push` com a CLI).
3. Authentication > URL Configuration: defina **Site URL** (URL da Vercel) e adicione `https://SEU-DOMINIO/auth/callback` em Redirect URLs (e `http://localhost:3000/auth/callback` para desenvolvimento).
4. Authentication > Providers > Email: mantenha habilitado. Desative "Allow new users to sign up" (contas são criadas pelo webhook de compra).
5. Crie seu usuário (Authentication > Users) e promova a admin:
   ```sql
   update public.profiles set role = 'admin' where email = 'seu@email.com';
   ```

### 2. Variáveis de ambiente
Copie `.env.example` para `.env.local` e preencha. Na Vercel, cadastre as mesmas em Settings > Environment Variables. `SUPABASE_SERVICE_ROLE_KEY` nunca pode ter prefixo `NEXT_PUBLIC_`.

### 3. Vercel
1. Suba este projeto para um repositório GitHub.
2. Vercel > Add New > Project > importe o repositório (framework Next.js detectado).
3. Cadastre as variáveis de ambiente e faça o deploy.
4. Atualize `NEXT_PUBLIC_SITE_URL` e a Site URL do Supabase com o domínio final.

## Desenvolvimento

```bash
npm install
cp .env.example .env.local
npm run dev
npm run typecheck
```
