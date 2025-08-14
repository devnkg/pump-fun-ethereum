import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL || "your_supabase_url";
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || "your_supabase_anon_key";

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error("Missing Supabase configuration. Please set SUPABASE_URL and SUPABASE_ANON_KEY in your environment.");
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
