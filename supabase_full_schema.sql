-- ====================================================================
-- TURING MACHINE CARD - FULL SUPABASE DATABASE SCHEMA
-- Run this script in your Supabase Dashboard -> SQL Editor
-- ====================================================================

-- 1. PROFILES TABLE (User Sharable Public IDs & Display Names)
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY,
    public_id TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Anyone logged in can look up public profiles by public_id
CREATE POLICY "Allow public read access to profiles"
    ON public.profiles FOR SELECT USING (true);

-- Users can insert/update their own profile
CREATE POLICY "Allow users to insert/update own profile"
    ON public.profiles FOR ALL
    USING (auth.uid()::text = id)
    WITH CHECK (auth.uid()::text = id);


-- 2. FRIEND REQUESTS TABLE
CREATE TABLE IF NOT EXISTS public.friend_requests (
    id TEXT PRIMARY KEY,
    from_user_id TEXT NOT NULL,
    from_public_id TEXT NOT NULL,
    from_user_name TEXT NOT NULL,
    to_user_id TEXT NOT NULL,
    to_public_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.friend_requests ENABLE ROW LEVEL SECURITY;

-- Users can view friend requests sent from or to them
CREATE POLICY "Allow users to read friend requests involving them"
    ON public.friend_requests FOR SELECT USING (true);

-- Authenticated users can insert friend requests
CREATE POLICY "Allow authenticated users to insert friend requests"
    ON public.friend_requests FOR INSERT WITH CHECK (true);

-- Users can update status of requests involving them (accept/reject)
CREATE POLICY "Allow users to update friend requests involving them"
    ON public.friend_requests FOR UPDATE USING (true);


-- 3. FRIENDSHIPS TABLE
CREATE TABLE IF NOT EXISTS public.friendships (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    user_public_id TEXT,
    user_name TEXT,
    friend_user_id TEXT NOT NULL,
    friend_public_id TEXT,
    friend_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow users to read friendships involving them"
    ON public.friendships FOR SELECT USING (true);

CREATE POLICY "Allow authenticated users to insert friendships"
    ON public.friendships FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow users to delete friendships"
    ON public.friendships FOR DELETE USING (true);


-- 4. CHALLENGES TABLE
CREATE TABLE IF NOT EXISTS public.challenges (
    id TEXT PRIMARY KEY,
    puzzle_hash TEXT NOT NULL,
    challenger_id TEXT NOT NULL,
    challenger_name TEXT NOT NULL,
    challenger_won BOOLEAN NOT NULL,
    challenger_beat_machine BOOLEAN NOT NULL,
    challenger_clues INTEGER NOT NULL,
    challenger_rounds INTEGER NOT NULL,
    challengee_id TEXT NOT NULL,
    challengee_name TEXT NOT NULL,
    challengee_won BOOLEAN,
    challengee_beat_machine BOOLEAN,
    challengee_clues INTEGER,
    challengee_rounds INTEGER,
    status TEXT NOT NULL DEFAULT 'pending',
    winner_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow users to read challenges involving them"
    ON public.challenges FOR SELECT USING (true);

CREATE POLICY "Allow users to insert challenges"
    ON public.challenges FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow users to update challenges"
    ON public.challenges FOR UPDATE USING (true);


-- 5. USER PUSH TOKENS TABLE
CREATE TABLE IF NOT EXISTS public.user_push_tokens (
    user_id TEXT PRIMARY KEY,
    push_token TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.user_push_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow individual insert/update to push tokens"
    ON public.user_push_tokens FOR ALL
    USING (auth.uid()::text = user_id)
    WITH CHECK (auth.uid()::text = user_id);

-- Enable Realtime publication for tables so listeners receive updates live
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friend_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friendships;
ALTER PUBLICATION supabase_realtime ADD TABLE public.challenges;
