import { supabase } from './supabase';
import { Database } from '../types/schema';

type Log = Database['public']['Tables']['logs']['Row'];
type InsertLog = Database['public']['Tables']['logs']['Insert'];
type UpdateLog = Database['public']['Tables']['logs']['Update'];

// Demo mode: keep logs in memory so the public demo needs no database and can't write to real data.
const DEMO_MODE = process.env.EXPO_PUBLIC_DEMO_MODE === 'true';
let demoLogs: Log[] = [];

export const LogsService = {
    /**
     * Fetch logs for a specific family.
     */
    async fetchLogs(familyId: string) {
        if (DEMO_MODE) return demoLogs;
        const { data, error } = await supabase
            .from('logs')
            .select('*')
            .eq('family_id', familyId)
            .order('created_at', { ascending: false });

        if (error) {
            console.error('Error fetching logs:', error);
            throw error;
        }

        return data as Log[];
    },

    /**
     * Save a new log to the database.
     */
    async saveLog(log: InsertLog) {
        if (DEMO_MODE) {
            const newLog = {
                id: `demo-${Date.now()}`,
                created_at: new Date().toISOString(),
                ...log,
            } as unknown as Log;
            demoLogs = [newLog, ...demoLogs];
            return newLog;
        }
        const { data, error } = await supabase
            .from('logs')
            .insert(log as any) // Type cast to bypass strict Supabase type checks for now
            .select()
            .single();

        if (error) {
            console.error('Error saving log:', error);
            throw error;
        }

        return data as Log;
    },

    /**
     * Update an existing log.
     */
    async updateLog(id: string, updates: UpdateLog) {
        const { data, error } = await supabase
            .from('logs')
            .update(updates as any) // Type cast to bypass strict Supabase type checks for now
            .eq('id', id)
            .select()
            .single();

        if (error) {
            console.error('Error updating log:', error);
            throw error;
        }

        return data as Log;
    },
};
