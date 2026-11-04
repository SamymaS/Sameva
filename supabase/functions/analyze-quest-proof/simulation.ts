// supabase/functions/analyze-quest-proof/simulation.ts
//
// Oracle SIMULÉ, réservé au banc d'essai local (tools/banc). Permet de tester
// tout le parcours sans clé Anthropic et de façon déterministe.
//
// Il ne s'active que si ORACLE_VISION=simulation ET que SUPABASE_URL pointe
// sur la machine locale : impossible à activer par erreur en production.
//
// Règle de jeu de la simulation, selon la luminosité moyenne de la photo :
//   - sombre (< 40)        → photo ratée : score 15, rien d'observé ;
//   - très claire (> 215)  → « ancienne photo » : score 90, défi absent ;
//   - sinon                → preuve valable : score 85, défi observé tel que demandé.

import { decode, Image } from "https://deno.land/x/imagescript@1.3.0/mod.ts";
import type { ImageInfo, Verdict } from "./logic.ts";
import { sha256Hex } from "./logic.ts";

export function simulationAllowed(env: { get(k: string): string | undefined }): boolean {
  if (env.get("ORACLE_VISION") !== "simulation") return false;
  try {
    const host = new URL(env.get("SUPABASE_URL") ?? "").hostname;
    // « kong » : passerelle de la pile Supabase locale (supabase start), jamais en production.
    return host === "127.0.0.1" || host === "localhost" || host === "host.docker.internal" || host === "kong";
  } catch {
    return false;
  }
}

async function brightness(bytes: Uint8Array): Promise<number> {
  const img = await decode(bytes);
  if (!(img instanceof Image)) return 128;
  const small = img.resize(16, 16);
  let sum = 0;
  for (let y = 1; y <= 16; y++) {
    for (let x = 1; x <= 16; x++) {
      const [r, g, b] = small.getRGBAAt(x, y);
      sum += 0.299 * r + 0.587 * g + 0.114 * b;
    }
  }
  return sum / 256;
}

/** Fabrique un callVision simulé ; `lookup` retrouve le défi attendu d'une photo. */
export function simulatedVision(
  lookup: (sha256: string) => Promise<{ gesture: string | null; number: string | null } | null>,
) {
  return async (image: ImageInfo, _title: string, _category: string, challengeRequired: boolean): Promise<Verdict> => {
    const level = await brightness(image.bytes);
    if (level < 40) {
      return { score: 15, observedGesture: null, observedCode: null, explanation: "[simulation] Photo trop sombre." };
    }
    if (level > 215 || !challengeRequired) {
      return { score: 90, observedGesture: null, observedCode: null, explanation: "[simulation] Preuve nette, défi absent." };
    }
    const expected = await lookup(await sha256Hex(image.bytes));
    return {
      score: 85,
      observedGesture: expected?.gesture ?? null,
      observedCode: expected?.number ?? null,
      explanation: "[simulation] Preuve et défi visibles, bravo !",
    };
  };
}
