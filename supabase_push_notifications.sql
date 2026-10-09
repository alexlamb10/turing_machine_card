-- ====================================================================
-- SUPABASE PUSH NOTIFICATIONS SCHEMA & WEBHOOK CONFIGURATION
-- ====================================================================

-- 1. Create table to store user device push tokens (FCM / APNs)
CREATE TABLE IF NOT EXISTS public.user_push_tokens (
    user_id TEXT PRIMARY KEY,
    push_token TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.user_push_tokens ENABLE ROW LEVEL SECURITY;

-- Allow users to upsert their own push token
CREATE POLICY "Allow individual insert/update to push tokens"
    ON public.user_push_tokens
    FOR ALL
    USING (auth.uid()::text = user_id)
    WITH CHECK (auth.uid()::text = user_id);


-- 2. Database Webhook Guidance for Background FCM / APNs Push Notifications:
--
-- In your Supabase Dashboard:
-- Go to Database -> Webhooks -> Add Webhook
--
-- Webhook 1: New Friend Request
--   Table: friend_requests
--   Events: INSERT
--   Type: HTTP Request (or Supabase Edge Function)
--   Payload sends FCM / OneSignal / APNs message to the device token matching 'to_user_id'.
--
-- Webhook 2: New Challenge Received
--   Table: challenges
--   Events: INSERT
--   Type: HTTP Request (or Supabase Edge Function)
--   Payload sends FCM / OneSignal / APNs message to the device token matching 'challengee_id'.
--
-- Webhook 3: Challenge Completed
--   Table: challenges
--   Events: UPDATE (where status = 'completed')
--   Payload sends FCM / OneSignal / APNs message to the device token matching 'challenger_id'.
