-- Meal Tracking Database Schema for Supabase
-- Add these tables to support nutrition tracking functionality

-- Create nutrition_goals table
CREATE TABLE public.nutrition_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    daily_calories INTEGER NOT NULL DEFAULT 2000,
    daily_protein_g INTEGER NOT NULL DEFAULT 150,
    daily_carbs_g INTEGER NOT NULL DEFAULT 200,
    daily_fat_g INTEGER NOT NULL DEFAULT 80,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(user_id) -- One active goal set per user
);

-- Create food_items table (reference database)
CREATE TABLE public.food_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    brand TEXT,
    barcode TEXT,
    -- Nutritional information per 100g
    calories_per_100g DECIMAL(6,2) NOT NULL,
    protein_per_100g DECIMAL(5,2) NOT NULL DEFAULT 0,
    carbs_per_100g DECIMAL(5,2) NOT NULL DEFAULT 0,
    fat_per_100g DECIMAL(5,2) NOT NULL DEFAULT 0,
    fiber_per_100g DECIMAL(5,2) DEFAULT 0,
    sugar_per_100g DECIMAL(5,2) DEFAULT 0,
    sodium_per_100g DECIMAL(6,2) DEFAULT 0, -- in mg
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create food_entries table
CREATE TABLE public.food_entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    food_item_id UUID REFERENCES public.food_items(id) ON DELETE CASCADE NOT NULL,
    consumed_date DATE NOT NULL,
    meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    quantity_grams DECIMAL(8,2) NOT NULL,
    -- Calculated nutritional values based on actual quantity
    calories DECIMAL(8,2) NOT NULL,
    protein_g DECIMAL(6,2) NOT NULL,
    carbs_g DECIMAL(6,2) NOT NULL,
    fat_g DECIMAL(6,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create shopping_list_items table
CREATE TABLE public.shopping_list_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    item_name TEXT NOT NULL,
    quantity TEXT, -- e.g., "2 lbs", "1 dozen", etc.
    is_checked BOOLEAN NOT NULL DEFAULT FALSE,
    category TEXT, -- e.g., "produce", "dairy", "meat", etc.
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.nutrition_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_list_items ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for nutrition_goals
CREATE POLICY "Users can view own nutrition goals" ON public.nutrition_goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own nutrition goals" ON public.nutrition_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own nutrition goals" ON public.nutrition_goals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own nutrition goals" ON public.nutrition_goals
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for food_items (public read access for reference data)
CREATE POLICY "Anyone can view food items" ON public.food_items
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert food items" ON public.food_items
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update food items" ON public.food_items
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Create RLS policies for food_entries
CREATE POLICY "Users can view own food entries" ON public.food_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own food entries" ON public.food_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own food entries" ON public.food_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own food entries" ON public.food_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for shopping_list_items
CREATE POLICY "Users can view own shopping list items" ON public.shopping_list_items
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own shopping list items" ON public.shopping_list_items
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own shopping list items" ON public.shopping_list_items
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own shopping list items" ON public.shopping_list_items
    FOR DELETE USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX idx_nutrition_goals_user_id ON public.nutrition_goals(user_id);

CREATE INDEX idx_food_items_name ON public.food_items(name);
CREATE INDEX idx_food_items_barcode ON public.food_items(barcode);
-- For text search, we'll use a standard index on lowercase name
CREATE INDEX idx_food_items_name_lower ON public.food_items(LOWER(name));

CREATE INDEX idx_food_entries_user_id ON public.food_entries(user_id);
CREATE INDEX idx_food_entries_consumed_date ON public.food_entries(consumed_date);
CREATE INDEX idx_food_entries_user_date ON public.food_entries(user_id, consumed_date);
CREATE INDEX idx_food_entries_meal_type ON public.food_entries(meal_type);

CREATE INDEX idx_shopping_list_items_user_id ON public.shopping_list_items(user_id);
CREATE INDEX idx_shopping_list_items_category ON public.shopping_list_items(category);
CREATE INDEX idx_shopping_list_items_checked ON public.shopping_list_items(is_checked);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at columns
CREATE TRIGGER update_nutrition_goals_updated_at 
    BEFORE UPDATE ON public.nutrition_goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_food_items_updated_at 
    BEFORE UPDATE ON public.food_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shopping_list_items_updated_at 
    BEFORE UPDATE ON public.shopping_list_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample food items for testing
INSERT INTO public.food_items (name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g) VALUES
('Chicken Breast (Raw)', 165, 31.0, 0, 3.6),
('Brown Rice (Cooked)', 112, 2.6, 22.9, 0.9),
('Broccoli (Raw)', 34, 2.8, 6.6, 0.4),
('Greek Yogurt (Plain)', 59, 10.3, 3.6, 0.4),
('Banana', 89, 1.1, 22.8, 0.3),
('Oats (Dry)', 389, 16.9, 66.3, 6.9),
('Almonds', 579, 21.2, 21.6, 49.9),
('Eggs (Large, Raw)', 155, 13.0, 1.1, 11.0),
('Sweet Potato (Raw)', 86, 1.6, 20.1, 0.1),
('Salmon (Raw)', 208, 25.4, 0, 12.4),
('Avocado', 160, 2.0, 8.5, 14.7),
('Quinoa (Cooked)', 120, 4.4, 21.3, 1.9);

-- Sample nutrition goals (these would be set by users)
-- Note: This is just for reference, actual goals will be set via the app
/*
Example usage:
INSERT INTO public.nutrition_goals (user_id, daily_calories, daily_protein_g, daily_carbs_g, daily_fat_g)
VALUES (auth.uid(), 2000, 150, 200, 80);
*/