-- Create profiles table
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE,
    full_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create workout_sessions table
CREATE TABLE public.workout_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create workout_sets table
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

-- Create personal_records table
CREATE TABLE public.personal_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    exercise_id TEXT NOT NULL,
    max_weight_kg DECIMAL(5,2) NOT NULL,
    reps INTEGER NOT NULL,
    achieved_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, exercise_id)
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personal_records ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for profiles
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can delete own profile" ON public.profiles
    FOR DELETE USING (auth.uid() = id);

-- Create RLS policies for workout_sessions
CREATE POLICY "Users can view own workout sessions" ON public.workout_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workout sessions" ON public.workout_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workout sessions" ON public.workout_sessions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own workout sessions" ON public.workout_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for workout_sets
CREATE POLICY "Users can view own workout sets" ON public.workout_sets
    FOR SELECT USING (
        auth.uid() = (
            SELECT user_id FROM public.workout_sessions
            WHERE id = workout_session_id
        )
    );

CREATE POLICY "Users can insert own workout sets" ON public.workout_sets
    FOR INSERT WITH CHECK (
        auth.uid() = (
            SELECT user_id FROM public.workout_sessions
            WHERE id = workout_session_id
        )
    );

CREATE POLICY "Users can update own workout sets" ON public.workout_sets
    FOR UPDATE USING (
        auth.uid() = (
            SELECT user_id FROM public.workout_sessions
            WHERE id = workout_session_id
        )
    );

CREATE POLICY "Users can delete own workout sets" ON public.workout_sets
    FOR DELETE USING (
        auth.uid() = (
            SELECT user_id FROM public.workout_sessions
            WHERE id = workout_session_id
        )
    );

-- Create RLS policies for personal_records
CREATE POLICY "Users can view own personal records" ON public.personal_records
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own personal records" ON public.personal_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own personal records" ON public.personal_records
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own personal records" ON public.personal_records
    FOR DELETE USING (auth.uid() = user_id);

-- Create body_weight_entries table
CREATE TABLE public.body_weight_entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    weight_kg DECIMAL(5,2) NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    notes TEXT
);

-- Enable Row Level Security for body_weight_entries
ALTER TABLE public.body_weight_entries ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for body_weight_entries
CREATE POLICY "Users can view own body weight entries" ON public.body_weight_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own body weight entries" ON public.body_weight_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own body weight entries" ON public.body_weight_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own body weight entries" ON public.body_weight_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX idx_profiles_username ON public.profiles(username);
CREATE INDEX idx_workout_sessions_user_id ON public.workout_sessions(user_id);
CREATE INDEX idx_workout_sessions_started_at ON public.workout_sessions(started_at);
CREATE INDEX idx_workout_sets_session_id ON public.workout_sets(workout_session_id);
CREATE INDEX idx_workout_sets_exercise_id ON public.workout_sets(exercise_id);
CREATE INDEX idx_personal_records_user_id ON public.personal_records(user_id);
CREATE INDEX idx_personal_records_exercise_id ON public.personal_records(exercise_id);
CREATE INDEX idx_body_weight_entries_user_id ON public.body_weight_entries(user_id);
CREATE INDEX idx_body_weight_entries_recorded_at ON public.body_weight_entries(recorded_at);