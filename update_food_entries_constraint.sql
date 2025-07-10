-- Update food_entries source constraint to include meal_template
-- This fixes the constraint violation when saving meals

-- Drop the existing constraint
ALTER TABLE public.food_entries DROP CONSTRAINT IF EXISTS food_entries_source_check;

-- Add the updated constraint with meal_template included
ALTER TABLE public.food_entries 
ADD CONSTRAINT food_entries_source_check 
CHECK (source IN ('manual', 'voice', 'camera', 'text', 'claude_search', 'meal_template'));

-- Update comment for the source column
COMMENT ON COLUMN public.food_entries.source IS 'How this food entry was logged (manual, voice, camera, text, claude_search, meal_template)';