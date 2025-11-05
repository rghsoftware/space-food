-- Space Food - Enhanced Shopping Experience
-- Migration 004: Visual grocery lists, pantry photos, store layouts, family sync

-- ==================== Pantry Enhancements ====================

-- Add photo support and location tracking to pantry items
ALTER TABLE pantry_items
    ADD COLUMN IF NOT EXISTS photo_url VARCHAR(500),
    ADD COLUMN IF NOT EXISTS thumbnail_url VARCHAR(500),
    ADD COLUMN IF NOT EXISTS expiration_date DATE,
    ADD COLUMN IF NOT EXISTS location VARCHAR(100), -- "fridge", "pantry", "freezer"
    ADD COLUMN IF NOT EXISTS is_running_low BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS minimum_quantity DECIMAL(10,2);

COMMENT ON COLUMN pantry_items.photo_url IS 'Full-size photo URL of the item';
COMMENT ON COLUMN pantry_items.thumbnail_url IS 'Thumbnail photo URL for grid display';
COMMENT ON COLUMN pantry_items.location IS 'Storage location: fridge, pantry, freezer, etc.';
COMMENT ON COLUMN pantry_items.is_running_low IS 'Whether item is below minimum quantity';

CREATE INDEX IF NOT EXISTS idx_pantry_items_location ON pantry_items(user_id, location);
CREATE INDEX IF NOT EXISTS idx_pantry_items_expiring ON pantry_items(expiration_date) WHERE expiration_date IS NOT NULL;

-- ==================== Household/Family Sharing ====================

-- Households for family sharing
CREATE TABLE IF NOT EXISTS households (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_households_created_by ON households(created_by);

-- Household members
CREATE TABLE IF NOT EXISTS household_members (
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (household_id, user_id)
);

CREATE INDEX idx_household_members_user ON household_members(user_id);

COMMENT ON TABLE households IS 'Family/household groups for sharing lists and pantry';
COMMENT ON TABLE household_members IS 'Members of a household with their roles';

-- Add household sharing to pantry and shopping lists
ALTER TABLE pantry_items
    ADD COLUMN IF NOT EXISTS household_id UUID REFERENCES households(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS is_shared BOOLEAN DEFAULT false;

ALTER TABLE shopping_lists
    ADD COLUMN IF NOT EXISTS household_id UUID REFERENCES households(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS is_shared BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_pantry_items_household ON pantry_items(household_id) WHERE household_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_shopping_lists_household ON shopping_lists(household_id) WHERE household_id IS NOT NULL;

-- ==================== Store Layouts ====================

-- Store layouts for organization
CREATE TABLE IF NOT EXISTS store_layouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id UUID REFERENCES households(id) ON DELETE CASCADE,
    store_name VARCHAR(200) NOT NULL,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_store_layouts_user ON store_layouts(user_id);
CREATE INDEX idx_store_layouts_household ON store_layouts(household_id) WHERE household_id IS NOT NULL;

-- Store sections within layouts
CREATE TABLE IF NOT EXISTS store_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_layout_id UUID NOT NULL REFERENCES store_layouts(id) ON DELETE CASCADE,
    section_name VARCHAR(100) NOT NULL,
    section_order INTEGER NOT NULL,
    color VARCHAR(7), -- Hex color for visual distinction (#FF6B6B)
    icon VARCHAR(50), -- Icon name for visual representation
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(store_layout_id, section_order),
    UNIQUE(store_layout_id, section_name)
);

CREATE INDEX idx_store_sections_layout ON store_sections(store_layout_id, section_order);

COMMENT ON TABLE store_layouts IS 'Store layouts for organizing shopping lists by aisle/section';
COMMENT ON TABLE store_sections IS 'Sections within a store layout (produce, dairy, etc.)';
COMMENT ON COLUMN store_sections.color IS 'Hex color code for visual distinction';

-- ==================== Enhanced Shopping List Items ====================

-- Add store sections and assignment to shopping list items
ALTER TABLE shopping_list_items
    ADD COLUMN IF NOT EXISTS store_section_id UUID REFERENCES store_sections(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS photo_url VARCHAR(500),
    ADD COLUMN IF NOT EXISTS added_from_recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS purchased_by UUID REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS purchased_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS notes TEXT;

CREATE INDEX IF NOT EXISTS idx_shopping_list_items_section ON shopping_list_items(store_section_id) WHERE store_section_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_shopping_list_items_assigned ON shopping_list_items(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_shopping_list_items_recipe ON shopping_list_items(added_from_recipe_id) WHERE added_from_recipe_id IS NOT NULL;

COMMENT ON COLUMN shopping_list_items.store_section_id IS 'Store section for organized shopping';
COMMENT ON COLUMN shopping_list_items.assigned_to IS 'Household member assigned to buy this item';
COMMENT ON COLUMN shopping_list_items.purchased_by IS 'Who actually purchased the item';

-- ==================== Online Ordering Integration ====================

-- Online ordering integrations (Instacart, Amazon Fresh, etc.)
CREATE TABLE IF NOT EXISTS online_order_integrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id UUID REFERENCES households(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL CHECK (provider IN ('instacart', 'amazon_fresh', 'walmart', 'other')),
    provider_user_id VARCHAR(200),
    auth_token TEXT,
    refresh_token TEXT,
    token_expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_online_orders_user ON online_order_integrations(user_id);
CREATE INDEX idx_online_orders_household ON online_order_integrations(household_id) WHERE household_id IS NOT NULL;

-- Link shopping list items to online products
ALTER TABLE shopping_list_items
    ADD COLUMN IF NOT EXISTS online_product_id VARCHAR(200),
    ADD COLUMN IF NOT EXISTS online_provider VARCHAR(50),
    ADD COLUMN IF NOT EXISTS online_product_url TEXT,
    ADD COLUMN IF NOT EXISTS online_price DECIMAL(10,2);

COMMENT ON TABLE online_order_integrations IS 'Integration with online grocery ordering services';
COMMENT ON COLUMN shopping_list_items.online_product_id IS 'Product ID from online provider';

-- ==================== Triggers ====================

-- Auto-update timestamp for households
CREATE OR REPLACE FUNCTION update_households_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER households_update_timestamp
    BEFORE UPDATE ON households
    FOR EACH ROW
    EXECUTE FUNCTION update_households_timestamp();

-- Auto-update timestamp for store_layouts
CREATE OR REPLACE FUNCTION update_store_layouts_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER store_layouts_update_timestamp
    BEFORE UPDATE ON store_layouts
    FOR EACH ROW
    EXECUTE FUNCTION update_store_layouts_timestamp();

-- Auto-update timestamp for online_order_integrations
CREATE OR REPLACE FUNCTION update_online_order_integrations_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER online_order_integrations_update_timestamp
    BEFORE UPDATE ON online_order_integrations
    FOR EACH ROW
    EXECUTE FUNCTION update_online_order_integrations_timestamp();
