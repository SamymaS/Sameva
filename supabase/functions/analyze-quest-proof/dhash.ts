// supabase/functions/analyze-quest-proof/dhash.ts
//
// Empreinte perceptuelle (dHash 64 bits) : l'image est réduite à 9 × 8 pixels
// en niveaux de gris, puis chaque bit dit si un pixel est plus clair que son
// voisin de droite. Deux versions d'une même photo (recompressée, recadrée
// légèrement, retouchée) donnent des empreintes à quelques bits d'écart, alors
// que leur SHA-256 n'a plus rien en commun.

import { decode, Image } from "https://deno.land/x/imagescript@1.3.0/mod.ts";
import type { NormalizedImage } from "./logic.ts";

/** Côté le plus long de l'image transmise au modèle. */
export const MAX_SIDE = 1280;

/** Empreinte à partir de 72 niveaux de gris (9 colonnes × 8 lignes). */
export function dhashFromGray(gray: number[]): bigint {
  if (gray.length !== 72) throw new Error("dhashFromGray attend 9 × 8 valeurs");
  let hash = 0n;
  for (let y = 0; y < 8; y++) {
    for (let x = 0; x < 8; x++) {
      const brighter = gray[y * 9 + x] > gray[y * 9 + x + 1];
      hash = (hash << 1n) | (brighter ? 1n : 0n);
    }
  }
  // Postgres stocke un bigint signé : on ramène l'empreinte dans [-2^63, 2^63[.
  return BigInt.asIntN(64, hash);
}

/** Nombre de bits différents entre deux empreintes. */
export function hammingDistance(a: bigint, b: bigint): number {
  let x = BigInt.asUintN(64, a ^ b);
  let count = 0;
  while (x > 0n) {
    count += Number(x & 1n);
    x >>= 1n;
  }
  return count;
}

/**
 * Décode l'image (JPEG ou PNG) et renvoie son empreinte sous forme de chaîne
 * (un bigint dépasse la précision des nombres JSON). Renvoie null si l'image
 * ne peut pas être décodée : l'analyse continue, seule cette protection manque.
 */
export async function computeDhash(bytes: Uint8Array): Promise<string | null> {
  try {
    const decoded = await decode(bytes);
    if (!(decoded instanceof Image)) return null;
    decoded.resize(9, 8);
    const gray: number[] = [];
    for (let y = 1; y <= 8; y++) {
      for (let x = 1; x <= 9; x++) {
        const [r, g, b] = decoded.getRGBAAt(x, y);
        gray.push(0.299 * r + 0.587 * g + 0.114 * b);
      }
    }
    return dhashFromGray(gray).toString();
  } catch (e) {
    console.error("Empreinte perceptuelle impossible :", e instanceof Error ? e.message : e);
    return null;
  }
}

function dhashOf(img: Image): string {
  const small = img.clone().resize(9, 8);
  const gray: number[] = [];
  for (let y = 1; y <= 8; y++) {
    for (let x = 1; x <= 9; x++) {
      const [r, g, b] = small.getRGBAAt(x, y);
      gray.push(0.299 * r + 0.587 * g + 0.114 * b);
    }
  }
  return dhashFromGray(gray).toString();
}

function toBase64(bytes: Uint8Array): string {
  let bin = "";
  for (let i = 0; i < bytes.length; i += 0x8000) {
    bin += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  return btoa(bin);
}

/**
 * Décode l'image, la ramène à 1280 px de côté au plus et la réencode en JPEG
 * (qualité 85). Le modèle n'analyse que ce fichier : formats exotiques,
 * métadonnées (EXIF, position GPS) et charges cachées disparaissent. Renvoie
 * null si l'image ne peut pas être décodée : elle n'est alors pas analysée.
 */
export async function normalizeImage(bytes: Uint8Array): Promise<NormalizedImage | null> {
  try {
    const decoded = await decode(bytes);
    if (!(decoded instanceof Image) || decoded.width < 64 || decoded.height < 64) return null;
    const scale = Math.min(1, MAX_SIDE / Math.max(decoded.width, decoded.height));
    const img = scale < 1
      ? decoded.resize(Math.round(decoded.width * scale), Math.round(decoded.height * scale))
      : decoded;
    const jpeg = await img.encodeJPEG(85);
    return { base64: toBase64(jpeg), dhash: dhashOf(img) };
  } catch (e) {
    console.error("Image illisible :", e instanceof Error ? e.message : e);
    return null;
  }
}
