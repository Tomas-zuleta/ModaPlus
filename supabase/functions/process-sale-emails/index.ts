import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.118.0";

type Event = { id: number; sale_id: number; event_type: "APROBADA" | "RECHAZADA"; attempts: number };
const response = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
const formatMoney = (value: number) => new Intl.NumberFormat("es-CO", {
  style: "currency", currency: "COP", maximumFractionDigits: 0,
}).format(value);

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") return response({ error: "Method not allowed" }, 405);
  const cronSecret = Deno.env.get("MODAPLUS_EMAIL_WORKER_SECRET");
  const supplied = request.headers.get("x-modaplus-worker-secret");
  if (!cronSecret || !supplied || supplied !== cronSecret) {
    return response({ error: "Unauthorized" }, 401);
  }
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const resendKey = Deno.env.get("RESEND_API_KEY");
  const sender = Deno.env.get("MODAPLUS_EMAIL_FROM");
  if (!url || !serviceKey || !resendKey || !sender) {
    return response({ error: "Missing server configuration" }, 503);
  }
  const db = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await db.rpc("modaplus_claim_email_events", { p_limit: 10 });
  if (error) return response({ error: "Unable to claim events" }, 500);
  let sent = 0, failed = 0;
  for (const event of (data ?? []) as Event[]) {
    try {
      const { data: sale, error: saleError } = await db.from("ventas")
        .select("id_venta,total_venta,fecha_venta,estado,clientes(nombres,apellidos,correo)")
        .eq("id_venta", event.sale_id).single();
      if (saleError || !sale) throw new Error("Sale not found");
      const customer = Array.isArray(sale.clientes) ? sale.clientes[0] : sale.clientes;
      const email = customer?.correo?.trim();
      if (!email) throw new Error("Customer email missing");
      const customerName = [customer?.nombres, customer?.apellidos].filter(Boolean).join(" ") || "cliente";
      const approved = event.event_type === "APROBADA";
      const title = approved ? "Tu pedido fue aprobado" : "Actualización de tu pedido";
      const message = approved
        ? "Tu pedido fue aprobado. Puedes consultar su estado desde tu cuenta."
        : "Tu pedido fue rechazado. Consulta el detalle en tu cuenta o comunícate con la tienda.";
      const html = `<div style="font-family:Arial,sans-serif;max-width:560px;margin:auto">
        <h1>ModaPlus</h1><p>Hola, ${escapeHtml(customerName)}.</p>
        <p>${message}</p><p>Pedido #${event.sale_id}</p>
        <p>Total: ${formatMoney(Number(sale.total_venta ?? 0))}</p>
        <p>Fecha: ${escapeHtml(String(sale.fecha_venta ?? ""))}</p>
        <p>Este es un mensaje automático.</p></div>`;
      const res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${resendKey}`,
          "Content-Type": "application/json",
          "Idempotency-Key": `modaplus-status/${event.id}`,
        },
        body: JSON.stringify({ from: sender, to: [email], subject: title, html }),
      });
      if (!res.ok) throw new Error(`Email provider HTTP ${res.status}`);
      const result = await res.json() as { id?: string };
      const { error: updateError } = await db.from("modaplus_email_outbox")
        .update({ status: "sent", sent_at: new Date().toISOString(),
          locked_at: null, provider_message_id: result.id ?? null, last_error: null })
        .eq("id", event.id).eq("status", "processing");
      if (updateError) throw updateError;
      sent++;
    } catch (error) {
      failed++;
      const retryDelayMinutes = Math.min(60, 2 ** Math.min(event.attempts, 6));
      await db.from("modaplus_email_outbox").update({
        status: "failed", locked_at: null,
        next_attempt_at: new Date(Date.now() + retryDelayMinutes * 60000).toISOString(),
        last_error: error instanceof Error ? error.message.slice(0, 300) : "Unknown error",
      }).eq("id", event.id).eq("status", "processing");
    }
  }
  return response({ processed: (data ?? []).length, sent, failed });
});

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (char) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char] ?? char);
}
