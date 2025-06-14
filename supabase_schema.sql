-- Werkout Database Schema

-- Users table (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  full_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workout sessions
CREATE TABLE workout_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  duration_minutes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sets (individual exercise sets within a workout)
CREATE TABLE sets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  workout_session_id UUID REFERENCES workout_sessions(id) ON DELETE CASCADE NOT NULL,
  exercise_id TEXT NOT NULL, -- References exercises.json
  set_number INTEGER NOT NULL,
  reps INTEGER NOT NULL,
  weight_lbs DECIMAL(5,2) NOT NULL,
  rest_seconds INTEGER,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(workout_session_id, exercise_id, set_number)
);

-- Exercise personal records
CREATE TABLE personal_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  exercise_id TEXT NOT NULL,
  max_weight_lbs DECIMAL(5,2) NOT NULL,
  reps INTEGER NOT NULL,
  achieved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id, exercise_id)
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view own workout sessions" ON workout_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workout sessions" ON workout_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workout sessions" ON workout_sessions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own workout sessions" ON workout_sessions
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own sets" ON sets
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM workout_sessions 
      WHERE id = sets.workout_session_id
    )
  );

CREATE POLICY "Users can insert own sets" ON sets
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM workout_sessions 
      WHERE id = sets.workout_session_id
    )
  );

CREATE POLICY "Users can update own sets" ON sets
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT user_id FROM workout_sessions 
      WHERE id = sets.workout_session_id
    )
  );

CREATE POLICY "Users can delete own sets" ON sets
  FOR DELETE USING (
    auth.uid() IN (
      SELECT user_id FROM workout_sessions 
      WHERE id = sets.workout_session_id
    )
  );

CREATE POLICY "Users can view own personal records" ON personal_records
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own personal records" ON personal_records
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own personal records" ON personal_records
  FOR UPDATE USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX idx_workout_sessions_started_at ON workout_sessions(started_at);
CREATE INDEX idx_sets_workout_session_id ON sets(workout_session_id);
CREATE INDEX idx_sets_exercise_id ON sets(exercise_id);
CREATE INDEX idx_personal_records_user_exercise ON personal_records(user_id, exercise_id);

-- Function to automatically update personal records
CREATE OR REPLACE FUNCTION update_personal_record()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate estimated 1RM using Epley formula: weight * (1 + reps/30)
  INSERT INTO personal_records (user_id, exercise_id, max_weight_lbs, reps, achieved_at)
  SELECT 
    ws.user_id,
    NEW.exercise_id,
    NEW.weight_lbs,
    NEW.reps,
    NEW.completed_at
  FROM workout_sessions ws
  WHERE ws.id = NEW.workout_session_id
    AND NEW.weight_lbs * (1 + NEW.reps::decimal / 30) > (
      SELECT COALESCE(max_weight_lbs * (1 + reps::decimal / 30), 0)
      FROM personal_records pr
      WHERE pr.user_id = ws.user_id AND pr.exercise_id = NEW.exercise_id
    )
  ON CONFLICT (user_id, exercise_id) 
  DO UPDATE SET 
    max_weight_lbs = EXCLUDED.max_weight_lbs,
    reps = EXCLUDED.reps,
    achieved_at = EXCLUDED.achieved_at;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update personal records when sets are inserted
CREATE TRIGGER trigger_update_personal_record
  AFTER INSERT ON sets
  FOR EACH ROW
  EXECUTE FUNCTION update_personal_record();