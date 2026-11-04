// supabase/functions/analyze-quest-proof/dhash.test.ts
// Exécution : deno test supabase/functions/analyze-quest-proof/dhash.test.ts

import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { Image } from "https://deno.land/x/imagescript@1.3.0/mod.ts";
import { computeDhash, dhashFromGray, hammingDistance } from "./dhash.ts";

/** Image de test : dégradé et motif, pour une empreinte non triviale. */
function scene(variant = 0): Image {
  const img = new Image(320, 240);
  for (let y = 1; y <= 240; y++) {
    for (let x = 1; x <= 320; x++) {
      const v = (x * 0.6 + Math.sin((y + variant) / 9) * 70 + (((x >> 5) + (y >> 5)) % 2) * 60) | 0;
      const c = Math.max(0, Math.min(255, v));
      img.setPixelAt(x, y, Image.rgbaToColor(c, (c * 0.8) | 0, 255 - c, 255));
    }
  }
  return img;
}

Deno.test("dhashFromGray : dégradé croissant → 0, décroissant → tous les bits", () => {
  const up = Array.from({ length: 72 }, (_, i) => i % 9);
  const down = Array.from({ length: 72 }, (_, i) => 9 - (i % 9));
  assertEquals(dhashFromGray(up), 0n);
  assertEquals(dhashFromGray(down), -1n);
});

Deno.test("hammingDistance compte les bits différents", () => {
  assertEquals(hammingDistance(0n, -1n), 64);
  assertEquals(hammingDistance(5n, 6n), 2);
});

Deno.test("même photo recompressée → empreinte quasi identique", async () => {
  const original = scene();
  const a = BigInt((await computeDhash(await original.encodeJPEG(95)))!);
  const b = BigInt((await computeDhash(await original.clone().resize(300, 225).encodeJPEG(40)))!);
  assert(hammingDistance(a, b) <= 4, `distance ${hammingDistance(a, b)}`);
});

Deno.test("scène différente → empreinte éloignée", async () => {
  const a = BigInt((await computeDhash(await scene(0).encodeJPEG(90)))!);
  const b = BigInt((await computeDhash(await scene(0).rotate(180).encodeJPEG(90)))!);
  assert(hammingDistance(a, b) > 10, `distance ${hammingDistance(a, b)}`);
});

Deno.test("octets illisibles → null, sans exception", async () => {
  assertEquals(await computeDhash(new Uint8Array([0xff, 0xd8, 0xff, 0, 1, 2])), null);
});

Deno.test("normalizeImage : réduit à 1280 px, réencode en JPEG, calcule l'empreinte", async () => {
  const { normalizeImage } = await import("./dhash.ts");
  const { decode } = await import("https://deno.land/x/imagescript@1.3.0/mod.ts");
  const big = scene().resize(2560, 1920);
  const out = await normalizeImage(await big.encode());
  if (!out) throw new Error("normalisation attendue");
  const bytes = Uint8Array.from(atob(out.base64), (c) => c.charCodeAt(0));
  assertEquals([bytes[0], bytes[1], bytes[2]], [0xff, 0xd8, 0xff]);
  const back = await decode(bytes) as Image;
  assertEquals([back.width, back.height], [1280, 960]);
  assert(/^-?\d+$/.test(out.dhash));
});

Deno.test("normalizeImage : image illisible ou minuscule → null", async () => {
  const { normalizeImage } = await import("./dhash.ts");
  assertEquals(await normalizeImage(new Uint8Array([0xff, 0xd8, 0xff, 0, 1, 2])), null);
  assertEquals(await normalizeImage(await new Image(16, 16).encodeJPEG(90)), null);
});
