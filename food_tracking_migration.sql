-- Food Tracking Enhancement Migration
-- This migration adds necessary columns and indexes for Claude-powered food tracking

-- Add columns to existing food_items table for enhanced functionality
ALTER TABLE public.food_items 
ADD COLUMN IF NOT EXISTS is_verified boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS source_url text,
ADD COLUMN IF NOT EXISTS last_verified_at timestamp with time zone,
ADD COLUMN IF NOT EXISTS created_by_user_id uuid REFERENCES auth.users(id);

-- Add source tracking and confidence to food_entries
ALTER TABLE public.food_entries 
ADD COLUMN IF NOT EXISTS source text CHECK (source IN ('manual', 'voice', 'camera', 'text', 'claude_search', 'meal_template')) DEFAULT 'manual',
ADD COLUMN IF NOT EXISTS confidence_score numeric DEFAULT 1.0 CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0);

-- Create indexes for efficient searching
CREATE INDEX IF NOT EXISTS idx_food_items_name_search ON public.food_items USING gin(to_tsvector('english', name));
CREATE INDEX IF NOT EXISTS idx_food_items_brand_search ON public.food_items USING gin(to_tsvector('english', brand));
CREATE INDEX IF NOT EXISTS idx_food_items_verified ON public.food_items (is_verified);
CREATE INDEX IF NOT EXISTS idx_food_items_name_brand ON public.food_items (name, brand);
CREATE INDEX IF NOT EXISTS idx_food_entries_source ON public.food_entries (source);
CREATE INDEX IF NOT EXISTS idx_food_entries_user_date ON public.food_entries (user_id, consumed_date);

-- Add some sample verified foods to get started (only if they don't already exist)
INSERT INTO public.food_items (name, brand, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, is_verified, source_url)
SELECT * FROM (VALUES
    ('Banana', NULL::text, 89::numeric, 1.1::numeric, 22.8::numeric, 0.3::numeric, true, 'https://fdc.nal.usda.gov/fdc-app.html#/food-details/173944/nutrients'),
    ('Chicken Breast', NULL::text, 165::numeric, 31.0::numeric, 0.0::numeric, 3.6::numeric, true, 'https://fdc.nal.usda.gov/fdc-app.html#/food-details/171077/nutrients'),
    ('White Rice', NULL::text, 130::numeric, 2.7::numeric, 28.2::numeric, 0.3::numeric, true, 'https://fdc.nal.usda.gov/fdc-app.html#/food-details/169704/nutrients'),
    ('Broccoli', NULL::text, 34::numeric, 2.8::numeric, 6.6::numeric, 0.4::numeric, true, 'https://fdc.nal.usda.gov/fdc-app.html#/food-details/170379/nutrients'),
    ('Greek Yogurt', NULL::text, 59::numeric, 10.0::numeric, 3.6::numeric, 0.4::numeric, true, 'https://fdc.nal.usda.gov/fdc-app.html#/food-details/170890/nutrients'),
    ('Oatmeal', NULL::text, 389::numeric, 16.9::numeric, 66.3::numeric, 6.9::numeric, true, 'https://fdc.nal.usda.gov/fdc-app.html#/food-details/173904/nutrients'),
    ('Salmon', NULL::text, 208::numeric, 25.4::numeric, 0.0::numeric, 12.4::numeric, true, 'https://fdc.nal.usda.gov/fdc-app.html#/food-details/175167/nutrients'),
    ('Sweet Potato', NULL::text, 86::numeric, 1.6::numeric, 20.1::numeric, 0.1::numeric, true, 'https://fdc.nal.usda.gov/fdc-app.html#/food-details/168482/nutrients'),
    ('Avocado', NULL::text, 160::numeric, 2.0::numeric, 8.5::numeric, 14.7::numeric, true, 'https://fdc.nal.usda.gov/fdc-app.html#/food-details/171705/nutrients'),
    ('Eggs', NULL::text, 155::numeric, 13.0::numeric, 1.1::numeric, 11.0::numeric, true, 'https://fdc.nal.usda.gov/fdc-app.html#/food-details/173424/nutrients')
) AS new_foods(name, brand, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, is_verified, source_url)
WHERE NOT EXISTS (
    SELECT 1 FROM public.food_items existing 
    WHERE existing.name = new_foods.name 
    AND (existing.brand IS NULL AND new_foods.brand IS NULL OR existing.brand = new_foods.brand)
);

-- Update existing entries to have default source
UPDATE public.food_entries SET source = 'manual' WHERE source IS NULL;

COMMENT ON COLUMN public.food_items.is_verified IS 'Indicates if nutrition data has been verified by Claude or trusted source';
COMMENT ON COLUMN public.food_items.source_url IS 'URL of the nutrition data source for verification';
COMMENT ON COLUMN public.food_items.last_verified_at IS 'When the nutrition data was last verified';
COMMENT ON COLUMN public.food_items.created_by_user_id IS 'User who first added this food item (nullable for system foods)';
COMMENT ON COLUMN public.food_entries.source IS 'How this food entry was logged (manual, voice, camera, text, claude_search)';
COMMENT ON COLUMN public.food_entries.confidence_score IS 'Confidence level of the food identification (0.0 to 1.0)';