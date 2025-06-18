# Supabase Migration Instructions

## Overview
This migration moves all app data from UserDefaults to Supabase for proper cloud sync. User preference settings (measurement units, temperature units) remain in UserDefaults as intended.

## What Gets Migrated
- ✅ **Meal Plans**: Complete AI-generated meal plans with recipes and nutrition
- ✅ **Shopping Lists**: Shopping lists with item completion tracking
- ✅ **Macro Goals**: User's daily nutrition targets
- ❌ **Settings**: Measurement and temperature units stay in UserDefaults

## Execution Steps

### Step 1: Database Schema Setup

**Simple 2-step process:**

1. **Drop all existing tables:**
   ```sql
   -- Copy and paste the entire content of drop_all_tables.sql into Supabase SQL editor
   ```

2. **Create complete schema:**
   ```sql
   -- Copy and paste the entire content of create_complete_schema.sql into Supabase SQL editor
   ```

### Step 2: Code Integration
The following files have been created/updated:

#### New Files Created:
- `SupabaseService.swift` - Centralized database operations
- `DataMigrationHelper.swift` - Migrates existing UserDefaults data
- `drop_all_tables.sql` - Drops all tables cleanly
- `create_complete_schema.sql` - Creates complete database schema

#### Updated Files:
- `MacroModels.swift` - Updated MealPlanManager and MacroGoalsManager
- `ShoppingListManager.swift` - Updated to use Supabase
- Added new initializers to support database loading

### Step 3: Test the Migration

1. **Build and run the app** - It should automatically load data from Supabase
2. **Test data migration** (if you have existing data):
   ```swift
   // In your app, call this once to migrate existing UserDefaults data
   await DataMigrationHelper.shared.performMigration()
   ```

### Step 4: Verify Everything Works

Test the following functionality:
- ✅ Create new meal plans
- ✅ View existing meal plans
- ✅ Delete meal plans
- ✅ Create shopping lists from meal plans
- ✅ Toggle shopping list item completion
- ✅ Update macro goals
- ✅ Data persists across app restarts
- ✅ Data syncs across devices (if using same account)

## Key Changes Made

### Database Schema
- `macro_goals` table with user_id foreign key
- `meal_plans` table with JSONB content storage
- `shopping_lists` and `shopping_list_items` tables
- Proper RLS policies for data security
- Optimized indexes for performance

### Swift Code Changes
- All managers now use async/await with Supabase
- Added proper error handling
- Added loading states
- Maintains backward compatibility with existing model structures
- Automatic migration from UserDefaults on first run

### Data Migration
- One-time migration from UserDefaults to Supabase
- Graceful fallback if migration fails
- Option to clear old UserDefaults data after successful migration

## Notes
- Settings (measurement units, temperature units) intentionally remain in UserDefaults
- All database operations are secured with Row Level Security (RLS)
- Data is automatically sorted by creation date
- Migration only runs once per device/installation

## Rollback Plan
If issues occur, you can:
1. Revert code changes to use UserDefaults
2. Restore database from backup (if available)
3. Use `DataMigrationHelper.resetMigrationState()` to retry migration