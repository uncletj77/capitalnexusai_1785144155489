-- Migration: Add pin_hash to user_profiles for PIN management
-- Timestamp: 20260726170000

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS pin_hash TEXT DEFAULT NULL;
