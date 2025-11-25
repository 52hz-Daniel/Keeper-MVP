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
    async parseLog(text: string) {
        try {
            const completion = await openai.chat.completions.create({
                messages: [
                    { role: 'system', content: SYSTEM_PROMPT },
                    { role: 'user', content: text },
                ],
                model: 'gpt-4o-mini',
                response_format: { type: 'json_object' },
            });

            const content = completion.choices[0].message.content;
            if (!content) throw new Error('No content returned');

            return JSON.parse(content);
        } catch (error) {
            console.error('OpenAI Error:', error);
            // Fallback mock for dev without API key
            return {
                event: 'note',
                raw_text: text,
                error: 'AI_FAILED',
            };
        }
    },
};
