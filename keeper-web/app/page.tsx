"use client";

import React, { useState, useEffect, useRef } from 'react';
import { Mic, Send } from 'lucide-react';
import { OpenAIService } from '@/lib/openai';
import { SafetyService } from '@/lib/safety';
import { LogsService, Log } from '@/lib/logs';
import { GhostLogCard } from '@/components/chat/GhostLogCard';

export default function ChatScreen() {
    const [input, setInput] = useState('');
    const [isProcessing, setIsProcessing] = useState(false);
    const [logs, setLogs] = useState<Log[]>([]);
    const [draftLog, setDraftLog] = useState<any>(null);
    const messagesEndRef = useRef<HTMLDivElement>(null);

    // Scroll to bottom on new logs
    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    };

    useEffect(() => {
        scrollToBottom();
    }, [logs, draftLog]);

    // Load logs on mount
    useEffect(() => {
        loadLogs();
    }, []);

    const loadLogs = async () => {
        try {
            // TODO: Get actual family_id from auth context
            const familyId = '00000000-0000-0000-0000-000000000000';
            const fetchedLogs = await LogsService.fetchLogs(familyId);
            if (fetchedLogs) {
                setLogs(fetchedLogs);
            }
        } catch (error) {
            console.error('Failed to load logs:', error);
        }
    };

    const handleSend = async (e?: React.FormEvent) => {
        e?.preventDefault();
        if (!input.trim()) return;

        setIsProcessing(true);
        try {
            // 1. Parse with AI
            const parsedData = await OpenAIService.parseLog(input);

            // 2. Check Safety
            if (parsedData.event_type === 'medication') {
                const safetyWarning = SafetyService.checkMedication(parsedData.structured_data);
                if (safetyWarning) {
                    parsedData.safety_warning = safetyWarning;
                }
            }

            // 3. Set Draft for Confirmation
            setDraftLog({
                ...parsedData,
                raw_text: input,
                timestamp: new Date().toISOString(),
            });

            setInput('');
        } catch (error) {
            console.error('Error processing log:', error);
            // TODO: Show error toast
        } finally {
            setIsProcessing(false);
        }
    };

    const handleConfirm = async () => {
        if (!draftLog) return;

        try {
            // Save to Supabase
            const newLog = await LogsService.saveLog({
                family_id: '00000000-0000-0000-0000-000000000000', // Placeholder
                creator_id: '00000000-0000-0000-0000-000000000000', // Placeholder
                event_type: draftLog.event_type,
                raw_text: draftLog.raw_text,
                structured_data: draftLog.structured_data,
                is_confirmed: true,
            });

            // Optimistic Update
            setLogs([newLog, ...logs]);
            setDraftLog(null);
        } catch (error) {
            console.error('Failed to save log:', error);
        }
    };

    return (
        <div className="flex flex-col h-full bg-slate-900">
            {/* Header */}
            <div className="px-6 py-4 border-b border-slate-800 bg-slate-900 z-10">
                <h1 className="text-xl font-bold text-slate-50">Keeper</h1>
                <p className="text-sm text-slate-400">The Silent Guardian</p>
            </div>

            {/* Chat Stream */}
            <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4">
                {/* Welcome Message */}
                <div className="bg-slate-800/50 p-4 rounded-2xl self-start max-w-[85%] text-slate-50">
                    I'm ready. Tell me when the baby last ate or slept.
                </div>

                {/* Logs Stream (Reversed for Chat UI? No, standard list is fine, usually bottom up) */}
                {/* Actually, let's render them in order, but scroll to bottom. */}
                {/* Wait, fetchLogs orders by created_at DESC. So newest first. */}
                {/* Chat usually shows oldest at top, newest at bottom. */}
                {/* Let's reverse the array for display so it flows like a chat. */}
                {[...logs].reverse().map((log) => (
                    <div key={log.id} className="bg-slate-800 p-4 rounded-2xl self-end max-w-[85%] border-l-4 border-indigo-400 ml-auto">
                        <div className="text-xs text-indigo-400 font-bold uppercase mb-1">
                            {log.event_type}
                        </div>
                        <div className="text-slate-50">
                            {log.raw_text || JSON.stringify(log.structured_data)}
                        </div>
                        <div className="text-xs text-slate-500 mt-2">
                            {new Date(log.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </div>
                    </div>
                ))}

                {/* Ghost Log (Draft) */}
                {draftLog && (
                    <div className="animate-in fade-in slide-in-from-bottom-4 duration-300">
                        <GhostLogCard
                            data={draftLog}
                            onConfirm={handleConfirm}
                            onEdit={() => console.log('Edit requested')}
                        />
                    </div>
                )}

                {isProcessing && (
                    <div className="flex justify-center p-4">
                        <div className="animate-pulse text-indigo-400 text-sm">Processing...</div>
                    </div>
                )}

                <div ref={messagesEndRef} />
            </div>

            {/* Input Area */}
            <div className="p-4 bg-slate-900/95 border-t border-slate-800 backdrop-blur-sm">
                <form onSubmit={handleSend} className="flex items-center gap-3">
                    <button
                        type="button"
                        className="w-12 h-12 rounded-full bg-slate-800 flex items-center justify-center text-slate-50 hover:bg-slate-700 transition-colors"
                        onClick={() => console.log('Mic pressed')}
                    >
                        <Mic size={24} />
                    </button>

                    <div className="flex-1 bg-slate-800 rounded-full px-4 py-2 flex items-center">
                        <input
                            className="flex-1 bg-transparent text-slate-50 text-base h-10 outline-none placeholder:text-slate-500"
                            placeholder="Type a log..."
                            value={input}
                            onChange={(e) => setInput(e.target.value)}
                        />
                    </div>

                    <button
                        type="submit"
                        disabled={!input.trim()}
                        className={`w-12 h-12 rounded-full flex items-center justify-center transition-all ${input.trim()
                                ? 'bg-indigo-500 text-slate-900 hover:bg-indigo-400'
                                : 'bg-slate-800 text-slate-600'
                            }`}
                    >
                        <Send size={20} />
                    </button>
                </form>
            </div>
        </div>
    );
}
