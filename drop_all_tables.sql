-- Drop all tables in public schema (preserves auth schema)
-- This will delete ALL data - only run in development!

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS public.shopping_list_items CASCADE;
DROP TABLE IF EXISTS public.shopping_lists CASCADE;
DROP TABLE IF EXISTS public.meal_plans CASCADE;
DROP TABLE IF EXISTS public.macro_goals CASCADE;
DROP TABLE IF EXISTS public.body_weight_entries CASCADE;
DROP TABLE IF EXISTS public.personal_records CASCADE;
DROP TABLE IF EXISTS public.workout_sets CASCADE;
DROP TABLE IF EXISTS public.workout_sessions CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Drop any remaining functions
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Verify all tables are dropped
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE';