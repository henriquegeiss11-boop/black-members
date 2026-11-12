import "server-only";
import { createClient } from "@supabase/supabase-js";

/**
 * Cliente com service_role: IGNORA RLS. Somente servidor
 * (webhook, ações administrativas já autorizadas). Nunca importar em componentes client.
 */
export function createAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error("Variáveis do Supabase (service role) não configuradas");
  return createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
}
