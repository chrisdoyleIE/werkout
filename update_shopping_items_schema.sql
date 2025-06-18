-- Update shopping_list_items table to support new structure
-- This adds the amount column and updates category to use enum values

-- Add amount column to shopping_list_items table
ALTER TABLE public.shopping_list_items 
ADD COLUMN IF NOT EXISTS amount TEXT NOT NULL DEFAULT '';

-- Update existing category values to match new enum
UPDATE public.shopping_list_items 
SET category = CASE 
    WHEN category ILIKE '%dairy%' OR category ILIKE '%milk%' OR category ILIKE '%cheese%' OR category ILIKE '%yogurt%' OR category ILIKE '%butter%' OR category ILIKE '%cream%' OR category ILIKE '%egg%' THEN 'Dairy'
    WHEN category ILIKE '%meat%' OR category ILIKE '%fish%' OR category ILIKE '%chicken%' OR category ILIKE '%beef%' OR category ILIKE '%pork%' OR category ILIKE '%seafood%' OR category ILIKE '%salmon%' OR category ILIKE '%cod%' THEN 'Meat & Fish'
    WHEN category ILIKE '%fruit%' OR category ILIKE '%veg%' OR category ILIKE '%vegetable%' OR category ILIKE '%produce%' OR category ILIKE '%fresh%' OR category ILIKE '%herb%' OR category ILIKE '%salad%' THEN 'Fruit & Veg'
    WHEN category ILIKE '%frozen%' OR category ILIKE '%ice%' THEN 'Frozen'
    WHEN category ILIKE '%bread%' OR category ILIKE '%grain%' OR category ILIKE '%cereal%' OR category ILIKE '%oat%' OR category ILIKE '%rice%' OR category ILIKE '%pasta%' OR category ILIKE '%flour%' THEN 'Breads & Grains'
    WHEN category ILIKE '%cupboard%' OR category ILIKE '%pantry%' OR category ILIKE '%spice%' OR category ILIKE '%oil%' OR category ILIKE '%vinegar%' OR category ILIKE '%can%' OR category ILIKE '%jar%' OR category ILIKE '%dry%' OR category ILIKE '%baking%' THEN 'Store Cupboard'
    ELSE 'Other'
END
WHERE category IS NOT NULL;

-- Set default category for NULL values
UPDATE public.shopping_list_items 
SET category = 'Other' 
WHERE category IS NULL;

-- Make category column NOT NULL now that we've updated all values
ALTER TABLE public.shopping_list_items 
ALTER COLUMN category SET NOT NULL;

-- Create index on category for better query performance
CREATE INDEX IF NOT EXISTS idx_shopping_list_items_category_amount ON public.shopping_list_items(category, amount);

-- Verify the changes
SELECT 
    category,
    COUNT(*) as item_count,
    COUNT(CASE WHEN amount != '' THEN 1 END) as items_with_amount
FROM public.shopping_list_items 
GROUP BY category 
ORDER BY category;