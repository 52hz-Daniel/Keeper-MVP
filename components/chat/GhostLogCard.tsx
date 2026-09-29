import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { Check, Edit2, AlertTriangle } from 'lucide-react-native';
import clsx from 'clsx';

interface GhostLogCardProps {
    data: any;
    onConfirm: () => void;
    onEdit: () => void;
    isConfirmed?: boolean;
}

export function GhostLogCard({ data, onConfirm, onEdit, isConfirmed = false }: GhostLogCardProps) {
    const isMedical = data.event_type === 'medication';
    const hasWarning = data.safety_warning || (isMedical && !data.structured_data?.amount);

    if (isConfirmed) {
        return (
            <View className="bg-slate-800 p-4 rounded-2xl mb-4 border border-slate-700 flex-row justify-between items-center">
                <View>
                    <Text className="text-cream font-bold text-lg capitalize">
                        {data.event_type}
                    </Text>
                    <Text className="text-slate-400">
                        {data.structured_data?.amount ? `${data.structured_data.amount}${data.structured_data.unit || ''}` : data.raw_text}
                    </Text>
                </View>
                <View className="bg-green-900/50 p-2 rounded-full">
                    <Check size={20} color="#4ade80" />
                </View>
            </View>
        );
    }

    return (
        <View className={clsx(
            "p-4 rounded-2xl mb-4 border-2 border-dashed",
            hasWarning ? "bg-red-900/20 border-coral" : "bg-slate-800 border-lavender"
        )}>
            <View className="flex-row justify-between items-start mb-2">
                <View>
                    <Text className={clsx(
                        "font-bold text-lg capitalize",
                        hasWarning ? "text-coral" : "text-lavender"
                    )}>
                        {data.event_type}
                    </Text>
                    <Text className={clsx(
                        "text-base",
                        hasWarning ? "text-red-200" : "text-cream"
                    )}>
                        {data.structured_data?.amount ? `${data.structured_data.amount}${data.structured_data.unit || ''}` : data.raw_text}
                    </Text>
                </View>
                {hasWarning && (
                    <AlertTriangle size={24} color="#FB7185" />
                )}
            </View>

            {hasWarning && (
                <Text className="text-coral mb-3 font-medium">
                    ⚠️ {data.safety_warning || "Please check details."}
                </Text>
            )}

            <View className="flex-row gap-3 mt-2">
                <TouchableOpacity
                    onPress={onConfirm}
                    className="flex-1 bg-lavender p-3 rounded-xl flex-row justify-center items-center"
                >
                    <Check size={20} color="#0F172A" className="mr-2" />
                    <Text className="text-midnight font-bold text-lg">Confirm</Text>
                </TouchableOpacity>

                <TouchableOpacity
                    onPress={onEdit}
                    className="bg-slate-700 p-3 rounded-xl border border-slate-600 justify-center items-center"
                >
                    <Edit2 size={20} color="#94a3b8" />
                </TouchableOpacity>
            </View>
        </View>
    );
}
