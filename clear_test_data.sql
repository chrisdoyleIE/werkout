-- Clear all test workout data while preserving auth
-- Run this script in your Supabase SQL editor

-- Delete in correct order to respect foreign key constraints

-- First, delete workout sets (they reference workout sessions)
DELETE FROM public.workout_sets;

-- Then, delete personal records
DELETE FROM public.personal_records;

-- Then, delete workout sessions
DELETE FROM public.workout_sessions;

-- Finally, delete user profiles (optional - keeps auth users but clears profile data)
DELETE FROM public.profiles;

-- Reset auto-increment sequences (if any)
-- Note: Since we're using UUID primary keys, no sequences to reset

-- Verify the cleanup
SELECT 'workout_sets' as table_name, COUNT(*) as remaining_rows FROM public.workout_sets
UNION ALL
SELECT 'personal_records', COUNT(*) FROM public.personal_records  
UNION ALL
SELECT 'workout_sessions', COUNT(*) FROM public.workout_sessions
UNION ALL
SELECT 'profiles', COUNT(*) FROM public.profiles;

-- This should show all zeros if the cleanup was successful