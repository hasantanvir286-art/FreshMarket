import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const storeId = Deno.env.get("AAMARPAY_STORE_ID");
  const signatureKey = Deno.env.get("AAMARPAY_SIGNATURE_KEY");
  const baseUrl = Deno.env.get("AAMARPAY_BASE_URL") || "https://sandbox.aamarpay.com";
  const appUrl = (Deno.env.get("APP_URL") || "https://example.invalid").replace(/\/$/, "");
  const service = createClient(supabaseUrl, serviceKey);
  const redirect = (result: string, order = "") => Response.redirect(`${appUrl}/?payment=${result}${order ? `&order=${encodeURIComponent(order)}` : ""}`, 303);
  if (!storeId || !signatureKey) return redirect("not_configured");

  let result = new URL(req.url).searchParams.get("result") || "failed";
  let body: Record<string, string> = {};
  try {
    if (req.method === "POST") {
      const contentType = req.headers.get("content-type") || "";
      if (contentType.includes("application/json")) body = await req.json();
      else body = Object.fromEntries(new URLSearchParams(await req.text()).entries());
    }
  } catch { /* The transaction lookup below remains authoritative. */ }
  const transaction = String(body.mer_txnid || body.tran_id || new URL(req.url).searchParams.get("mer_txnid") || "").slice(0, 32);
  if (!transaction) return redirect("failed");

  const { data: order } = await service.from("orders")
    .select("order_number,total_cents,currency,payment_method,payment_status")
    .eq("order_number", transaction).maybeSingle();
  if (!order || order.payment_method !== "aamarpay") return redirect("failed", transaction);
  if (order.payment_status === "paid") return redirect("success", transaction);

  const verifyUrl = new URL(`${baseUrl.replace(/\/$/, "")}/api/v1/trxcheck/request.php`);
  verifyUrl.searchParams.set("request_id", transaction);
  verifyUrl.searchParams.set("store_id", storeId);
  verifyUrl.searchParams.set("signature_key", signatureKey);
  verifyUrl.searchParams.set("type", "json");
  const verification = await fetch(verifyUrl);
  const payment = await verification.json().catch(() => ({}));
  const valid = verification.ok && String(payment.status_code) === "2" &&
    String(payment.pay_status || "").toLowerCase() === "successful" &&
    String(payment.mer_txnid) === transaction && String(payment.store_id) === storeId &&
    String(payment.currency_merchant || payment.currency || "").toUpperCase() === "BDT" &&
    Math.round(Number(payment.amount) * 100) === Number(order.total_cents);
  if (valid) {
    await service.rpc("resolve_aamarpay_payment", {
      p_order_number: transaction, p_result: "paid", p_provider_reference: String(payment.pg_txnid || payment.bank_txn || "").slice(0, 160),
    });
    return redirect("success", transaction);
  }
  if (String(payment.status_code) === "3" || String(payment.status_code) === "7") {
    await service.rpc("resolve_aamarpay_payment", {
      p_order_number: transaction, p_result: "failed", p_provider_reference: String(payment.pg_txnid || "").slice(0, 160),
    });
  }
  result = new URL(req.url).searchParams.get("result") || "failed";
  return redirect(result === "failed" ? "failed" : "pending", transaction);
});
