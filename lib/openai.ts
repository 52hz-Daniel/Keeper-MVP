import OpenAI from 'openai';

const openai = new OpenAI({
    apiKey: process.env.EXPO_PUBLIC_OPENAI_API_KEY,
    dangerouslyAllowBrowser: true, // Required for React Native
});

const SYSTEM_PROMPT = `You are Keeper, the Family Chief of Staff. Your job is to extract structured parenting data from natural language.
Tone: Calm, Brief, Alert, Warm. (e.g., 'Logged.' not 'Great job mama!')
Current Date: ${new Date().toISOString()}

INPUT: 'He drank 4oz of milk.'
OUTPUT: JSON { "event": "feed", "subtype": "formula", "amount": 4, "unit": "oz", "time": "current_time" }

INPUT: 'Gave him Tylenol.'
OUTPUT: JSON { "event": "medication", "drug": "Tylenol", "amount": null, "warning": "missing_dosage" }

If the user asks a question ('Is this normal?'), reply with plain text based on standard AAP guidelines, but keep it brief.`;

export const OpenAIService = {
    client: openai, // Add the OpenAI client as a property
    async parseLog(input: string): Promise<any> {
        // MOCK MODE: If no API key is present, return a simulated response.
        if (process.env.EXPO_PUBLIC_DEMO_MODE === 'true') {
            // Public demo: call the serverless proxy (key stays server-side); fall back to mock on any failure.
            try {
                const res = await fetch('/api/parse', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ input }),
                });
                if (res.ok) return await res.json();
            } catch (error) {
                console.warn('Demo AI proxy unavailable, using mock.', error);
            }
        }

        if (process.env.EXPO_PUBLIC_DEMO_MODE === 'true' || !process.env.EXPO_PUBLIC_OPENAI_API_KEY || process.env.EXPO_PUBLIC_OPENAI_API_KEY === "") {
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
