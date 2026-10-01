import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://jyjdrmwmjoboawuxtkhc.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_-B42s-_Vpzsa2b7MJ5iyCg_DUkHAH_w';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
});
