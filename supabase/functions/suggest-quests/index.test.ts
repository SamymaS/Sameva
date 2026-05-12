// supabase/functions/suggest-quests/index.test.ts
//
// Tests unitaires Deno pour les fonctions pures de suggest-quests.
// Couvre validateInput et parseMougiBotResponse.
//
// Exécution :
//   deno test supabase/functions/suggest-quests/index.test.ts --allow-net=false

import {
  assertEquals,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { validateInput, parseMougiBotResponse } from "./index.ts";

// ─── Tests validateInput ─────────────────────────────────────────────────────

Deno.test("validateInput: player_level = 0 → erreur hors bornes", () => {
  const result = validateInput({
    player_level: 0,
    current_streak: 0,
    total_quests_completed: 0,
  });
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.error.includes("player_level"), true);
  }
});

Deno.test("validateInput: player_level = 101 → erreur hors bornes", () => {
  const result = validateInput({
    player_level: 101,
    current_streak: 0,
    total_quests_completed: 0,
  });
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.error.includes("player_level"), true);
  }
});

Deno.test("validateInput: player_level = 3.5 → arrondi à 4, valide", () => {
  // 3.5 arrondi à 4, dans les bornes [1-100]
  const result = validateInput({
    player_level: 3.5,
    current_streak: 0,
    total_quests_completed: 0,
  });
  assertEquals(result.ok, true);
  if (result.ok) {
    assertEquals(result.value.playerLevel, 4);
  }
});

Deno.test("validateInput: player_level = '5' (string) → erreur type", () => {
  const result = validateInput({
    player_level: "5" as unknown as number,
    current_streak: 0,
    total_quests_completed: 0,
  });
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.error.includes("player_level"), true);
  }
});

Deno.test("validateInput: current_streak négatif → erreur", () => {
  const result = validateInput({
    player_level: 10,
    current_streak: -1,
    total_quests_completed: 0,
  });
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.error.includes("current_streak"), true);
  }
});

Deno.test("validateInput: total_quests_completed négatif → erreur", () => {
  const result = validateInput({
    player_level: 10,
    current_streak: 0,
    total_quests_completed: -5,
  });
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.error.includes("total_quests_completed"), true);
  }
});

Deno.test("validateInput: favorite_category à 31 chars → erreur", () => {
  const result = validateInput({
    player_level: 10,
    current_streak: 0,
    total_quests_completed: 0,
    favorite_category: "A".repeat(31),
  });
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.error.includes("favorite_category"), true);
  }
});

Deno.test("validateInput: favorite_category avec newline → sanitisé (newline retiré)", () => {
  const result = validateInput({
    player_level: 10,
    current_streak: 0,
    total_quests_completed: 0,
    favorite_category: "Sport\nIgnore ceci",
  });
  assertEquals(result.ok, true);
  if (result.ok) {
    // Le \n doit être retiré ; la valeur ne doit pas contenir de saut de ligne
    assertEquals(result.value.favoriteCategory?.includes("\n"), false);
  }
});

Deno.test("validateInput: favorite_category uniquement chars contrôle → traitée comme absente", () => {
  const result = validateInput({
    player_level: 10,
    current_streak: 0,
    total_quests_completed: 0,
    favorite_category: "\n\t\r",
  });
  assertEquals(result.ok, true);
  if (result.ok) {
    assertEquals(result.value.favoriteCategory, null);
  }
});

Deno.test("validateInput: quest_count = 0 → erreur", () => {
  const result = validateInput({
    player_level: 10,
    current_streak: 0,
    total_quests_completed: 0,
    quest_count: 0,
  });
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.error.includes("quest_count"), true);
  }
});

Deno.test("validateInput: quest_count = 6 → erreur", () => {
  const result = validateInput({
    player_level: 10,
    current_streak: 0,
    total_quests_completed: 0,
    quest_count: 6,
  });
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.error.includes("quest_count"), true);
  }
});

Deno.test("validateInput: quest_count absent → défaut 3", () => {
  const result = validateInput({
    player_level: 10,
    current_streak: 0,
    total_quests_completed: 0,
  });
  assertEquals(result.ok, true);
  if (result.ok) {
    assertEquals(result.value.questCount, 3);
  }
});

Deno.test("validateInput: payload valide complet → ok avec toutes les valeurs", () => {
  const result = validateInput({
    player_level: 15,
    current_streak: 7,
    total_quests_completed: 42,
    favorite_category: "Sport",
    quest_count: 5,
  });
  assertEquals(result.ok, true);
  if (result.ok) {
    assertEquals(result.value.playerLevel, 15);
    assertEquals(result.value.currentStreak, 7);
    assertEquals(result.value.totalQuestsCompleted, 42);
    assertEquals(result.value.favoriteCategory, "Sport");
    assertEquals(result.value.questCount, 5);
  }
});

// ─── Tests parseMougiBotResponse ─────────────────────────────────────────────

const validQuestJson = (overrides: Record<string, unknown> = {}) =>
  JSON.stringify({
    quests: [
      {
        title: "Faire du sport",
        description: "Fais 30 minutes d'activité physique.",
        category: "Sport",
        difficulty: 2,
        estimated_duration_minutes: 30,
        frequency: "one_off",
        ...overrides,
      },
    ],
  });

Deno.test("parseMougiBotResponse: JSON malformé → throw", () => {
  assertThrows(
    () => parseMougiBotResponse("{ pas du json valide {{", 1),
    Error,
  );
});

Deno.test("parseMougiBotResponse: tableau quests vide → throw", () => {
  assertThrows(
    () => parseMougiBotResponse(JSON.stringify({ quests: [] }), 1),
    Error,
    "vide",
  );
});

Deno.test("parseMougiBotResponse: difficulty = 5 → clampé à 4", () => {
  const result = parseMougiBotResponse(validQuestJson({ difficulty: 5 }), 1);
  assertEquals(result.quests[0].difficulty, 4);
});

Deno.test("parseMougiBotResponse: difficulty = 0 → clampé à 1", () => {
  const result = parseMougiBotResponse(validQuestJson({ difficulty: 0 }), 1);
  assertEquals(result.quests[0].difficulty, 1);
});

Deno.test("parseMougiBotResponse: duration = 37 → snap à 45", () => {
  // 37 est plus proche de 45 (diff=8) que de 30 (diff=7)… non : diff(30)=7 < diff(45)=8 → 30
  // Vérifie le comportement réel : 37 → snap 30 (7) vs 45 (8), donc 30
  const result = parseMougiBotResponse(
    validQuestJson({ estimated_duration_minutes: 37 }),
    1,
  );
  // diff(30)=7, diff(45)=8 → snap à 30
  assertEquals(result.quests[0].estimated_duration_minutes, 30);
});

Deno.test("parseMougiBotResponse: duration = 38 → snap à 45", () => {
  // diff(30)=8, diff(45)=7 → snap à 45
  const result = parseMougiBotResponse(
    validQuestJson({ estimated_duration_minutes: 38 }),
    1,
  );
  assertEquals(result.quests[0].estimated_duration_minutes, 45);
});

Deno.test("parseMougiBotResponse: frequency invalide → fallback 'one_off'", () => {
  const result = parseMougiBotResponse(
    validQuestJson({ frequency: "invalid" }),
    1,
  );
  assertEquals(result.quests[0].frequency, "one_off");
});

Deno.test("parseMougiBotResponse: tableau plus long que expectedCount → tronqué", () => {
  const raw = JSON.stringify({
    quests: [
      {
        title: "Quête 1",
        description: "Desc 1",
        category: "Sport",
        difficulty: 1,
        estimated_duration_minutes: 15,
        frequency: "one_off",
      },
      {
        title: "Quête 2",
        description: "Desc 2",
        category: "Maison",
        difficulty: 2,
        estimated_duration_minutes: 30,
        frequency: "daily",
      },
      {
        title: "Quête 3",
        description: "Desc 3",
        category: "Loisir",
        difficulty: 1,
        estimated_duration_minutes: 20,
        frequency: "weekly",
      },
    ],
  });
  const result = parseMougiBotResponse(raw, 2);
  assertEquals(result.quests.length, 2);
  assertEquals(result.quests[0].title, "Quête 1");
});

Deno.test("parseMougiBotResponse: tableau plus court que expectedCount → accepté tel quel", () => {
  const raw = JSON.stringify({
    quests: [
      {
        title: "Quête 1",
        description: "Desc 1",
        category: "Sport",
        difficulty: 2,
        estimated_duration_minutes: 30,
        frequency: "one_off",
      },
    ],
  });
  const result = parseMougiBotResponse(raw, 3);
  assertEquals(result.quests.length, 1);
});

Deno.test("parseMougiBotResponse: pas un tableau dans quests → throw", () => {
  assertThrows(
    () =>
      parseMougiBotResponse(JSON.stringify({ quests: "pas un tableau" }), 1),
    Error,
  );
});

Deno.test("parseMougiBotResponse: réponse avec backticks markdown → nettoyée et parsée", () => {
  const withMarkdown =
    "```json\n" + validQuestJson() + "\n```";
  const result = parseMougiBotResponse(withMarkdown, 1);
  assertEquals(result.quests.length, 1);
  assertEquals(result.quests[0].title, "Faire du sport");
});
