import OpenAI from 'openai';

const openai = new OpenAI({
    apiKey: process.env.NEXT_PUBLIC_OPENAI_API_KEY || '',
    dangerouslyAllowBrowser: true // Allow client-side usage for PWA
});

const SYSTEM_PROMPT = `You are Keeper, an AI for tracking baby logs.
Parse the user's input into a structured JSON format.
Output JSON ONLY. No markdown.

Schema:
{
  "event_type": "feed" | "sleep" | "diaper" | "medication" | "growth" | "note" | "symptom",
  "structured_data": {
    // Feed
    "amount": number,
    "unit": "oz" | "ml",
    "type": "formula" | "breast_milk" | "solid",
    
    // Sleep
    "duration_minutes": number,
    
    // Diaper
    "consistency": "normal" | "runny" | "hard",
    "color": string,
    
    // Medication
    "medication_name": string,
    "dosage": string,
    
    // Symptom
    "symptom": string,
    "temperature": number,
    
    // Common
    "notes": string
  }
}

If the user asks a question ('Is this normal?'), reply with plain text based on standard AAP guidelines, but keep it brief.`;

export const OpenAIService = {
    client: openai,
    async parseLog(input: string): Promise<any> {
        // MOCK MODE: If no API key is present, return a simulated response.
        if (!process.env.NEXT_PUBLIC_OPENAI_API_KEY || process.env.NEXT_PUBLIC_OPENAI_API_KEY === "") {
            console.log("⚠️ No OpenAI API Key found. Using Mock Mode.");
            await new Promise(resolve => setTimeout(resolve, 1500)); // Simulate network delay

            // Simple keyword detection for mock responses
            const lowerInput = input.toLowerCase();

            if (lowerInput.includes("fever") || lowerInput.includes("pain") || lowerInput.includes("hot")) {
                return {
                    event_type: "symptom",
                    structured_data: {
                        symptom: "fever",
                        temperature: 101.2,
                        unit: "F",
                        notes: input
                    }
                };
            }

            if (lowerInput.includes("poop") || lowerInput.includes("diaper")) {
                return {
                    event_type: "diaper",
                    structured_data: {
                        consistency: "normal",
                        color: "yellow",
                        notes: input
                    }
                };
            }

            // Default Mock Response (Feed)
            return {
                event_type: "feed",
                structured_data: {
                    amount: 4,
                    unit: "oz",
                    type: "formula",
                    notes: input
                }
            };
        }

        try {
            const completion = await this.client.chat.completions.create({
                messages: [
                    { role: "system", content: SYSTEM_PROMPT },
                    { role: "user", content: input },
                ],
                model: "gpt-4o-mini",
                response_format: { type: "json_object" },
            });

            const content = completion.choices[0].message.content;
            if (!content) throw new Error("No content received from OpenAI");

            return JSON.parse(content);
        } catch (error) {
            console.error("OpenAI Error:", error);
            throw error;
        }
    },
};
