-- Migration: CNA Brain AI Memory & Preferences Enhancement
-- Ensures ai_memory table has all required columns for the CNA Brain system

-- Add is_active column if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'ai_memory'
    AND column_name = 'is_active'
  ) THEN
    ALTER TABLE public.ai_memory ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
  END IF;
END $$;

-- Add importance_score column if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'ai_memory'
    AND column_name = 'importance_score'
  ) THEN
    ALTER TABLE public.ai_memory ADD COLUMN importance_score INTEGER DEFAULT 5;
  END IF;
END $$;

-- Add memory_type column if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'ai_memory'
    AND column_name = 'memory_type'
  ) THEN
    ALTER TABLE public.ai_memory ADD COLUMN memory_type TEXT DEFAULT 'general';
  END IF;
END $$;

-- Create ai_memory table if it doesn't exist at all
CREATE TABLE IF NOT EXISTS public.ai_memory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  memory_type TEXT NOT NULL DEFAULT 'general',
  content TEXT NOT NULL,
  importance_score INTEGER DEFAULT 5,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create ai_conversations table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.ai_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT 'New Conversation',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create ai_messages table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.ai_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.ai_conversations(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  agent_type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create ai_actions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.ai_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  description TEXT,
  payload JSONB,
  approved BOOLEAN DEFAULT FALSE,
  rejected BOOLEAN DEFAULT FALSE,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create ai_recommendations table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.ai_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT,
  body TEXT,
  category TEXT DEFAULT 'info',
  priority TEXT DEFAULT 'medium',
  agent_type TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_memory_user_active
  ON public.ai_memory(user_id, is_active);

CREATE INDEX IF NOT EXISTS idx_ai_conversations_user
  ON public.ai_conversations(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation
  ON public.ai_messages(conversation_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_ai_actions_user_pending
  ON public.ai_actions(user_id, completed, rejected);

CREATE INDEX IF NOT EXISTS idx_ai_recommendations_user
  ON public.ai_recommendations(user_id, created_at DESC);

-- RLS Policies
ALTER TABLE public.ai_memory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recommendations ENABLE ROW LEVEL SECURITY;

-- ai_memory policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'ai_memory' AND policyname = 'ai_memory_user_policy'
  ) THEN
    CREATE POLICY ai_memory_user_policy ON public.ai_memory
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ai_conversations policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'ai_conversations' AND policyname = 'ai_conversations_user_policy'
  ) THEN
    CREATE POLICY ai_conversations_user_policy ON public.ai_conversations
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ai_messages policies (via conversation ownership)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'ai_messages' AND policyname = 'ai_messages_user_policy'
  ) THEN
    CREATE POLICY ai_messages_user_policy ON public.ai_messages
      FOR ALL USING (
        EXISTS (
          SELECT 1 FROM public.ai_conversations c
          WHERE c.id = conversation_id AND c.user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- ai_actions policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'ai_actions' AND policyname = 'ai_actions_user_policy'
  ) THEN
    CREATE POLICY ai_actions_user_policy ON public.ai_actions
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ai_recommendations policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'ai_recommendations' AND policyname = 'ai_recommendations_user_policy'
  ) THEN
    CREATE POLICY ai_recommendations_user_policy ON public.ai_recommendations
      FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;
