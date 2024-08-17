-- 8 up
ALTER TABLE http_transactions ADD COLUMN os VARCHAR(100);
-- 8 down
ALTER TABLE http_transactions DROP COLUMN os;
