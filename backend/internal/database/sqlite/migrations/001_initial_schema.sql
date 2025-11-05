-- Initial database schema for Space Food application (SQLite)

-- Users table
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login_at DATETIME,
    email_verified INTEGER DEFAULT 0,
    active INTEGER DEFAULT 1
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(active);

-- Recipes table
CREATE TABLE recipes (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    instructions TEXT,
    prep_time INTEGER,
    cook_time INTEGER,
    servings INTEGER,
    difficulty TEXT,
    image_url TEXT,
    source TEXT,
    source_url TEXT,
    rating REAL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_recipes_user_id ON recipes(user_id);
CREATE INDEX idx_recipes_title ON recipes(title);
CREATE INDEX idx_recipes_rating ON recipes(rating);

-- Recipe categories
CREATE TABLE recipe_categories (
    recipe_id TEXT REFERENCES recipes(id) ON DELETE CASCADE,
    category TEXT,
    PRIMARY KEY (recipe_id, category)
);

CREATE INDEX idx_recipe_categories_category ON recipe_categories(category);

-- Recipe tags
CREATE TABLE recipe_tags (
    recipe_id TEXT REFERENCES recipes(id) ON DELETE CASCADE,
    tag TEXT,
    PRIMARY KEY (recipe_id, tag)
);

CREATE INDEX idx_recipe_tags_tag ON recipe_tags(tag);

-- Ingredients table
CREATE TABLE ingredients (
    id TEXT PRIMARY KEY,
    recipe_id TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    quantity REAL,
    unit TEXT,
    notes TEXT,
    optional INTEGER DEFAULT 0,
    display_order INTEGER
);

CREATE INDEX idx_ingredients_recipe_id ON ingredients(recipe_id);

-- Recipe nutrition information
CREATE TABLE recipe_nutrition (
    recipe_id TEXT PRIMARY KEY REFERENCES recipes(id) ON DELETE CASCADE,
    calories REAL,
    protein REAL,
    carbohydrates REAL,
    fat REAL,
    fiber REAL,
    sugar REAL,
    sodium REAL
);

-- Meal plans table
CREATE TABLE meal_plans (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_meal_plans_user_id ON meal_plans(user_id);
CREATE INDEX idx_meal_plans_dates ON meal_plans(start_date, end_date);

-- Planned meals table
CREATE TABLE planned_meals (
    id TEXT PRIMARY KEY,
    meal_plan_id TEXT NOT NULL REFERENCES meal_plans(id) ON DELETE CASCADE,
    recipe_id TEXT REFERENCES recipes(id) ON DELETE SET NULL,
    date DATE NOT NULL,
    meal_type TEXT NOT NULL,
    servings INTEGER DEFAULT 1,
    notes TEXT
);

CREATE INDEX idx_planned_meals_meal_plan_id ON planned_meals(meal_plan_id);
CREATE INDEX idx_planned_meals_recipe_id ON planned_meals(recipe_id);
CREATE INDEX idx_planned_meals_date ON planned_meals(date);

-- Pantry items table
CREATE TABLE pantry_items (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    quantity REAL,
    unit TEXT,
    category TEXT,
    location TEXT,
    purchase_date DATE,
    expiry_date DATE,
    notes TEXT,
    barcode TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pantry_items_user_id ON pantry_items(user_id);
CREATE INDEX idx_pantry_items_category ON pantry_items(category);
CREATE INDEX idx_pantry_items_expiry_date ON pantry_items(expiry_date);

-- Shopping list items table
CREATE TABLE shopping_list_items (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    quantity REAL,
    unit TEXT,
    category TEXT,
    notes TEXT,
    completed INTEGER DEFAULT 0,
    recipe_id TEXT REFERENCES recipes(id) ON DELETE SET NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_shopping_list_items_user_id ON shopping_list_items(user_id);
CREATE INDEX idx_shopping_list_items_completed ON shopping_list_items(completed);
CREATE INDEX idx_shopping_list_items_category ON shopping_list_items(category);

-- Nutrition logs table
CREATE TABLE nutrition_logs (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    meal_type TEXT,
    recipe_id TEXT REFERENCES recipes(id) ON DELETE SET NULL,
    food_name TEXT NOT NULL,
    servings REAL,
    calories REAL,
    protein REAL,
    carbohydrates REAL,
    fat REAL,
    fiber REAL,
    sugar REAL,
    sodium REAL,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_nutrition_logs_user_id ON nutrition_logs(user_id);
CREATE INDEX idx_nutrition_logs_date ON nutrition_logs(date);

-- Enable full-text search for SQLite
CREATE VIRTUAL TABLE recipes_fts USING fts5(title, description, content=recipes, content_rowid=id);
CREATE VIRTUAL TABLE ingredients_fts USING fts5(name, content=ingredients, content_rowid=id);
