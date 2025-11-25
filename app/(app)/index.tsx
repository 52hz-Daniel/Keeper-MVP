import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, ScrollView, SafeAreaView, KeyboardAvoidingView, Platform } from 'react-native';
import { Mic, Send } from 'lucide-react-native';
import { GhostLogCard } from '../../components/chat/GhostLogCard';
import { OpenAIService } from '../../lib/openai';
import { SafetyService } from '../../lib/safety';

export default function ChatScreen() {
    const [input, setInput] = useState('');
    const [logs, setLogs] = useState<any[]>([]);
    const [isRecording, setIsRecording] = useState(false);
    const [isProcessing, setIsProcessing] = useState(false);

    const handleSend = async () => {
        if (!input.trim()) return;

        const text = input;
        setInput('');
        setIsProcessing(true);

        // 1. Optimistic UI (User Message)
        const userLog = { id: Date.now().toString(), role: 'user', text };
        setLogs(prev => [userLog, ...prev]);

        // 2. AI Processing
        const parsed = await OpenAIService.parseLog(text);

        // 3. Safety Check
        if (parsed.event === 'medication') {
            const safety = SafetyService.checkMedication(parsed.drug || '', parsed.amount || '', 3); // Mock age 3 months
            if (!safety.isSafe) {
                parsed.warning = safety.warning;
            }
        }

        // 4. Ghost Log (AI Message)
        const ghostLog = {
            id: (Date.now() + 1).toString(),
            role: 'ai',
            data: parsed,
            isConfirmed: false
        };

        setLogs(prev => [ghostLog, ...prev]);
        setIsProcessing(false);
    };

    const handleConfirm = (id: string) => {
        setLogs(prev => prev.map(log =>
            log.id === id ? { ...log, isConfirmed: true } : log
        ));
        // TODO: Save to Supabase here
    };

    return (
        <SafeAreaView className="flex-1 bg-slate-50 dark:bg-slate-950">
            <View className="flex-1">
                {/* Header */}
                <View className="p-4 border-b border-slate-200 dark:border-slate-800">
                    <Text className="text-xl font-bold text-slate-900 dark:text-slate-50">
                        Keeper
                    </Text>
                    <Text className="text-sm text-slate-500">Chief of Staff</Text>
                </View>

                {/* Chat Stream */}
                <ScrollView
                    className="flex-1 px-4 py-4"
                    contentContainerStyle={{ paddingBottom: 100 }}
                >
                    {logs.length === 0 && (
                        <View className="items-center justify-center mt-20 opacity-50">
                            <Text className="text-slate-400 text-lg">No logs yet.</Text>
                            <Text className="text-slate-400">Try "Ate 4oz" or "Tylenol"</Text>
                        </View>
                    )}

                    {/* Render logs in reverse order if we prepend, but ScrollView renders top-down. 
              Usually chat is flex-col-reverse. For simple ScrollView, we map normally.
              Wait, I prepended logs in state. So I should map them.
          */}
                    {logs.map(log => (
                        <View key={log.id} className="mb-4">
                            {log.role === 'user' ? (
                                <View className="self-end bg-indigo-600 px-4 py-2 rounded-2xl rounded-tr-sm max-w-[80%]">
                                    <Text className="text-white text-lg">{log.text}</Text>
                                </View>
                            ) : (
                                <GhostLogCard
                                    data={log.data}
                                    isConfirmed={log.isConfirmed}
                                    onConfirm={() => handleConfirm(log.id)}
                                    onEdit={() => console.log('Edit')}
                                />
                            )}
                        </View>
                    ))}

                    {isProcessing && (
                        <View className="self-start bg-slate-200 dark:bg-slate-800 px-4 py-2 rounded-2xl rounded-tl-sm">
                            <Text className="text-slate-500">Thinking...</Text>
                        </View>
                    )}
                </ScrollView>

                {/* Input Area */}
                <KeyboardAvoidingView
                    behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
                    className="absolute bottom-0 left-0 right-0 p-4 bg-white dark:bg-slate-900 border-t border-slate-200 dark:border-slate-800"
                >
                    <View className="flex-row items-center gap-3">
                        <TextInput
                            className="flex-1 bg-slate-100 dark:bg-slate-800 p-4 rounded-full text-lg text-slate-900 dark:text-slate-50"
                            placeholder="Log something..."
                            placeholderTextColor="#94a3b8"
                            value={input}
                            onChangeText={setInput}
                            onSubmitEditing={handleSend}
                        />

                        {input.length > 0 ? (
                            <TouchableOpacity
                                onPress={handleSend}
                                className="bg-indigo-600 p-4 rounded-full"
                            >
                                <Send size={24} color="white" />
                            </TouchableOpacity>
                        ) : (
                            <TouchableOpacity
                                className="bg-indigo-600 p-4 rounded-full"
                                onPress={() => setIsRecording(!isRecording)}
                            >
                                <Mic size={24} color="white" className={isRecording ? "opacity-50" : "opacity-100"} />
                            </TouchableOpacity>
                        )}
                    </View>
                </KeyboardAvoidingView>
            </View>
        </SafeAreaView>
    );
}
