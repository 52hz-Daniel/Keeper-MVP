// Vercel serverless function: keeps OPENAI_API_KEY server-side for the public demo.
const SYSTEM_PROMPT = `You are Keeper, the Family Chief of Staff for a baby-tracking app. Extract structured parenting data from the user's message.
Tone: calm, brief, warm.
Respond ONLY with JSON in one of two shapes:
1) A log: { "event_type": "feed" | "sleep" | "diaper" | "medication" | "symptom" | "other", "structured_data": { ...relevant fields e.g. amount (number), unit, drug, type, temperature, notes } }
   For medication, always include "drug" and "amount" (null if not stated).
2) If the user asks a question (e.g. "Is this normal?"), { "reply": "<brief plain-text answer based on standard AAP guidance>" }
Current date: `;

const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 8;
const hits = new Map(); // best-effort per-instance limiter

module.exports = async function handler(req, res) {
    if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });

    const ip = String(req.headers['x-forwarded-for'] || 'unknown').split(',')[0].trim();
    const now = Date.now();
    const recent = (hits.get(ip) || []).filter((t) => now - t < WINDOW_MS);
    if (recent.length >= MAX_PER_WINDOW) return res.status(429).json({ error: 'Too many requests' });
    hits.set(ip, [...recent, now]);

    const input = typeof req.body?.input === 'string' ? req.body.input.trim().slice(0, 300) : '';
    if (!input) return res.status(400).json({ error: 'Missing input' });
    if (!process.env.OPENAI_API_KEY) return res.status(503).json({ error: 'AI not configured' });

    try {
        const r = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
            },
            body: JSON.stringify({
                model: 'gpt-4o-mini',
                response_format: { type: 'json_object' },
                max_tokens: 300,
                messages: [
                    { role: 'system', content: SYSTEM_PROMPT + new Date().toISOString() },
                    { role: 'user', content: input },
                ],
            }),
        });
        if (!r.ok) return res.status(502).json({ error: 'Upstream error' });
        const data = await r.json();
        return res.status(200).json(JSON.parse(data.choices[0].message.content));
    } catch (e) {
        return res.status(500).json({ error: 'Failed to parse' });
    }
};
