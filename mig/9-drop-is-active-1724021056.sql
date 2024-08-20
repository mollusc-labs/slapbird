-- 9 up
ALTER TABLE user_pricing_plans DROP COLUMN is_active;
ALTER TABLE user_pricing_plans ADD COLUMN on_hold BOOLEAN;
ALTER TABLE user_pricing_plans ALTER COLUMN on_hold SET DEFAULT false;
-- 9 down
ALTER TABLE user_pricing_plans DROP COLUMN on_hold;
ALTER TABLE user_pricing_plans ADD COLUMN is_active BOOLEAN;
ALTER TABLE user_pricing_plans ALTER COLUMN is_active SET DEFAULT true;
