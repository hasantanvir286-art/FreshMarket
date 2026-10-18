import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-retry-count, traceparent, tracestate, baggage",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, "Content-Type": "application/json" },
});

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const storeId = Deno.env.get("AAMARPAY_STORE_ID");
  const signatureKey = Deno.env.get("AAMARPAY_SIGNATURE_KEY");
  const appUrl = Deno.env.get("APP_URL");
  const baseUrl = Deno.env.get("AAMARPAY_BASE_URL") || "https://sandbox.aamarpay.com";
  if (!storeId || !signatureKey || !appUrl) return json({ error: "Online payments are not configured. Add aamarPay credentials and APP_URL to Supabase Edge Function secrets." }, 503);
  if (!/^https:\/\//i.test(appUrl) && !/^http:\/\/localhost(?::\d+)?$/i.test(appUrl)) return json({ error: "APP_URL must be an https URL (localhost is allowed for local development)." }, 500);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const customer = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: `Bearer ${anonKey}` } } });
  const service = createClient(supabaseUrl, serviceKey);

  try {
    const body = await req.json();
    const name = String(body.name || "").trim();
    const email = String(body.email || "").trim().toLowerCase();
    const phone = String(body.phone || "").trim();
    const address = body.address || {};
    const items = Array.isArray(body.items) ? body.items : [];
    const idempotencyKey = String(body.idempotency_key || "");
    if (!name || !email || !phone || !address.line1 || !address.city || !address.postal_code || items.length < 1 || items.length > 30 || !/^[0-9a-f-]{36}$/i.test(idempotencyKey)) {
      return json({ error: "Complete the delivery details and basket, then try again." }, 400);
    }
    const safeItems = items.map((item: any) => ({ product_id: String(item.product_id), quantity: Number(item.quantity) }));
    if (safeItems.some((item: any) => !/^[0-9a-f-]{36}$/i.test(item.product_id) || !Number.isInteger(item.quantity) || item.quantity < 1 || item.quantity > 99)) return json({ error: "The basket contains invalid items." }, 400);

    // The database verifies live prices and stock; never trust a client amount.
    const { data: orderNumber, error: orderError } = await customer.rpc("place_guest_cod_order", {
      p_name: name, p_email: email, p_phone: phone, p_address: address,
      p_instructions: String(body.instructions || "").slice(0, 500),
      p_items: safeItems, p_idempotency_key: idempotencyKey,
    });
    if (orderError || !orderNumber) return json({ error: orderError?.message || "Could not create the order." }, 400);

    const { data: order, error: lookupError } = await service.from("orders")
      .select("id,total_cents,guest_name,guest_email,guest_phone,delivery_address")
      .eq("order_number", orderNumber).single();
    if (lookupError || !order) return json({ error: "Order was created but could not be prepared for payment. Contact the store with order " + orderNumber }, 500);
    const { error: methodError } = await service.from("orders").update({ payment_method: "aamarpay" }).eq("id", order.id);
    if (methodError) return json({ error: "Could not mark the order for online payment." }, 500);

    const callback = `${supabaseUrl}/functions/v1/aamarpay-return`;
    const origin = appUrl.replace(/\/$/, "");
    const payload = {
      store_id: storeId, signature_key: signatureKey,
      tran_id: orderNumber, amount: (Number(order.total_cents) / 100).toFixed(2), currency: "BDT",
      desc: `Fresh Market order ${orderNumber}`,
      cus_name: order.guest_name, cus_email: order.guest_email, cus_phone: order.guest_phone,
      cus_add1: String(order.delivery_address?.line1 || "Dhaka").slice(0, 100),
      cus_city: String(order.delivery_address?.city || "Dhaka").slice(0, 50),
      cus_postcode: String(order.delivery_address?.postal_code || "1200").slice(0, 20), cus_country: "Bangladesh",
      success_url: `${callback}?result=success`, fail_url: `${callback}?result=failed`, cancel_url: `${callback}?result=failed`, type: "json",
    };
    let gateway: Response;
    try {
      gateway = await fetch(`${baseUrl.replace(/\/$/, "")}/jsonpost.php`, {
        method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload),
      });
    } catch {
      await service.rpc("resolve_aamarpay_payment", { p_order_number: orderNumber, p_result: "failed", p_provider_reference: null });
      return json({ error: "Could not reach the payment provider. Reserved stock was restored; please try again." }, 502);
    }
    const response = await gateway.json().catch(() => ({}));
    if (!gateway.ok || response.result !== "true" || typeof response.payment_url !== "string" || !response.payment_url.startsWith(baseUrl)) {
      await service.rpc("resolve_aamarpay_payment", { p_order_number: orderNumber, p_result: "failed", p_provider_reference: null });
      return json({ error: response.message || "The payment provider could not start checkout. Your stock was restored; please try again." }, 502);
    }
    return json({ payment_url: response.payment_url, order_number: orderNumber });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : "Could not start online checkout." }, 500);
  }
});
