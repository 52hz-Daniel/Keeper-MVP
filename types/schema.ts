export type Json =
    | string
    | number
    | boolean
    | null
    | { [key: string]: Json | undefined }
    | Json[]

export interface Database {
    public: {
        Tables: {
            families: {
                Row: {
                    id: string
                    created_at: string
                    invite_code: string
                }
                Insert: {
                    id?: string
                    created_at?: string
                    invite_code: string
                }
                Update: {
                    id?: string
                    created_at?: string
                    invite_code?: string
                }
            }
            profiles: {
                Row: {
                    id: string
                    email: string | null
                    family_id: string | null
                    role: 'Mom' | 'Dad' | 'Partner' | 'Guardian' | null
                    created_at: string
                }
                Insert: {
                    id: string
                    email?: string | null
                    family_id?: string | null
                    role?: 'Mom' | 'Dad' | 'Partner' | 'Guardian' | null
                    created_at?: string
                }
                Update: {
                    id?: string
                    email?: string | null
                    family_id?: string | null
                    role?: 'Mom' | 'Dad' | 'Partner' | 'Guardian' | null
                    created_at?: string
                }
            }
            logs: {
                Row: {
                    id: string
                    created_at: string
                    family_id: string
                    creator_id: string
                    event_type: 'sleep' | 'feed' | 'diaper' | 'medication' | 'note' | 'growth'
                    raw_text: string | null
                    structured_data: Json | null
                    is_confirmed: boolean
                    client_updated_at: string | null
                    last_modified_by: string | null
                }
                Insert: {
                    id?: string
                    created_at?: string
                    family_id: string
                    creator_id: string
                    event_type: 'sleep' | 'feed' | 'diaper' | 'medication' | 'note' | 'growth'
                    raw_text?: string | null
                    structured_data?: Json | null
                    is_confirmed?: boolean
                    client_updated_at?: string | null
                    last_modified_by?: string | null
                }
                Update: {
                    id?: string
                    created_at?: string
                    family_id?: string
                    creator_id?: string
                    event_type?: 'sleep' | 'feed' | 'diaper' | 'medication' | 'note' | 'growth'
                    raw_text?: string | null
                    structured_data?: Json | null
                    is_confirmed?: boolean
                    client_updated_at?: string | null
                    last_modified_by?: string | null
                }
            }
        }
    }
}
