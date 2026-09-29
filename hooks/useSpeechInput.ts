import { useCallback, useEffect, useRef, useState } from 'react';
import { Platform } from 'react-native';

/**
 * Voice-to-text via the browser Web Speech API (free, no key; Chrome/Edge/Safari).
 * Native iOS/Android would need a dev build with a speech module, so `supported` is false there.
 */
export function useSpeechInput(onTranscript: (text: string) => void) {
    const [listening, setListening] = useState(false);
    const recognitionRef = useRef<any>(null);
    const callbackRef = useRef(onTranscript);
    callbackRef.current = onTranscript;

    const SpeechRecognition =
        Platform.OS === 'web' && typeof window !== 'undefined'
            ? (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition
            : undefined;
    const supported = !!SpeechRecognition;

    useEffect(() => () => recognitionRef.current?.abort(), []);

    const toggle = useCallback(() => {
        if (!SpeechRecognition) return;
        if (listening) {
            recognitionRef.current?.stop();
            return;
        }
        const rec = new SpeechRecognition();
        rec.lang = 'en-US';
        rec.interimResults = true;
        rec.continuous = false;
        rec.onresult = (e: any) => {
            const text = Array.from(e.results).map((r: any) => r[0].transcript).join('');
            callbackRef.current(text);
        };
        rec.onend = () => setListening(false);
        rec.onerror = () => setListening(false);
        recognitionRef.current = rec;
        setListening(true);
        rec.start();
    }, [SpeechRecognition, listening]);

    return { supported, listening, toggle };
}
