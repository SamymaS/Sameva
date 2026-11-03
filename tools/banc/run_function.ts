// Lance une Edge Function Supabase sur un port donné (banc d'essai).
// Les fonctions appellent `Deno.serve(handler)` sans port : on fixe le port
// et l'hôte avant d'importer le module.
const port = Number(Deno.env.get("FN_PORT"));
const entry = Deno.env.get("FN_ENTRY")!;
const original = Deno.serve.bind(Deno);
// deno-lint-ignore no-explicit-any
(Deno as any).serve = (a: any, b?: any) =>
  typeof a === "function"
    ? original({ port, hostname: "127.0.0.1" }, a)
    : original({ ...a, port, hostname: "127.0.0.1" }, b);
await import(new URL(entry, `file://${Deno.cwd()}/`).href);
