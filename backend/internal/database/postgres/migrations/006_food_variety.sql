-- Space Food - Self-Hosted Meal Planning Application
-- Copyright (C) 2025 RGH Software
-- Licensed under AGPL-3.0
--
-- Migration: 006_food_variety.sql
-- Description: Food Variety & Rotation System with ADHD-friendly hyperfixation tracking

-- ============================================================================
-- Food Hyperfixation Tracking (Non-judgmental)
-- ============================================================================
-- Track food hyperfixation patterns without shame

CREATE TABLE IF NOT EXISTS food_hyperfixations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    food_name VARCHAR(200) NOT NULL,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMP,
    frequency_count INTEGER DEFAULT 1,
    peak_frequency_per_day DECIMAL(5,2), -- Max times per day during fixation
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_food_hyperfixations_user ON food_hyperfixations(user_id);
CREATE INDEX idx_food_hyperfixations_active ON food_hyperfixations(is_active) WHERE is_active = true;
CREATE INDEX idx_food_hyperfixations_food ON food_hyperfixations(food_name);

COMMENT ON TABLE food_hyperfixations IS 'Non-judgmental tracking of food hyperfixation patterns';
COMMENT ON COLUMN food_hyperfixations.peak_frequency_per_day IS 'Maximum times per day food was eaten during active fixation';

-- ============================================================================
-- Food Profiles for Chaining
-- ============================================================================
-- Food characteristics to enable "food chaining" - suggesting similar foods

CREATE TABLE IF NOT EXISTS food_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    food_name VARCHAR(200) NOT NULL UNIQUE,
    texture VARCHAR(50), -- 'crunchy', 'soft', 'chewy', 'smooth', 'crispy'
    flavor_profile VARCHAR(50), -- 'sweet', 'salty', 'savory', 'umami', 'spicy'
    temperature VARCHAR(20), -- 'hot', 'cold', 'room_temp'
    complexity INTEGER CHECK (complexity >= 1 AND complexity <= 5), -- 1=simple, 5=complex
    common_allergens TEXT[], -- List of allergens
    dietary_tags TEXT[], -- 'vegetarian', 'vegan', 'gluten-free', etc.
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_food_profiles_name ON food_profiles(food_name);
CREATE INDEX idx_food_profiles_texture ON food_profiles(texture);
CREATE INDEX idx_food_profiles_flavor ON food_profiles(flavor_profile);

COMMENT ON TABLE food_profiles IS 'Food characteristics for food chaining suggestions';
COMMENT ON COLUMN food_profiles.complexity IS '1=simple single ingredient, 5=complex multi-component dish';

-- ============================================================================
-- Food Chain Suggestions
-- ============================================================================
-- AI-generated suggestions for expanding food repertoire

CREATE TABLE IF NOT EXISTS food_chain_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    current_food_name VARCHAR(200) NOT NULL,
    suggested_food_name VARCHAR(200) NOT NULL,
    similarity_score DECIMAL(3,2) CHECK (similarity_score >= 0 AND similarity_score <= 1),
    reasoning TEXT NOT NULL,
    was_tried BOOLEAN DEFAULT false,
    was_liked BOOLEAN,
    tried_at TIMESTAMP,
    feedback TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_food_chain_suggestions_user ON food_chain_suggestions(user_id);
CREATE INDEX idx_food_chain_suggestions_current ON food_chain_suggestions(current_food_name);
CREATE INDEX idx_food_chain_suggestions_untried ON food_chain_suggestions(was_tried) WHERE was_tried = false;

COMMENT ON TABLE food_chain_suggestions IS 'AI-generated food chaining suggestions for variety';
COMMENT ON COLUMN food_chain_suggestions.similarity_score IS 'How similar the suggested food is (0.0-1.0)';
COMMENT ON COLUMN food_chain_suggestions.reasoning IS 'Why this food is similar (specific characteristics)';

-- ============================================================================
-- Food Variations
-- ============================================================================
-- Simple variations for familiar foods (different sauces, toppings, etc.)

CREATE TABLE IF NOT EXISTS food_variations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    base_food_name VARCHAR(200) NOT NULL,
    variation_type VARCHAR(50) NOT NULL, -- 'sauce', 'topping', 'preparation', 'side'
    variation_name VARCHAR(200) NOT NULL,
    description TEXT,
    complexity INTEGER CHECK (complexity >= 1 AND complexity <= 5),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_food_variations_base ON food_variations(base_food_name);
CREATE INDEX idx_food_variations_type ON food_variations(variation_type);

COMMENT ON TABLE food_variations IS 'Simple variations for familiar foods to add variety';
COMMENT ON COLUMN food_variations.variation_type IS 'Type of variation: sauce, topping, preparation method, or side dish';

-- ============================================================================
-- Compassionate Nutrition Tracking Settings (Opt-in)
-- ============================================================================
-- User preferences for nutrition tracking (completely optional)

CREATE TABLE IF NOT EXISTS nutrition_tracking_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    tracking_enabled BOOLEAN DEFAULT false,
    show_calorie_counts BOOLEAN DEFAULT false,
    show_macros BOOLEAN DEFAULT false,
    show_micronutrients BOOLEAN DEFAULT false,
    focus_nutrients TEXT[], -- Specific nutrients user wants to track (e.g., 'protein', 'iron')
    show_weekly_summary BOOLEAN DEFAULT true,
    show_daily_summary BOOLEAN DEFAULT false,
    reminder_style VARCHAR(20) DEFAULT 'gentle', -- 'gentle', 'disabled'
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE nutrition_tracking_settings IS 'Optional, compassionate nutrition tracking preferences';
COMMENT ON COLUMN nutrition_tracking_settings.reminder_style IS 'How reminders are presented: gentle encouragement or disabled';

-- ============================================================================
-- Gentle Nutrition Insights (Weekly Summaries)
-- ============================================================================
-- Non-judgmental nutrition insights generated weekly

CREATE TABLE IF NOT EXISTS nutrition_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    insight_type VARCHAR(50) NOT NULL, -- 'protein_sufficient', 'variety_suggestion', 'hydration_reminder'
    message TEXT NOT NULL,
    is_dismissed BOOLEAN DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, week_start_date, insight_type)
);

CREATE INDEX idx_nutrition_insights_user ON nutrition_insights(user_id);
CREATE INDEX idx_nutrition_insights_week ON nutrition_insights(week_start_date);
CREATE INDEX idx_nutrition_insights_active ON nutrition_insights(is_dismissed) WHERE is_dismissed = false;

COMMENT ON TABLE nutrition_insights IS 'Gentle, non-judgmental weekly nutrition insights';
COMMENT ON COLUMN nutrition_insights.insight_type IS 'Type of insight - always positive or neutral, never critical';

-- ============================================================================
-- Food Rotation Schedules (Optional Structure)
-- ============================================================================
-- Optional structured rotation for users who prefer it

CREATE TABLE IF NOT EXISTS food_rotation_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    schedule_name VARCHAR(200) NOT NULL,
    rotation_days INTEGER DEFAULT 7, -- Rotate every N days
    foods JSONB NOT NULL, -- Array of food items: [{"name": "...", "day": 1}]
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_food_rotation_user ON food_rotation_schedules(user_id);
CREATE INDEX idx_food_rotation_active ON food_rotation_schedules(is_active) WHERE is_active = true;

COMMENT ON TABLE food_rotation_schedules IS 'Optional structured food rotation for users who prefer routine';
COMMENT ON COLUMN food_rotation_schedules.foods IS 'JSONB array of foods with optional day assignments';

-- ============================================================================
-- Last Eaten Tracking (for Variety Analysis)
-- ============================================================================
-- Track when foods were last eaten for rotation and variety analysis

CREATE TABLE IF NOT EXISTS last_eaten_tracking (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    food_name VARCHAR(200) NOT NULL,
    last_eaten_at TIMESTAMP NOT NULL,
    times_eaten_last_7_days INTEGER DEFAULT 1,
    times_eaten_last_30_days INTEGER DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, food_name)
);

CREATE INDEX idx_last_eaten_user ON last_eaten_tracking(user_id);
CREATE INDEX idx_last_eaten_date ON last_eaten_tracking(last_eaten_at DESC);
CREATE INDEX idx_last_eaten_recent ON last_eaten_tracking(user_id, last_eaten_at DESC);

COMMENT ON TABLE last_eaten_tracking IS 'Track food consumption patterns for variety analysis';
COMMENT ON COLUMN last_eaten_tracking.times_eaten_last_7_days IS 'Counter updated when food is logged';

-- ============================================================================
-- Triggers for updated_at timestamps
-- ============================================================================

CREATE TRIGGER update_food_hyperfixations_updated_at BEFORE UPDATE ON food_hyperfixations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_nutrition_tracking_settings_updated_at BEFORE UPDATE ON nutrition_tracking_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_food_rotation_schedules_updated_at BEFORE UPDATE ON food_rotation_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_last_eaten_tracking_updated_at BEFORE UPDATE ON last_eaten_tracking
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Sample Food Profiles (Common Foods)
-- ============================================================================
-- Seed database with common food profiles for chaining

INSERT INTO food_profiles (food_name, texture, flavor_profile, temperature, complexity, dietary_tags) VALUES
('Chicken nuggets', 'crispy', 'savory', 'hot', 2, ARRAY['contains_gluten']),
('French fries', 'crispy', 'salty', 'hot', 1, ARRAY['vegan', 'vegetarian']),
('Mac and cheese', 'soft', 'savory', 'hot', 2, ARRAY['vegetarian', 'contains_dairy']),
('Pizza', 'chewy', 'savory', 'hot', 3, ARRAY['contains_gluten', 'contains_dairy']),
('Grilled cheese', 'crispy', 'savory', 'hot', 2, ARRAY['vegetarian', 'contains_dairy', 'contains_gluten']),
('Pasta with butter', 'soft', 'savory', 'hot', 2, ARRAY['vegetarian', 'contains_gluten', 'contains_dairy']),
('Rice', 'soft', 'savory', 'hot', 1, ARRAY['vegan', 'vegetarian', 'gluten-free']),
('Yogurt', 'smooth', 'sweet', 'cold', 1, ARRAY['vegetarian', 'contains_dairy']),
('Apple slices', 'crunchy', 'sweet', 'cold', 1, ARRAY['vegan', 'vegetarian']),
('Crackers', 'crunchy', 'salty', 'room_temp', 1, ARRAY['contains_gluten']),
('Peanut butter sandwich', 'soft', 'savory', 'room_temp', 2, ARRAY['vegetarian', 'contains_gluten']),
('Quesadilla', 'chewy', 'savory', 'hot', 2, ARRAY['vegetarian', 'contains_dairy', 'contains_gluten']),
('Ramen noodles', 'soft', 'savory', 'hot', 2, ARRAY['contains_gluten']),
('Cereal', 'crunchy', 'sweet', 'cold', 1, ARRAY['vegetarian', 'contains_dairy']),
('Toast', 'crispy', 'savory', 'hot', 1, ARRAY['contains_gluten'])
ON CONFLICT (food_name) DO NOTHING;

-- Sample variations for common safe foods
INSERT INTO food_variations (base_food_name, variation_type, variation_name, description, complexity) VALUES
('Mac and cheese', 'topping', 'Add breadcrumbs', 'Sprinkle breadcrumbs on top for extra crunch', 1),
('Mac and cheese', 'topping', 'Add bacon bits', 'Mix in bacon bits for savory flavor', 2),
('Mac and cheese', 'side', 'Serve with broccoli', 'Steam broccoli on the side', 2),
('Chicken nuggets', 'sauce', 'Honey mustard', 'Sweet and tangy dipping sauce', 1),
('Chicken nuggets', 'sauce', 'BBQ sauce', 'Sweet and smoky dipping sauce', 1),
('Chicken nuggets', 'side', 'Apple slices', 'Fresh apple slices for contrast', 1),
('French fries', 'topping', 'Cheese fries', 'Melt cheese on top', 2),
('French fries', 'sauce', 'Ranch dressing', 'Creamy dipping sauce', 1),
('Pasta with butter', 'topping', 'Parmesan cheese', 'Grate fresh parmesan on top', 1),
('Pasta with butter', 'preparation', 'Add garlic', 'Sauté garlic in the butter', 2),
('Pizza', 'topping', 'Add vegetables', 'Try one vegetable topping', 2),
('Pizza', 'side', 'Side salad', 'Simple green salad', 2),
('Grilled cheese', 'preparation', 'Add tomato', 'Slice tomato inside sandwich', 2),
('Grilled cheese', 'side', 'Tomato soup', 'Classic pairing', 2)
ON CONFLICT DO NOTHING;
