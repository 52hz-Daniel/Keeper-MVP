import React, { useState, useEffect } from 'react';
import { View, TextInput, TouchableOpacity, Text, ScrollView, KeyboardAvoidingView, Platform, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Mic, MicOff, Send } from 'lucide-react-native';
import { OpenAIService } from '../../lib/openai';
import { SafetyService } from '../../lib/safety';
import { LogsService } from '../../lib/logs';
import { useSpeechInput } from '../../hooks/useSpeechInput';
import { GhostLogCard } from '../../components/chat/GhostLogCard';
import { Database } from '../../types/schema';

type Log = Database['public']['Tables']['logs']['Row'];

export default function ChatScreen() {
    const [input, setInput] = useState('');
    const [isProcessing, setIsProcessing] = useState(false);
    const [logs, setLogs] = useState<Log[]>([]);
    const [draftLog, setDraftLog] = useState<any>(null);
    const [aiReply, setAiReply] = useState<string | null>(null);
    const [notice, setNotice] = useState<string | null>(null);
    const { supported: voiceSupported, listening, toggle: toggleVoice } = useSpeechInput(setInput);

    const handleMic = () => {
        if (!voiceSupported) {
            setNotice("Voice input isn't supported in this browser. Try Chrome or Safari, or use your keyboard's mic.");
            return;
        }
        setNotice(null);
        toggleVoice();
    };

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

    const handleSend = async () => {
        if (!input.trim()) return;

        setIsProcessing(true);
        setAiReply(null);
        setNotice(null);
        try {
            // 1. Parse with AI
            const parsedData = await OpenAIService.parseLog(input);

            // Questions come back as a plain-text reply instead of a log
            if (parsedData.reply) {
                setAiReply(parsedData.reply);
                setInput('');
                return;
            }

            // 2. Check Safety
            if (parsedData.event_type === 'medication') {
                const { drug, amount } = parsedData.structured_data || {};
                const result = SafetyService.checkMedication(String(drug ?? ''), String(amount ?? ''), 3); // TODO: real baby age
                if (result.warning) {
                    parsedData.safety_warning = result.warning;
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
            setNotice("Couldn't process that. Please try again.");
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
        <SafeAreaView className="flex-1 bg-midnight">
            <KeyboardAvoidingView
                behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
                className="flex-1"
            >
                {/* Header */}
                <View className="px-6 py-4 border-b border-slate-800">
                    <Text className="text-xl font-bold text-cream">Keeper</Text>
                    <Text className="text-sm text-slate-400">The Silent Guardian</Text>
                </View>

                {/* Chat Stream */}
                <ScrollView className="flex-1 px-4 py-4">
                    {/* Welcome Message */}
                    <View className="bg-slate-800/50 p-4 rounded-2xl mb-4 self-start max-w-[85%]">
                        <Text className="text-cream">
                            I'm ready. Tell me when the baby last ate or slept.
                        </Text>
                    </View>

                    {/* Logs Stream */}
                    {logs.map((log) => (
                        <View key={log.id} className="bg-slate-800 p-4 rounded-2xl mb-4 self-end max-w-[85%] border-l-4 border-lavender">
                            <Text className="text-xs text-lavender font-bold uppercase mb-1">
                                {log.event_type}
                            </Text>
                            <Text className="text-cream">
                                {log.raw_text || JSON.stringify(log.structured_data)}
                            </Text>
                            <Text className="text-xs text-slate-500 mt-2">
                                {new Date(log.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </Text>
                        </View>
                    ))}

                    {aiReply && (
                        <View className="bg-slate-800/50 p-4 rounded-2xl mb-4 self-start max-w-[85%]">
                            <Text className="text-cream">{aiReply}</Text>
                        </View>
                    )}

                    {/* Ghost Log (Draft) */}
                    {draftLog && (
                        <View className="mb-4">
                            <GhostLogCard
                                data={draftLog}
                                onConfirm={handleConfirm}
                                onEdit={() => console.log('Edit requested')}
                            />
                        </View>
                    )}

                    {isProcessing && (
                        <View className="self-center p-4">
                            <ActivityIndicator color="#818CF8" />
                            <Text className="text-slate-400 text-xs text-center mt-2">Processing...</Text>
                        </View>
                    )}
                </ScrollView>

                {notice && (
                    <Text className="text-coral text-xs px-6 py-2 bg-slate-900/90">{notice}</Text>
                )}

                {/* Input Area */}
                <View className="p-4 bg-slate-900/90 border-t border-slate-800">
                    <View className="flex-row items-center space-x-3">
                        <TouchableOpacity
                            className={`w-12 h-12 rounded-full items-center justify-center ${listening ? 'bg-coral' : 'bg-slate-800'}`}
                            onPress={handleMic}
                        >
                            {listening ? <MicOff size={24} color="#0F172A" /> : <Mic size={24} color="#F1F5F9" />}
                        </TouchableOpacity>

                        <View className="flex-1 bg-slate-800 rounded-full px-4 py-2 flex-row items-center">
                            <TextInput
                                className="flex-1 text-cream text-base h-10"
                                placeholder={listening ? "Listening..." : "Type a log..."}
                                placeholderTextColor="#64748B"
                                value={input}
                                onChangeText={setInput}
                                onSubmitEditing={handleSend}
                            />
                        </View>

                        <TouchableOpacity
                            className={`w-12 h-12 rounded-full items-center justify-center ${input.trim() ? 'bg-lavender' : 'bg-slate-800'}`}
                            onPress={handleSend}
                            disabled={!input.trim()}
                        >
                            <Send size={20} color={input.trim() ? '#0F172A' : '#64748B'} />
                        </TouchableOpacity>
                    </View>
                </View>
            </KeyboardAvoidingView>
        </SafeAreaView>
    );
}
