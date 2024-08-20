-- 10 up
ALTER TABLE pricing_plans ADD COLUMN stripe_id VARCHAR(100);
-- 10 down
ALTER TABLE pricing_plans DROP COLUMN stripe_id;
