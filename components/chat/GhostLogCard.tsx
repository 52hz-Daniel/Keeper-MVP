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
    const isMedical = data.event === 'medication';
    const hasWarning = data.warning || (isMedical && !data.amount);

    if (isConfirmed) {
        return (
            <View className="bg-white dark:bg-slate-800 p-4 rounded-2xl mb-4 border border-slate-200 dark:border-slate-700 flex-row justify-between items-center">
                <View>
                    <Text className="text-slate-900 dark:text-slate-50 font-bold text-lg capitalize">
                        {data.event}
                    </Text>
                    <Text className="text-slate-500 dark:text-slate-400">
                        {data.amount ? `${data.amount}${data.unit || ''}` : data.raw_text}
                    </Text>
                </View>
                <View className="bg-green-100 dark:bg-green-900 p-2 rounded-full">
                    <Check size={20} color="#16a34a" />
                </View>
            </View>
        );
    }

    return (
        <View className={clsx(
            "p-4 rounded-2xl mb-4 border-2 border-dashed",
            hasWarning ? "bg-red-50 border-red-200" : "bg-indigo-50 border-indigo-300"
        )}>
            <View className="flex-row justify-between items-start mb-2">
                <View>
                    <Text className={clsx(
                        "font-bold text-lg capitalize",
                        hasWarning ? "text-red-900" : "text-indigo-900"
                    )}>
                        {data.event}
                    </Text>
                    <Text className={clsx(
                        "text-base",
                        hasWarning ? "text-red-700" : "text-indigo-700"
                    )}>
                        {data.amount ? `${data.amount}${data.unit || ''}` : data.raw_text}
                    </Text>
                </View>
                {hasWarning && (
                    <AlertTriangle size={24} color="#dc2626" />
                )}
            </View>

            {hasWarning && (
                <Text className="text-red-600 mb-3 font-medium">
                    ⚠️ {data.warning || "Please check details."}
                </Text>
            )}

            <View className="flex-row gap-3 mt-2">
                <TouchableOpacity
                    onPress={onConfirm}
                    className="flex-1 bg-green-600 p-3 rounded-xl flex-row justify-center items-center"
                >
                    <Check size={20} color="white" className="mr-2" />
                    <Text className="text-white font-bold text-lg">Confirm</Text>
                </TouchableOpacity>

                <TouchableOpacity
                    onPress={onEdit}
                    className="bg-white p-3 rounded-xl border border-slate-200 justify-center items-center"
                >
                    <Edit2 size={20} color="#64748b" />
                </TouchableOpacity>
            </View>
        </View>
    );
}
