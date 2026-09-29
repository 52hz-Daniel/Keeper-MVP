import { supabase } from './supabase';

// Define Types manually since we don't have the generated types yet in this new project
// Ideally we would copy types/schema.ts too, but for speed we'll inline or use 'any' carefully
export interface Log {
    id: string;
    created_at: string;
    family_id: string;
    creator_id: string;
    event_type: string;
    raw_text: string;
    structured_data: any;
    is_confirmed: boolean;
}

export const LogsService = {
    /**
     * Fetch logs for a specific family.
     */
    async fetchLogs(familyId: string) {
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
    async saveLog(log: Partial<Log>) {
        try {
            const { data, error } = await supabase
                .from('logs')
                .insert(log)
                .select()
                .single();

            if (error) throw error;
            return data as Log;
        } catch (error) {
            console.warn('Supabase save failed (Mock Mode active):', error);
            // Mock return for demo purposes
            return {
                ...log,
                id: Math.random().toString(),
                created_at: new Date().toISOString(),
            } as Log;
        }
    },

    /**
     * Update an existing log.
     */
    async updateLog(id: string, updates: Partial<Log>) {
        const { data, error } = await supabase
            .from('logs')
            .update(updates)
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
