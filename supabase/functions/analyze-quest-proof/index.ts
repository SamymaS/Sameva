// Edge Function : analyse d'image par IA (OpenAI GPT-4 Vision)
// Reçoit image_base64 + quest_title + quest_category, renvoie { score, explanation }
// Référence : https://supabase.com/docs/guides/functions/quickstart

// Types pour l'exécution Deno (Supabase Edge Functions) — évite "Cannot find name 'Deno'" dans l'IDE
declare const Deno: {
  env: { get(key: string): string | undefined };
  serve: (handler: (req: Request) => Promise<Response> | Response) => void;
};

const OPENAI_API_URL = "https://api.openai.com/v1/chat/completions";
const MODEL = "gpt-4o"; // ou "gpt-4-turbo" si disponible

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface RequestBody {
  image_base64: string;
  quest_title: string;
  quest_category: string;
}

interface ValidationResponse {
  score: number;
  explanation: string;
}

function buildSystemPrompt(questTitle: string, questCategory: string): string {
  return `Tu es un assistant qui évalue si une photo prouve qu'une tâche (quête) a été réalisée.

Quête à vérifier :
- Titre : "${questTitle}"
- Catégorie : "${questCategory}"

Règles :
- Score de 0 à 100 : 100 = preuve parfaite, 0 = aucune preuve.
- Sois strict : 70 ou plus seulement si la preuve est clairement convaincante.
- Réponds UNIQUEMENT avec un JSON valide, sans markdown, sans texte autour :
{"score": <nombre 0-100>, "explanation": "<phrase courte expliquant ton jugement>"}`;
}

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Méthode non autorisée. Utilisez POST." }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    return new Response(
      JSON.stringify({
        error: "OPENAI_API_KEY non configuré. Utilisez supabase secrets set OPENAI_API_KEY=...",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  let body: RequestBody;
  try {
    body = (await req.json()) as RequestBody;
  } catch {
    return new Response(
      JSON.stringify({ error: "Body JSON invalide." }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const { image_base64, quest_title, quest_category } = body;
  if (!image_base64 || !quest_title || !quest_category) {
    return new Response(
      JSON.stringify({
        error:
          "Champs requis : image_base64, quest_title, quest_category.",
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // Format attendu par OpenAI Vision : data:image/jpeg;base64,<data>
  const imageUrl = image_base64.startsWith("data:")
    ? image_base64
    : `data:image/jpeg;base64,${image_base64}`;

  const systemPrompt = buildSystemPrompt(quest_title, quest_category);

  const openaiBody = {
    model: MODEL,
    max_tokens: 300,
    messages: [
      { role: "system", content: systemPrompt },
      {
        role: "user",
        content: [
          { type: "text", text: "Évalue cette image pour la quête donnée." },
          {
            type: "image_url",
            image_url: { url: imageUrl },
          },
        ],
      },
    ],
  };

  let openaiResponse: Response;
  try {
    openaiResponse = await fetch(OPENAI_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(openaiBody),
    });
  } catch (e) {
    return new Response(
      JSON.stringify({
        error: "Erreur lors de l'appel OpenAI.",
        detail: String(e),
      }),
      {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  if (!openaiResponse.ok) {
    const errText = await openaiResponse.text();
    return new Response(
      JSON.stringify({
        error: "OpenAI a renvoyé une erreur.",
        status: openaiResponse.status,
        detail: errText.slice(0, 500),
      }),
      {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const openaiData = await openaiResponse.json();
  const content =
    openaiData?.choices?.[0]?.message?.content?.trim() ?? "";

  // Extraire le JSON de la réponse (parfois entouré de ```json ... ```)
  let jsonStr = content;
  const jsonMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) jsonStr = jsonMatch[1].trim();
  else jsonStr = content.trim();

  let parsed: ValidationResponse;
  try {
    parsed = JSON.parse(jsonStr) as ValidationResponse;
  } catch {
    return new Response(
      JSON.stringify({
        error: "Réponse IA non parsable en JSON.",
        raw: content.slice(0, 300),
      }),
      {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  const score = Math.min(100, Math.max(0, Number(parsed.score) || 0));
  const explanation =
    typeof parsed.explanation === "string"
      ? parsed.explanation
      : "Analyse effectuée.";

  return new Response(
    JSON.stringify({ score, explanation }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
});
