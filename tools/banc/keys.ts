// Génère les clés anon et service_role du banc (JWT HS256 signés avec JWT_SECRET).
const secret = Deno.env.get("JWT_SECRET")!;
const enc = (o: unknown) =>
  btoa(JSON.stringify(o)).replaceAll("=", "").replaceAll("+", "-").replaceAll("/", "_");
async function sign(role: string): Promise<string> {
  const header = enc({ alg: "HS256", typ: "JWT" });
  const payload = enc({ iss: "supabase-banc", role, iat: 1700000000, exp: 4102444800 });
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${header}.${payload}`)));
  const b64 = btoa(String.fromCharCode(...sig)).replaceAll("=", "").replaceAll("+", "-").replaceAll("/", "_");
  return `${header}.${payload}.${b64}`;
}
console.log(`ANON_KEY=${await sign("anon")}`);
console.log(`SERVICE_ROLE_KEY=${await sign("service_role")}`);
