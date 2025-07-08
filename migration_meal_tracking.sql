-- Meal-Based Food Tracking Migration
-- Run this in Supabase SQL Editor

-- 1. Add meal grouping support to food_entries
ALTER TABLE public.food_entries 
ADD COLUMN IF NOT EXISTS meal_group_id uuid,
ADD COLUMN IF NOT EXISTS meal_group_name text,
ADD COLUMN IF NOT EXISTS is_meal_template boolean DEFAULT false;

-- Create index for efficient meal group queries
CREATE INDEX IF NOT EXISTS idx_food_entries_meal_group 
ON public.food_entries(meal_group_id) 
WHERE meal_group_id IS NOT NULL;

-- Create index for meal templates
CREATE INDEX IF NOT EXISTS idx_food_entries_meal_templates 
ON public.food_entries(user_id, is_meal_template) 
WHERE is_meal_template = true;

-- 2. Enhance food_items table for user-created foods
ALTER TABLE public.food_items 
ADD COLUMN IF NOT EXISTS created_by_user_id uuid REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS is_user_recipe boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS serving_size_name text,
ADD COLUMN IF NOT EXISTS serving_size_grams numeric,
ADD COLUMN IF NOT EXISTS use_count integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_used_at timestamp with time zone;

-- Create index for better search performance
CREATE INDEX IF NOT EXISTS idx_food_items_search 
ON public.food_items 
USING gin(to_tsvector('english', name || ' ' || COALESCE(brand, '')));

-- Create index for user-created foods
CREATE INDEX IF NOT EXISTS idx_food_items_user_created 
ON public.food_items(created_by_user_id) 
WHERE created_by_user_id IS NOT NULL;

-- 3. Create view for meal templates
CREATE OR REPLACE VIEW public.meal_templates AS
SELECT 
  fe.meal_group_id,
  fe.meal_group_name,
  fe.user_id,
  COUNT(*) as component_count,
  array_agg(
    json_build_object(
      'food_item_id', fe.food_item_id,
      'quantity_grams', fe.quantity_grams,
      'food_name', fi.name,
      'brand', fi.brand,
      'calories_per_100g', fi.calories_per_100g,
      'protein_per_100g', fi.protein_per_100g,
      'carbs_per_100g', fi.carbs_per_100g,
      'fat_per_100g', fi.fat_per_100g
    ) ORDER BY fe.created_at
  ) as components,
  SUM(fe.calories) as total_calories,
  SUM(fe.protein_g) as total_protein,
  SUM(fe.carbs_g) as total_carbs,
  SUM(fe.fat_g) as total_fat,
  MAX(fe.created_at) as last_used,
  COUNT(DISTINCT DATE(fe.created_at)) as use_count
FROM public.food_entries fe
JOIN public.food_items fi ON fe.food_item_id = fi.id
WHERE fe.meal_group_id IS NOT NULL 
  AND fe.is_meal_template = true
GROUP BY fe.meal_group_id, fe.meal_group_name, fe.user_id;

-- 4. Create function to get recent foods and meals
CREATE OR REPLACE FUNCTION public.get_recent_foods_and_meals(
  p_user_id uuid,
  p_days integer DEFAULT 7,
  p_meal_type text DEFAULT NULL
)
RETURNS TABLE (
  item_type text,
  item_id uuid,
  name text,
  brand text,
  last_used timestamp with time zone,
  use_count bigint,
  avg_quantity numeric,
  calories_per_serving numeric,
  protein_per_serving numeric,
  is_meal boolean,
  components jsonb
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  -- Recent individual foods
  SELECT 
    'food'::text as item_type,
    fi.id as item_id,
    fi.name,
    fi.brand,
    MAX(fe.created_at) as last_used,
    COUNT(*)::bigint as use_count,
    AVG(fe.quantity_grams) as avg_quantity,
    AVG(fe.calories) as calories_per_serving,
    AVG(fe.protein_g) as protein_per_serving,
    false as is_meal,
    NULL::jsonb as components
  FROM public.food_entries fe
  JOIN public.food_items fi ON fe.food_item_id = fi.id
  WHERE fe.user_id = p_user_id
    AND fe.created_at >= NOW() - INTERVAL '1 day' * p_days
    AND fe.meal_group_id IS NULL  -- Individual foods only
    AND (p_meal_type IS NULL OR fe.meal_type = p_meal_type)
  GROUP BY fi.id, fi.name, fi.brand
  
  UNION ALL
  
  -- Recent meals
  SELECT 
    'meal'::text as item_type,
    mt.meal_group_id as item_id,
    mt.meal_group_name as name,
    NULL::text as brand,
    mt.last_used,
    mt.use_count::bigint,
    NULL::numeric as avg_quantity,
    mt.total_calories as calories_per_serving,
    mt.total_protein as protein_per_serving,
    true as is_meal,
    to_jsonb(mt.components) as components
  FROM public.meal_templates mt
  WHERE mt.user_id = p_user_id
  
  -- Order by recency and frequency
  ORDER BY last_used DESC, use_count DESC
  LIMIT 20;
END;
$$;

-- 5. Create function to save a meal template
CREATE OR REPLACE FUNCTION public.save_meal_template(
  p_user_id uuid,
  p_meal_name text,
  p_food_entries uuid[]
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_meal_group_id uuid;
BEGIN
  -- Generate new meal group ID
  v_meal_group_id := gen_random_uuid();
  
  -- Update the food entries to be part of this meal template
  UPDATE public.food_entries
  SET 
    meal_group_id = v_meal_group_id,
    meal_group_name = p_meal_name,
    is_meal_template = true
  WHERE id = ANY(p_food_entries)
    AND user_id = p_user_id;
    
  RETURN v_meal_group_id;
END;
$$;

-- 6. Create function to log a meal from template
CREATE OR REPLACE FUNCTION public.log_meal_from_template(
  p_user_id uuid,
  p_meal_group_id uuid,
  p_meal_type text,
  p_consumed_date date DEFAULT CURRENT_DATE,
  p_scale_factor numeric DEFAULT 1.0
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_meal_group_id uuid;
  v_template_entry RECORD;
BEGIN
  -- Generate new meal group ID for this instance
  v_new_meal_group_id := gen_random_uuid();
  
  -- Copy all entries from the template
  FOR v_template_entry IN 
    SELECT fe.*, fi.calories_per_100g, fi.protein_per_100g, fi.carbs_per_100g, fi.fat_per_100g
    FROM public.food_entries fe
    JOIN public.food_items fi ON fe.food_item_id = fi.id
    WHERE fe.meal_group_id = p_meal_group_id
      AND fe.is_meal_template = true
  LOOP
    INSERT INTO public.food_entries (
      user_id,
      food_item_id,
      consumed_date,
      meal_type,
      quantity_grams,
      calories,
      protein_g,
      carbs_g,
      fat_g,
      meal_group_id,
      meal_group_name,
      is_meal_template,
      source
    ) VALUES (
      p_user_id,
      v_template_entry.food_item_id,
      p_consumed_date,
      p_meal_type,
      v_template_entry.quantity_grams * p_scale_factor,
      (v_template_entry.calories_per_100g * v_template_entry.quantity_grams * p_scale_factor) / 100,
      (v_template_entry.protein_per_100g * v_template_entry.quantity_grams * p_scale_factor) / 100,
      (v_template_entry.carbs_per_100g * v_template_entry.quantity_grams * p_scale_factor) / 100,
      (v_template_entry.fat_per_100g * v_template_entry.quantity_grams * p_scale_factor) / 100,
      v_new_meal_group_id,
      v_template_entry.meal_group_name,
      false,  -- This is an instance, not a template
      'meal_template'
    );
  END LOOP;
  
  -- Update use count for food items
  UPDATE public.food_items fi
  SET 
    use_count = COALESCE(use_count, 0) + 1,
    last_used_at = NOW()
  WHERE fi.id IN (
    SELECT food_item_id 
    FROM public.food_entries 
    WHERE meal_group_id = v_new_meal_group_id
  );
  
  RETURN v_new_meal_group_id;
END;
$$;

-- 7. Create RLS policies for new functionality
-- Enable RLS if not already enabled
ALTER TABLE public.food_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;

-- Policy for users to see their own meal templates
CREATE POLICY "Users can view own meal templates" ON public.food_entries
  FOR SELECT USING (auth.uid() = user_id);

-- Policy for users to create meal templates
CREATE POLICY "Users can create meal templates" ON public.food_entries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy for users to update their meal templates
CREATE POLICY "Users can update own meal templates" ON public.food_entries
  FOR UPDATE USING (auth.uid() = user_id);

-- Policy for users to see all verified food items and their own created items
CREATE POLICY "Users can view food items" ON public.food_items
  FOR SELECT USING (
    is_verified = true 
    OR created_by_user_id = auth.uid() 
    OR created_by_user_id IS NULL
  );

-- Policy for users to create food items
CREATE POLICY "Users can create food items" ON public.food_items
  FOR INSERT WITH CHECK (
    created_by_user_id = auth.uid() 
    OR created_by_user_id IS NULL
  );

-- Policy for users to update their own food items
CREATE POLICY "Users can update own food items" ON public.food_items
  FOR UPDATE USING (created_by_user_id = auth.uid());

-- 8. Create helpful indexes for performance
CREATE INDEX IF NOT EXISTS idx_food_entries_user_date 
ON public.food_entries(user_id, consumed_date DESC);

CREATE INDEX IF NOT EXISTS idx_food_items_last_used 
ON public.food_items(last_used_at DESC NULLS LAST) 
WHERE last_used_at IS NOT NULL;

-- 9. Grant necessary permissions
GRANT SELECT ON public.meal_templates TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_recent_foods_and_meals TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_meal_template TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_meal_from_template TO authenticated;