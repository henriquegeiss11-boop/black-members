import { createClient } from "@/lib/supabase/server";

export type SupportSettings = {
  platform_name: string;
  whatsapp_url: string | null;
  support_email: string | null;
  hours: string | null;
  help_message: string | null;
};

export async function getSupportSettings(): Promise<SupportSettings> {
  const supabase = createClient();
  const { data } = await supabase
    .from("support_settings")
    .select("platform_name,whatsapp_url,support_email,hours,help_message")
    .eq("id", 1)
    .maybeSingle<SupportSettings>();
  return (
    data ?? { platform_name: "BLACK MEMBERS", whatsapp_url: null, support_email: null, hours: null, help_message: null }
  );
}
