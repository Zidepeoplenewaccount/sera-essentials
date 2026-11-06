import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply({ error: "POST only" }, 405);
  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
    const auth = req.headers.get("Authorization") || "";
    const supabase = createClient(url, anon, { global: { headers: { Authorization: auth } } });
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) return reply({ error: "Please sign in as a SERA admin." }, 401);
    const { data: isAdmin, error: adminError } = await supabase.rpc("is_sera_admin");
    if (adminError || !isAdmin) return reply({ error: "Admin access required." }, 403);

    const key = Deno.env.get("FETCHLAYER_API_KEY");
    if (!key) return reply({ error: "Supplier data connector is not configured yet. Add FETCHLAYER_API_KEY as a Supabase Edge Function secret." }, 503);
    const body = await req.json();
    const action = body.action;
    let endpoint = "";
    let payload: Record<string, unknown> = {};

    if (action === "search") {
      const query = String(body.query || "").trim().slice(0, 100);
      if (!query) return reply({ error: "Enter a product category or keyword." }, 400);
      endpoint = "search-products";
      payload = {
        query, shipTo: "NG", currency: "USD", language: "en_US",
        fourStarsAndUp: true, sort: "orders", limit: 60
      };
    } else if (action === "import") {
      const supplierUrl = String(body.url || "").trim();
      let parsed: URL;
      try { parsed = new URL(supplierUrl); } catch { return reply({ error: "Enter a valid product URL." }, 400); }
      if (!/(^|\.)aliexpress\.com$/i.test(parsed.hostname)) {
        return reply({ error: "Automatic link import is currently enabled for AliExpress links only. Temu needs a separate approved data connection; we will not pretend it imported successfully." }, 400);
      }
      endpoint = "product-details";
      payload = { product: supplierUrl, shipTo: "NG", currency: "USD", language: "en_US" };
    } else {
      return reply({ error: "Unknown action." }, 400);
    }

    const response = await fetch(`https://api.fetchlayer.dev/aliexpress/${endpoint}`, {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok) return reply({ error: data.error || `Supplier API returned ${response.status}`, retryable: !!data.retryable }, response.status >= 500 ? 502 : response.status);
    return reply(data);
  } catch (e) {
    return reply({ error: e instanceof Error ? e.message : "Unexpected supplier connector error." }, 500);
  }
});

function reply(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status, headers: { ...cors, "Content-Type": "application/json" },
  });
}
