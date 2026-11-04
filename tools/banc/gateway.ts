// Passerelle du banc : imite l'API Gateway (Kong) de Supabase sur un seul port.
//   /rest/v1/*          → PostgREST
//   /auth/v1/*          → GoTrue
//   /functions/v1/<nom> → Edge Function <nom> (un processus Deno par fonction)
const PORT = Number(Deno.env.get("GATEWAY_PORT"));
const REST = `http://127.0.0.1:${Deno.env.get("POSTGREST_PORT")}`;
const AUTH = `http://127.0.0.1:${Deno.env.get("GOTRUE_PORT")}`;
const FUNCTIONS: Record<string, number> = JSON.parse(Deno.env.get("FUNCTION_PORTS") ?? "{}");

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, prefer, range, accept-profile, content-profile, x-supabase-api-version, accept",
  "Access-Control-Expose-Headers": "content-range, x-supabase-api-version",
};

async function forward(req: Request, target: string): Promise<Response> {
  const headers = new Headers(req.headers);
  headers.delete("host");
  const res = await fetch(target, {
    method: req.method,
    headers,
    body: ["GET", "HEAD"].includes(req.method) ? undefined : await req.arrayBuffer(),
    redirect: "manual",
  });
  const out = new Headers(res.headers);
  for (const [k, v] of Object.entries(CORS)) out.set(k, v);
  return new Response(res.body, { status: res.status, headers: out });
}

Deno.serve({ port: PORT, hostname: "127.0.0.1" }, (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS });
  const url = new URL(req.url);
  const path = url.pathname;
  if (path.startsWith("/rest/v1")) return forward(req, REST + path.slice("/rest/v1".length) + url.search);
  if (path.startsWith("/auth/v1")) return forward(req, AUTH + path.slice("/auth/v1".length) + url.search);
  const m = path.match(/^\/functions\/v1\/([\w-]+)(.*)$/);
  if (m && FUNCTIONS[m[1]]) return forward(req, `http://127.0.0.1:${FUNCTIONS[m[1]]}${m[2] || "/"}${url.search}`);
  return new Response(JSON.stringify({ error: "route inconnue du banc", path }), { status: 404, headers: CORS });
});
