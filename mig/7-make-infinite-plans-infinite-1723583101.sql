-- 7 up
BEGIN;
UPDATE pricing_plans SET max_applications = 2147483647 WHERE max_applications = -1;
UPDATE pricing_plans SET max_api_keys = 2147483647 WHERE max_api_keys = -1;
UPDATE pricing_plans SET max_users = 2147483647 WHERE max_users = -1;
COMMIT;
-- 7 down
BEGIN;
UPDATE pricing_plans SET max_applications = -1 WHERE max_applications = 2147483647;
UPDATE pricing_plans SET max_api_keys = -1 WHERE max_api_keys = 2147483647;
UPDATE pricing_plans SET max_users = -1 WHERE max_users = 2147483647;
COMMIT;
