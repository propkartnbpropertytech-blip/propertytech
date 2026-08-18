import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function sha256Hex(value: string) {
  const data = new TextEncoder().encode(value);
  const hash = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function resetPageUrl(req: Request) {
  const origin = (req.headers.get("origin") || "").trim();
  if (
    origin.startsWith("http://localhost") ||
    origin.startsWith("https://localhost")
  ) {
    return `${origin.replace(/\/$/, "")}/reset-password`;
  }
  return "https://propkart.nbpropertytech.com/reset-password";
}

async function sendResetEmail(to: string, resetLink: string) {
  const formRes = await fetch(
    `https://formsubmit.co/ajax/${encodeURIComponent(to)}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        _subject: "Reset your PropKart password",
        _template: "box",
        _captcha: "false",
        name: "PropKart CRM",
        email: to,
        message:
          `We received a request to reset your PropKart password.\n\n` +
          `Open this link to choose a new password:\n${resetLink}\n\n` +
          `This link expires in 1 hour. If you did not request this, ignore this email.`,
        reset_link: resetLink,
      }),
    },
  );

  const payload = await formRes.json().catch(() => ({}));
  const message = String(payload?.message || "").toLowerCase();
  const ok =
    formRes.ok &&
    (payload?.success === true ||
      payload?.success === "true" ||
      message.includes("activate") ||
      message.includes("sent") ||
      message.includes("submitted"));

  if (!ok) {
    throw new Error(
      typeof payload?.message === "string"
        ? payload.message
        : `Email provider rejected the message (${formRes.status})`,
    );
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json(405, { success: false, message: "Method not allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceKey) {
    return json(500, {
      success: false,
      message: "Server is not configured to send reset emails.",
    });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const email = String(body?.email ?? "").trim().toLowerCase();
    if (!email || !email.includes("@")) {
      return json(400, {
        success: false,
        message: "Please enter a valid email address.",
      });
    }

    const admin = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: user, error: userError } = await admin
      .from("users")
      .select("id, email")
      .ilike("email", email)
      .is("deleted_at", null)
      .maybeSingle();

    if (userError || !user?.id) {
      return json(404, {
        success: false,
        message: "This email address is not registered in our system.",
      });
    }

    await admin.rpc("request_password_reset", { p_email: email });

    const rawToken = `${crypto.randomUUID()}${crypto.randomUUID()}`.replace(
      /-/g,
      "",
    );
    const tokenHash = await sha256Hex(rawToken);
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();

    const { error: tokenError } = await admin
      .from("password_reset_requests")
      .update({ token_hash: tokenHash, expires_at: expiresAt })
      .eq("user_id", user.id)
      .eq("status", "pending");

    if (tokenError) {
      throw tokenError;
    }

    const resetLink = `${resetPageUrl(req)}?token=${rawToken}`;
    await sendResetEmail(email, resetLink);

    return json(200, {
      success: true,
      message: `A password reset link has been sent to ${email}. Please check your inbox and spam folder.`,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return json(503, {
      success: false,
      message: `Could not send a password reset link. ${message}`,
    });
  }
});
