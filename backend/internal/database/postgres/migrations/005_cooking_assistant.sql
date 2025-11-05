-- Space Food - Self-Hosted Meal Planning Application
-- Copyright (C) 2025 RGH Software
-- Licensed under AGPL-3.0
--
-- Migration: 005_cooking_assistant.sql
-- Description: AI-Powered Cooking Assistant with recipe breakdown, timers, and body doubling

-- ============================================================================
-- Recipe Breakdowns (AI-Generated, Cached)
-- ============================================================================
-- Stores AI-generated recipe breakdowns at different granularity levels
-- Cached to avoid re-generating the same breakdown repeatedly

CREATE TABLE IF NOT EXISTS recipe_breakdowns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE, -- NULL = system-generated
    granularity_level INTEGER NOT NULL CHECK (granularity_level >= 1 AND granularity_level <= 5),
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5), -- Adapted for energy
    breakdown_data JSONB NOT NULL, -- Structured breakdown with steps, timers, dependencies
    ai_provider VARCHAR(50), -- 'openai', 'anthropic', 'google', etc.
    ai_model VARCHAR(100), -- Model version used
    generated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_used_at TIMESTAMP,
    use_count INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    -- One breakdown per recipe/granularity/energy combination
    UNIQUE(recipe_id, granularity_level, energy_level)
);

CREATE INDEX idx_recipe_breakdowns_recipe ON recipe_breakdowns(recipe_id);
CREATE INDEX idx_recipe_breakdowns_user ON recipe_breakdowns(user_id);
CREATE INDEX idx_recipe_breakdowns_last_used ON recipe_breakdowns(last_used_at DESC);

COMMENT ON TABLE recipe_breakdowns IS 'AI-generated recipe breakdowns cached for performance';
COMMENT ON COLUMN recipe_breakdowns.granularity_level IS '1=Very detailed (ADHD-friendly), 5=Minimal steps';
COMMENT ON COLUMN recipe_breakdowns.energy_level IS 'Adapted breakdown for specific energy level';
COMMENT ON COLUMN recipe_breakdowns.breakdown_data IS 'JSONB: {steps: [{text, duration_seconds, timers, dependencies, tips}], total_time, active_time}';

-- ============================================================================
-- Cooking Sessions
-- ============================================================================
-- Active cooking sessions with progress tracking

CREATE TABLE IF NOT EXISTS cooking_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    breakdown_id UUID REFERENCES recipe_breakdowns(id) ON DELETE SET NULL,
    meal_log_id UUID REFERENCES meal_logs(id) ON DELETE SET NULL, -- Link to logged meal

    -- Session state
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'abandoned')),
    current_step_index INTEGER DEFAULT 0, -- Which step user is on
    total_steps INTEGER NOT NULL,

    -- Timing
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    paused_at TIMESTAMP,
    resumed_at TIMESTAMP,
    completed_at TIMESTAMP,
    abandoned_at TIMESTAMP,
    total_pause_duration_seconds INTEGER DEFAULT 0, -- Track total pause time

    -- Context
    energy_level_at_start INTEGER CHECK (energy_level_at_start >= 1 AND energy_level_at_start <= 5),
    notes TEXT, -- User notes during cooking

    -- Body doubling
    body_doubling_room_id UUID REFERENCES body_doubling_rooms(id) ON DELETE SET NULL,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cooking_sessions_user ON cooking_sessions(user_id);
CREATE INDEX idx_cooking_sessions_recipe ON cooking_sessions(recipe_id);
CREATE INDEX idx_cooking_sessions_status ON cooking_sessions(status);
CREATE INDEX idx_cooking_sessions_started ON cooking_sessions(started_at DESC);

COMMENT ON TABLE cooking_sessions IS 'Active and historical cooking sessions with progress tracking';
COMMENT ON COLUMN cooking_sessions.total_pause_duration_seconds IS 'Sum of all pause durations for accurate time tracking';

-- ============================================================================
-- Cooking Step Completions
-- ============================================================================
-- Track which steps have been completed in a cooking session

CREATE TABLE IF NOT EXISTS cooking_step_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cooking_session_id UUID NOT NULL REFERENCES cooking_sessions(id) ON DELETE CASCADE,
    step_index INTEGER NOT NULL,
    step_text TEXT NOT NULL, -- Snapshot of step text at completion

    -- Completion details
    completed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    time_taken_seconds INTEGER, -- How long this step actually took
    skipped BOOLEAN DEFAULT false, -- User skipped this step
    difficulty_rating INTEGER CHECK (difficulty_rating >= 1 AND difficulty_rating <= 5), -- User feedback
    notes TEXT, -- User notes for this step

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    UNIQUE(cooking_session_id, step_index)
);

CREATE INDEX idx_step_completions_session ON cooking_step_completions(cooking_session_id);
CREATE INDEX idx_step_completions_completed ON cooking_step_completions(completed_at DESC);

COMMENT ON TABLE cooking_step_completions IS 'Step-by-step completion tracking for analytics and learning';
COMMENT ON COLUMN cooking_step_completions.difficulty_rating IS 'Optional user feedback on step difficulty';

-- ============================================================================
-- Cooking Timers
-- ============================================================================
-- Multi-timer management for cooking sessions

CREATE TABLE IF NOT EXISTS cooking_timers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cooking_session_id UUID NOT NULL REFERENCES cooking_sessions(id) ON DELETE CASCADE,
    step_index INTEGER, -- Which step this timer is for (NULL = manual timer)

    -- Timer details
    name VARCHAR(100) NOT NULL, -- e.g., "Pasta boiling", "Chicken in oven"
    duration_seconds INTEGER NOT NULL,
    remaining_seconds INTEGER NOT NULL,

    -- State
    status VARCHAR(20) NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'paused', 'completed', 'cancelled')),

    -- Timing
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    paused_at TIMESTAMP,
    resumed_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    total_pause_duration_seconds INTEGER DEFAULT 0,

    -- Notifications
    notification_sent BOOLEAN DEFAULT false,
    notification_sent_at TIMESTAMP,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cooking_timers_session ON cooking_timers(cooking_session_id);
CREATE INDEX idx_cooking_timers_status ON cooking_timers(status);
CREATE INDEX idx_cooking_timers_step ON cooking_timers(step_index);

COMMENT ON TABLE cooking_timers IS 'Multi-timer management with pause/resume support';
COMMENT ON COLUMN cooking_timers.remaining_seconds IS 'Calculated: duration - elapsed + pause_duration';

-- ============================================================================
-- Body Doubling Rooms
-- ============================================================================
-- Virtual co-cooking sessions for social accountability and support

CREATE TABLE IF NOT EXISTS body_doubling_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Room details
    room_name VARCHAR(200) NOT NULL,
    room_code VARCHAR(20) UNIQUE NOT NULL, -- Easy-to-share code (e.g., "PASTA-2024")
    description TEXT, -- What are we cooking?
    max_participants INTEGER DEFAULT 10,

    -- Privacy
    is_public BOOLEAN DEFAULT false, -- Public rooms discoverable by others
    password_hash VARCHAR(255), -- Optional password protection

    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'ended')),

    -- Timing
    scheduled_start_time TIMESTAMP, -- Optional: schedule for later
    actual_start_time TIMESTAMP,
    ended_at TIMESTAMP,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_body_doubling_rooms_creator ON body_doubling_rooms(created_by);
CREATE INDEX idx_body_doubling_rooms_code ON body_doubling_rooms(room_code);
CREATE INDEX idx_body_doubling_rooms_public ON body_doubling_rooms(is_public) WHERE is_public = true;
CREATE INDEX idx_body_doubling_rooms_status ON body_doubling_rooms(status);
CREATE INDEX idx_body_doubling_rooms_scheduled ON body_doubling_rooms(scheduled_start_time) WHERE scheduled_start_time IS NOT NULL;

COMMENT ON TABLE body_doubling_rooms IS 'Virtual co-cooking rooms for body doubling support';
COMMENT ON COLUMN body_doubling_rooms.room_code IS 'Easy-to-share code for joining (e.g., PASTA-2024)';

-- ============================================================================
-- Body Doubling Participants
-- ============================================================================
-- Track who is in which body doubling room

CREATE TABLE IF NOT EXISTS body_doubling_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES body_doubling_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    cooking_session_id UUID REFERENCES cooking_sessions(id) ON DELETE SET NULL,

    -- Participation details
    joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
    left_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true, -- Currently in the room

    -- User's cooking context
    recipe_name VARCHAR(300), -- What they're cooking
    current_step TEXT, -- Current step they're on
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),

    -- Interaction
    last_activity_at TIMESTAMP DEFAULT NOW(), -- Last message/update
    message_count INTEGER DEFAULT 0, -- How many messages sent

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    UNIQUE(room_id, user_id)
);

CREATE INDEX idx_body_doubling_participants_room ON body_doubling_participants(room_id);
CREATE INDEX idx_body_doubling_participants_user ON body_doubling_participants(user_id);
CREATE INDEX idx_body_doubling_participants_active ON body_doubling_participants(is_active) WHERE is_active = true;
CREATE INDEX idx_body_doubling_participants_session ON body_doubling_participants(cooking_session_id);

COMMENT ON TABLE body_doubling_participants IS 'Room membership and activity tracking';
COMMENT ON COLUMN body_doubling_participants.is_active IS 'Currently in the room (not left)';
COMMENT ON COLUMN body_doubling_participants.last_activity_at IS 'Used to detect inactive participants';

-- ============================================================================
-- Add AI service configuration to recipes (for breakdown generation)
-- ============================================================================

ALTER TABLE recipes
ADD COLUMN IF NOT EXISTS default_granularity INTEGER DEFAULT 2 CHECK (default_granularity >= 1 AND default_granularity <= 5);

COMMENT ON COLUMN recipes.default_granularity IS 'Default breakdown granularity for this recipe (1=very detailed, 5=minimal)';

-- ============================================================================
-- Triggers for updated_at timestamps
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_recipe_breakdowns_updated_at BEFORE UPDATE ON recipe_breakdowns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cooking_sessions_updated_at BEFORE UPDATE ON cooking_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cooking_timers_updated_at BEFORE UPDATE ON cooking_timers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_body_doubling_rooms_updated_at BEFORE UPDATE ON body_doubling_rooms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_body_doubling_participants_updated_at BEFORE UPDATE ON body_doubling_participants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Sample Data for Testing
-- ============================================================================

-- Sample room code generator function
CREATE OR REPLACE FUNCTION generate_room_code()
RETURNS VARCHAR(20) AS $$
DECLARE
    words TEXT[] := ARRAY['PASTA', 'PIZZA', 'SALAD', 'SOUP', 'STIR', 'BAKE', 'GRILL', 'ROAST', 'FRY', 'STEAM'];
    word TEXT;
    year_suffix VARCHAR(4);
    code VARCHAR(20);
BEGIN
    word := words[1 + floor(random() * array_length(words, 1))::int];
    year_suffix := to_char(NOW(), 'YYYY');
    code := word || '-' || year_suffix;
    RETURN code;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_room_code IS 'Generate memorable room codes like PASTA-2024';
