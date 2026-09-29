import React from 'react';
import { Check, Edit2, AlertTriangle } from 'lucide-react';
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
            <div className="bg-slate-800 p-4 rounded-2xl mb-4 border border-slate-700 flex justify-between items-center">
                <div>
                    <div className="text-slate-50 font-bold text-lg capitalize">
                        {data.event_type}
                    </div>
                    <div className="text-slate-400">
                        {data.structured_data?.amount ? `${data.structured_data.amount}${data.structured_data.unit || ''}` : data.raw_text}
                    </div>
                </div>
                <div className="bg-green-900/50 p-2 rounded-full">
                    <Check size={20} color="#4ade80" />
                </div>
            </div>
        );
    }

    return (
        <div className={clsx(
            "p-4 rounded-2xl mb-4 border-2 border-dashed transition-all",
            hasWarning ? "bg-red-900/20 border-rose-400" : "bg-slate-800 border-indigo-400"
        )}>
            <div className="flex justify-between items-start mb-2">
                <div>
                    <div className={clsx(
                        "font-bold text-lg capitalize",
                        hasWarning ? "text-rose-400" : "text-indigo-400"
                    )}>
                        {data.event_type}
                    </div>
                    <div className={clsx(
                        "text-base",
                        hasWarning ? "text-rose-200" : "text-slate-50"
                    )}>
                        {data.structured_data?.amount ? `${data.structured_data.amount}${data.structured_data.unit || ''}` : data.raw_text}
                    </div>
                </div>
                {hasWarning && (
                    <AlertTriangle size={24} color="#FB7185" />
                )}
            </div>

            {hasWarning && (
                <div className="text-rose-400 mb-3 font-medium">
                    ⚠️ {data.safety_warning || "Please check details."}
                </div>
            )}

            <div className="flex gap-3 mt-2">
                <button
                    onClick={onConfirm}
                    className="flex-1 bg-indigo-400 hover:bg-indigo-500 p-3 rounded-xl flex justify-center items-center transition-colors"
                >
                    <Check size={20} color="#0F172A" className="mr-2" />
                    <span className="text-slate-900 font-bold text-lg">Confirm</span>
                </button>

                <button
                    onClick={onEdit}
                    className="bg-slate-700 hover:bg-slate-600 p-3 rounded-xl border border-slate-600 justify-center items-center transition-colors"
                >
                    <Edit2 size={20} color="#94a3b8" />
                </button>
            </div>
        </div>
    );
}
