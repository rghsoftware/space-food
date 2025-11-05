-- Migration: Meal Reminder & Logging System
-- Description: Tables for ADHD-focused meal reminders, logging, and timeline tracking
-- Date: 2025-11-05

-- Meal Reminders table
-- Stores recurring meal reminders with pre-alerts
CREATE TABLE IF NOT EXISTS meal_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    scheduled_time TIME NOT NULL,
    pre_alert_minutes INTEGER DEFAULT 15 CHECK (pre_alert_minutes >= 0 AND pre_alert_minutes <= 60),
    enabled BOOLEAN DEFAULT true,
    days_of_week INTEGER[] DEFAULT ARRAY[0,1,2,3,4,5,6], -- 0=Sunday, 6=Saturday
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_meal_reminders_user ON meal_reminders(user_id);
CREATE INDEX idx_meal_reminders_enabled ON meal_reminders(enabled);
CREATE INDEX idx_meal_reminders_user_enabled ON meal_reminders(user_id, enabled);

-- Meal Logs table
-- Tracks when users actually eat with optional energy level
CREATE TABLE IF NOT EXISTS meal_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reminder_id UUID REFERENCES meal_reminders(id) ON DELETE SET NULL,
    logged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    scheduled_for TIMESTAMP,
    notes TEXT,
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_meal_logs_user ON meal_logs(user_id);
CREATE INDEX idx_meal_logs_logged_at ON meal_logs(logged_at);
CREATE INDEX idx_meal_logs_user_date ON meal_logs(user_id, DATE(logged_at));
CREATE INDEX idx_meal_logs_reminder ON meal_logs(reminder_id);

-- Eating Timeline Settings table
-- User preferences for timeline display
CREATE TABLE IF NOT EXISTS eating_timeline_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    daily_meal_goal INTEGER DEFAULT 3 CHECK (daily_meal_goal >= 0),
    daily_snack_goal INTEGER DEFAULT 2 CHECK (daily_snack_goal >= 0),
    show_streak BOOLEAN DEFAULT true,
    show_missed_meals BOOLEAN DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for auto-updating updated_at
CREATE TRIGGER update_meal_reminders_updated_at BEFORE UPDATE ON meal_reminders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_eating_timeline_settings_updated_at BEFORE UPDATE ON eating_timeline_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE meal_reminders IS 'Recurring meal reminders with pre-alerts for ADHD meal management';
COMMENT ON TABLE meal_logs IS 'Historical record of meals eaten with optional energy level tracking';
COMMENT ON TABLE eating_timeline_settings IS 'User preferences for eating timeline visualization';

COMMENT ON COLUMN meal_reminders.pre_alert_minutes IS 'Minutes before scheduled time to send pre-alert (e.g., 15 = alert at 7:45 for 8:00 meal)';
COMMENT ON COLUMN meal_reminders.days_of_week IS 'Array of days (0=Sunday) when reminder is active';
COMMENT ON COLUMN meal_logs.energy_level IS 'Self-reported energy level after eating (1=exhausted, 5=energized)';
COMMENT ON COLUMN meal_logs.scheduled_for IS 'Original scheduled time if logged from a reminder';
COMMENT ON COLUMN eating_timeline_settings.show_missed_meals IS 'Whether to show missed meals (default false for shame-free UX)';
