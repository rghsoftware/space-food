-- Space Food - Energy-Aware Meal Management
-- Migration 003: Energy tracking and favorite meals

-- Add energy level columns to recipes table
ALTER TABLE recipes
    ADD COLUMN IF NOT EXISTS energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),
    ADD COLUMN IF NOT EXISTS preparation_time_minutes INTEGER,
    ADD COLUMN IF NOT EXISTS active_time_minutes INTEGER;

COMMENT ON COLUMN recipes.energy_level IS 'Required energy level: 1=Exhausted, 2=Low, 3=Moderate, 4=Good, 5=High';
COMMENT ON COLUMN recipes.preparation_time_minutes IS 'Total time from start to finish';
COMMENT ON COLUMN recipes.active_time_minutes IS 'Actual hands-on cooking time';

-- Track user energy patterns over time
CREATE TABLE IF NOT EXISTS user_energy_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    time_of_day VARCHAR(20) NOT NULL CHECK (time_of_day IN ('morning', 'afternoon', 'evening', 'night')),
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    typical_energy_level INTEGER NOT NULL CHECK (typical_energy_level >= 1 AND typical_energy_level <= 5),
    sample_count INTEGER DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, time_of_day, day_of_week)
);

CREATE INDEX idx_user_energy_patterns_user ON user_energy_patterns(user_id);
CREATE INDEX idx_user_energy_patterns_lookup ON user_energy_patterns(user_id, time_of_day, day_of_week);

COMMENT ON TABLE user_energy_patterns IS 'Learned energy patterns by time of day and day of week';
COMMENT ON COLUMN user_energy_patterns.time_of_day IS 'Time slot: morning (5am-12pm), afternoon (12pm-5pm), evening (5pm-10pm), night (10pm-5am)';
COMMENT ON COLUMN user_energy_patterns.sample_count IS 'Number of samples used to calculate average';

-- Store individual energy snapshots for pattern learning
CREATE TABLE IF NOT EXISTS energy_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recorded_at TIMESTAMP NOT NULL DEFAULT NOW(),
    energy_level INTEGER NOT NULL CHECK (energy_level >= 1 AND energy_level <= 5),
    time_of_day VARCHAR(20) NOT NULL,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    context VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_energy_snapshots_user ON energy_snapshots(user_id);
CREATE INDEX idx_energy_snapshots_user_time ON energy_snapshots(user_id, recorded_at);
CREATE INDEX idx_energy_snapshots_time ON energy_snapshots(recorded_at);

COMMENT ON TABLE energy_snapshots IS 'Individual energy level recordings for pattern analysis';
COMMENT ON COLUMN energy_snapshots.context IS 'Context: meal_log, manual_entry, cooking_session, etc.';

-- User's favorite meals with energy associations
CREATE TABLE IF NOT EXISTS saved_favorite_meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
    meal_name VARCHAR(200) NOT NULL,
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),
    typical_time_of_day VARCHAR(20) CHECK (typical_time_of_day IN ('morning', 'afternoon', 'evening', 'night')),
    frequency_score INTEGER DEFAULT 0,
    last_eaten TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_favorite_meals_user ON saved_favorite_meals(user_id);
CREATE INDEX idx_favorite_meals_user_energy ON saved_favorite_meals(user_id, energy_level);
CREATE INDEX idx_favorite_meals_frequency ON saved_favorite_meals(user_id, frequency_score DESC);

COMMENT ON TABLE saved_favorite_meals IS 'User favorite meals with energy level associations';
COMMENT ON COLUMN saved_favorite_meals.frequency_score IS 'Incremented each time meal is eaten';
COMMENT ON COLUMN saved_favorite_meals.typical_time_of_day IS 'When user typically eats this meal';

-- Auto-update timestamps trigger for user_energy_patterns
CREATE OR REPLACE FUNCTION update_user_energy_patterns_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_energy_patterns_update_timestamp
    BEFORE UPDATE ON user_energy_patterns
    FOR EACH ROW
    EXECUTE FUNCTION update_user_energy_patterns_timestamp();

-- Auto-update timestamps trigger for saved_favorite_meals
CREATE OR REPLACE FUNCTION update_saved_favorite_meals_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER saved_favorite_meals_update_timestamp
    BEFORE UPDATE ON saved_favorite_meals
    FOR EACH ROW
    EXECUTE FUNCTION update_saved_favorite_meals_timestamp();
