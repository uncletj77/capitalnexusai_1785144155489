-- Add missing address and city columns to user_profiles
-- This fixes the PGRST204 error: "could not find the address column of users profiles in schema cache"

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS city TEXT,
  ADD COLUMN IF NOT EXISTS address TEXT;
