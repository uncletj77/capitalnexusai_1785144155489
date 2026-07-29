-- ─────────────────────────────────────────────────────────────────────────────
-- NOTIFICATIONS TABLE — ADD MISSING COLUMNS
-- Migration: 20260727220000_notifications_add_is_read.sql
-- Adds is_read, action_route, entity_type, entity_id columns to existing
-- notifications table created in 20260726140000_automation_smart_assistant_engine.sql
-- ─────────────────────────────────────────────────────────────────────────────

-- Add is_read boolean column (maps from existing status column)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'is_read'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN is_read BOOLEAN DEFAULT FALSE;
    -- Backfill from existing status column
    UPDATE public.notifications SET is_read = (status = 'read') WHERE is_read IS NULL;
  END IF;
END $$;

-- Add action_route column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'action_route'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN action_route TEXT;
  END IF;
END $$;

-- Add entity_type column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'entity_type'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN entity_type TEXT;
  END IF;
END $$;

-- Add entity_id column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'entity_id'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN entity_id TEXT;
  END IF;
END $$;

-- Add read_at column if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'read_at'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN read_at TIMESTAMPTZ;
  END IF;
END $$;

-- Add priority column if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'priority'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN priority TEXT NOT NULL DEFAULT 'normal';
  END IF;
END $$;

-- Add notification_type column if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'notification_type'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN notification_type TEXT NOT NULL DEFAULT 'general';
  END IF;
END $$;

-- Create index on is_read for fast unread queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_is_read
  ON public.notifications(user_id, is_read, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_entity
  ON public.notifications(entity_type, entity_id)
  WHERE entity_type IS NOT NULL;
