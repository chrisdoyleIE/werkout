-- Complete Werkout Database Schema
-- This creates all tables, policies, indexes, and triggers from scratch

-- =============================================================================
-- TABLES
-- =============================================================================

-- User profiles table
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE,
    full_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Workout sessions table
CREATE TABLE public.workout_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Workout sets table
CREATE TABLE public.workout_sets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    workout_session_id UUID REFERENCES public.workout_sessions(id) ON DELETE CASCADE NOT NULL,
    exercise_id TEXT NOT NULL,
    set_number INTEGER NOT NULL,
    reps INTEGER,
    weight_kg DECIMAL(5,2),
    duration_seconds INTEGER,
    rest_seconds INTEGER,
    completed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Personal records table
CREATE TABLE public.personal_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    exercise_id TEXT NOT NULL,
    max_weight_kg DECIMAL(5,2) NOT NULL,
    reps INTEGER NOT NULL,
    achieved_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, exercise_id)
);

-- Body weight tracking table
CREATE TABLE public.body_weight_entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    weight_kg DECIMAL(5,2) NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    notes TEXT
);

-- Macro nutrition goals table
CREATE TABLE public.macro_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    calories DECIMAL(7,2) NOT NULL,
    protein DECIMAL(6,2) NOT NULL,
    carbs DECIMAL(6,2) NOT NULL,
    fat DECIMAL(6,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Meal plans table
CREATE TABLE public.meal_plans (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    number_of_days INTEGER NOT NULL,
    meal_plan_text TEXT NOT NULL,
    is_ai_generated BOOLEAN NOT NULL DEFAULT false,
    generated_content JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Shopping lists table
CREATE TABLE public.shopping_lists (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    meal_plan_id UUID REFERENCES public.meal_plans(id) ON DELETE CASCADE NOT NULL,
    meal_plan_title TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, meal_plan_id)
);

-- Shopping list items table
CREATE TABLE public.shopping_list_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    shopping_list_id UUID REFERENCES public.shopping_lists(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    category TEXT,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personal_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.body_weight_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.macro_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_list_items ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- RLS POLICIES
-- =============================================================================

-- Profiles policies
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can delete own profile" ON public.profiles
    FOR DELETE USING (auth.uid() = id);

-- Workout sessions policies
CREATE POLICY "Users can view own workout sessions" ON public.workout_sessions
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own workout sessions" ON public.workout_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own workout sessions" ON public.workout_sessions
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own workout sessions" ON public.workout_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- Workout sets policies
CREATE POLICY "Users can view own workout sets" ON public.workout_sets
    FOR SELECT USING (
        auth.uid() = (SELECT user_id FROM public.workout_sessions WHERE id = workout_session_id)
    );
CREATE POLICY "Users can insert own workout sets" ON public.workout_sets
    FOR INSERT WITH CHECK (
        auth.uid() = (SELECT user_id FROM public.workout_sessions WHERE id = workout_session_id)
    );
CREATE POLICY "Users can update own workout sets" ON public.workout_sets
    FOR UPDATE USING (
        auth.uid() = (SELECT user_id FROM public.workout_sessions WHERE id = workout_session_id)
    );
CREATE POLICY "Users can delete own workout sets" ON public.workout_sets
    FOR DELETE USING (
        auth.uid() = (SELECT user_id FROM public.workout_sessions WHERE id = workout_session_id)
    );

-- Personal records policies
CREATE POLICY "Users can view own personal records" ON public.personal_records
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own personal records" ON public.personal_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own personal records" ON public.personal_records
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own personal records" ON public.personal_records
    FOR DELETE USING (auth.uid() = user_id);

-- Body weight entries policies
CREATE POLICY "Users can view own body weight entries" ON public.body_weight_entries
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own body weight entries" ON public.body_weight_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own body weight entries" ON public.body_weight_entries
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own body weight entries" ON public.body_weight_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Macro goals policies
CREATE POLICY "Users can view own macro goals" ON public.macro_goals
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own macro goals" ON public.macro_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own macro goals" ON public.macro_goals
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own macro goals" ON public.macro_goals
    FOR DELETE USING (auth.uid() = user_id);

-- Meal plans policies
CREATE POLICY "Users can view own meal plans" ON public.meal_plans
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own meal plans" ON public.meal_plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own meal plans" ON public.meal_plans
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own meal plans" ON public.meal_plans
    FOR DELETE USING (auth.uid() = user_id);

-- Shopping lists policies
CREATE POLICY "Users can view own shopping lists" ON public.shopping_lists
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own shopping lists" ON public.shopping_lists
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own shopping lists" ON public.shopping_lists
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own shopping lists" ON public.shopping_lists
    FOR DELETE USING (auth.uid() = user_id);

-- Shopping list items policies
CREATE POLICY "Users can view own shopping list items" ON public.shopping_list_items
    FOR SELECT USING (
        auth.uid() = (SELECT user_id FROM public.shopping_lists WHERE id = shopping_list_id)
    );
CREATE POLICY "Users can insert own shopping list items" ON public.shopping_list_items
    FOR INSERT WITH CHECK (
        auth.uid() = (SELECT user_id FROM public.shopping_lists WHERE id = shopping_list_id)
    );
CREATE POLICY "Users can update own shopping list items" ON public.shopping_list_items
    FOR UPDATE USING (
        auth.uid() = (SELECT user_id FROM public.shopping_lists WHERE id = shopping_list_id)
    );
CREATE POLICY "Users can delete own shopping list items" ON public.shopping_list_items
    FOR DELETE USING (
        auth.uid() = (SELECT user_id FROM public.shopping_lists WHERE id = shopping_list_id)
    );

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Profile indexes
CREATE INDEX idx_profiles_username ON public.profiles(username);

-- Workout indexes
CREATE INDEX idx_workout_sessions_user_id ON public.workout_sessions(user_id);
CREATE INDEX idx_workout_sessions_started_at ON public.workout_sessions(started_at);
CREATE INDEX idx_workout_sets_session_id ON public.workout_sets(workout_session_id);
CREATE INDEX idx_workout_sets_exercise_id ON public.workout_sets(exercise_id);

-- Personal records indexes
CREATE INDEX idx_personal_records_user_id ON public.personal_records(user_id);
CREATE INDEX idx_personal_records_exercise_id ON public.personal_records(exercise_id);

-- Body weight indexes
CREATE INDEX idx_body_weight_entries_user_id ON public.body_weight_entries(user_id);
CREATE INDEX idx_body_weight_entries_recorded_at ON public.body_weight_entries(recorded_at);

-- Meal planning indexes
CREATE INDEX idx_macro_goals_user_id ON public.macro_goals(user_id);
CREATE INDEX idx_meal_plans_user_id ON public.meal_plans(user_id);
CREATE INDEX idx_meal_plans_start_date ON public.meal_plans(start_date);
CREATE INDEX idx_meal_plans_created_at ON public.meal_plans(created_at);
CREATE INDEX idx_shopping_lists_user_id ON public.shopping_lists(user_id);
CREATE INDEX idx_shopping_lists_meal_plan_id ON public.shopping_lists(meal_plan_id);
CREATE INDEX idx_shopping_list_items_shopping_list_id ON public.shopping_list_items(shopping_list_id);
CREATE INDEX idx_shopping_list_items_category ON public.shopping_list_items(category);

-- =============================================================================
-- TRIGGERS AND FUNCTIONS
-- =============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at columns
CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_macro_goals_updated_at 
    BEFORE UPDATE ON public.macro_goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meal_plans_updated_at 
    BEFORE UPDATE ON public.meal_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shopping_lists_updated_at 
    BEFORE UPDATE ON public.shopping_lists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shopping_list_items_updated_at 
    BEFORE UPDATE ON public.shopping_list_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- VERIFICATION
-- =============================================================================

-- Show all created tables
SELECT table_name, 
       (SELECT count(*) FROM information_schema.columns WHERE table_name = t.table_name AND table_schema = 'public') as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;